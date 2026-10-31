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
  static const int maxFileBytes = 25 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (mounted) setState(() => loading = true);
    try {
      final result = await client.storage.from('ngn-media').list(
        searchOptions: const SearchOptions(
          limit: 100,
          sortBy: SortBy(column: 'created_at', order: 'desc'),
        ),
      );
      if (mounted) setState(() => files = result);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage error: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? _mimeType(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'rtf':
        return 'application/rtf';
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      default:
        return null;
    }
  }

  Future<void> upload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'webp', 'mp3', 'm4a', 'wav', 'mp4',
        'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt',
      ],
    );
    if (picked == null || picked.files.isEmpty) return;
    final item = picked.files.single;
    if (item.path == null) return;
    if (item.size <= 0 || item.size > maxFileBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a file smaller than 25 MB.')),
        );
      }
      return;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in as an administrator.')),
        );
      }
      return;
    }

    final safeName = item.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'community_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final mime = _mimeType(item.name);
    var uploaded = false;
    try {
      await client.storage.from('ngn-media').upload(
        path,
        File(item.path!),
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );
      uploaded = true;

      await client.from('community_messages').insert({
        'author_id': user.id,
        'message_type': 'file',
        'file_path': path,
        'file_name': item.name,
        'file_mime_type': mime,
        'file_size_bytes': item.size,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded and published in Community Chat.')),
      );
      await refresh();
    } catch (e) {
      if (uploaded) {
        try {
          await client.storage.from('ngn-media').remove([path]);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish file: $e')),
        );
      }
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final references = await client
          .from('teachings')
          .select('id')
          .ilike('media_url', '%$path%')
          .limit(1);
      if ((references as List).isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This file is linked to a teaching resource. Archive or update that teaching before deleting its media.'),
            ),
          );
        }
        return;
      }

      final attachments = await client
          .from('community_messages')
          .select('id')
          .eq('file_path', path);
      final count = (attachments as List).length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete uploaded file?'),
          content: Text(
            count > 0
                ? 'This will remove the file and its Community Chat message. People who already downloaded a copy will keep it.'
                : 'This will permanently remove the file from online storage. People with an old link will no longer be able to open it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete file'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      if (count > 0) {
        await client.from('community_messages').delete().eq('file_path', path);
      }
      await client.storage.from('ngn-media').remove([path]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File and its chat attachment have been deleted.')),
        );
      }
      await refresh();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete attachment: ${e.message}')),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete file: ${e.message}')),
        );
      }
    }
  }

  void copyUrl(String path) {
    final url = client.storage.from('ngn-media').getPublicUrl(path);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media URL copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('N.G.N. Community Files')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: upload,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Upload to Community'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refresh,
              child: files.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No uploaded media yet.')),
                      ],
                    )
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
                            subtitle: Text(
                              file.metadata?['size'] == null
                                  ? 'N.G.N. media'
                                  : '${file.metadata?['size']} bytes',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'copy') copyUrl(file.name);
                                if (value == 'delete') await deleteFile(file.name);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'copy',
                                  child: Text('Copy public URL'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete file and chat post'),
                                ),
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
