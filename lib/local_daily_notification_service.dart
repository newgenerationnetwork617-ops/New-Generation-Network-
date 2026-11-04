import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'content_repository.dart';

/// Schedules the bundled daily Word for Today and devotional on the device.
/// The rolling 30-day window stays below iOS's 64 pending-notification limit.
class LocalDailyNotificationService {
  LocalDailyNotificationService._();

  static final LocalDailyNotificationService instance =
      LocalDailyNotificationService._();

  static const int _windowDays = 30;
  static const int _wordIdBase = 10000;
  static const int _devotionalIdBase = 20000;
  static const String _wordEnabledKey = 'ngn_local_word_notifications_enabled';
  static const String _devotionalEnabledKey =
      'ngn_local_devotional_notifications_enabled';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<bool> wordEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> devotionalEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<String?> openedPayload = ValueNotifier<String?>(null);

  bool _initialized = false;
  late final ContentRepository _content;

  Future<void> initialize() async {
    if (_initialized) return;

    _content = ContentRepository(Supabase.instance.client);
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Nigeria is the safe fallback if the device timezone cannot be read.
      tz.setLocalLocation(tz.getLocation('Africa/Lagos'));
    }

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
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          openedPayload.value = payload;
        }
      },
    );

    final prefs = await SharedPreferences.getInstance();
    wordEnabled.value = prefs.getBool(_wordEnabledKey) ?? true;
    devotionalEnabled.value = prefs.getBool(_devotionalEnabledKey) ?? true;
    _initialized = true;

    await requestPermissions();
    await _captureLaunchNotification();
    await scheduleUpcomingNotifications();
  }

  Future<void> _captureLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    final payload = response?.payload;
    if (details?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      openedPayload.value = payload;
    }
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: false, sound: true);
  }

  Future<void> setWordEnabled(bool enabled) async {
    wordEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wordEnabledKey, enabled);
    if (enabled) await requestPermissions();
    await scheduleUpcomingNotifications();
  }

  Future<void> setDevotionalEnabled(bool enabled) async {
    devotionalEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devotionalEnabledKey, enabled);
    if (enabled) await requestPermissions();
    await scheduleUpcomingNotifications();
  }

  int _dateId(DateTime date, int base) =>
      base + date.difference(DateTime(2020, 1, 1)).inDays;

  String _excerpt(String value, {int maxLength = 145}) {
    final cleaned = value.replaceAll(RegExp(r'\\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength).trimRight()}…';
  }

  Future<void> _clearScheduledWindow() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final item in pending) {
      final id = item.id;
      if ((id >= _wordIdBase && id < _wordIdBase + 5000) ||
          (id >= _devotionalIdBase && id < _devotionalIdBase + 5000)) {
        await _plugin.cancel(id: id);
      }
    }
  }

  Future<void> scheduleUpcomingNotifications() async {
    if (!_initialized) return;

    await _clearScheduledWindow();
    if (!wordEnabled.value && !devotionalEnabled.value) return;

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);

    for (var offset = 0; offset < _windowDays; offset++) {
      final date = today.add(Duration(days: offset));
      final localDate = DateTime(date.year, date.month, date.day);

      if (wordEnabled.value) {
        final scheduled = tz.TZDateTime(
          tz.local, date.year, date.month, date.day, 7, 0);
        if (scheduled.isAfter(now)) {
          final word = await _content.wordForDate(localDate);
          if (word != null) {
            final title = word['word']?.toString().trim();
            final reference = word['reference']?.toString().trim();
            final verse = word['verse_text']?.toString().trim();
            final meaning = word['meaning']?.toString().trim();
            if (title != null &&
                title.isNotEmpty &&
                reference != null &&
                reference.isNotEmpty &&
                verse != null &&
                verse.isNotEmpty) {
              final bodyParts = <String>[
                reference,
                if (meaning != null && meaning.isNotEmpty) meaning,
                _excerpt(verse, maxLength: 110),
              ];
              await _plugin.zonedSchedule(
                id: _dateId(date, _wordIdBase),
                title: 'Word for Today: $title',
                body: bodyParts.join(' • '),
                scheduledDate: scheduled,
                notificationDetails: const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'ngn_daily_word',
                    'Daily Bible Verse',
                    channelDescription:
                        'Daily offline Bible verse and Word for Today',
                    importance: Importance.high,
                    priority: Priority.high,
                    styleInformation: BigTextStyleInformation(''),
                  ),
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentSound: true,
                    presentBadge: false,
                    threadIdentifier: 'ngn-daily-word',
                  ),
                ),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                payload: 'word_for_today',
              );
            }
          }
        }
      }

      if (devotionalEnabled.value) {
        final scheduled = tz.TZDateTime(
          tz.local, date.year, date.month, date.day, 7, 30);
        if (scheduled.isAfter(now)) {
          final devotional = await _content.devotionalForDate(localDate);
          if (devotional != null) {
            final title = devotional['title']?.toString().trim();
            final reference =
                devotional['bible_reference']?.toString().trim();
            final message = devotional['message']?.toString().trim();
            if (title != null &&
                title.isNotEmpty &&
                reference != null &&
                reference.isNotEmpty &&
                message != null &&
                message.isNotEmpty) {
              await _plugin.zonedSchedule(
                id: _dateId(date, _devotionalIdBase),
                title: title,
                body: '$reference • ${_excerpt(message)}',
                scheduledDate: scheduled,
                notificationDetails: const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'ngn_daily_devotional',
                    'Daily Devotional',
                    channelDescription:
                        'Daily offline devotional reading and Bible reference',
                    importance: Importance.high,
                    priority: Priority.high,
                    styleInformation: BigTextStyleInformation(''),
                  ),
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentSound: true,
                    presentBadge: false,
                    threadIdentifier: 'ngn-daily-devotional',
                  ),
                ),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                payload: 'daily_devotional',
              );
            }
          }
        }
      }
    }
  }
}
