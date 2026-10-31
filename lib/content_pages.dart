import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'in_app_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'content_repository.dart';
import 'offline_media_service.dart';

class ContentListPage extends StatefulWidget {
  const ContentListPage({super.key, required this.title, required this.loader, required this.emptyMessage, required this.itemBuilder});
  final String title;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final String emptyMessage;
  final Widget Function(BuildContext, Map<String, dynamic>) itemBuilder;
  @override
  State<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends State<ContentListPage> {
  late Future<List<Map<String,dynamic>>> future;
  @override
  void initState() { super.initState(); future = widget.loader(); }
  Future<void> refresh() async {
    final next = widget.loader();
    setState(() => future = next);
    await next;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<Map<String,dynamic>>>(
          future: future,
          builder: (context,snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return ListView(children: const [SizedBox(height: 220), Center(child: CircularProgressIndicator())]);
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return ListView(children: [const SizedBox(height: 180), Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(widget.emptyMessage, textAlign: TextAlign.center)))]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context,index) => widget.itemBuilder(context,items[index]),
            );
          },
        ),
      ),
    );
  }
}

class DevotionalsPage extends StatefulWidget {
  const DevotionalsPage({super.key});

  @override
  State<DevotionalsPage> createState() => _DevotionalsPageState();
}

class _DevotionalsPageState extends State<DevotionalsPage> {
  final repo = ContentRepository(Supabase.instance.client);
  late Future<Map<String, dynamic>?> future;

  @override
  void initState() {
    super.initState();
    future = repo.devotionalForDate(DateTime.now());
  }

  Future<void> refresh() async {
    final next = repo.devotionalForDate(DateTime.now());
    setState(() => future = next);
    await next;
  }

  String _dateLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _section(String heading, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SelectableText(text, style: const TextStyle(height: 1.65, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc().add(const Duration(hours: 1));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devotional'),
        actions: [
          IconButton(
            tooltip: 'Refresh today’s reading',
            onPressed: refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return ListView(children: const [
                SizedBox(height: 220),
                Center(child: CircularProgressIndicator()),
              ]);
            }
            final item = snapshot.data;
            if (item == null) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 110),
                  const Icon(Icons.menu_book_rounded, size: 58, color: Color(0xFF0B5ED7)),
                  const SizedBox(height: 18),
                  const Text('Today’s devotional is not available yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(_dateLabel(today),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  const Text('Please check again later or refresh this page.',
                      textAlign: TextAlign.center),
                ],
              );
            }
            final theme = item['theme']?.toString().trim() ?? '';
            final reference = item['bible_reference']?.toString().trim() ?? '';
            final message = item['message']?.toString().trim() ?? '';
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              children: [
                Text(_dateLabel(today),
                    style: const TextStyle(color: Color(0xFF0B5ED7), fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(item['title']?.toString() ?? 'Daily Devotional',
                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1.2)),
                if (theme.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(theme, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 22),
                if (reference.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B5ED7).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(reference,
                        style: const TextStyle(color: Color(0xFF0B5ED7), fontWeight: FontWeight.w900)),
                  ),
                const SizedBox(height: 18),
                SelectableText(
                  message.isEmpty ? 'The devotional message is not available.' : message,
                  style: const TextStyle(height: 1.7, fontSize: 16),
                ),
                _section('Life Application', item['life_application']),
                _section('Memory Verse', item['memory_verse']),
                _section('Prayer', item['prayer']),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TeachingsPage extends StatefulWidget {
  const TeachingsPage({super.key});
  @override
  State<TeachingsPage> createState() => _TeachingsPageState();
}

class _TeachingsPageState extends State<TeachingsPage> {
  final repo = ContentRepository(Supabase.instance.client);
  final search = TextEditingController();
  late Future<List<Map<String,dynamic>>> future;
  String query = '';
  int section = 0;

  @override
  void initState() { super.initState(); future = repo.teachings(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> refresh() async {
    final next = repo.teachings();
    setState(() => future = next);
    await next;
  }

  bool matches(Map<String,dynamic> item) {
    final type = item['content_type']?.toString().toLowerCase() ?? '';
    final youtube = item['youtube_url']?.toString().trim() ?? '';
    final audio = item['audio_url']?.toString().trim() ?? '';
    final media = item['media_url']?.toString().trim() ?? '';
    final lowerMedia = media.toLowerCase().split('?').first;
    final isVideo = type.contains('video') || youtube.isNotEmpty || lowerMedia.endsWith('.mp4') || lowerMedia.endsWith('.mov');
    final isAudio = type.contains('audio') || audio.isNotEmpty || ['.mp3', '.m4a', '.wav', '.aac', '.ogg'].any(lowerMedia.endsWith);
    final isBook = type.contains('book') || type.contains('document') || type.contains('pdf') ||
        ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'].any(lowerMedia.endsWith);
    final sectionMatch = section == 0 ? isVideo : section == 1 ? isAudio : isBook;
    if (!sectionMatch) return false;
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    final text = [item['title'], item['speaker'], item['description'], item['series_name'], item['content_type']].where((v) => v != null).join(' ').toLowerCase();
    return text.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teachings')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<Map<String,dynamic>>>(
          future: future,
          builder: (context,snapshot) {
            final all = snapshot.data ?? const <Map<String,dynamic>>[];
            final items = all.where(matches).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: search,
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'Search title, speaker, topic or series',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty ? null : IconButton(
                      onPressed: () { search.clear(); setState(() => query = ''); },
                      icon: const Icon(Icons.clear_rounded),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, icon: Icon(Icons.ondemand_video_rounded), label: Text('Videos')),
                      ButtonSegment(value: 1, icon: Icon(Icons.headphones_rounded), label: Text('Audios')),
                      ButtonSegment(value: 2, icon: Icon(Icons.menu_book_rounded), label: Text('Books')),
                    ],
                    selected: {section},
                    onSelectionChanged: (value) => setState(() => section = value.first),
                    showSelectedIcon: false,
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                  const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator()))
                else if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(child: Text(query.isEmpty ? 'No published resources in this section yet.' : 'No teachings match your search.')),
                  )
                else
                  ...items.map((item) => _TeachingCard(item: item)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  @override
  void initState() {
    super.initState();
    InAppNotificationService.instance.markAnnouncementsRead();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    return ContentListPage(
      title: 'Announcements',
      loader: repo.announcements,
      emptyMessage: 'No published announcements yet.',
      itemBuilder: (_, item) => Card(
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFFFF8E1), child: Icon(Icons.campaign_rounded, color: Color(0xFF9A7410))),
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
          leading: const CircleAvatar(backgroundColor: Color(0xFFEAF5EC), child: Icon(Icons.event_rounded, color: Color(0xFF2E7D32))),
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
  String get youtubeUrl => widget.item['youtube_url']?.toString().trim() ?? '';
  String get thumbnailUrl => widget.item['thumbnail_url']?.toString().trim() ?? '';
  String get mediaUrl {
    final direct = widget.item['media_url']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    return widget.item['audio_url']?.toString().trim() ?? '';
  }

  bool get isBook {
    final type = widget.item['content_type']?.toString().toLowerCase() ?? '';
    final path = mediaUrl.toLowerCase().split('?').first;
    return type.contains('book') || type.contains('document') || type.contains('pdf') ||
        ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'].any(path.endsWith);
  }

  String? get youtubeId {
    if (youtubeUrl.isEmpty) return null;
    final uri = Uri.tryParse(youtubeUrl);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
    if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters['v']?.isNotEmpty == true) return uri.queryParameters['v'];
      final i = uri.pathSegments.indexOf('shorts');
      if (i >= 0 && i + 1 < uri.pathSegments.length) return uri.pathSegments[i + 1];
      final e = uri.pathSegments.indexOf('embed');
      if (e >= 0 && e + 1 < uri.pathSegments.length) return uri.pathSegments[e + 1];
    }
    return null;
  }

  String get displayThumbnail {
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    final videoId = youtubeId;
    return videoId == null ? '' : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final saved = await offline.saved();
    if (mounted) setState(() => localPath = saved[id]);
  }

  Future<void> watch() async {
    if (youtubeUrl.isEmpty) return;
    final ok = await launchUrl(Uri.parse(youtubeUrl), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this teaching video.')));
    }
  }

  Future<void> downloadBookToDevice() async {
    if (mediaUrl.isEmpty) return;
    final uri = Uri.parse(mediaUrl);
    final storedName = uri.pathSegments.isEmpty ? 'teaching.pdf' : uri.pathSegments.last;
    final extension = storedName.contains('.') ? '.${storedName.split('.').last}' : '';
    final safeTitle = (widget.item['title']?.toString() ?? 'teaching_book')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final downloadUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'download': safeTitle + extension,
    });
    final ok = await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start the document download.')),
      );
    }
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
    final description = widget.item['description']?.toString().trim() ?? '';
    final speaker = widget.item['speaker']?.toString().trim() ?? '';
    final image = displayThumbnail;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (image.isNotEmpty)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.ondemand_video_rounded, size: 52)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.item['title']?.toString() ?? 'Teaching', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (speaker.isNotEmpty) ...[const SizedBox(height: 5), Text(speaker, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B5ED7)))],
            if (description.isNotEmpty) ...[const SizedBox(height: 9), Text(description, maxLines: 3, overflow: TextOverflow.ellipsis)],
            if (localPath != null) ...[const SizedBox(height: 8), const Row(children: [Icon(Icons.download_done_rounded, size: 17), SizedBox(width: 5), Text('Available offline')])],
            const SizedBox(height: 14),
            Row(children: [
              if (youtubeUrl.isNotEmpty) Expanded(child: FilledButton.icon(onPressed: watch, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Watch'))),
              if (youtubeUrl.isNotEmpty && mediaUrl.isNotEmpty) const SizedBox(width: 8),
              if (mediaUrl.isNotEmpty && isBook) Expanded(child: FilledButton.icon(onPressed: downloadBookToDevice, icon: const Icon(Icons.download_rounded), label: const Text('Download'))),
              if (mediaUrl.isNotEmpty && isBook) const SizedBox(width: 8),
              if (mediaUrl.isNotEmpty) Expanded(child: OutlinedButton.icon(onPressed: busy ? null : (localPath == null ? download : () => offline.open(localPath!)), icon: Icon(localPath == null ? Icons.save_alt_rounded : Icons.open_in_new_rounded), label: Text(localPath == null ? (isBook ? 'Save offline' : 'Offline') : (isBook ? 'Open book' : 'Open')))),
              if (localPath != null) IconButton(onPressed: remove, tooltip: 'Remove offline copy', icon: const Icon(Icons.delete_outline_rounded)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
