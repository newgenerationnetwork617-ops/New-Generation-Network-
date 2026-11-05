import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Offline daily notifications sourced entirely from NGN's bundled content.
///
/// iOS retains at most 64 pending local notifications. NGN therefore keeps a
/// rolling 30-day window (at most 60 reminders) and refreshes it whenever the
/// app is opened or resumed.
class DailyLocalNotificationService {
  DailyLocalNotificationService._();

  static final DailyLocalNotificationService instance =
      DailyLocalNotificationService._();

  static const String dailyVerseEnabledKey = 'ngn_local_daily_verse_enabled';
  static const String devotionalEnabledKey = 'ngn_local_devotional_enabled';
  static const String eveningReflectionEnabledKey = 'ngn_local_evening_reflection_enabled';
  // Keep at most 63 pending reminders for iOS compatibility (21 days × 3).
  static const int _rollingDays = 21;
  static const int _verseNotificationOffset = 1;
  static const int _devotionalNotificationOffset = 2;
  static const int _eveningNotificationOffset = 3;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<String?> openedPayload = ValueNotifier<String?>(null);

  Map<String, dynamic>? _wordLibrary;
  final Map<String, Map<String, dynamic>> _devotionalMonthCache = {};
  bool _initialized = false;

  Future<void> _refreshLocalTimezone() async {
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
    } catch (_) {
      // Keep the last known timezone rather than guessing from an abbreviation.
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _refreshLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        openedPayload.value = response.payload;
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      openedPayload.value =
          launchDetails?.notificationResponse?.payload;
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<bool> dailyVerseEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dailyVerseEnabledKey) ?? true;
  }

  Future<bool> devotionalEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(devotionalEnabledKey) ?? true;
  }

  Future<void> setDailyVerseEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dailyVerseEnabledKey, enabled);
    if (enabled && !await requestPermissions()) return;
    await scheduleUpcoming();
  }

  Future<void> setDevotionalEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(devotionalEnabledKey, enabled);
    if (enabled && !await requestPermissions()) return;
    await scheduleUpcoming();
  }

  Future<bool> eveningReflectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(eveningReflectionEnabledKey) ?? true;
  }

  Future<void> setEveningReflectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(eveningReflectionEnabledKey, enabled);
    if (enabled && !await requestPermissions()) return;
    await scheduleUpcoming();
  }

  Future<void> requestPermissionAndSchedule() async {
    if (!await dailyVerseEnabled() &&
        !await devotionalEnabled() &&
        !await eveningReflectionEnabled()) return;
    if (await requestPermissions()) {
      await scheduleUpcoming();
    }
  }

  Future<void> scheduleUpcoming() async {
    if (!_initialized) await initialize();
    await _refreshLocalTimezone();

    final verseEnabled = await dailyVerseEnabled();
    final devotionalIsEnabled = await devotionalEnabled();
    final eveningIsEnabled = await eveningReflectionEnabled();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Clear only IDs reserved for this feature. Do not affect any future
    // announcement or Firebase notification implementation.
    for (var offset = 0; offset < _rollingDays; offset++) {
      final date = today.add(Duration(days: offset));
      await _plugin.cancel(id: _notificationId(date, _verseNotificationOffset));
      await _plugin.cancel(
        id: _notificationId(date, _devotionalNotificationOffset),
      );
      await _plugin.cancel(
        id: _notificationId(date, _eveningNotificationOffset),
      );
    }

    for (var offset = 0; offset < _rollingDays; offset++) {
      final date = today.add(Duration(days: offset));

      if (verseEnabled) {
        final scheduledAt = _scheduledTime(date, 6, 30);
        if (scheduledAt.isAfter(now)) {
          final verse = await _wordForDate(date);
          if (verse != null) {
            await _schedule(
              id: _notificationId(date, _verseNotificationOffset),
              title: 'NGN • Word for Today',
              body: _verseNotificationBody(verse),
              scheduledAt: scheduledAt,
              payload: 'word:${_dateKey(date)}',
            );
          }
        }
      }

      if (devotionalIsEnabled) {
        final scheduledAt = _scheduledTime(date, 7, 0);
        if (scheduledAt.isAfter(now)) {
          final devotional = await _devotionalForDate(date);
          if (devotional != null) {
            await _schedule(
              id: _notificationId(date, _devotionalNotificationOffset),
              title: 'NGN • Daily Devotional',
              body: _devotionalNotificationBody(devotional),
              scheduledAt: scheduledAt,
              payload: 'devotional:${_dateKey(date)}',
            );
          }
        }
      }

      if (eveningIsEnabled) {
        final scheduledAt = _scheduledTime(date, 18, 0);
        if (scheduledAt.isAfter(now)) {
          await _schedule(
            id: _notificationId(date, _eveningNotificationOffset),
            title: 'NGN • Evening Reflection',
            body: 'Have you read your Bible today? Have you gone through your devotion? What have you heard from God today? Take a moment to reflect.',
            scheduledAt: scheduledAt,
            payload: 'reflection:${_dateKey(date)}',
          );
        }
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ngn_daily_readings',
        'Daily Bible Readings',
        channelDescription:
            'Daily Bible verse and devotional reminders from NGN',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<Map<String, dynamic>?> _wordForDate(DateTime date) async {
    try {
      _wordLibrary ??= jsonDecode(
        await rootBundle.loadString('assets/word_of_day/word_of_day.json'),
      ) as Map<String, dynamic>;
      final entries = _wordLibrary!['entries'] as List<dynamic>? ?? const [];
      final key = _dateKey(date);
      for (final entry in entries) {
        if (entry is Map && entry['date']?.toString() == key) {
          return Map<String, dynamic>.from(entry);
        }
      }
    } catch (_) {
      // Missing content for a date means no notification is scheduled.
    }
    return null;
  }

  Future<Map<String, dynamic>?> _devotionalForDate(DateTime date) async {
    final key = _dateKey(date);
    final month = key.substring(0, 7);
    try {
      var library = _devotionalMonthCache[month];
      if (library == null) {
        library = jsonDecode(
          await rootBundle.loadString(
            'assets/devotionals/spurgeon-morning/$month.json',
          ),
        ) as Map<String, dynamic>;
        _devotionalMonthCache[month] = library;
      }

      final entries = library['entries'] as List<dynamic>? ?? const [];
      for (final entry in entries) {
        if (entry is Map &&
            (entry['published_at']?.toString() ?? '').startsWith(key)) {
          return Map<String, dynamic>.from(entry);
        }
      }
    } catch (_) {
      // Missing content for a date means no notification is scheduled.
    }
    return null;
  }

  String _verseNotificationBody(Map<String, dynamic> verse) {
    final word = verse['word']?.toString().trim() ?? '';
    final reference = verse['reference']?.toString().trim() ?? '';
    final excerpt = _excerpt(verse['verse_text']?.toString() ?? '');
    return [
      if (word.isNotEmpty) word,
      if (reference.isNotEmpty) reference,
      if (excerpt.isNotEmpty) excerpt,
    ].join(' • ');
  }

  String _devotionalNotificationBody(Map<String, dynamic> devotional) {
    final title = devotional['title']?.toString().trim() ?? '';
    final reference = devotional['bible_reference']?.toString().trim() ?? '';
    final excerpt = _excerpt(devotional['message']?.toString() ?? '');
    return [
      if (title.isNotEmpty) title,
      if (reference.isNotEmpty) reference,
      if (excerpt.isNotEmpty) excerpt,
    ].join(' • ');
  }

  String _excerpt(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 145) return normalized;
    return '${normalized.substring(0, 142).trimRight()}…';
  }

  DateTime _scheduledTime(DateTime date, int hour, int minute) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // Android notification IDs are 32-bit integers. A YYYYMMDD-based ID
  // exceeds that range, so use the UTC day number and a two-slot offset.
  int _notificationId(DateTime date, int offset) =>
      DateTime.utc(date.year, date.month, date.day)
              .difference(DateTime.utc(1970, 1, 1))
              .inDays *
          10 +
      offset;
}
