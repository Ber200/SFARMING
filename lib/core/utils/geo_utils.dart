import 'package:geolocator/geolocator.dart';

enum GeoLocationStatus {
  enabled,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Utility for GPS location handling and Point-in-Polygon calculations.
class GeoUtils {
  /// The exact 10-point registered rice field polygon boundary coordinates.
  static const List<Map<String, double>> registeredFarmPolygon = [
    {'lat': 7.330700250052051, 'lng': 125.67823349471458},
    {'lat': 7.330719799619558, 'lng': 125.67866318753023},
    {'lat': 7.33072761944632, 'lng': 125.67911850422941},
    {'lat': 7.3304558803857995, 'lng': 125.6790830250061},
    {'lat': 7.330297528770478, 'lng': 125.67906528539444},
    {'lat': 7.329886987283392, 'lng': 125.67896673199634},
    {'lat': 7.329863527758415, 'lng': 125.67864544791858},
    {'lat': 7.329867437679334, 'lng': 125.67826306073401},
    {'lat': 7.330229105215577, 'lng': 125.67823349471458},
    {'lat': 7.330467610132843, 'lng': 125.67822758151068},
  ];

  static const double registeredFarmCenterLat = 7.330315123397189;
  static const double registeredFarmCenterLng = 125.67865727432635;

  /// Ray-casting Point-in-Polygon algorithm.
  /// Determines if a given [lat], [lng] position lies within the registered rice field boundary.
  static bool isPointInsideFarm(double lat, double lng, [List<Map<String, double>>? polygon]) {
    final poly = polygon ?? registeredFarmPolygon;
    if (poly.length < 3) return false;

    bool inside = false;
    int j = poly.length - 1;
    for (int i = 0; i < poly.length; i++) {
      final xi = poly[i]['lat']!;
      final yi = poly[i]['lng']!;
      final xj = poly[j]['lat']!;
      final yj = poly[j]['lng']!;

      final intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  /// Evaluates location status label based on coordinates.
  static String getLocationStatus(double? lat, double? lng, [List<Map<String, double>>? polygon]) {
    if (lat == null || lng == null) return 'Outside Registered Farm';
    final inside = isPointInsideFarm(lat, lng, polygon);
    return inside ? 'Inside Registered Farm' : 'Outside Registered Farm';
  }

  /// Checks the current location service and permission status.
  static Future<GeoLocationStatus> checkPermissionState() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return GeoLocationStatus.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return GeoLocationStatus.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return GeoLocationStatus.permissionDeniedForever;
    }
    return GeoLocationStatus.enabled;
  }

  /// Attempts to capture the device's current GPS position with high accuracy.
  /// Returns a tuple of (latitude, longitude), or null if unavailable.
  static Future<(double, double)?> getCurrentLocation() async {
    try {
      final state = await checkPermissionState();
      if (state != GeoLocationStatus.enabled) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return (last.latitude, last.longitude);
        return null;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null) {
        return (pos.latitude, pos.longitude);
      }
      return null;
    } catch (_) {
      return null;
    }
  }


  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
