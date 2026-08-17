import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';
import '../services/tflite_service.dart';
import '../services/local_storage_service.dart';
import '../models/detection_model.dart';
import '../core/utils/geo_utils.dart';
import '../analytics/scan_analytics.dart';

class DetectionProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TFLiteService _tfliteService = TFLiteService();

  List<DetectionModel> _detections = [];
  bool _isLoading = false;
  bool _isDetecting = false;
  bool _hasLoaded = false;
  DateTime? _lastUpdated;
  String? _errorMessage;

  List<DetectionModel> get detections => _detections;
  bool get isLoading => _isLoading;
  bool get isDetecting => _isDetecting;
  bool get hasLoaded => _hasLoaded;
  DateTime? get lastUpdated => _lastUpdated;
  String? get errorMessage => _errorMessage;
  int get totalDetections => _detections.length;

  /// Non-archived scans with a recognized disease category (excludes Invalid).
  List<DetectionModel> get validDetections => validScanRecords(_detections);
  int get totalValidDetections => validDetections.length;

  DetectionProvider() {
    _initializeTFLite();
  }

  Future<void> _initializeTFLite() async {
    try {
      if (!kIsWeb) {
        await _tfliteService.initialize();
        debugPrint('[DetectionProvider] TFLite model initialized successfully.');
      }
    } catch (e) {
      debugPrint('[DetectionProvider] ⚠️ TFLite initialization failed: $e');
      _errorMessage = 'Failed to initialize leaf disease detector: $e';
      notifyListeners();
    }
  }

  /// Load detections. When [isOnline] is false, loads from Hive only.
  Future<void> loadDetections(String userId, {bool isOnline = true}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (!isOnline || userId == 'offline_guest') {
        final localMaps = LocalStorageService.getDetections(userId);
        _detections = localMaps
            .map((m) => DetectionModel.fromMap(m, m['localId'] as String? ?? ''))
            .toList();
        _hasLoaded = true;
        _lastUpdated = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (userId.isEmpty) {
        _firebaseService.getAllDetections().listen((detections) {
          _detections = detections;
          _hasLoaded = true;
          _lastUpdated = DateTime.now();
          notifyListeners();
        });
      } else {
        _firebaseService.getDetectionsByUser(userId).listen((firebaseDetections) {
          final localUnsynced = LocalStorageService.getUnsyncedDetections(userId)
              .map((m) => DetectionModel.fromMap(m, m['localId'] as String? ?? ''))
              .toList();
          final allIds = firebaseDetections.map((d) => d.id).toSet();
          final onlyLocal = localUnsynced
              .where((d) => !allIds.contains(d.id))
              .toList();
          _detections = [...firebaseDetections, ...onlyLocal];
          _detections.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _hasLoaded = true;
          _lastUpdated = DateTime.now();
          notifyListeners();
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load detections: $e';
      notifyListeners();
    }
  }

  /// Detect disease from [imageFile] using the real trained TFLite model.
  Future<Map<String, dynamic>?> detectDisease(
      dynamic imageFile, String userId,
      {bool isOnline = true, double? latitude, double? longitude, String crop = 'Rice'}) async {
    if (_isDetecting) {
      debugPrint('[DetectionProvider] Submitting ignored: detectDisease already in progress.');
      return null;
    }

    try {
      _isDetecting = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('[DetectionProvider] Starting detectDisease for userId: $userId...');

      // 1. Capture real GPS location at scan time
      double? lat = latitude;
      double? lng = longitude;
      if (lat == null || lng == null) {
        final loc = await GeoUtils.getCurrentLocation();
        if (loc != null) {
          lat = loc.$1;
          lng = loc.$2;
        }
      }

      final bool isInside = (lat != null && lng != null)
          ? GeoUtils.isPointInsideFarm(lat, lng)
          : false;
      final String locStatus = (lat != null && lng != null)
          ? GeoUtils.getLocationStatus(lat, lng)
          : 'No Recorded Scan Location';
      debugPrint('[DetectionProvider] Scan GPS captured: lat=$lat, lng=$lng, insideFarm=$isInside');


      // 2. Run real TFLite model prediction
      final Map<String, dynamic> prediction;
      if (!kIsWeb) {
        prediction = await _tfliteService.predict(imageFile);
      } else {
        throw UnsupportedError(
          'TFLite inference is only supported on mobile devices (Android/iOS).',
        );
      }

      final disease = prediction['disease'] as String;
      final confidence = (prediction['confidence'] as num).toDouble();
      final isLowConfidence = prediction['isLowConfidence'] as bool? ?? false;
      final topPredictions =
          (prediction['topPredictions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      debugPrint('[DetectionProvider] Prediction success: Disease="$disease", Confidence=$confidence, isLowConfidence=$isLowConfidence');

      // 3. Online path: try uploading image to Cloudinary & save to Firebase safely
      String imageUrl = '';
      if (isOnline && userId != 'offline_guest') {
        try {
          imageUrl = await _cloudinaryService.uploadImage(imageFile, userId);
          debugPrint('[DetectionProvider] Cloudinary upload success: $imageUrl');
        } catch (e) {
          debugPrint('[DetectionProvider] ⚠️ Cloudinary upload failed (continuing with local record): $e');
        }

        final detection = DetectionModel(
          id: '',
          userId: userId,
          imageUrl: imageUrl,
          disease: disease,
          confidence: confidence,
          isLowConfidence: isLowConfidence,
          timestamp: DateTime.now(),
          synced: imageUrl.isNotEmpty,
          latitude: lat,
          longitude: lng,
          isInsideFarm: isInside,
          locationStatus: locStatus,
          crop: crop,
          status: 'Detected',
        );

        String docId = '';
        try {
          docId = await _firebaseService.saveDetection(detection);
          debugPrint('[DetectionProvider] Saved detection to Firebase with docId: $docId');
        } catch (e) {
          debugPrint('[DetectionProvider] ⚠️ Firebase save error: $e');
        }

        final result = {
          'id': docId.isNotEmpty ? docId : 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'farmerId': userId,
          'disease': disease,
          'confidence': confidence,
          'isLowConfidence': isLowConfidence,
          'topPredictions': topPredictions,
          'crop': crop,
          'status': 'Detected',
          'imageUrl': imageUrl,
          'latitude': lat,
          'longitude': lng,
          'isInsideFarm': isInside,
          'locationStatus': locStatus,
          'timestamp': DateTime.now().toIso8601String(),
        };

        return result;
      } else {
        // Offline path: save to Hive
        final localId = 'local_${DateTime.now().millisecondsSinceEpoch}_$userId';
        final localMap = {
          'localId': localId,
          'userId': userId,
          'farmerId': userId,
          'imageUrl': '',
          'disease': disease,
          'confidence': confidence,
          'isLowConfidence': isLowConfidence,
          'topPredictions': topPredictions,
          'crop': crop,
          'status': 'Detected',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'notes': null,
          'synced': false,
          'latitude': lat,
          'longitude': lng,
          'isInsideFarm': isInside,
          'locationStatus': locStatus,
        };
        await LocalStorageService.saveDetection(userId, localMap);

        _detections.insert(
          0,
          DetectionModel(
            id: localId,
            userId: userId,
            imageUrl: '',
            disease: disease,
            confidence: confidence,
            isLowConfidence: isLowConfidence,
            timestamp: DateTime.now(),
            synced: false,
            latitude: lat,
            longitude: lng,
            isInsideFarm: isInside,
            locationStatus: locStatus,
            crop: crop,
            status: 'Detected',
          ),
        );
        _hasLoaded = true;
        _lastUpdated = DateTime.now();

        return {
          'id': localId,
          'farmerId': userId,
          'disease': disease,
          'confidence': confidence,
          'isLowConfidence': isLowConfidence,
          'topPredictions': topPredictions,
          'crop': crop,
          'status': 'Detected',
          'imageUrl': '',
          'latitude': lat,
          'longitude': lng,
          'isInsideFarm': isInside,
          'locationStatus': locStatus,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e, stack) {
      debugPrint('[DetectionProvider] detectDisease Error: $e\n$stack');
      _errorMessage = 'Detection failed: ${e.toString()}';
      return null;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }

  Future<bool> archiveDetection(String detectionId) async {
    try {
      await _firebaseService.archiveDetection(detectionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unarchiveDetection(String detectionId) async {
    try {
      await _firebaseService.unarchiveDetection(detectionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDetection(String detectionId) async {
    try {
      await _firebaseService.deleteDetection(detectionId);
      _detections.removeWhere((d) => d.id == detectionId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  DetectionModel? getLatestDetection() {
    if (_detections.isEmpty) return null;
    return _detections.first;
  }

  Map<String, int> getDiseaseDistribution() {
    final distribution = <String, int>{};
    for (var detection in _detections) {
      distribution[detection.disease] =
          (distribution[detection.disease] ?? 0) + 1;
    }
    return distribution;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }
}
