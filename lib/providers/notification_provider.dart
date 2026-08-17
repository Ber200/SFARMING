import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_repository.dart';
import '../services/notification_service.dart';

/// Drives the farmer's Notification Center.
///
/// Binds to the signed-in user, streams their persisted notification records
/// from the repository, exposes the list + unread count, writes new records
/// (deduplicated by `eventKey`) and throttles SMARTFARMING tips.
class NotificationProvider extends ChangeNotifier {
  static const Duration _tipInterval = Duration(days: 3);

  static const List<String> _tips = [
    'Water your crops early in the morning or late in the afternoon to reduce evaporation loss.',
    'Keep the soil pH in the ideal 6.0–6.8 range; test regularly for best yields.',
    'Spray pesticides in the late afternoon so the solution stays longer on the leaves.',
    'Rotate your crops each season to prevent soil-borne diseases from building up.',
    'Mulching around plants conserves soil moisture and suppresses weeds.',
    'Inspect leaves weekly; catching disease early makes treatment cheaper and faster.',
    'Ensure drainage ditches are clear before the rainy season to avoid flooding.',
    'Fertilize in split doses instead of one heavy application for steady crop growth.',
    'Maintain records of treatments applied — they help spot recurring pest patterns.',
    'Clean farm equipment after each use to prevent the spread of disease.',
  ];

  final NotificationRepository _repository = NotificationRepository();
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _userId;
  StreamSubscription? _subscription;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get currentUserId => _userId;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Binds the provider to the signed-in user: starts the real-time listener
  /// and registers the device FCM token. Rebinding to the same user is a no-op.
  void bindUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.streamForUser(userId).listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
        _maybeGenerateTip(userId);
      },
      onError: (Object error) {
        debugPrint('[NotificationProvider] stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );

    _notificationService.registerDeviceToken(userId);
  }

  /// Unbinds the listener and removes this device's FCM token.
  void unbind() {
    _subscription?.cancel();
    _subscription = null;
    if (_userId != null) {
      _notificationService.unregisterDeviceToken(_userId!);
    }
    _userId = null;
    _notifications = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Writes a new notification record (deduplicated by [eventKey]) and, when
  /// [showLocal] is true, immediately shows a local notification.
  Future<bool> addNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? actionRoute,
    String? relatedId,
    String? eventKey,
    bool showLocal = false,
  }) async {
    if (userId.isEmpty) return false;
    final key = eventKey ??
        '${type.key}|$userId|${DateTime.now().millisecondsSinceEpoch}';

    final model = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      actionRoute: actionRoute,
      relatedId: relatedId,
      eventKey: key,
      createdAt: DateTime.now(),
    );

    final id = await _repository.add(model);
    if (id == null) return false;

    if (showLocal) {
      _notificationService.showLocalNotification(
        title,
        body,
        payload: actionRoute,
        channel: _localChannelFor(type),
      );
    }
    return true;
  }

  /// Marks a single notification read (optimistic local update + repo write).
  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0 || _notifications[index].read) return;
    _notifications[index] = NotificationModel(
      id: _notifications[index].id,
      userId: _notifications[index].userId,
      type: _notifications[index].type,
      title: _notifications[index].title,
      body: _notifications[index].body,
      actionRoute: _notifications[index].actionRoute,
      relatedId: _notifications[index].relatedId,
      eventKey: _notifications[index].eventKey,
      read: true,
      readAt: DateTime.now(),
      createdAt: _notifications[index].createdAt,
    );
    notifyListeners();
    try {
      await _repository.markRead(notificationId);
    } catch (e) {
      debugPrint('[NotificationProvider] markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    final unread = _notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final now = DateTime.now();
    _notifications = [
      for (final n in _notifications)
        n.read ? n : NotificationModel(id: n.id, userId: n.userId, type: n.type, title: n.title, body: n.body, actionRoute: n.actionRoute, relatedId: n.relatedId, eventKey: n.eventKey, read: true, readAt: now, createdAt: n.createdAt),
    ];
    notifyListeners();
    try {
      await _repository.markAllRead(unread.map((n) => n.id).toList());
    } catch (e) {
      debugPrint('[NotificationProvider] markAllRead failed: $e');
    }
  }

  /// Emits a SMARTFARMING tip notification at most once per [_tipInterval].
  Future<void> _maybeGenerateTip(String userId) async {
    final last = LocalStorageService.getLastTipTime();
    final now = DateTime.now();
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) < _tipInterval) {
      return;
    }

    // Rotate through the tips deterministically by day.
    final tip = _tips[now.day % _tips.length];
    final eventKey = 'tip|$userId|${now.year}-${now.month}-${now.day}';
    try {
      final added = await addNotification(
        userId: userId,
        type: NotificationType.tip,
        title: 'SMARTFARMING Tip',
        body: tip,
        eventKey: eventKey,
      );
      if (added) {
        await LocalStorageService.saveLastTipTime(now.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('[NotificationProvider] tip failed: $e');
    }
  }

  static String _localChannelFor(NotificationType type) {
    switch (type) {
      case NotificationType.weatherAdvisory:
        return NotificationService.channelAlerts;
      case NotificationType.treatmentReminder:
      case NotificationType.fertilizerReminder:
        return NotificationService.channelReminders;
      default:
        return NotificationService.channelInformation;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
