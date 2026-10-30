import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_repository.dart';
import 'offline_media_service.dart';

class ContentListPage extends StatelessWidget {
  const ContentListPage({
    super.key,
    required this.title,
    required this.loader,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final String title;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final String emptyMessage;
  final Widget Function(BuildContext, Map<String, dynamic>) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loader(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(emptyMessage, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(context, items[index]),
          );
        },
      ),
    );
  }
}

class DevotionalsPage extends StatelessWidget {
  const DevotionalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    return ContentListPage(
      title: 'Daily Devotionals',
      loader: repo.devotionals,
      emptyMessage: 'No published devotionals yet.',
      itemBuilder: (_, item) => Card(
        child: ListTile(
          title: Text(item['title']?.toString() ?? 'Devotional'),
          subtitle: Text(item['theme']?.toString() ?? ''),
        ),
      ),
    );
  }
}

class TeachingsPage extends StatelessWidget {
  const TeachingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    return ContentListPage(
      title: 'Teachings & Sermons',
      loader: repo.teachings,
      emptyMessage: 'No published teachings yet.',
      itemBuilder: (_, item) => _TeachingCard(item: item),
    );
  }
}

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    return ContentListPage(
      title: 'Announcements',
      loader: repo.announcements,
      emptyMessage: 'No published announcements yet.',
      itemBuilder: (_, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.campaign_rounded),
          title: Text(item['title']?.toString() ?? 'Announcement'),
          subtitle: Text(item['body']?.toString() ?? ''),
        ),
      ),
    );
  }
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    return ContentListPage(
      title: 'Upcoming Events',
      loader: repo.events,
      emptyMessage: 'No upcoming events yet.',
      itemBuilder: (_, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.event_rounded),
          title: Text(item['title']?.toString() ?? 'Event'),
          subtitle: Text(
            '${item['venue']?.toString() ?? ''}\n${item['starts_at']?.toString() ?? ''}',
          ),
        ),
      ),
    );
  }
}


class _TeachingCard extends StatefulWidget {
  const _TeachingCard({required this.item});
  final Map<String,dynamic> item;
  @override
  State<_TeachingCard> createState() => _TeachingCardState();
}

class _TeachingCardState extends State<_TeachingCard> {
  final offline = OfflineMediaService();
  bool busy = false;
  String? localPath;

  String get id => widget.item['id']?.toString() ?? widget.item['title']?.toString() ?? 'teaching';
  String get mediaUrl {
    final direct = widget.item['media_url']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final audio = widget.item['audio_url']?.toString().trim() ?? '';
    return audio;
  }

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final saved = await offline.saved();
    if (mounted) setState(() => localPath = saved[id]);
  }

  Future<void> download() async {
    if (mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This teaching does not have a downloadable media file yet.')));
      return;
    }
    setState(() => busy = true);
    try {
      final path = await offline.download(id: id, url: mediaUrl, title: widget.item['title']?.toString() ?? 'teaching');
      if (mounted) {
        setState(() => localPath = path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teaching saved on this phone for offline use.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    await offline.remove(id);
    if (mounted) setState(() => localPath = null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill_rounded),
        title: Text(widget.item['title']?.toString() ?? 'Teaching'),
        subtitle: Text('${widget.item['speaker']?.toString() ?? ''}${localPath == null ? '' : '\nAvailable offline'}'),
        trailing: busy
            ? const SizedBox(width: 24,height: 24,child: CircularProgressIndicator(strokeWidth: 2))
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'download') download();
                  if (value == 'open' && localPath != null) offline.open(localPath!);
                  if (value == 'remove') remove();
                },
                itemBuilder: (_) => [
                  if (localPath == null) const PopupMenuItem(value: 'download', child: Text('Download for offline')),
                  if (localPath != null) const PopupMenuItem(value: 'open', child: Text('Open offline copy')),
                  if (localPath != null) const PopupMenuItem(value: 'remove', child: Text('Remove download')),
                ],
              ),
      ),
    );
  }
}
