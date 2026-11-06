import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles online push notifications. Supabase stores installation tokens;
/// Firebase Cloud Messaging delivers remote notifications to those tokens.
@pragma('vm:entry-point')
Future<void> ngnFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Notification payloads are displayed automatically by Android while the
  // app is backgrounded. Data-only messages need a local notification.
  if (message.notification != null) return;

  final title = (message.data['title'] ?? 'New Generation Network').toString();
  final body = (message.data['body'] ?? message.data['message'] ?? '').toString();
  if (body.trim().isEmpty) return;

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  const channel = AndroidNotificationChannel(
    'ngn_push_notifications',
    'NGN Updates',
    description: 'Community messages, teachings, events and ministry updates',
    importance: Importance.high,
  );
  final android = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(channel);

  await notifications.show(
    id: message.messageId?.hashCode ?? message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'ngn_push_notifications',
        'NGN Updates',
        channelDescription:
            'Community messages, teachings, events and ministry updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: message.data['route']?.toString(),
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ngn_push_notifications',
    'NGN Updates',
    description: 'Community messages, teachings, events and ministry updates',
    importance: Importance.high,
  );

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      ngnFirebaseMessagingBackgroundHandler,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final canReceiveNotifications =
        permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;

    if (canReceiveNotifications) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Store the token against a stable installation ID so a backend sender
      // can target this installation even when the public visitor is signed out.
      await _registerCurrentToken();
      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerToken(token)),
        onError: (Object error) =>
            debugPrint('NGN FCM token refresh failed: $error'),
      );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    _initialized = true;
  }

  Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'ngn_push_installation_id';
    final saved = prefs.getString(key);
    if (saved != null && saved.isNotEmpty) return saved;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final id = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
    await prefs.setString(key, id);
    return id;
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) await _registerToken(token);
    } catch (error) {
      debugPrint('NGN could not obtain/register FCM token: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final installationId = await _installationId();
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'other';

      await Supabase.instance.client.from('ngn_push_tokens').insert({
        'installation_id': installationId,
        'device_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('NGN FCM token registered for this installation.');
    } catch (error) {
      // A repeated token may already exist; token refreshes insert the new
      // token without requiring clients to read or update token records.
      // Do not block startup if the network is temporarily unavailable.
      debugPrint('NGN FCM token registration failed: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'New Generation Network',
      body: notification.body ?? 'You have a new update.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ngn_push_notifications',
          'NGN Updates',
          channelDescription:
              'Community messages, teachings, events and ministry updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route']?.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      debugPrint('NGN notification opened for route: $route');
    }
  }

  Future<String?> getDeviceToken() async {
    if (!_initialized) await initialize();
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }
    return token;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
