import 'package:hive_flutter/hive_flutter.dart';
import '../models/ai_message_model.dart';

/// Thin wrapper around all Hive boxes used for offline storage.
///
/// Box layout:
///   offline_user  – Map  keyed by 'user'
///   detections    – Map  keyed by userId → List<Map>
///   treatments    – Map  keyed by userId → List<Map>
///   soil_data     – Map  keyed by userId → Map
///   chat_history  – Map  keyed by userId → List<Map> (AI assistant messages)
///   pending_sync  – List of Map (each entry has 'type', 'userId', 'data')
class LocalStorageService {
  static const _boxUser = 'offline_user';
  static const _boxDetections = 'detections';
  static const _boxTreatments = 'treatments';
  static const _boxSoil = 'soil_data';
  static const _boxChatHistory = 'chat_history';
  static const _boxPendingSync = 'pending_sync';
  static const _boxNotificationMeta = 'notification_meta';

  static Future<void> init() async {
    await Hive.openBox(_boxUser);
    await Hive.openBox(_boxDetections);
    await Hive.openBox(_boxTreatments);
    await Hive.openBox(_boxSoil);
    await Hive.openBox(_boxChatHistory);
    await Hive.openBox(_boxPendingSync);
    await Hive.openBox(_boxNotificationMeta);
  }

  // ── Offline User ────────────────────────────────────────────────────────────

  static Future<void> saveOfflineUser(Map<String, dynamic> userMap) async {
    final box = Hive.box(_boxUser);
    await box.put('user', userMap);
  }

  static Map<String, dynamic>? getOfflineUser() {
    final box = Hive.box(_boxUser);
    final raw = box.get('user');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<void> clearOfflineUser() async {
    final box = Hive.box(_boxUser);
    await box.delete('user');
  }

  // ── Admin Map Boundary ───────────────────────────────────────────────────────
  static Future<void> saveAdminMapBoundary(List<Map<String, double>> points) async {
    final box = Hive.box(_boxUser);
    await box.put('map_boundary', points);
  }

  static List<Map<String, double>>? getAdminMapBoundary() {
    final box = Hive.box(_boxUser);
    final raw = box.get('map_boundary');
    if (raw == null) return null;
    return (raw as List).map((e) {
      final m = Map<dynamic, dynamic>.from(e as Map);
      return {
        'lat': (m['lat'] as num).toDouble(),
        'lng': (m['lng'] as num).toDouble(),
      };
    }).toList();
  }

  // ── Detections ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getDetections(String userId) {
    final box = Hive.box(_boxDetections);
    final raw = box.get(userId);
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveDetection(
      String userId, Map<String, dynamic> detectionMap) async {
    final box = Hive.box(_boxDetections);
    final existing = getDetections(userId);
    existing.insert(0, detectionMap); // newest first
    await box.put(userId, existing);
  }

  static Future<void> markDetectionSynced(
      String userId, String localId) async {
    final box = Hive.box(_boxDetections);
    final list = getDetections(userId);
    final idx = list.indexWhere((d) => d['localId'] == localId);
    if (idx >= 0) {
      list[idx] = {...list[idx], 'synced': true};
      await box.put(userId, list);
    }
  }

  static List<Map<String, dynamic>> getUnsyncedDetections(String userId) {
    return getDetections(userId)
        .where((d) => d['synced'] == false)
        .toList();
  }

  // ── Treatments ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getTreatments(String userId) {
    final box = Hive.box(_boxTreatments);
    final raw = box.get(userId);
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveTreatment(
      String userId, Map<String, dynamic> treatmentMap) async {
    final box = Hive.box(_boxTreatments);
    final existing = getTreatments(userId);
    existing.add(treatmentMap);
    await box.put(userId, existing);
  }

  static Future<void> updateTreatmentStatus(
      String userId, String localId, String status) async {
    final box = Hive.box(_boxTreatments);
    final list = getTreatments(userId);
    final idx = list.indexWhere((t) => t['localId'] == localId);
    if (idx >= 0) {
      list[idx] = {...list[idx], 'status': status, 'synced': false};
      await box.put(userId, list);
    }
  }

  static Future<void> deleteTreatment(String userId, String localId) async {
    final box = Hive.box(_boxTreatments);
    final list = getTreatments(userId)
        .where((t) => t['localId'] != localId)
        .toList();
    await box.put(userId, list);
  }

  static Future<void> markTreatmentSynced(
      String userId, String localId) async {
    final box = Hive.box(_boxTreatments);
    final list = getTreatments(userId);
    final idx = list.indexWhere((t) => t['localId'] == localId);
    if (idx >= 0) {
      list[idx] = {...list[idx], 'synced': true};
      await box.put(userId, list);
    }
  }

  static List<Map<String, dynamic>> getUnsyncedTreatments(String userId) {
    return getTreatments(userId)
        .where((t) => t['synced'] == false)
        .toList();
  }

  // ── Soil Data ───────────────────────────────────────────────────────────────

  static Map<String, dynamic>? getSoilData(String userId) {
    final box = Hive.box(_boxSoil);
    final raw = box.get(userId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<void> saveSoilData(
      String userId, Map<String, dynamic> soilMap) async {
    final box = Hive.box(_boxSoil);
    await box.put(userId, soilMap);
  }

  // ── Chat History (AI assistant) ───────────────────────────────────────────

  static List<AiMessage> getChatMessages(String userId) {
    final box = Hive.box(_boxChatHistory);
    final raw = box.get(userId);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => AiMessage.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveChatMessages(
      String userId, List<AiMessage> messages) async {
    final box = Hive.box(_boxChatHistory);
    await box.put(userId, messages.map((m) => m.toMap()).toList());
  }

  static Future<void> clearChatMessages(String userId) async {
    final box = Hive.box(_boxChatHistory);
    await box.delete(userId);
  }

  // ── Notification Meta (tip throttling) ───────────────────────────────────────

  static Future<void> saveLastTipTime(int millisecondsSinceEpoch) async {
    final box = Hive.box(_boxNotificationMeta);
    await box.put('last_tip_time', millisecondsSinceEpoch);
  }

  static int? getLastTipTime() {
    final box = Hive.box(_boxNotificationMeta);
    return box.get('last_tip_time') as int?;
  }

  // ── Pending Sync Queue ──────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getPendingSyncQueue() {
    final box = Hive.box(_boxPendingSync);
    final raw = box.get('queue');
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> addToPendingSync(Map<String, dynamic> entry) async {
    final box = Hive.box(_boxPendingSync);
    final queue = getPendingSyncQueue();
    queue.add(entry);
    await box.put('queue', queue);
  }

  static Future<void> removeFromPendingSync(int index) async {
    final box = Hive.box(_boxPendingSync);
    final queue = getPendingSyncQueue();
    if (index >= 0 && index < queue.length) {
      queue.removeAt(index);
      await box.put('queue', queue);
    }
  }

  static Future<void> clearPendingSyncQueue() async {
    final box = Hive.box(_boxPendingSync);
    await box.put('queue', <Map<String, dynamic>>[]);
  }

  // ── Weather AI Analysis ───────────────────────────────────────────────────

  static Future<void> saveWeatherAiAnalysis(Map<String, dynamic> analysisMap) async {
    final box = Hive.box(_boxUser);
    await box.put('weather_ai_analysis', analysisMap);
  }

  static Map<String, dynamic>? getWeatherAiAnalysis() {
    final box = Hive.box(_boxUser);
    final raw = box.get('weather_ai_analysis');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // ── Cache Clear ─────────────────────────────────────────────────────────────

  /// Clears all cached farmer data (detections, treatments, soil, chat history
  /// and the pending-sync queue). Keeps the offline login session and the admin
  /// map boundary intact.
  static Future<void> clearAllData() async {
    await Hive.box(_boxDetections).clear();
    await Hive.box(_boxTreatments).clear();
    await Hive.box(_boxSoil).clear();
    await Hive.box(_boxChatHistory).clear();
    await Hive.box(_boxPendingSync).clear();
  }
}

