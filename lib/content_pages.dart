import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_repository.dart';

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
      itemBuilder: (_, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill_rounded),
          title: Text(item['title']?.toString() ?? 'Teaching'),
          subtitle: Text(item['speaker']?.toString() ?? ''),
        ),
      ),
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
            (item['venue']?.toString() ?? '') +
                '\n' +
                (item['starts_at']?.toString() ?? ''),
          ),
        ),
      ),
    );
  }
}
