import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../core/routes/app_routes.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

/// Top-level FCM background/terminated handler.
///
/// Runs in its own isolate with a re-initialized default Firebase app, so it
/// can only use Firebase SDKs (no widget tree / provider access). Writes the
/// incoming data message into the notification center so it is visible the
/// next time the app opens.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final data = message.data;
    final userId = data['userId']?.toString() ?? '';
    if (userId.isEmpty) return;

    final model = NotificationModel(
      id: '',
      userId: userId,
      type: NotificationType.fromKey(data['type']?.toString()),
      title: data['title']?.toString() ?? message.notification?.title ?? 'Notification',
      body: data['body']?.toString() ?? message.notification?.body ?? '',
      actionRoute: data['actionRoute']?.toString(),
      relatedId: data['relatedId']?.toString(),
      eventKey: data['eventKey']?.toString() ?? '',
      createdAt: DateTime.now(),
    );

    await NotificationRepository().add(model);
  } catch (e) {
    debugPrint('[NotificationService] background handler failed: $e');
  }
}

class NotificationService {
  static const String channelAlerts = 'alerts';
  static const String channelReminders = 'reminders';
  static const String channelInformation = 'updates';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();

  bool _isInitialized = false;
  String? _registeredUserId;
  String? _currentToken;

  /// Idempotent one-time setup: timezone, permissions, local notifications,
  /// FCM listeners and the background handler.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Local notifications are unsupported on the web; the admin portal is
    // web-only and needs no push setup.
    if (kIsWeb) return;

    tz.initializeTimeZones();

    await _requestPermissions();

    await _initializeLocalNotifications();

    await _configureFirebaseMessaging();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[NotificationService] FCM permission granted');
      }
    } catch (e) {
      debugPrint('[NotificationService] FCM permission request failed: $e');
    }

    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Navigates to the route stored in the notification payload when the user
  /// taps a notification. The payload may be a plain route or `route|relatedId`
  /// (encoded by [_scheduleReminder]) so treatment reminders deep-link to the
  /// exact record.
  void _onNotificationTapped(NotificationResponse response) {
    final (route, relatedId) = _parseNotificationPayload(response.payload);
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamed(
      route,
      arguments: (route == AppRoutes.treatmentCalendar && relatedId != null)
          ? relatedId
          : null,
    );
  }

  /// Parses a notification payload. Empty payloads fall back to the weather
  /// details screen (kept for legacy notifications).
  (String, String?) _parseNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return (AppRoutes.weatherDetails, null);
    }
    final separator = payload.indexOf('|');
    if (separator > 0) {
      final route = payload.substring(0, separator);
      final relatedId = payload.substring(separator + 1);
      return (route, relatedId.isEmpty ? null : relatedId);
    }
    return (payload, null);
  }

  Future<void> _configureFirebaseMessaging() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('[NotificationService] getToken failed: $e');
    }

    FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleAppOpenedMessage(message);
    });

    _firebaseMessaging.onTokenRefresh.listen((token) {
      debugPrint('[NotificationService] FCM token refreshed');
      _currentToken = token;
      if (_registeredUserId != null) {
        _storeDeviceToken(_registeredUserId!, token);
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title =
        data['title']?.toString() ?? message.notification?.title ?? 'Notification';
    final body =
        data['body']?.toString() ?? message.notification?.body ?? '';
    final actionRoute = data['actionRoute']?.toString();

    _showLocalNotification(
      title,
      body,
      payload: actionRoute,
      channel: _channelForType(data['type']?.toString()),
    );

    // Persist into the notification center (deduplicated by eventKey).
    final userId = data['userId']?.toString() ?? _registeredUserId;
    if (userId != null && userId.isNotEmpty) {
      final model = NotificationModel(
        id: '',
        userId: userId,
        type: NotificationType.fromKey(data['type']?.toString()),
        title: title,
        body: body,
        actionRoute: actionRoute,
        relatedId: data['relatedId']?.toString(),
        eventKey: data['eventKey']?.toString() ?? '',
        createdAt: DateTime.now(),
      );
      _repository.add(model);
    }
  }

  void _handleAppOpenedMessage(RemoteMessage message) {
    final actionRoute = message.data['actionRoute']?.toString();
    if (actionRoute == null || actionRoute.isEmpty) return;
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) return;
    final relatedId = message.data['relatedId']?.toString();
    navigator.pushNamed(
      actionRoute,
      arguments: (actionRoute == AppRoutes.treatmentCalendar &&
              relatedId != null &&
              relatedId.isNotEmpty)
          ? relatedId
          : null,
    );
  }

  static String _channelForType(String? typeKey) {
    final type = NotificationType.fromKey(typeKey);
    switch (type) {
      case NotificationType.treatmentReminder:
      case NotificationType.fertilizerReminder:
        return channelReminders;
      case NotificationType.weatherAdvisory:
        return channelAlerts;
      case NotificationType.weatherUpdate:
      case NotificationType.tip:
      case NotificationType.adminAnnouncement:
      case NotificationType.farmActivity:
        return channelInformation;
    }
  }

  /// Registers this device's FCM token under `users/{uid}/devices/{token}` so a
  /// future push server can deliver messages to this device. Safe to call
  /// repeatedly (idempotent).
  Future<void> registerDeviceToken(String userId) async {
    if (userId.isEmpty) return;
    final token = _currentToken ?? await _firebaseMessaging.getToken();
    if (token == null || token.isEmpty) return;

    _registeredUserId = userId;
    _currentToken = token;
    await _storeDeviceToken(userId, token);
  }

  Future<void> _storeDeviceToken(String userId, String token) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('devices')
          .child(token)
          .set({
        'platform': defaultTargetPlatform.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[NotificationService] token registration failed: $e');
    }
  }

  /// Removes this device's token when the user signs out.
  Future<void> unregisterDeviceToken(String userId) async {
    try {
      final token = _currentToken ?? await _firebaseMessaging.getToken();
      if (userId.isNotEmpty && token != null && token.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .child('devices')
            .child(token)
            .remove();
      }
    } catch (e) {
      debugPrint('[NotificationService] token removal failed: $e');
    }
    _registeredUserId = null;
  }

  /// Schedules an exact local reminder on the Reminders channel. Works while
  /// the app is closed (Android exact-alarm with boot receiver).
  Future<void> scheduleTreatmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? relatedId,
  }) async {
    await _scheduleReminder(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      relatedId: relatedId,
    );
  }

  Future<void> scheduleFertilizationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? relatedId,
  }) async {
    await _scheduleReminder(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      relatedId: relatedId,
    );
  }

  Future<void> _scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? relatedId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelReminders,
      'Reminders',
      channelDescription: 'Treatment and fertilization reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );
    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: relatedId == null || relatedId.isEmpty
          ? AppRoutes.treatmentCalendar
          : '${AppRoutes.treatmentCalendar}|$relatedId',
    );
  }

  Future<void> showRainWarning(String message) async {
    await _showLocalNotification(
      'Rain Warning',
      message,
      payload: AppRoutes.weatherDetails,
      channel: channelAlerts,
    );
  }

  Future<void> showPHAlert(String message) async {
    await _showLocalNotification(
      'pH Alert',
      message,
      channel: channelAlerts,
    );
  }

  Future<void> showMoistureAlert(String message) async {
    await _showLocalNotification(
      'Moisture Alert',
      message,
      channel: channelAlerts,
    );
  }

  /// Immediately shows a local notification. Used for the immediate rain
  /// warning and for foreground FCM messages.
  Future<void> showLocalNotification(
    String title,
    String body, {
    String? payload,
    String channel = channelAlerts,
  }) {
    return _showLocalNotification(title, body, payload: payload, channel: channel);
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
    String channel = channelAlerts,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      _channelName(channel),
      channelDescription: _channelDescription(channel),
      importance: channel == channelInformation
          ? Importance.defaultImportance
          : Importance.high,
      priority: channel == channelInformation
          ? Priority.defaultPriority
          : Priority.high,
      icon: 'ic_notification',
    );
    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] show local notification failed: $e');
    }
  }

  static String _channelName(String channel) {
    switch (channel) {
      case channelReminders:
        return 'Reminders';
      case channelInformation:
        return 'Information';
      case channelAlerts:
      default:
        return 'Alerts';
    }
  }

  static String _channelDescription(String channel) {
    switch (channel) {
      case channelReminders:
        return 'Treatment and fertilization reminders';
      case channelInformation:
        return 'Weather updates, tips and announcements';
      case channelAlerts:
      default:
        return 'Important farm alerts and warnings';
    }
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
