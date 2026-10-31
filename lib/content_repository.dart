import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContentRepository {
  ContentRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> _cachedList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    String table,
    String cacheKey,
    String orderColumn,
  ) async {
    final cached = await _cachedList(cacheKey);
    try {
      var query = client.from(table).select();
      if (orderColumn == 'published_at') {
        query = query.lte('published_at', DateTime.now().toUtc().toIso8601String());
      }
      final rows = await query.order(orderColumn, ascending: false);
      final remote = List<Map<String, dynamic>>.from(
        (rows as List).map((row) => Map<String, dynamic>.from(row)),
      );

      // Keep previously synced items on this phone even if an administrator
      // later archives them. The server no longer sends archived items to new
      // installs, but a successful refresh must not erase an existing copy.
      final byId = <String, Map<String, dynamic>>{};
      for (final item in cached) {
        final id = item['id']?.toString();
        if (id != null) byId[id] = item;
      }
      for (final item in remote) {
        final id = item['id']?.toString();
        if (id != null) byId[id] = item;
      }
      final data = byId.values.toList()
        ..sort((a, b) => (b[orderColumn]?.toString() ?? '')
            .compareTo(a[orderColumn]?.toString() ?? ''));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(data));
      return data;
    } catch (_) {
      return cached;
    }
  }

  Future<List<Map<String, dynamic>>> devotionals() =>
      _fetchList('devotionals', 'ngn_devotionals', 'published_at');

  Future<Map<String, dynamic>?> devotionalForDate(DateTime date) async {
    final keyDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final rows = await client
          .from('devotionals')
          .select()
          .gte('published_at', start.toUtc().toIso8601String())
          .lt('published_at', end.toUtc().toIso8601String())
          .order('published_at');
      final data = List<Map<String, dynamic>>.from(
        (rows as List).map((row) => Map<String, dynamic>.from(row)),
      );
      if (data.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ngn_devotional_day_$keyDate', jsonEncode(data.first));
      return data.first;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ngn_devotional_day_$keyDate');
      if (raw != null) {
        try {
          return Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {}
      }
      final cached = await _cachedList('ngn_devotionals');
      for (final item in cached) {
        final published = DateTime.tryParse(item['published_at']?.toString() ?? '')?.toLocal();
        if (published != null &&
            published.year == date.year &&
            published.month == date.month &&
            published.day == date.day) {
          return item;
        }
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> teachings() =>
      _fetchList('teachings', 'ngn_teachings', 'published_at');

  Future<List<Map<String, dynamic>>> announcements() =>
      _fetchList('announcements', 'ngn_announcements', 'published_at');

  Future<List<Map<String, dynamic>>> events() =>
      _fetchList('events', 'ngn_events', 'starts_at');

  Future<Map<String, dynamic>?> dailyVerse() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final row = await client
          .from('daily_bible_verses')
          .select()
          .eq('verse_date', today)
          .maybeSingle();
      if (row != null) {
        final data = Map<String, dynamic>.from(row);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ngn_daily_verse_$today', jsonEncode(data));
        return data;
      }
    } catch (_) {}

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ngn_daily_verse_$today') ??
        prefs.getString('ngn_daily_verse');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
