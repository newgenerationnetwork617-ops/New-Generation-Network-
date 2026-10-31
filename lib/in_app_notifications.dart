import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InAppNotificationService {
  InAppNotificationService._();

  static final InAppNotificationService instance = InAppNotificationService._();

  final client = Supabase.instance.client;
  final ValueNotifier<int> communityUnread = ValueNotifier<int>(0);
  final ValueNotifier<int> announcementsUnread = ValueNotifier<int>(0);
  bool _started = false;

  String _now() => DateTime.now().toUtc().toIso8601String();

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('ngn_community_last_read')) {
      await prefs.setString('ngn_community_last_read', _now());
    }
    if (!prefs.containsKey('ngn_announcements_last_read')) {
      await prefs.setString('ngn_announcements_last_read', _now());
    }

    // A guest session enables safe chat identity without asking for email,
    // password, or a separate registration process.
    if (client.auth.currentUser == null) {
      try {
        await client.auth.signInAnonymously();
      } catch (_) {
        // Keep the rest of the app available if guest sign-in is not enabled.
      }
    }

    await refreshCounts();
    client
        .channel('ngn-in-app-notification-counts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_messages',
          callback: (_) => refreshCommunityCount(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (_) => refreshAnnouncementCount(),
        )
        .subscribe();
  }

  Future<void> refreshCounts() async {
    await Future.wait([refreshCommunityCount(), refreshAnnouncementCount()]);
  }

  Future<void> refreshCommunityCount() async {
    final user = client.auth.currentUser;
    if (user == null) {
      communityUnread.value = 0;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRead = prefs.getString('ngn_community_last_read') ?? _now();
      final rows = await client
          .from('community_messages')
          .select('id')
          .gt('created_at', lastRead)
          .neq('author_id', user.id)
          .limit(501);
      communityUnread.value = rows.length;
    } catch (_) {}
  }

  Future<void> refreshAnnouncementCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRead = prefs.getString('ngn_announcements_last_read') ?? _now();
      final rows = await client
          .from('announcements')
          .select('id')
          .eq('is_archived', false)
          .gt('published_at', lastRead)
          .lte('published_at', _now())
          .limit(501);
      announcementsUnread.value = rows.length;
    } catch (_) {}
  }

  Future<void> markCommunityRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ngn_community_last_read', _now());
    communityUnread.value = 0;
  }

  Future<void> markAnnouncementsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ngn_announcements_last_read', _now());
    announcementsUnread.value = 0;
  }
}
