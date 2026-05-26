import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'mobile_push_message_mapper.dart';

typedef MobilePushMessageHandler = FutureOr<void> Function(
  MobilePushMessage message,
);

class MobilePushLocalNotifications {
  MobilePushLocalNotifications({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const androidChannelId = 'open_vts_alerts';
  static const androidChannelName = 'OpenVTS Alerts';
  static const androidChannelDescription =
      'Vehicle alerts and operational notifications';

  static const AndroidNotificationChannel androidAlertChannel =
      AndroidNotificationChannel(
    androidChannelId,
    androidChannelName,
    description: androidChannelDescription,
    importance: Importance.high,
  );

  static const _androidNotificationIcon = 'ic_stat_open_vts';

  final FlutterLocalNotificationsPlugin _notifications;

  bool _initialized = false;
  MobilePushMessageHandler? _tapHandler;

  Future<void> initialize({MobilePushMessageHandler? onTap}) async {
    _tapHandler = onTap;
    if (_initialized) {
      return;
    }

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings(_androidNotificationIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
      await _ensureAndroidChannel();
      await _handleLaunchFromLocalNotification();
      _initialized = true;
    } catch (_) {
      _initialized = false;
      throw Exception('Local notifications could not be initialized.');
    }
  }

  Future<void> showForegroundMessage(MobilePushMessage message) async {
    if (!_initialized) {
      await initialize(onTap: _tapHandler);
    }

    final title = message.title?.trim().isNotEmpty == true
        ? message.title!.trim()
        : 'OpenVTS';
    final body = message.body?.trim().isNotEmpty == true
        ? message.body!.trim()
        : 'New notification received.';

    // Primary attempt: use the branded notification icon.
    try {
      await _showWithIcon(
        message,
        title: title,
        body: body,
        androidIcon: _androidNotificationIcon,
      );
      return;
    } catch (_) {
      // Icon may be unavailable at runtime; fall through to retry without it.
    }

    // Fallback: omit the custom icon so the plugin uses the default configured
    // in AndroidInitializationSettings.
    try {
      await _showWithIcon(message, title: title, body: body, androidIcon: null);
    } catch (_) {
      throw Exception('Unable to display local notification.');
    }
  }

  Future<void> _showWithIcon(
    MobilePushMessage message, {
    required String title,
    required String body,
    required String? androidIcon,
  }) async {
    await _notifications.show(
      id: message.localNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          icon: androidIcon,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      ),
      payload: message.toLocalNotificationPayload(),
    );
  }

  Future<void> _ensureAndroidChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final androidNotifications =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(androidAlertChannel);
  }

  Future<void> _handleLaunchFromLocalNotification() async {
    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) {
      return;
    }

    final response = launchDetails?.notificationResponse;
    if (response == null) {
      return;
    }

    _handleNotificationResponse(response);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final message = MobilePushMessageMapper.fromLocalNotificationPayload(
      response.payload,
    );
    if (message == null) {
      return;
    }

    final handler = _tapHandler;
    if (handler != null) {
      Future<void>.sync(() => handler(message));
    }
  }
}
