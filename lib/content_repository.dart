import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
      // A stalled or unavailable connection must not leave content screens
      // showing an endless loading indicator. On timeout, fall back to the
      // last successful on-device cache in the catch block below.
      final rows = await query
          .order(orderColumn, ascending: false)
          .timeout(const Duration(seconds: 7));
      final remote = List<Map<String, dynamic>>.from(
        (rows as List).map((row) => Map<String, dynamic>.from(row)),
      );

      // A successful server refresh is authoritative: deleted content must
      // disappear from this device's synced cache. If offline, _fetchList
      // still returns the last cached copy from the catch block.
      final data = remote
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
    // Daily devotionals are bundled in the app and work without a network.
    // Use the device's local calendar date and time zone. This works offline.
    final localDate = date.toLocal();
    final keyDate =
        '${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    final monthAsset =
        'assets/devotionals/spurgeon-morning/${keyDate.substring(0, 7)}.json';
    try {
      final raw = await rootBundle.loadString(monthAsset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = decoded['entries'] as List<dynamic>? ?? const [];
      for (final value in entries) {
        if (value is Map) {
          final item = Map<String, dynamic>.from(value);
          if ((item['published_at']?.toString() ?? '').startsWith(keyDate)) {
            return item;
          }
        }
      }
    } catch (_) {
      // The selected date may be outside the range bundled in this app.
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> teachings() =>
      _fetchList('teachings', 'ngn_teachings', 'published_at');

  Future<List<Map<String, dynamic>>> announcements() =>
      _fetchList('announcements', 'ngn_announcements', 'published_at');

  Future<List<Map<String, dynamic>>> events() =>
      _fetchList('events', 'ngn_events', 'starts_at');


  Future<Map<String, dynamic>?> wordForDate(DateTime date) async {
    // The daily word, meaning, and full Scripture text are bundled locally.
    // Use the device's local calendar date and time zone. The bundled
    // word, meaning, and Scripture remain available completely offline.
    final localDate = date.toLocal();
    final keyDate =
        '${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    try {
      final raw = await rootBundle.loadString('assets/word_of_day/word_of_day.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = decoded['entries'] as List<dynamic>? ?? const [];
      for (final value in entries) {
        if (value is Map && value['date']?.toString() == keyDate) {
          final selected = Map<String, dynamic>.from(value);
          selected['translation'] = decoded['translation'] ?? 'World English Bible (WEB)';
          if ((selected['verse_text']?.toString() ?? '').isNotEmpty) return selected;
          return null;
        }
      }
    } catch (_) {
      // The bundled daily reading could not be read.
    }
    return null;
  }

  Future<Map<String, dynamic>?> dailyVerse() async {
    try {
      final today = DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String().substring(0, 10);
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

    final today = DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String().substring(0, 10);
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
