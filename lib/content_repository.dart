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
    try {
      final rows = await client
          .from(table)
          .select()
          .order(orderColumn, ascending: false);
      final data = List<Map<String, dynamic>>.from(
        (rows as List).map((row) => Map<String, dynamic>.from(row)),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(data));
      return data;
    } catch (_) {
      return _cachedList(cacheKey);
    }
  }

  Future<List<Map<String, dynamic>>> devotionals() =>
      _fetchList('devotionals', 'ngn_devotionals', 'published_at');

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
        await prefs.setString('ngn_daily_verse', jsonEncode(data));
        return data;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ngn_daily_verse');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
