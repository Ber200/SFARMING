import '../config/weather_config.dart';

class FarmLocationModel {
  final String farmName;
  final String barangay;
  final String municipality;
  final String province;
  final double? latitude;
  final double? longitude;

  const FarmLocationModel({
    required this.farmName,
    required this.barangay,
    required this.municipality,
    required this.province,
    this.latitude,
    this.longitude,
  });

  /// Default registered rice farm location instance
  static const FarmLocationModel defaultFarm = FarmLocationModel(
    farmName: WeatherConfig.defaultFarmName,
    barangay: WeatherConfig.defaultBarangay,
    municipality: WeatherConfig.defaultCity,
    province: WeatherConfig.defaultProvince,
    latitude: WeatherConfig.defaultFarmLat,
    longitude: WeatherConfig.defaultFarmLng,
  );

  bool get hasLocation => latitude != null && longitude != null;

  String get fullAddress {
    final parts = <String>[];
    if (barangay.isNotEmpty) parts.add('Brgy. $barangay');
    if (municipality.isNotEmpty) parts.add(municipality);
    if (province.isNotEmpty) parts.add(province);
    return parts.join(', ');
  }

  factory FarmLocationModel.fromMap(Map<String, dynamic> map) {
    return FarmLocationModel(
      farmName: map['farmName'] ?? map['name'] ?? WeatherConfig.defaultFarmName,
      barangay: map['barangay'] ?? WeatherConfig.defaultBarangay,
      municipality: map['municipality'] ?? map['city'] ?? WeatherConfig.defaultCity,
      province: map['province'] ?? WeatherConfig.defaultProvince,
      latitude: (map['latitude'] as num?)?.toDouble() ?? WeatherConfig.defaultFarmLat,
      longitude: (map['longitude'] as num?)?.toDouble() ?? WeatherConfig.defaultFarmLng,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmName': farmName,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  FarmLocationModel copyWith({
    String? farmName,
    String? barangay,
    String? municipality,
    String? province,
    double? latitude,
    double? longitude,
  }) {
    return FarmLocationModel(
      farmName: farmName ?? this.farmName,
      barangay: barangay ?? this.barangay,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
