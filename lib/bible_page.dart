import 'package:flutter/material.dart';

import 'bible_repository.dart';

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
          Card(
            child: ListTile(
              leading: const Icon(Icons.offline_bolt_rounded),
              title: const Text('Offline Bible'),
              subtitle: const Text(
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

class BibleChapterPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$book $chapter')),
      body: FutureBuilder<List<BibleVerse>>(
        future: repository.verses(book, chapter),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
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
