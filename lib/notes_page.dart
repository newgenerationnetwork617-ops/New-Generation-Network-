import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const _storageKey = 'holy_word_ngn_personal_notes_v1';
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _notes = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
          ..sort((a, b) => (b['updatedAt'] ?? '').toString()
              .compareTo((a['updatedAt'] ?? '').toString()));
      } catch (_) {
        _notes = [];
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_notes));
  }

  Future<void> _editNote({Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final body = TextEditingController(text: existing?['body']?.toString() ?? '');
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => Scaffold(
          backgroundColor: Theme.of(pageContext).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(existing == null ? 'Add Note' : 'Edit Note'),
            actions: [
              TextButton(
                onPressed: () {
                  if (body.text.trim().isEmpty && title.text.trim().isEmpty) {
                    Navigator.pop(pageContext, false);
                    return;
                  }
                  Navigator.pop(pageContext, true);
                },
                child: Text('Save', style: TextStyle(
                  color: Theme.of(pageContext).colorScheme.secondary, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextField(
                controller: title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 90,
                decoration: InputDecoration(
                  hintText: 'Note title (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Theme.of(pageContext).colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                autofocus: existing == null,
                minLines: 12,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Start writing your church notes, sermon points, Bible study thoughts...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Theme.of(pageContext).colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your notes are saved on this device and are available offline.',
                style: TextStyle(color: Color(0xFF666666), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      final now = DateTime.now().toIso8601String();
      final id = existing?['id']?.toString() ?? now;
      final note = <String, dynamic>{
        'id': id,
        'title': title.text.trim(),
        'body': body.text.trim(),
        'updatedAt': now,
      };
      setState(() {
        final index = _notes.indexWhere((item) => item['id'] == id);
        if (index >= 0) {
          _notes[index] = note;
        } else {
          _notes.insert(0, note);
        }
        _notes.sort((a, b) => (b['updatedAt'] ?? '').toString()
            .compareTo((a['updatedAt'] ?? '').toString()));
      });
      await _persist();
    }
    title.dispose();
    body.dispose();
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This only removes the note from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _notes.removeWhere((item) => item['id'] == note['id']));
    await _persist();
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Saved note';
    return 'Updated ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            tooltip: 'Add note',
            onPressed: () => _editNote(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editNote(),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.edit_note_rounded,
                              size: 42, color: Theme.of(context).colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(height: 18),
                        const Text('Your notebook starts here',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        const Text(
                          'Save sermon notes, church lecture points, Bible study insights and personal reflections.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF666666), height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => _editNote(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add your first note'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final title = note['title']?.toString().trim() ?? '';
                    final body = note['body']?.toString() ?? '';
                    return Card(
                      color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _editNote(existing: note),
                        onLongPress: () => _deleteNote(note),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.description_outlined,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title.isEmpty ? 'Untitled note' : title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                                    const SizedBox(height: 8),
                                    Text(_dateLabel(note['updatedAt']),
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _editNote(existing: note);
                                  if (value == 'delete') _deleteNote(note);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
