/// The kind of notification a farmer can receive. Mirrors the categories the
/// spec requires in the Notification Center (Alerts, Reminders, Information).
enum NotificationType {
  /// Scheduled crop treatment reminder (1 day / 1 hour before).
  treatmentReminder,

  /// Scheduled fertilization reminder.
  fertilizerReminder,

  /// General farm activity or schedule update.
  farmActivity,

  /// Dangerous weather event (heavy rain, extreme heat, etc.).
  weatherAdvisory,

  /// Informational weather update.
  weatherUpdate,

  /// SMARTFARMING tip / best practice.
  tip,

  /// Broadcast announcement sent by an admin.
  adminAnnouncement;

  String get key => name;

  static NotificationType fromKey(String? key) {
    return NotificationType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => NotificationType.adminAnnouncement,
    );
  }
}

/// A single notification record persisted in the Realtime Database under
/// `notifications/{id}`. Owned by one farmer (`userId`); admin broadcasts are
/// fanned out into one record per farmer so every farmer only queries their
/// own records.
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? actionRoute;
  final String? relatedId;

  /// Globally unique key used to de-duplicate repeated writes for the same
  /// logical event (e.g. `weather|2026-08-14|heavy-rain`).
  final String eventKey;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.actionRoute,
    this.relatedId,
    required this.eventKey,
    this.read = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.fromKey(map['type']?.toString()),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      actionRoute: map['actionRoute']?.toString(),
      relatedId: map['relatedId']?.toString(),
      eventKey: map['eventKey'] ?? '',
      read: map['read'] as bool? ?? false,
      readAt: map['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'] as int)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.key,
      'title': title,
      'body': body,
      'actionRoute': actionRoute,
      'relatedId': relatedId,
      'eventKey': eventKey,
      'read': read,
      'readAt': readAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  NotificationModel copyWith({
    String? id,
    bool? read,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      actionRoute: actionRoute,
      relatedId: relatedId,
      eventKey: eventKey,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
