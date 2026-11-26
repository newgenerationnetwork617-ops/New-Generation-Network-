import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _tokenRefreshListenerAttached = false;
  final ValueNotifier<String?> openedRoute = ValueNotifier<String?>(null);

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
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) openedRoute.value = route;
      },
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
      await _registerDeviceToken(await _messaging.getToken());
      if (!_tokenRefreshListenerAttached) {
        _messaging.onTokenRefresh.listen((token) {
          unawaited(_registerDeviceToken(token));
        });
        _tokenRefreshListenerAttached = true;
      }
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
      openedRoute.value = route;
    }
  }

  Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('ngn_push_installation_id');
    if (id != null && id.isNotEmpty) return id;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    id = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await prefs.setString('ngn_push_installation_id', id);
    return id;
  }

  Future<void> _registerDeviceToken(String? token) async {
    if (token == null || token.isEmpty || kIsWeb) return;
    try {
      await Supabase.instance.client.from('ngn_push_tokens').insert({
        'installation_id': await _installationId(),
        'device_token': token,
        'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'other',
      });
    } on PostgrestException catch (error) {
      // A duplicate FCM token is already registered; clients may INSERT only.
      if (error.code != '23505') {
        debugPrint('NGN push token registration failed: ${error.message}');
      }
    } catch (error) {
      debugPrint('NGN push token registration failed: $error');
    }
  }

  Future<void> notifyCommunityMessage(String messageId) async {
    try {
      if (!_initialized) await initialize();
      await Supabase.instance.client.functions.invoke(
        'send-push-notification',
        body: {
          'type': 'community_message',
          'record_id': messageId,
          'exclude_installation_id': await _installationId(),
        },
      );
    } catch (error) {
      // Push delivery must not interrupt sending or saving a chat message.
      debugPrint('NGN community push request failed: $error');
    }
  }

  Future<String?> getDeviceToken() async {
    if (!_initialized) await initialize();
    return _messaging.getToken();
  }
}
