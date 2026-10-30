import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bible_repository.dart';
import 'bible_saved_page.dart';

class BiblePage extends StatelessWidget {
  const BiblePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = BibleRepository();
    final books = repository.bookNames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holy Bible'),
        actions: [
          IconButton(
            tooltip: 'Saved Bible',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BibleSavedPage()),
            ),
            icon: const Icon(Icons.bookmarks_rounded),
          ),
          IconButton(
            tooltip: 'Search Bible',
            onPressed: () => showSearch(
              context: context,
              delegate: BibleSearchDelegate(repository),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.offline_bolt_rounded),
              title: Text('Offline Bible'),
              subtitle: Text(
                'World English Bible (WEB) • 66 books • stored locally',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Old Testament',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...books.take(39).map(
                (book) => _BookTile(repository: repository, book: book),
              ),
          const SizedBox(height: 16),
          const Text(
            'New Testament',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...books.skip(39).map(
                (book) => _BookTile(repository: repository, book: book),
              ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.repository, required this.book});

  final BibleRepository repository;
  final String book;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book_rounded),
        title: Text(book),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BibleBookPage(
              repository: repository,
              book: book,
            ),
          ),
        ),
      ),
    );
  }
}

class BibleBookPage extends StatelessWidget {
  const BibleBookPage({
    super.key,
    required this.repository,
    required this.book,
  });

  final BibleRepository repository;
  final String book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book)),
      body: FutureBuilder<List<BibleChapter>>(
        future: repository.chapters(book),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Bible data is not ready: ${snapshot.error}'),
            );
          }

          final chapters = snapshot.data ?? const [];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BibleChapterPage(
                        repository: repository,
                        book: book,
                        chapter: chapter.number,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${chapter.number}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BibleChapterPage extends StatefulWidget {
  const BibleChapterPage({
    super.key,
    required this.repository,
    required this.book,
    required this.chapter,
  });

  final BibleRepository repository;
  final String book;
  final int chapter;

  @override
  State<BibleChapterPage> createState() => _BibleChapterPageState();
}

class _BibleChapterPageState extends State<BibleChapterPage> {
  Set<String> _bookmarks = <String>{};

  String _key(int verse) => '${widget.book}|${widget.chapter}|$verse';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookmarks = (prefs.getStringList('bible_bookmarks') ?? const <String>[]).toSet();
    });
  }

  Future<void> _toggleBookmark(BibleVerse verse) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(verse.number);
    setState(() {
      _bookmarks.contains(key) ? _bookmarks.remove(key) : _bookmarks.add(key);
    });
    await prefs.setStringList('bible_bookmarks', _bookmarks.toList());
  }

  Future<void> _editNote(BibleVerse verse) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bible_note_${_key(verse.number)}';
    final controller = TextEditingController(text: prefs.getString(key) ?? '');
    if (!mounted) return;
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note • ${widget.book} ${widget.chapter}:${verse.number}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Write your personal note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    if (note.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, note);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(note.isEmpty ? 'Note removed.' : 'Note saved on this phone.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.book} ${widget.chapter}')),
      body: FutureBuilder<List<BibleVerse>>(
        future: widget.repository.verses(widget.book, widget.chapter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Bible data is not ready: ${snapshot.error}'),
            );
          }

          final verses = snapshot.data ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              final bookmarked = _bookmarks.contains(_key(verse.number));
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style.copyWith(
                                  fontSize: 17,
                                  height: 1.6,
                                ),
                            children: [
                              TextSpan(
                                text: '${verse.number} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B5ED7),
                                ),
                              ),
                              TextSpan(text: verse.text),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Verse options',
                        onSelected: (value) {
                          if (value == 'bookmark') _toggleBookmark(verse);
                          if (value == 'note') _editNote(verse);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'bookmark',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(bookmarked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded),
                              title: Text(bookmarked ? 'Remove bookmark' : 'Bookmark verse'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'note',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_note_rounded),
                              title: Text('Write a note'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BibleSearchDelegate extends SearchDelegate<String?> {
  BibleSearchDelegate(this.repository);

  final BibleRepository repository;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.clear_rounded),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_rounded),
      );

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: repository.search(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return const Center(child: Text('No matching verses found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final row = results[index];
            return Card(
              child: ListTile(
                title: Text(
                  '${row['book']} ${row['chapter']}:${row['verse']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(row['text']?.toString() ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Search words or phrases in the Bible.'),
    );
  }
}
