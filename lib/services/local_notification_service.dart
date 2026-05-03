import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onTap,
  }) async {
    if (_initialized || kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        try {
          final parsed = jsonDecode(payload);
          if (parsed is Map<String, dynamic>) {
            onTap?.call(parsed);
          } else if (parsed is Map) {
            onTap?.call(parsed.cast<String, dynamic>());
          }
        } catch (_) {
          // Ignore malformed payloads.
        }
      },
    );

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'soil_alerts',
          'Soil Alerts',
          description: 'Soil weather and fingerprint alerts',
          importance: Importance.max,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'security_alerts',
          'Security Alerts',
          description: 'Security incident alerts',
          importance: Importance.max,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'fieldly_general',
          'Fieldly Notifications',
          description: 'General Fieldly notifications',
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];

    if ((title == null || title.toString().trim().isEmpty) &&
        (body == null || body.toString().trim().isEmpty)) {
      return;
    }

    final payload = Map<String, dynamic>.from(message.data);
    final channelId = _resolveChannelId(payload);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'soil_alerts'
          ? 'Soil Alerts'
          : channelId == 'security_alerts'
              ? 'Security Alerts'
              : 'Fieldly Notifications',
      channelDescription: 'Fieldly alerts and notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      (title ?? 'Fieldly Alert').toString(),
      (body ?? '').toString(),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(payload),
    );
  }

  static Future<void> showSoilAlertNotification({
    required String alertId,
    required String parcelId,
    required String severity,
    required String alertType,
    required String message,
  }) async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final normalizedSeverity = severity.toUpperCase();
    final title = 'Soil Alert ($normalizedSeverity)';

    final payload = {
      'screen': 'SOIL_ALERTS',
      'type': 'SOIL_WEATHER_ALERT',
      'alertId': alertId,
      'parcelId': parcelId,
      'severity': normalizedSeverity,
      'alertType': alertType,
      'message': message,
    };

    const androidDetails = AndroidNotificationDetails(
      'soil_alerts',
      'Soil Alerts',
      channelDescription: 'Soil weather and fingerprint alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      alertId.hashCode,
      title,
      message,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(payload),
    );
  }

  static String _resolveChannelId(Map<String, dynamic> data) {
    final screen = (data['screen'] ?? '').toString().toUpperCase();
    final type = (data['type'] ?? '').toString().toUpperCase();

    if (screen == 'SOIL_ALERTS' || type == 'SOIL_WEATHER_ALERT') {
      return 'soil_alerts';
    }

    if (screen == 'INCIDENT_DETAILS') {
      return 'security_alerts';
    }

    return 'fieldly_general';
  }
}
