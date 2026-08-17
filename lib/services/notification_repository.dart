import 'package:firebase_database/firebase_database.dart';
import '../models/notification_model.dart';

/// Persists farmer notifications in the Firebase Realtime Database under
/// `notifications/{autoId}`.
///
/// Every record belongs to exactly one farmer (`userId`). Admin broadcasts are
/// fanned out into one record per farmer (mirroring how admin-created
/// treatments are fanned out), so a farmer only ever queries their own node.
///
/// Requires the rules + indexes documented in FIREBASE_RULES.md:
///   "notifications": { ".indexOn": ["userId", "eventKey"] }
class NotificationRepository {
  final DatabaseReference _notifications =
      FirebaseDatabase.instance.ref().child('notifications');

  /// Streams the notification list for a farmer, newest first.
  Stream<List<NotificationModel>> streamForUser(String userId) {
    return _notifications
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <NotificationModel>[];
      }
      final Map<dynamic, dynamic> data =
          Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map((entry) => NotificationModel.fromMap(
                Map<dynamic, dynamic>.from(entry.value as Map),
                entry.key.toString(),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }).handleError((Object error) {
      throw Exception('Failed to load notifications: $error');
    });
  }

  /// True when a record with the given unique [eventKey] already exists.
  Future<bool> exists(String eventKey) async {
    if (eventKey.isEmpty) return false;
    final snapshot = await _notifications
        .orderByChild('eventKey')
        .equalTo(eventKey)
        .limitToFirst(1)
        .get();
    return snapshot.exists && snapshot.value != null;
  }

  /// Writes a new notification record. Returns the generated id, or null when
  /// a record with the same [NotificationModel.eventKey] already exists.
  Future<String?> add(NotificationModel model) async {
    final key = model.eventKey;
    if (key.isNotEmpty && await exists(key)) {
      return null;
    }
    final ref = _notifications.push();
    await ref.set(model.toMap());
    return ref.key;
  }

  Future<void> markRead(String notificationId) async {
    await _notifications.child(notificationId).update({
      'read': true,
      'readAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Marks a batch of ids as read in a single multi-path update.
  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{
      for (final id in ids) 'notifications/$id/read': true,
      for (final id in ids) 'notifications/$id/readAt': now,
    };
    await FirebaseDatabase.instance.ref().update(updates);
  }

  /// Admin: fans out a broadcast announcement to every registered farmer so it
  /// appears in each farmer's Notification Center.
  Future<int> broadcastToFarmers({
    required NotificationType type,
    required String title,
    required String body,
    String? actionRoute,
    String? relatedId,
    String? eventKey,
  }) async {
    final usersSnapshot = await FirebaseDatabase.instance.ref().child('users').get();
    if (!usersSnapshot.exists || usersSnapshot.value == null) return 0;

    final users = Map<dynamic, dynamic>.from(usersSnapshot.value as Map);
    final farmerIds = users.entries
        .where((e) =>
            e.value is Map &&
            (e.value as Map)['role'] != 'admin')
        .map((e) => e.key.toString())
        .toList();

    if (farmerIds.isEmpty) return 0;

    final now = DateTime.now();
    final baseKey = eventKey ?? 'admin|$relatedId|${now.millisecondsSinceEpoch}';
    var written = 0;
    for (final userId in farmerIds) {
      final model = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        body: body,
        actionRoute: actionRoute,
        relatedId: relatedId,
        eventKey: '$baseKey|$userId',
        createdAt: now,
      );
      await _notifications.push().set(model.toMap());
      written++;
    }
    return written;
  }
}
