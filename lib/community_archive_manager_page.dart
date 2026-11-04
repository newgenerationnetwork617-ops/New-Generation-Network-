import 'package:flutter/material.dart';

import 'community_archive_service.dart';

class CommunityArchiveManagerPage extends StatefulWidget {
  const CommunityArchiveManagerPage({super.key});

  @override
  State<CommunityArchiveManagerPage> createState() =>
      _CommunityArchiveManagerPageState();
}

class _CommunityArchiveManagerPageState
    extends State<CommunityArchiveManagerPage> {
  final _archive = CommunityArchiveService.instance;
  late Future<void> _loading;
  List<Map<String, dynamic>> _messages = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<void> _load() async {
    final messages = await _archive.loadMessages();
    final stats = await _archive.storageStats();
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _stats = stats;
    });
  }

  String _preview(Map<String, dynamic> message) {
    switch (message['message_type']) {
      case 'voice':
        return 'Voice note';
      case 'file':
        return message['file_name']?.toString() ?? 'Attachment';
      default:
        return message['body']?.toString() ?? 'Message';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteOne(Map<String, dynamic> message) async {
    final id = message['id']?.toString();
    if (id == null) return;
    await _archive.deleteMessageLocally(id);
    await _load();
  }

  Future<void> _clearAll() async {
    if (_messages.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear saved Community history?'),
        content: const Text(
          'This removes saved messages and cached media from this phone only. '
          'It does not delete messages for other members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear this phone'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _archive.clearArchive();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Storage'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() => _loading = _load()),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Clear saved history',
            onPressed: _messages.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved on this phone',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text('${_stats['messages'] ?? 0} messages'),
                        Text('${_stats['media'] ?? 0} cached media files'),
                        Text('Media: ${_formatBytes(_stats['mediaBytes'] ?? 0)}'),
                        Text('Total archive: ${_formatBytes(_stats['totalBytes'] ?? 0)}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Saved text stays on this phone until you remove it, '
                          'clear the archive, or uninstall/clear app data. '
                          'Photos, voice notes and files are cached when you open them.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Saved messages',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (_messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('No saved Community messages yet.')),
                  ),
                ..._messages.reversed.map((message) {
                  final created = DateTime.tryParse(
                    message['created_at']?.toString() ?? '',
                  )?.toLocal();
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        message['message_type'] == 'voice'
                            ? Icons.mic_none_rounded
                            : message['message_type'] == 'file'
                                ? Icons.attach_file_rounded
                                : Icons.chat_bubble_outline_rounded,
                      ),
                      title: Text(
                        _preview(message),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        created?.toString().substring(0, 16) ?? 'Date unavailable',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove from this phone',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _deleteOne(message),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
