import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBibleWordSearchPage extends StatefulWidget {
  const AdminBibleWordSearchPage({super.key});

  @override
  State<AdminBibleWordSearchPage> createState() => _AdminBibleWordSearchPageState();
}

class _AdminBibleWordSearchPageState extends State<AdminBibleWordSearchPage> {
  final _client = Supabase.instance.client;
  static const _categories = [
    'Bible Names',
    'Bible Cities',
    'Bible Kings',
    'Verses & Chapters',
    'Bible Events & Places',
  ];
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _client
        .from('bible_word_searches')
        .select('id,category,theme,verse_text,bible_reference,words,explanation,difficulty,is_published,created_at')
        .order('created_at', ascending: false)
        .limit(250);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final theme = TextEditingController(text: item?['theme']?.toString() ?? '');
    final prompt = TextEditingController(text: item?['verse_text']?.toString() ?? '');
    final reference = TextEditingController(text: item?['bible_reference']?.toString() ?? '');
    final words = TextEditingController(
      text: item == null ? '' : (item['words'] as List).join(', '),
    );
    final explanation = TextEditingController(text: item?['explanation']?.toString() ?? '');
    var category = item?['category']?.toString() ?? _categories.first;
    var difficulty = item?['difficulty']?.toString() ?? 'Easy';
    var published = item?['is_published'] == true;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add word-search puzzle' : 'Edit word-search puzzle'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => category = v); },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: theme, decoration: const InputDecoration(labelText: 'Puzzle title / theme')),
                  TextField(controller: prompt, maxLines: 3, decoration: const InputDecoration(labelText: 'Puzzle prompt or verse text')),
                  TextField(controller: reference, decoration: const InputDecoration(labelText: 'Bible reference / source')),
                  TextField(controller: words, maxLines: 3, decoration: const InputDecoration(labelText: 'Words (separate with commas)')),
                  TextField(controller: explanation, maxLines: 3, decoration: const InputDecoration(labelText: 'Learning note (optional)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: const ['Easy', 'Medium', 'Hard'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => difficulty = v); },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Publish for players'),
                    value: published,
                    onChanged: (v) => setDialogState(() => published = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                final list = words.text
                    .split(',')
                    .map((v) => v.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), ''))
                    .where((v) => v.isNotEmpty)
                    .toSet()
                    .toList();
                if (theme.text.trim().isEmpty || prompt.text.trim().isEmpty ||
                    reference.text.trim().isEmpty || list.length < 3 ||
                    list.length > 12 || list.any((v) => v.length > 12)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add a title, prompt, reference and 3–12 words. Each word must be 12 letters or fewer.')),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                final data = {
                  'category': category,
                  'theme': theme.text.trim(),
                  'verse_text': prompt.text.trim(),
                  'bible_reference': reference.text.trim(),
                  'words': list,
                  'explanation': explanation.text.trim(),
                  'difficulty': difficulty,
                  'is_published': published,
                  'updated_at': DateTime.now().toIso8601String(),
                };
                try {
                  if (item == null) {
                    await _client.from('bible_word_searches').insert(data);
                  } else {
                    await _client.from('bible_word_searches').update(data).eq('id', item['id']);
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _refresh();
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Could not save puzzle: $e')),
                  );
                }
              },
              child: Text(saving ? 'Saving…' : 'Save puzzle'),
            ),
          ],
        ),
      ),
    );
    theme.dispose();
    prompt.dispose();
    reference.dispose();
    words.dispose();
    explanation.dispose();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete puzzle?'),
        content: const Text('This removes the puzzle from future downloads. Existing offline copies may remain until the next refresh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _client.from('bible_word_searches').delete().eq('id', item['id']);
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete puzzle: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Word Search Puzzle Bank'),
      actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add puzzle'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load the puzzle bank. ${snapshot.error}'),
          ));
        }
        final rows = snapshot.data ?? [];
        final published = rows.where((r) => r['is_published'] == true).length;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF123A82), Color(0xFF1764C0)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PUBLISH NEW OFFLINE PUZZLES', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: .6)),
                  const SizedBox(height: 7),
                  Text('${rows.length} managed here • $published published', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Published puzzles are downloaded by the app when a player is online, then remain available offline.', style: TextStyle(color: Colors.white70, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No extra puzzles yet. Add and publish puzzles here to make them available for download.', textAlign: TextAlign.center),
                ),
              for (final item in rows)
                Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    title: Text(item['theme']?.toString() ?? 'Untitled puzzle', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item['category']} • ${item['difficulty']} • ${item['is_published'] == true ? 'Published' : 'Draft'}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _edit(item);
                        if (v == 'delete') _delete(item);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
