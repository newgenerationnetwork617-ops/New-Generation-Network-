import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBibleCharactersPage extends StatefulWidget {
  const AdminBibleCharactersPage({super.key});

  @override
  State<AdminBibleCharactersPage> createState() => _AdminBibleCharactersPageState();
}

class _AdminBibleCharactersPageState extends State<AdminBibleCharactersPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> characters = [];

  @override
  void initState() {
    super.initState();
    loadCharacters();
  }

  Future<void> loadCharacters() async {
    setState(() => loading = true);
    try {
      final rows = await supabase.from('bible_characters').select().order('name');
      if (mounted) {
        setState(() {
          characters = List<Map<String, dynamic>>.from(rows);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load characters: $e')),
        );
      }
    }
  }

  Future<void> editCharacter([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final reference = TextEditingController(text: existing?['bible_references']?.toString() ?? '');
    final explanation = TextEditingController(text: existing?['explanation']?.toString() ?? '');
    final clues = List.generate(4, (i) => TextEditingController(
      text: existing != null && (existing['clues'] as List).length > i
          ? (existing['clues'] as List)[i].toString()
          : '',
    ));
    var difficulty = existing?['difficulty']?.toString() ?? 'Easy';
    var published = existing?['is_published'] == true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Bible Character' : 'Edit Bible Character'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Character name')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: const ['Easy', 'Medium', 'Hard']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => difficulty = v); },
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 4; i++) ...[
                    TextField(
                      controller: clues[i],
                      maxLines: 2,
                      decoration: InputDecoration(labelText: 'Clue ${i + 1}'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(controller: reference, maxLines: 2, decoration: const InputDecoration(labelText: 'Bible references')),
                  const SizedBox(height: 10),
                  TextField(controller: explanation, maxLines: 3, decoration: const InputDecoration(labelText: 'Short explanation')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published and visible in the game'),
                    value: published,
                    onChanged: (v) => setDialogState(() => published = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty ||
                    clues.any((c) => c.text.trim().isEmpty) ||
                    reference.text.trim().isEmpty ||
                    explanation.text.trim().isEmpty) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Complete the name, all four clues, references and explanation.')),
                    );
                  }
                  return;
                }
                final data = {
                  'name': name.text.trim(),
                  'difficulty': difficulty,
                  'clues': clues.map((c) => c.text.trim()).toList(),
                  'bible_references': reference.text.trim(),
                  'explanation': explanation.text.trim(),
                  'is_published': published,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                };
                try {
                  if (existing == null) {
                    await supabase.from('bible_characters').insert(data);
                  } else {
                    await supabase.from('bible_characters').update(data).eq('id', existing['id']);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  await loadCharacters();
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Could not save character: $e')),
                    );
                  }
                }
              },
              child: const Text('Save character'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    reference.dispose();
    explanation.dispose();
    for (final clue in clues) {
      clue.dispose();
    }
  }

  Future<void> setPublished(Map<String, dynamic> character, bool value) async {
    try {
      await supabase.from('bible_characters').update({
        'is_published': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', character['id']);
      await loadCharacters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update publication status: $e')),
        );
      }
    }
  }

  Future<void> deleteCharacter(Map<String, dynamic> character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete character?'),
        content: Text('Delete ${character['name']} from the character bank?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await supabase.from('bible_characters').delete().eq('id', character['id']);
      await loadCharacters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete character: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bible Character Bank'),
      actions: [IconButton(onPressed: loadCharacters, icon: const Icon(Icons.refresh_rounded))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => editCharacter(),
      icon: const Icon(Icons.add),
      label: const Text('Add character'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : characters.isEmpty
            ? const Center(child: Text('No characters yet. Add the first one.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final item = characters[index];
                  final clues = item['clues'] as List;
                  final isPublished = item['is_published'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      title: Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${item['difficulty']} • ${isPublished ? 'Published' : 'Draft'} • 4 clues'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < clues.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('Clue ${i + 1}: ${clues[i]}'),
                                ),
                              Text('References: ${item['bible_references']}'),
                              const SizedBox(height: 6),
                              Text(item['explanation'].toString()),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Published'),
                                value: isPublished,
                                onChanged: (v) => setPublished(item, v),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(onPressed: () => editCharacter(item), icon: const Icon(Icons.edit), label: const Text('Edit')),
                                  TextButton.icon(onPressed: () => deleteCharacter(item), icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
  );
}
