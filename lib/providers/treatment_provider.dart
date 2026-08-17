import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/local_storage_service.dart';
import '../models/treatment_model.dart';
import '../models/notification_model.dart';
import '../core/utils/geo_utils.dart';
import '../core/routes/app_routes.dart';
import 'settings_provider.dart';
import 'notification_provider.dart';

class TreatmentProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  List<TreatmentModel> _treatments = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _treatmentsSubscription;
  final Set<String> _inFlightCreateKeys = <String>{};
  SettingsProvider? _settings;
  NotificationProvider? _notifications;

  List<TreatmentModel> get treatments => List.unmodifiable(_treatments);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TreatmentModel> get pendingTreatments =>
      _treatments.where((t) => (t.isPending || t.isApproved) && !t.archived).toList();


  List<TreatmentModel> get approvedTreatments =>
      _treatments.where((t) => t.isApproved && !t.archived).toList();

  List<TreatmentModel> get completedTreatments =>
      _treatments.where((t) => t.isCompleted && !t.archived).toList();

  List<TreatmentModel> get upcomingTreatments {
    final now = DateTime.now();
    return _treatments
        .where((t) =>
            (t.isPending || t.isApproved) &&
            !t.archived &&
            t.scheduleDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
  }

  List<TreatmentModel> get archivedTreatments =>
      _treatments.where((t) => t.archived).toList();

  /// Gives this provider access to the persisted settings so scheduling
  /// respects the "Treatment Reminders" toggle in real time.
  void attachSettings(SettingsProvider settings) {
    _settings = settings;
  }

  /// Gives this provider access to the Notification Center so reminders are
  /// also persisted (deduplicated by eventKey) alongside the local push.
  void attachNotifications(NotificationProvider notifications) {
    _notifications = notifications;
  }

  /// Applies the reminders preference live: re-schedules every reminder when
  /// enabled, or cancels every scheduled reminder when disabled.
  Future<void> applyReminderSetting(bool enabled) async {
    for (final t in _treatments.toList()) {
      if (enabled) {
        _scheduleTreatmentReminders(t);
      } else {
        await _cancelTreatmentNotifications(t.id);
      }
    }
  }

  /// Load treatments. When [isOnline] is false, loads from Hive only.
  Future<void> loadTreatments(String userId, {bool isOnline = true}) async {
    await _treatmentsSubscription?.cancel();

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (!isOnline || userId == 'offline_guest') {
        final localMaps = LocalStorageService.getTreatments(userId);
        _treatments = localMaps
            .map((m) => TreatmentModel.fromMap(m, m['localId'] as String? ?? ''))
            .toList();
        _treatments.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
        _scheduleNotificationsForUpcomingTreatments();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final stream = userId.isEmpty
          ? _firebaseService.getAllTreatments()
          : _firebaseService.getTreatmentsByUser(userId);

      _treatmentsSubscription = stream.listen(
        (firebaseTreatments) {
          // Merge with local unsynced records (admin uses userId='' so onlyLocal is empty)
          final localUnsynced = userId.isEmpty
              ? <TreatmentModel>[]
              : LocalStorageService.getUnsyncedTreatments(userId)
                  .map((m) =>
                      TreatmentModel.fromMap(m, m['localId'] as String? ?? ''))
                  .toList();
          final allIds = firebaseTreatments.map((t) => t.id).toSet();
          final onlyLocal =
              localUnsynced.where((t) => !allIds.contains(t.id)).toList();
          _treatments = [...firebaseTreatments, ...onlyLocal];
          _treatments.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
          _scheduleNotificationsForUpcomingTreatments();
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to load treatments: $e';
          _isLoading = false;
          notifyListeners();
        },
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (_isLoading && _treatments.isEmpty) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load treatments: $e';
      notifyListeners();
    }
  }

  /// Add a treatment. When [isOnline] is false, saves to Hive with synced=false.
  Future<bool> addTreatment({
    required String userId,
    required String disease,
    String? remedy,
    required DateTime scheduleDate,
    required String type,
    String? notes,
    bool isOnline = true,
  }) async {
    if (userId.isEmpty) return false;

    try {
      final requestKey = '$userId|$type|$disease|${scheduleDate.millisecondsSinceEpoch}';
      if (_inFlightCreateKeys.contains(requestKey)) {
        _errorMessage = 'Schedule request already in progress.';
        notifyListeners();
        return false;
      }
      _inFlightCreateKeys.add(requestKey);

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final now = DateTime.now();

      final hasLocalDuplicate = _treatments.any((t) =>
          t.userId == userId &&
          t.type == type &&
          t.disease == disease &&
          t.scheduleDate.millisecondsSinceEpoch ==
              scheduleDate.millisecondsSinceEpoch &&
          !t.archived &&
          !t.isCancelled);
      if (hasLocalDuplicate) {
        _isLoading = false;
        _errorMessage = 'This schedule already exists.';
        notifyListeners();
        return false;
      }

      if (isOnline && userId != 'offline_guest') {
        final hasServerDuplicate = await _firebaseService.hasDuplicateTreatment(
          userId: userId,
          type: type,
          disease: disease,
          scheduleDate: scheduleDate,
        );
        if (hasServerDuplicate) {
          _isLoading = false;
          _errorMessage = 'Duplicate schedule detected. Please refresh.';
          notifyListeners();
          return false;
        }

        // Online path: save to Firebase
        final treatment = TreatmentModel(
          id: '',
          userId: userId,
          disease: disease,
          remedy: remedy,
          scheduleDate: scheduleDate,
          status: 'pending',
          notes: notes,
          type: type,
          createdAt: now,
          synced: true,
        );

        final treatmentId = await _firebaseService.saveTreatment(treatment);

        final newTreatment = treatment.copyWith(id: treatmentId);
        _treatments = [..._treatments, newTreatment];
        _treatments.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));

        _scheduleTreatmentReminders(newTreatment);
      } else {
        // Offline path: save to Hive
        final localId = 'local_${now.millisecondsSinceEpoch}_$userId';
        final localMap = {
          'localId': localId,
          'userId': userId,
          'disease': disease,
          'remedy': remedy,
          'scheduleDate': scheduleDate.millisecondsSinceEpoch,
          'status': 'pending',
          'notes': notes,
          'type': type,
          'createdAt': now.millisecondsSinceEpoch,
          'synced': false,
        };
        await LocalStorageService.saveTreatment(userId, localMap);

        final newTreatment = TreatmentModel(
          id: localId,
          userId: userId,
          disease: disease,
          remedy: remedy,
          scheduleDate: scheduleDate,
          status: 'pending',
          notes: notes,
          type: type,
          createdAt: now,
          synced: false,
        );
        _treatments = [..._treatments, newTreatment];
        _treatments.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));

        _scheduleTreatmentReminders(newTreatment);
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add treatment: $e';
      notifyListeners();
      return false;
    } finally {
      final requestKey = '$userId|$type|$disease|${scheduleDate.millisecondsSinceEpoch}';
      _inFlightCreateKeys.remove(requestKey);
    }
  }

  int _dayBeforeId(String id) => (id.hashCode & 0x0FFFFFFF) * 2;
  int _hourBeforeId(String id) => (id.hashCode & 0x0FFFFFFF) * 2 + 1;

  /// Schedules the two treatment reminders: 1 day before and 1 hour before.
  /// Re-scheduling with the same treatment id replaces any prior reminders.
  /// Skipped entirely when the user has disabled treatment reminders.
  void _scheduleTreatmentReminders(TreatmentModel t) {
    if (!(_settings?.treatmentRemindersEnabled ?? true)) return;

    final title =
        t.type == 'fertilization' ? 'Fertilization Reminder' : 'Treatment Reminder';
    final crop = t.cropName;
    final now = DateTime.now();
    final type = t.type == 'fertilization'
        ? NotificationType.fertilizerReminder
        : NotificationType.treatmentReminder;

    final oneDayBefore = t.scheduleDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      _notificationService.scheduleTreatmentReminder(
        id: _dayBeforeId(t.id),
        title: '$title (Tomorrow)',
        body: 'Reminder: Your scheduled ${t.type} for $crop (${t.disease}) is tomorrow at ${DateFormat('HH:mm').format(t.scheduleDate)}.',
        scheduledDate: oneDayBefore,
        relatedId: t.id,
      );
      _notifications?.addNotification(
        userId: t.userId,
        type: type,
        title: '$title (Tomorrow)',
        body: 'Your scheduled ${t.type} for $crop (${t.disease}) is tomorrow at ${DateFormat('HH:mm').format(t.scheduleDate)}.',
        actionRoute: AppRoutes.treatmentCalendar,
        relatedId: t.id,
        eventKey: '${type.key}|${t.userId}|${t.id}|day-before',
      );
    }

    final oneHourBefore = t.scheduleDate.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      _notificationService.scheduleTreatmentReminder(
        id: _hourBeforeId(t.id),
        title: '$title (1 Hour)',
        body: 'Reminder: Your ${t.type} for $crop (${t.disease}) starts in 1 hour at ${DateFormat('HH:mm').format(t.scheduleDate)}.',
        scheduledDate: oneHourBefore,
        relatedId: t.id,
      );
      _notifications?.addNotification(
        userId: t.userId,
        type: type,
        title: '$title (1 Hour)',
        body: 'Your ${t.type} for $crop (${t.disease}) starts in 1 hour at ${DateFormat('HH:mm').format(t.scheduleDate)}.',
        actionRoute: AppRoutes.treatmentCalendar,
        relatedId: t.id,
        eventKey: '${type.key}|${t.userId}|${t.id}|hour-before',
      );
    }
  }

  Future<void> _cancelTreatmentNotifications(String id) async {
    // Cancel both reminder slots plus the legacy single-reminder id
    // (so reminders scheduled before this scheme change are cleared too).
    await _notificationService.cancelNotification(_dayBeforeId(id));
    await _notificationService.cancelNotification(_hourBeforeId(id));
    await _notificationService.cancelNotification(id.hashCode);
  }

  Future<bool> markAsCompleted(String treatmentId,
      {bool isOnline = true}) async {
    try {
      final index = _treatments.indexWhere((t) => t.id == treatmentId);
      if (index < 0) return false;
      final t = _treatments[index];

      if (isOnline && t.synced) {
        await _firebaseService.updateTreatmentStatus(treatmentId, 'completed');
      } else {
        await LocalStorageService.updateTreatmentStatus(
            t.userId, treatmentId, 'completed');
      }

      await _cancelTreatmentNotifications(treatmentId);

      _treatments = [..._treatments]..[index] = t.copyWith(status: 'completed');
      notifyListeners();
      _notifications?.addNotification(
        userId: t.userId,
        type: NotificationType.farmActivity,
        title: 'Farm Activity Completed',
        body: 'Your ${t.type} for ${t.cropName} (${t.disease}) has been marked as completed.',
        actionRoute: AppRoutes.treatmentCalendar,
        relatedId: t.id,
        eventKey: 'completed|${t.userId}|${t.id}',
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update treatment: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark treatment as completed with mandatory photo proof (real-time camera only).
  /// Records the GPS location so the completed task shows on the admin field map.
  Future<bool> markAsCompletedWithPhoto(
    String treatmentId,
    Uint8List photoBytes, {
    bool isOnline = true,
  }) async {
    try {
      final index = _treatments.indexWhere((t) => t.id == treatmentId);
      if (index < 0) return false;
      final t = _treatments[index];

      double? lat;
      double? lng;
      final loc = await GeoUtils.getCurrentLocation();
      if (loc != null) {
        lat = loc.$1;
        lng = loc.$2;
      }
      final completedAt = DateTime.now();


      String? photoUrl;
      if (isOnline && t.synced) {
        photoUrl =
            await _firebaseService.uploadPhotoProof(treatmentId, photoBytes);
        await _firebaseService.updateTreatment(
          treatmentId: treatmentId,
          status: 'completed',
          photoProofUrl: photoUrl,
          latitude: lat,
          longitude: lng,
          completedAt: completedAt.millisecondsSinceEpoch,
        );
      } else {
        await LocalStorageService.updateTreatmentStatus(
            t.userId, treatmentId, 'completed');
      }

      await _cancelTreatmentNotifications(treatmentId);

      _treatments = [..._treatments]
        ..[index] = t.copyWith(
          status: 'completed',
          photoProofUrl: photoUrl,
          latitude: lat,
          longitude: lng,
          completedAt: completedAt,
        );
      notifyListeners();
      _notifications?.addNotification(
        userId: t.userId,
        type: NotificationType.farmActivity,
        title: 'Farm Activity Completed',
        body: 'Your ${t.type} for ${t.cropName} (${t.disease}) has been marked as completed with photo proof.',
        actionRoute: AppRoutes.treatmentCalendar,
        relatedId: t.id,
        eventKey: 'completed|${t.userId}|${t.id}',
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete treatment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveTreatment(String treatmentId) async {
    try {
      final index = _treatments.indexWhere((t) => t.id == treatmentId);
      if (index < 0) return false;
      final t = _treatments[index];

      if (t.synced) {
        await _firebaseService.archiveTreatment(treatmentId);
      }

      _treatments = [..._treatments]..[index] = t.copyWith(archived: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to archive treatment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unarchiveTreatment(String treatmentId) async {
    try {
      final index = _treatments.indexWhere((t) => t.id == treatmentId);
      if (index < 0) return false;
      final t = _treatments[index];

      if (t.synced) {
        await _firebaseService.unarchiveTreatment(treatmentId);
      }

      _treatments = [..._treatments]..[index] = t.copyWith(archived: false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to restore treatment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveTreatment(String treatmentId) async {
    try {
      await _firebaseService.updateTreatmentStatus(treatmentId, 'approved');
      final index = _treatments.indexWhere((t) => t.id == treatmentId);
      if (index >= 0) {
        _treatments = [..._treatments]
          ..[index] = _treatments[index].copyWith(status: 'approved');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve treatment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> disapproveTreatment(String treatmentId) async {
    try {
      await _firebaseService.updateTreatmentStatus(treatmentId, 'cancelled');
      final index = _treatments.indexWhere((t) => t.id == treatmentId);
      if (index >= 0) {
        _treatments = [..._treatments]
          ..[index] = _treatments[index].copyWith(status: 'cancelled');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to disapprove treatment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeTreatment(String treatmentId,
      {bool isOnline = true}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final t = _treatments.firstWhere((t) => t.id == treatmentId,
          orElse: () => throw Exception('Treatment not found'));

      if (isOnline && t.synced) {
        await _firebaseService.deleteTreatment(treatmentId);
      } else {
        await LocalStorageService.deleteTreatment(t.userId, treatmentId);
      }

      await _cancelTreatmentNotifications(treatmentId);
      _treatments = _treatments.where((t) => t.id != treatmentId).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to remove treatment: $e';
      notifyListeners();
      return false;
    }
  }

  List<TreatmentModel> getTreatmentsForDate(DateTime date) {
    return _treatments.where((treatment) {
      if (treatment.archived) return false;
      final treatmentDate = DateTime(
        treatment.scheduleDate.year,
        treatment.scheduleDate.month,
        treatment.scheduleDate.day,
      );
      final checkDate = DateTime(date.year, date.month, date.day);
      return treatmentDate.isAtSameMomentAs(checkDate);
    }).toList();
  }

  void _scheduleNotificationsForUpcomingTreatments() {
    for (final t in upcomingTreatments) {
      _scheduleTreatmentReminders(t);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _treatmentsSubscription?.cancel();
    super.dispose();
  }
}
