import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminContentManagerPage extends StatefulWidget {
  const AdminContentManagerPage({super.key});
  @override
  State<AdminContentManagerPage> createState() => _AdminContentManagerPageState();
}

class _AdminContentManagerPageState extends State<AdminContentManagerPage> {
  final client = Supabase.instance.client;
  String table = 'devotionals';
  bool loading = true;
  List<Map<String, dynamic>> rows = const [];

  static const configs = <String, List<String>>{
    'devotionals': ['title','theme','bible_reference','message','life_application','prayer','memory_verse'],
    'teachings': ['title','speaker','description','youtube_url','audio_url','content_type','series_name','thumbnail_url','media_url'],
    'announcements': ['title','body'],
    'events': ['title','description','venue','starts_at'],
    'daily_bible_verses': ['verse_date','reference','verse_text'],
  };

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() => loading = true);
    try {
      final data = await client.from(table).select().limit(1000);
      if (mounted) setState(() => rows = List<Map<String,dynamic>>.from(data));
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String label(String key) => key.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  Future<void> edit(Map<String,dynamic> row) async {
    final controllers = <String, TextEditingController>{
      for (final field in configs[table]!) field: TextEditingController(text: row[field]?.toString() ?? ''),
    };
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${table.replaceAll('_', ' ')}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final field in configs[table]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[field],
                      maxLines: ['message','life_application','description','body','verse_text'].contains(field) ? 4 : 1,
                      decoration: InputDecoration(labelText: label(field), border: const OutlineInputBorder()),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save changes')),
        ],
      ),
    );
    if (save != true) {
      for (final c in controllers.values) {
        c.dispose();
      }
      return;
    }
    final update = <String,dynamic>{for (final e in controllers.entries) e.key: e.value.text.trim()};
    if (table == 'events') update['published'] = true;
    await client.from(table).update(update).eq('id', row['id']);
    for (final c in controllers.values) {
      c.dispose();
    }
    await refresh();
  }

  Future<void> schedule(Map<String,dynamic> row) async {
    if (table == 'daily_bible_verses') return;
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: now, lastDate: DateTime(now.year + 5), initialDate: now);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final when = DateTime(date.year,date.month,date.day,time.hour,time.minute);
    final update = <String,dynamic>{'published_at': when.toUtc().toIso8601String()};
    if (table == 'events') update['published'] = true;
    await client.from(table).update(update).eq('id', row['id']);
    await refresh();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scheduled for ${when.toString().substring(0,16)}.')));
  }

  String? _storagePathFromPublicUrl(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    const marker = '/storage/v1/object/public/ngn-media/';
    final index = uri.path.indexOf(marker);
    if (index < 0) return null;
    final objectPath = Uri.decodeComponent(uri.path.substring(index + marker.length));
    return objectPath.isEmpty ? null : objectPath;
  }

  Future<void> deleteContent(Map<String,dynamic> row) async {
    final title = (row['title'] ?? row['reference'] ?? 'this content').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          '“$title” will be deleted from the N.G.N. database. Any linked teaching files stored in Supabase will also be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (table == 'teachings') {
        final paths = <String?>[
          _storagePathFromPublicUrl(row['media_url']),
          _storagePathFromPublicUrl(row['thumbnail_url']),
        ].whereType<String>().toList();
        if (paths.isNotEmpty) {
          await client.storage.from('ngn-media').remove(paths);
        }
      }
      await client.from(table).delete().eq('id', row['id']);
      await refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content deleted permanently.')),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete content: ${e.message}')),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete linked media: ${e.message}. The database record was kept.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete content: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Published Content')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: table,
              decoration: const InputDecoration(labelText: 'Content type', border: OutlineInputBorder()),
              items: configs.keys.map((v) => DropdownMenuItem(value: v, child: Text(label(v)))).toList(),
              onChanged: (v) { if (v != null) { setState(() => table = v); refresh(); } },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refresh,
                    child: rows.isEmpty
                        ? ListView(children: const [SizedBox(height: 160), Center(child: Text('No content in this section yet.'))])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16,0,16,24),
                            itemCount: rows.length,
                            itemBuilder: (_, i) {
                              final row = rows[i];
                              final title = row['title'] ?? row['reference'] ?? 'Content item';
                              final scheduleText = row['published_at']?.toString() ?? row['verse_date']?.toString() ?? '';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (scheduleText.isNotEmpty) Text('Publish: $scheduleText'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') edit(row);
                                      if (v == 'schedule') schedule(row);
                                      if (v == 'delete') deleteContent(row);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      if (table != 'daily_bible_verses') const PopupMenuItem(value: 'schedule', child: Text('Schedule publication')),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete permanently', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
