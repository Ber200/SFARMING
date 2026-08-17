import '../core/utils/geo_utils.dart';

class DetectionModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String disease;
  final double confidence;
  /// True when the model's top-1 confidence fell below the reporting threshold.
  final bool isLowConfidence;
  final DateTime timestamp;
  final String? notes;
  final bool isArchived;
  /// True when this record has been saved to Firebase.
  /// False when created offline and pending sync.
  final bool synced;
  final double? latitude;
  final double? longitude;
  final bool isInsideFarm;
  final String locationStatus;
  final String crop;
  final String status;

  String get farmerId => userId;

  DetectionModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.disease,
    required this.confidence,
    this.isLowConfidence = false,
    required this.timestamp,
    this.notes,
    this.isArchived = false,
    this.synced = true,
    this.latitude,
    this.longitude,
    bool? isInsideFarm,
    String? locationStatus,
    this.crop = 'Rice',
    this.status = 'Detected',
  })  : isInsideFarm = isInsideFarm ??
            (latitude != null && longitude != null
                ? GeoUtils.isPointInsideFarm(latitude, longitude)
                : true),
        locationStatus = locationStatus ??
            (latitude != null && longitude != null
                ? GeoUtils.getLocationStatus(latitude, longitude)
                : 'Inside Registered Farm');

  static double? _parseCoordinate(dynamic val) {
    if (val == null) return null;
    if (val is num) {
      final d = val.toDouble();
      return (d.isFinite && d >= -180 && d <= 180) ? d : null;
    }
    if (val is String) {
      final parsed = double.tryParse(val.trim());
      if (parsed != null && parsed.isFinite && parsed >= -180 && parsed <= 180) {
        return parsed;
      }
    }
    return null;
  }

  factory DetectionModel.fromMap(Map<String, dynamic> map, String id) {
    double? lat = _parseCoordinate(map['latitude']) ??
        _parseCoordinate(map['lat']) ??
        _parseCoordinate(map['Latitude']) ??
        _parseCoordinate(map['Lat']);

    double? lng = _parseCoordinate(map['longitude']) ??
        _parseCoordinate(map['lng']) ??
        _parseCoordinate(map['long']) ??
        _parseCoordinate(map['lon']) ??
        _parseCoordinate(map['Longitude']) ??
        _parseCoordinate(map['Lng']);

    if (lat == null || lng == null) {
      final loc = map['location'] ??
          map['coordinates'] ??
          map['coords'] ??
          map['position'] ??
          map['farmLocation'];
      if (loc is Map) {
        lat ??= _parseCoordinate(loc['latitude']) ??
            _parseCoordinate(loc['lat']) ??
            _parseCoordinate(loc['Latitude']);
        lng ??= _parseCoordinate(loc['longitude']) ??
            _parseCoordinate(loc['lng']) ??
            _parseCoordinate(loc['Longitude']);
      } else if (loc is List && loc.length >= 2) {
        final c1 = _parseCoordinate(loc[0]);
        final c2 = _parseCoordinate(loc[1]);
        if (c1 != null && c2 != null) {
          if (c1.abs() <= 90 && (c2.abs() > 90 || c2.abs() <= 180)) {
            lat ??= c1;
            lng ??= c2;
          } else {
            lat ??= c2;
            lng ??= c1;
          }
        }
      }
    }

    final inside = map['isInsideFarm'] as bool? ??
        (lat != null && lng != null ? GeoUtils.isPointInsideFarm(lat, lng) : false);
    final locStatus = map['locationStatus'] as String? ??
        (lat != null && lng != null
            ? GeoUtils.getLocationStatus(lat, lng)
            : 'No Recorded Scan Location');

    return DetectionModel(
      id: id,
      userId: map['farmerId'] ?? map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      disease: map['disease'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      isLowConfidence: map['isLowConfidence'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      notes: map['notes'],
      isArchived: map['isArchived'] as bool? ?? false,
      synced: map['synced'] as bool? ?? true,
      latitude: lat,
      longitude: lng,
      isInsideFarm: inside,
      locationStatus: locStatus,
      crop: map['crop'] as String? ?? 'Rice',
      status: map['status'] as String? ?? 'Detected',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'farmerId': userId,
      'userId': userId,
      'imageUrl': imageUrl,
      'disease': disease,
      'confidence': confidence,
      'isLowConfidence': isLowConfidence,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
      'isArchived': isArchived,
      'synced': synced,
      'latitude': latitude,
      'longitude': longitude,
      'isInsideFarm': isInsideFarm,
      'locationStatus': locationStatus,
      'crop': crop,
      'status': status,
    };
  }

  DetectionModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? disease,
    double? confidence,
    bool? isLowConfidence,
    DateTime? timestamp,
    String? notes,
    bool? isArchived,
    bool? synced,
    double? latitude,
    double? longitude,
    bool? isInsideFarm,
    String? locationStatus,
    String? crop,
    String? status,
  }) {
    return DetectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      disease: disease ?? this.disease,
      confidence: confidence ?? this.confidence,
      isLowConfidence: isLowConfidence ?? this.isLowConfidence,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      synced: synced ?? this.synced,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isInsideFarm: isInsideFarm ?? this.isInsideFarm,
      locationStatus: locationStatus ?? this.locationStatus,
      crop: crop ?? this.crop,
      status: status ?? this.status,
    );
  }
}
