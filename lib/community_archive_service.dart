import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistent, device-only archive for Community messages and media.
/// Local removals never delete the corresponding server message.
class CommunityArchiveService {
  CommunityArchiveService._();
  static final CommunityArchiveService instance = CommunityArchiveService._();

  Database? _database;
  final Set<String> _hiddenMessageIds = {};

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final directory = await getApplicationSupportDirectory();
    _database = await openDatabase(
      '${directory.path}/ngn_community_archive.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            payload TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE media (
            message_id TEXT PRIMARY KEY,
            local_path TEXT NOT NULL,
            bucket TEXT NOT NULL,
            storage_path TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE hidden_messages (
            id TEXT PRIMARY KEY,
            hidden_at TEXT NOT NULL
          )
        ''');
      },
    );
    final hiddenRows = await _database!.query('hidden_messages', columns: ['id']);
    _hiddenMessageIds.addAll(hiddenRows.map((row) => row['id'] as String));
    return _database!;
  }

  List<Map<String, dynamic>> filterVisibleMessages(
    List<Map<String, dynamic>> rows,
  ) => rows.where((row) => !_hiddenMessageIds.contains(row['id']?.toString())).toList();

  Future<void> cacheMessages(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final db = await _db;
    final hidden = _hiddenMessageIds;
    final batch = db.batch();
    for (final row in rows) {
      final id = row['id']?.toString();
      final createdAt = row['created_at']?.toString();
      if (id == null || createdAt == null || hidden.contains(id)) continue;
      batch.insert(
        'messages',
        {
          'id': id,
          'created_at': createdAt,
          'payload': jsonEncode(row),
          'cached_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> loadMessages() async {
    final db = await _db;
    final rows = await db.query('messages', orderBy: 'created_at ASC');
    return rows
        .map((row) => Map<String, dynamic>.from(
              jsonDecode(row['payload'] as String) as Map,
            ))
        .toList();
  }

  Future<String?> cachedMediaPath(String messageId) async {
    final db = await _db;
    final rows = await db.query(
      'media',
      columns: ['local_path'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final path = rows.first['local_path'] as String;
    return await File(path).exists() ? path : null;
  }

  Future<String> cacheMedia({
    required String messageId,
    required String bucket,
    required String storagePath,
    required String extension,
  }) async {
    final existing = await cachedMediaPath(messageId);
    if (existing != null) return existing;

    final client = Supabase.instance.client;
    final signedUrl = await client.storage.from(bucket).createSignedUrl(
          storagePath,
          3600,
        );
    final response = await http.get(Uri.parse(signedUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Media download failed (${response.statusCode}).');
    }

    final directory = await getApplicationSupportDirectory();
    final mediaDirectory = Directory('${directory.path}/ngn_community_media');
    if (!await mediaDirectory.exists()) {
      await mediaDirectory.create(recursive: true);
    }
    final safeId = messageId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final safeExtension = extension.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final file = File(
      '${mediaDirectory.path}/$safeId.${safeExtension.isEmpty ? 'bin' : safeExtension}',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);

    final db = await _db;
    await db.insert(
      'media',
      {
        'message_id': messageId,
        'local_path': file.path,
        'bucket': bucket,
        'storage_path': storagePath,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return file.path;
  }

  Future<void> deleteMessageLocally(String messageId) async {
    final db = await _db;
    final media = await db.query(
      'media',
      columns: ['local_path'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    _hiddenMessageIds.add(messageId);
    await db.insert(
      'hidden_messages',
      {'id': messageId, 'hidden_at': DateTime.now().toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
    await db.delete('media', where: 'message_id = ?', whereArgs: [messageId]);
    if (media.isNotEmpty) {
      final file = File(media.first['local_path'] as String);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> clearArchive() async {
    final db = await _db;
    final rows = await db.query('messages', columns: ['id']);
    final batch = db.batch();
    for (final row in rows) {
      _hiddenMessageIds.add(row['id'] as String);
      batch.insert(
        'hidden_messages',
        {
          'id': row['id'],
          'hidden_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    final media = await db.query('media', columns: ['local_path']);
    await db.delete('messages');
    await db.delete('media');
    for (final row in media) {
      final file = File(row['local_path'] as String);
      if (await file.exists()) await file.delete();
    }
  }

  Future<Map<String, int>> storageStats() async {
    final db = await _db;
    final messageCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM messages'),
        ) ??
        0;
    final mediaRows = await db.query('media', columns: ['local_path']);
    var mediaBytes = 0;
    for (final row in mediaRows) {
      final file = File(row['local_path'] as String);
      if (await file.exists()) mediaBytes += await file.length();
    }
    final dbPath = db.path;
    final dbFile = File(dbPath);
    final dbBytes = await dbFile.exists() ? await dbFile.length() : 0;
    return {
      'messages': messageCount,
      'media': mediaRows.length,
      'mediaBytes': mediaBytes,
      'databaseBytes': dbBytes,
      'totalBytes': mediaBytes + dbBytes,
    };
  }
}
