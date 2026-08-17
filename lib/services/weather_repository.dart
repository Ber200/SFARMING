import 'package:hive_flutter/hive_flutter.dart';
import '../models/weather_model.dart';
import '../models/farm_location_model.dart';
import 'weather_service.dart';

/// Repository coordinating weather data access between API service and local Hive cache.
class WeatherRepository {
  final WeatherService _apiService = WeatherService();
  static const String _boxName = 'weather_cache';
  static const String _lastKey = 'last_weather_query';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Normalizes the location query string to avoid cache duplication.
  String _normalizeQuery(String query) {
    return query.trim().toLowerCase();
  }

  /// Fetches weather data.
  Future<(WeatherModel data, bool isCached)> getWeatherData({
    required String query,
    required String apiKey,
    bool forceRefresh = false,
    bool isOnline = true,
  }) async {
    final box = await _getBox();
    final normalizedQuery = _normalizeQuery(query);

    await box.put(_lastKey, query);
    final cachedMap = box.get(normalizedQuery);

    if (cachedMap != null) {
      try {
        final WeatherModel cachedData = WeatherModel.fromMap(Map<String, dynamic>.from(cachedMap));
        final age = DateTime.now().difference(cachedData.timestamp);

        if (age.inMinutes < 15 && !forceRefresh && isOnline) {
          return (cachedData, true);
        }

        if (!isOnline) {
          return (cachedData, true);
        }
      } catch (_) {}
    }

    if (!isOnline) {
      throw WeatherException(
        WeatherErrorType.noInternet,
        'Offline. No cached weather data is available.',
      );
    }

    try {
      final (response, isCached) = await _apiService.fetchFarmWeather(FarmLocationModel.defaultFarm);
      final freshData = WeatherModel.fromOpenMeteoResponse(response, FarmLocationModel.defaultFarm);
      await box.put(normalizedQuery, freshData.toMap());
      return (freshData, isCached);
    } catch (e) {
      if (cachedMap != null) {
        try {
          final WeatherModel cachedData = WeatherModel.fromMap(Map<String, dynamic>.from(cachedMap));
          return (cachedData, true);
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Retrieves the last queried location.
  Future<String?> getLastQuery() async {
    final box = await _getBox();
    return box.get(_lastKey) as String?;
  }
}
