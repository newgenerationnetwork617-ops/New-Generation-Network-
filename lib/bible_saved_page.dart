import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BibleSavedPage extends StatefulWidget {
  const BibleSavedPage({super.key});
  @override
  State<BibleSavedPage> createState() => _BibleSavedPageState();
}

class _BibleSavedPageState extends State<BibleSavedPage> {
  List<String> bookmarks = const [];
  Map<String, String> notes = const {};

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bible_bookmarks') ?? const <String>[];
    final foundNotes = <String, String>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('bible_note_')) {
        final value = prefs.getString(key);
        if (value != null && value.trim().isNotEmpty) foundNotes[key.substring('bible_note_'.length)] = value;
      }
    }
    if (!mounted) return;
    setState(() { bookmarks = saved; notes = foundNotes; });
  }

  String reference(String key) {
    final p = key.split('|');
    return p.length == 3 ? '${p[0]} ${p[1]}:${p[2]}' : key;
  }

  Future<void> removeBookmark(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [...bookmarks]..remove(key);
    await prefs.setStringList('bible_bookmarks', updated);
    await load();
  }

  Future<void> removeNote(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bible_note_$key');
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = <String>{...bookmarks, ...notes.keys}.toList()..sort((a, b) => reference(a).compareTo(reference(b)));
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Bible')),
      body: allKeys.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Your bookmarked verses and personal Bible notes will appear here. They are stored only on this phone.', textAlign: TextAlign.center)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allKeys.length,
              itemBuilder: (context, index) {
                final key = allKeys[index];
                final bookmarked = bookmarks.contains(key);
                final note = notes[key];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(bookmarked ? Icons.bookmark_rounded : Icons.edit_note_rounded),
                    title: Text(reference(key), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: note == null ? const Text('Bookmarked verse') : Text(note),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) { if (value == 'bookmark') removeBookmark(key); if (value == 'note') removeNote(key); },
                      itemBuilder: (_) => [
                        if (bookmarked) const PopupMenuItem(value: 'bookmark', child: Text('Remove bookmark')),
                        if (note != null) const PopupMenuItem(value: 'note', child: Text('Delete note')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
