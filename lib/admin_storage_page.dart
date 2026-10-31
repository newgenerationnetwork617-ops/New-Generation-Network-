import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStoragePage extends StatefulWidget {
  const AdminStoragePage({super.key});
  @override
  State<AdminStoragePage> createState() => _AdminStoragePageState();
}

class _AdminStoragePageState extends State<AdminStoragePage> {
  final client = Supabase.instance.client;
  bool loading = true;
  List<FileObject> files = const [];

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() => loading = true);
    try {
      final result = await client.storage.from('ngn-media').list(
        searchOptions: const SearchOptions(limit: 100, sortBy: SortBy(column: 'created_at', order: 'desc')),
      );
      if (mounted) setState(() => files = result);
    } on StorageException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Storage error: ${e.message}')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> upload() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','webp','mp3','m4a','wav','mp4','pdf','doc','docx','txt','rtf','odt']);
    if (picked == null || picked.files.single.path == null) return;
    final item = picked.files.single;
    final safeName = item.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      await client.storage.from('ngn-media').upload(path, File(item.path!), fileOptions: const FileOptions(upsert: false));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded to N.G.N. Storage.')));
      await refresh();
    } on StorageException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${e.message}')));
    }
  }

  Future<void> deleteFile(String name) async {
    await client.storage.from('ngn-media').remove([name]);
    await refresh();
  }

  void copyUrl(String name) {
    final url = client.storage.from('ngn-media').getPublicUrl(name);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media URL copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('N.G.N. Media Storage')),
      floatingActionButton: FloatingActionButton.extended(onPressed: upload, icon: const Icon(Icons.cloud_upload_rounded), label: const Text('Upload')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refresh,
              child: files.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No uploaded media yet.'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file_rounded),
                            title: Text(file.name),
                            subtitle: Text(file.metadata?['size'] == null ? 'N.G.N. media' : '${file.metadata?['size']} bytes'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'copy') copyUrl(file.name);
                                if (value == 'delete') await deleteFile(file.name);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'copy', child: Text('Copy public URL')),
                                PopupMenuItem(value: 'delete', child: Text('Delete file')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
