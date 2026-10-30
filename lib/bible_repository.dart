import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class BibleBook {
  const BibleBook({required this.name, required this.chapters});
  final String name;
  final List<BibleChapter> chapters;

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      name: json['englishName']?.toString() ?? json['book']?.toString() ?? '',
      chapters: (json['chapters'] as List? ?? const [])
          .map((chapter) => BibleChapter.fromJson(
                Map<String, dynamic>.from(chapter as Map),
              ))
          .toList(),
    );
  }
}

class BibleChapter {
  const BibleChapter({required this.number, required this.verses});
  final int number;
  final List<BibleVerse> verses;

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    return BibleChapter(
      number: (json['chapter'] as num?)?.toInt() ?? 0,
      verses: (json['verses'] as List? ?? const [])
          .map((verse) => BibleVerse.fromJson(
                Map<String, dynamic>.from(verse as Map),
              ))
          .toList(),
    );
  }
}

class BibleVerse {
  const BibleVerse({required this.number, required this.text});
  final int number;
  final String text;

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      number: (json['number'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
    );
  }
}

class BibleRepository {
  static const translation = 'World English Bible (WEB)';
  static const _dbName = 'ngn_bible.db';

  static const _books = <String>[
    'Genesis','Exodus','Leviticus','Numbers','Deuteronomy','Joshua','Judges','Ruth',
    '1 Samuel','2 Samuel','1 Kings','2 Kings','1 Chronicles','2 Chronicles','Ezra',
    'Nehemiah','Esther','Job','Psalms','Proverbs','Ecclesiastes','Song of Solomon',
    'Isaiah','Jeremiah','Lamentations','Ezekiel','Daniel','Hosea','Joel','Amos',
    'Obadiah','Jonah','Micah','Nahum','Habakkuk','Zephaniah','Haggai','Zechariah',
    'Malachi','Matthew','Mark','Luke','John','Acts','Romans','1 Corinthians',
    '2 Corinthians','Galatians','Ephesians','Philippians','Colossians',
    '1 Thessalonians','2 Thessalonians','1 Timothy','2 Timothy','Titus','Philemon',
    'Hebrews','James','1 Peter','2 Peter','1 John','2 John','3 John','Jude',
    'Revelation',
  ];

  Database? _database;

  List<String> get bookNames => List.unmodifiable(_books);

  Future<Database> _open() async {
    if (_database != null) return _database!;
    final path = '${await getDatabasesPath()}/$_dbName';
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE verses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL,
            UNIQUE(book, chapter, verse)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_bible_search ON verses(book, chapter, verse)',
        );
      },
    );
    return _database!;
  }

  Future<bool> isBookAvailable(String book) async {
    final db = await _open();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM verses WHERE book = ?',
      [book],
    );
    return ((result.first['count'] as num?) ?? 0) > 0;
  }

  Future<void> importBook(String book) async {
    final db = await _open();
    final raw = await rootBundle.loadString('assets/bible/books/$book.json');
    final parsed = BibleBook.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final chapter in parsed.chapters) {
        for (final verse in chapter.verses) {
          batch.insert(
            'verses',
            {
              'book': parsed.name,
              'chapter': chapter.number,
              'verse': verse.number,
              'text': verse.text,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> ensureBook(String book) async {
    if (!await isBookAvailable(book)) {
      await importBook(book);
    }
  }

  Future<List<BibleChapter>> chapters(String book) async {
    await ensureBook(book);
    final db = await _open();
    final rows = await db.query(
      'verses',
      columns: ['chapter', 'verse', 'text'],
      where: 'book = ?',
      whereArgs: [book],
      orderBy: 'chapter ASC, verse ASC',
    );

    final byChapter = <int, List<BibleVerse>>{};
    for (final row in rows) {
      final chapter = row['chapter'] as int;
      byChapter.putIfAbsent(chapter, () => []).add(
            BibleVerse(
              number: row['verse'] as int,
              text: row['text'] as String,
            ),
          );
    }

    return byChapter.entries
        .map((entry) => BibleChapter(number: entry.key, verses: entry.value))
        .toList();
  }

  Future<List<BibleVerse>> verses(String book, int chapter) async {
    await ensureBook(book);
    final db = await _open();
    final rows = await db.query(
      'verses',
      columns: ['verse', 'text'],
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse ASC',
    );

    return rows
        .map((row) => BibleVerse(
              number: row['verse'] as int,
              text: row['text'] as String,
            ))
        .toList();
  }

  Future<List<Map<String, Object?>>> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];

    for (final book in _books) {
      await ensureBook(book);
    }

    final db = await _open();

    // Reference search without a regular expression, e.g. John 3:16 or Romans 8.
    final parts = clean.split(RegExp(r'\\s+'));
    if (parts.length >= 2) {
      final last = parts.last;
      final referenceParts = last.split(':');
      final chapter = int.tryParse(referenceParts.first);
      final verse = referenceParts.length == 2
          ? int.tryParse(referenceParts[1])
          : null;
      final requestedBook =
          parts.sublist(0, parts.length - 1).join(' ').toLowerCase();

      String? book;
      for (final candidate in _books) {
        if (candidate.toLowerCase() == requestedBook) {
          book = candidate;
          break;
        }
      }

      if (book != null && chapter != null) {
        if (referenceParts.length == 2 && verse != null) {
          return db.query(
            'verses',
            columns: ['book', 'chapter', 'verse', 'text'],
            where: 'book = ? AND chapter = ? AND verse = ?',
            whereArgs: [book, chapter, verse],
            orderBy: 'verse ASC',
            limit: 100,
          );
        }
        if (referenceParts.length == 1) {
          return db.query(
            'verses',
            columns: ['book', 'chapter', 'verse', 'text'],
            where: 'book = ? AND chapter = ?',
            whereArgs: [book, chapter],
            orderBy: 'verse ASC',
            limit: 100,
          );
        }
      }
    }

    return db.query(
      'verses',
      columns: ['book', 'chapter', 'verse', 'text'],
      where: 'LOWER(text) LIKE ?',
      whereArgs: ['%${clean.toLowerCase()}%'],
      orderBy: 'book ASC, chapter ASC, verse ASC',
      limit: 100,
    );
  }
}
