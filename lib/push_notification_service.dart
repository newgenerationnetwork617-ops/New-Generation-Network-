import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles online push notifications. Supabase remains NGN's backend;
/// Firebase Cloud Messaging is used only for device notification delivery.
@pragma('vm:entry-point')
Future<void> ngnFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    _initialized = true;
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
    // Routing will be connected to the relevant NGN screens in the app.
    // Keep this callback safe when a push has no route data.
    final route = message.data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      debugPrint('NGN notification opened for route: $route');
    }
  }

  Future<String?> getDeviceToken() async {
    if (!_initialized) await initialize();
    return _messaging.getToken();
  }
}
