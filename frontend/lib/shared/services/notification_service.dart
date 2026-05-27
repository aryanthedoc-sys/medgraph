import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'api_service.dart';

// Must be a top-level function — runs in a separate isolate when app is killed.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // Firebase SDK already displays the notification for notification-messages.
  // Data-only messages in background are handled here if needed.
  debugPrint('[FCM background] type=${message.data['type']}');
}

class NotificationService {
  NotificationService._();

  // Attach this to GoRouter's navigatorKey so we can route on tap.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'medgraph_main',
    'MedGraph Notifications',
    description: 'Matches, sessions, and activity',
    importance: Importance.max,
    playSound: true,
  );

  static bool _initialized = false;

  /// Call once from main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    // Register background handler before any other FirebaseMessaging calls.
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Create Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Init flutter_local_notifications.
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Request OS permissions (no-op on Android <13; prompts on iOS/Android 13+).
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // Register token with backend.
    await _registerToken();

    // Refresh token whenever Firebase rotates it.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      ApiService.post('/api/notifications/token', {'token': token})
          .catchError((_) => <String, dynamic>{});
    });

    // Foreground messages — show via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Taps when app was in background (not killed).
    FirebaseMessaging.onMessageOpenedApp
        .listen((msg) => _routeFromData(msg.data));

    // Taps that launched the app from a killed state.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _routeFromData(initial.data);
  }

  /// Remove token on logout so the user stops receiving pushes.
  static Future<void> deregisterToken() async {
    try {
      await Future.wait([
        ApiService.delete('/api/notifications/token'),
        FirebaseMessaging.instance.deleteToken(),
      ]);
    } catch (_) {}
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.post('/api/notifications/token', {'token': token});
      }
    } catch (e) {
      debugPrint('[FCM] token registration failed: $e');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    final type = message.data['type'] ?? '';
    final id = message.data['roomId'] ?? message.data['sessionId'] ?? '';

    _localNotifications.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '$type|$id',
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length < 2) return;
    _navigateTo(parts[0], parts[1]);
  }

  static void _routeFromData(Map<String, dynamic> data) {
    _navigateTo(
      data['type'] as String? ?? '',
      data['roomId'] as String? ?? data['sessionId'] as String? ?? '',
    );
  }

  static void _navigateTo(String type, String id) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'match_found':
        GoRouter.of(context).go('/roulette');
      case 'session_matched':
        GoRouter.of(context).go('/sessions');
      case 'streak_reminder':
        GoRouter.of(context).go('/home');
    }
  }
}
