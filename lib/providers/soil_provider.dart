import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/local_storage_service.dart';
import '../models/soil_data_model.dart';

class SoilProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  SoilDataModel? _soilData;
  bool _isLoading = false;
  String? _errorMessage;

  SoilDataModel? get soilData => _soilData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load soil data. When [isOnline] is false, loads from Hive.
  Future<void> loadSoilData(String userId, {bool isOnline = true}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (!isOnline || userId == 'offline_guest') {
        final map = LocalStorageService.getSoilData(userId);
        if (map != null) {
          _soilData = SoilDataModel(
            userId: userId,
            ph: (map['ph'] as num?)?.toDouble(),
            moisture: (map['moisture'] as num?)?.toDouble(),
            humidity: (map['humidity'] as num?)?.toDouble(),
            status: map['status'] as String?,
            description: map['description'] as String?,
            timestamp: map['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
                : DateTime.now(),
          );
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      _firebaseService.getSoilDataStream(userId).listen((soilData) {
        _soilData = soilData;
        // Cache to Hive for offline access
        if (soilData != null) {
          LocalStorageService.saveSoilData(userId, {
            ...soilData.toMap(),
            'synced': true,
          });
        }
        _checkAlerts(userId);
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load soil data: $e';
      notifyListeners();
    }
  }

  /// Update soil data. When [isOnline] is false, saves to Hive with synced=false.
  Future<bool> updateSoilData({
    required String userId,
    double? ph,
    double? moisture,
    double? humidity,
    String? status,
    String? description,
    double? fertility,
    double? electricalConductivity,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? temperature,
    String? temperatureUnit,
    double? sunlight,
    String? source,
    bool? verifiedByFarmer,
    String? scanImage,
    bool isOnline = true,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final soilData = SoilDataModel(
        userId: userId,
        ph: ph,
        moisture: moisture,
        humidity: humidity,
        status: status,
        description: description,
        timestamp: DateTime.now(),
        fertility: fertility ?? electricalConductivity,
        electricalConductivity: electricalConductivity ?? fertility,
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        temperature: temperature,
        temperatureUnit: temperatureUnit,
        sunlight: sunlight,
        source: source,
        verifiedByFarmer: verifiedByFarmer,
        scanImage: scanImage,
      );

      if (isOnline && userId != 'offline_guest') {
        await _firebaseService.saveSoilData(soilData);
        await LocalStorageService.saveSoilData(userId, {
          ...soilData.toMap(),
          'synced': true,
        });
      } else {
        // Offline: save locally, queue for sync
        await LocalStorageService.saveSoilData(userId, {
          ...soilData.toMap(),
          'synced': false,
        });
      }

      _soilData = soilData;
      _checkAlerts(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update soil data: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSoilDataForUser({
    required String userId,
    double? ph,
    double? moisture,
    String? status,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.updateSoilDataForUser(
        userId: userId,
        ph: ph,
        moisture: moisture,
        status: status,
        description: description,
      );

      if (_soilData?.userId == userId) {
        await loadSoilData(userId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update soil data: $e';
      notifyListeners();
      return false;
    }
  }

  void _checkAlerts(String userId) {
    if (_soilData == null) return;

    if (_soilData!.ph != null) {
      if (_soilData!.ph! < 5.5 || _soilData!.ph! > 7.5) {
        _notificationService.showPHAlert(
          'Soil pH is ${_soilData!.phStatus} (${_soilData!.ph!.toStringAsFixed(1)}). '
          'Consider adjusting pH levels.',
        );
      }
    }

    if (_soilData!.moisture != null) {
      if (_soilData!.moisture! < 30) {
        _notificationService.showMoistureAlert(
          'Soil moisture is low (${_soilData!.moisture!.toStringAsFixed(1)}%). '
          'Consider irrigation.',
        );
      } else if (_soilData!.moisture! > 70) {
        _notificationService.showMoistureAlert(
          'Soil moisture is high (${_soilData!.moisture!.toStringAsFixed(1)}%). '
          'Monitor for waterlogging.',
        );
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
