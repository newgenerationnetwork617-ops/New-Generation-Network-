import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bible_repository.dart';

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
    // Daily devotionals are bundled in the app and work without a network.
    // NGN uses Nigeria time (UTC+1) to select the correct calendar reading.
    final lagosDate = date.toUtc().add(const Duration(hours: 1));
    final keyDate =
        '${lagosDate.year.toString().padLeft(4, '0')}-${lagosDate.month.toString().padLeft(2, '0')}-${lagosDate.day.toString().padLeft(2, '0')}';
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
    // Select the daily word using Nigeria time, then read its Scripture from
    // the Bible bundled with the app. No network request is required.
    final nigeriaDate = date.toUtc().add(const Duration(hours: 1));
    final keyDate =
        '${nigeriaDate.year.toString().padLeft(4, '0')}-${nigeriaDate.month.toString().padLeft(2, '0')}-${nigeriaDate.day.toString().padLeft(2, '0')}';
    try {
      final raw = await rootBundle.loadString('assets/word_of_day/word_of_day.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = decoded['entries'] as List<dynamic>? ?? const [];
      Map<String, dynamic>? selected;
      for (final value in entries) {
        if (value is Map && value['date']?.toString() == keyDate) {
          selected = Map<String, dynamic>.from(value);
          break;
        }
      }
      if (selected == null) return null;
      final reference = selected['reference']?.toString() ?? '';
      final match = RegExp(r'^(.+) ([0-9]+):([0-9]+)$').firstMatch(reference);
      if (match == null) return null;
      final book = match.group(1)!;
      final chapter = int.parse(match.group(2)!);
      final verseNumber = int.parse(match.group(3)!);
      final verses = await BibleRepository().verses(book, chapter);
      for (final verse in verses) {
        if (verse.number == verseNumber) {
          selected['verse_text'] = verse.text;
          selected['translation'] = BibleRepository.translation;
          return selected;
        }
      }
    } catch (_) {
      // The bundled word or Bible text could not be read.
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
