import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBibleTriviaPage extends StatefulWidget {
  const AdminBibleTriviaPage({super.key});

  @override
  State<AdminBibleTriviaPage> createState() => _AdminBibleTriviaPageState();
}

class _AdminBibleTriviaPageState extends State<AdminBibleTriviaPage> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _client
        .from('bible_trivia_questions')
        .select('id,question,options,correct_index,difficulty,bible_reference,explanation,is_published,created_at')
        .order('created_at', ascending: false)
        .limit(200);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final question = TextEditingController(text: item?['question']?.toString() ?? '');
    final options = List.generate(4, (i) => TextEditingController(
      text: item != null && (item['options'] as List).length > i
          ? (item['options'] as List)[i].toString()
          : '',
    ));
    final reference = TextEditingController(text: item?['bible_reference']?.toString() ?? '');
    final explanation = TextEditingController(text: item?['explanation']?.toString() ?? '');
    var difficulty = item?['difficulty']?.toString() ?? 'Easy';
    var correct = (item?['correct_index'] as int?) ?? 0;
    var published = item?['is_published'] == true;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add trivia question' : 'Edit trivia question'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: question, maxLines: 3, decoration: const InputDecoration(labelText: 'Question')),
                  const SizedBox(height: 10),
                  for (var i = 0; i < 4; i++) ...[
                    TextField(controller: options[i], decoration: InputDecoration(labelText: 'Option ${String.fromCharCode(65 + i)}')),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: const ['Easy', 'Medium', 'Hard'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => difficulty = v); },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: correct,
                    decoration: const InputDecoration(labelText: 'Correct option'),
                    items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('Option ${String.fromCharCode(65 + i)}'))),
                    onChanged: (v) { if (v != null) setDialogState(() => correct = v); },
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: reference, decoration: const InputDecoration(labelText: 'Bible reference')),
                  const SizedBox(height: 8),
                  TextField(controller: explanation, maxLines: 3, decoration: const InputDecoration(labelText: 'Explanation')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Publish this question'),
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
                if (question.text.trim().isEmpty ||
                    options.any((c) => c.text.trim().isEmpty) ||
                    reference.text.trim().isEmpty ||
                    explanation.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete the question, four options, reference and explanation.')),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                final data = {
                  'question': question.text.trim(),
                  'options': options.map((c) => c.text.trim()).toList(),
                  'correct_index': correct,
                  'difficulty': difficulty,
                  'bible_reference': reference.text.trim(),
                  'explanation': explanation.text.trim(),
                  'is_published': published,
                  'updated_at': DateTime.now().toIso8601String(),
                };
                try {
                  if (item == null) {
                    await _client.from('bible_trivia_questions').insert(data);
                  } else {
                    await _client.from('bible_trivia_questions').update(data).eq('id', item['id']);
                  }
                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _refresh();
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(item == null ? 'Question saved.' : 'Question updated.')),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Could not save question: $e')));
                }
              },
              child: Text(saving ? 'Saving…' : 'Save question'),
            ),
          ],
        ),
      ),
    );
    question.dispose();
    reference.dispose();
    explanation.dispose();
    for (final controller in options) {
      controller.dispose();
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This permanently removes this trivia question from the bank.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _client.from('bible_trivia_questions').delete().eq('id', item['id']);
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete question: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bible Trivia Question Bank'),
      actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        const SizedBox(width: 6),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add question'),
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
            child: Text('Could not load the question bank. ${snapshot.error}'),
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
                  gradient: const LinearGradient(colors: [Color(0xFF142E52), Color(0xFF073B8C)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('BUILD THE 1,000-QUESTION BANK', style: TextStyle(color: Color(0xFFFFD66B), fontWeight: FontWeight.w900, letterSpacing: .7)),
                  const SizedBox(height: 8),
                  Text('${rows.length} loaded here • $published published', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: (published / 1000).clamp(0.0, 1.0), minHeight: 7, backgroundColor: Colors.white24, color: const Color(0xFFFFD66B)),
                  ),
                  const SizedBox(height: 7),
                  Text('${(published / 1000 * 100).toStringAsFixed(1)}% of the 1,000 target', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No remote questions yet. Add questions here; published questions become available in Bible Trivia when players are online.', textAlign: TextAlign.center),
                ),
              for (final item in rows)
                Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    title: Text(item['question'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item['difficulty']} • ${item['bible_reference']} • ${item['is_published'] == true ? 'Published' : 'Draft'}'),
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
