import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../models/detection_model.dart';
import '../models/treatment_model.dart';
import '../models/soil_data_model.dart';

/// Reads all pending (unsynced) local records from Hive and pushes them
/// to Firebase when the device comes back online.
///
/// Called by [ConnectivityProvider.onReconnected] and also after a
/// successful online login to catch up any records created while offline.
class SyncService {
  final FirebaseService _firebaseService = FirebaseService();

  /// Sync all pending detections, treatments, and soil data for [userId].
  Future<void> syncAll(String userId) async {
    if (userId.isEmpty) return;
    await _syncDetections(userId);
    await _syncTreatments(userId);
    await _syncSoilData(userId);
  }

  // ── Detections ──────────────────────────────────────────────────────────────

  Future<void> _syncDetections(String userId) async {
    final pending = LocalStorageService.getUnsyncedDetections(userId);
    for (final map in pending) {
      try {
        final localId = map['localId'] as String? ?? '';
        final detection = DetectionModel(
          id: '',
          userId: map['userId'] as String? ?? userId,
          imageUrl: map['imageUrl'] as String? ?? '',
          disease: map['disease'] as String? ?? '',
          confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
          timestamp: map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : DateTime.now(),
          notes: map['notes'] as String?,
          synced: false,
        );
        await _firebaseService.saveDetection(detection);
        await LocalStorageService.markDetectionSynced(userId, localId);
      } catch (_) {
        // Leave unsynced; will retry next reconnect
      }
    }
  }

  // ── Treatments ──────────────────────────────────────────────────────────────

  Future<void> _syncTreatments(String userId) async {
    final pending = LocalStorageService.getUnsyncedTreatments(userId);
    for (final map in pending) {
      try {
        final localId = map['localId'] as String? ?? '';
        final treatment = TreatmentModel(
          id: '',
          userId: map['userId'] as String? ?? userId,
          disease: map['disease'] as String? ?? '',
          remedy: map['remedy'] as String?,
          scheduleDate: map['scheduleDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['scheduleDate'] as int)
              : DateTime.now(),
          status: map['status'] as String? ?? 'pending',
          notes: map['notes'] as String?,
          type: map['type'] as String? ?? 'treatment',
          createdAt: map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : DateTime.now(),
          synced: false,
        );
        await _firebaseService.saveTreatment(treatment);
        await LocalStorageService.markTreatmentSynced(userId, localId);
      } catch (_) {
        // Leave unsynced; will retry next reconnect
      }
    }
  }

  // ── Soil Data ───────────────────────────────────────────────────────────────

  Future<void> _syncSoilData(String userId) async {
    final map = LocalStorageService.getSoilData(userId);
    if (map == null) return;
    // Only sync if flagged as unsynced
    if (map['synced'] == false) {
      try {
        final soilData = SoilDataModel(
          userId: userId,
          ph: (map['ph'] as num?)?.toDouble(),
          moisture: (map['moisture'] as num?)?.toDouble(),
          status: map['status'] as String?,
          description: map['description'] as String?,
          timestamp: map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : DateTime.now(),
        );
        await _firebaseService.saveSoilData(soilData);
        // Mark synced in Hive
        await LocalStorageService.saveSoilData(
            userId, {...map, 'synced': true});
      } catch (_) {
        // Leave unsynced; will retry next reconnect
      }
    }
  }
}
