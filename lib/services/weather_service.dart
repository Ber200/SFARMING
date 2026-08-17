import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/weather_config.dart';
import '../models/farm_location_model.dart';
import '../models/weather_response_model.dart';

enum WeatherErrorType {
  noInternet,
  timeout,
  missingFarmLocation,
  serverError,
  unknown,
}

class WeatherException implements Exception {
  final WeatherErrorType type;
  final String message;

  WeatherException(this.type, this.message);

  @override
  String toString() => message;
}

class WeatherService {
  /// Fetches real-time and daily forecast weather from Open-Meteo API for given [latitude] & [longitude].
  Future<(WeatherResponse, bool isCached)> fetchOpenMeteoWeather(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      '${WeatherConfig.openMeteoBaseUrl}?'
      'latitude=$latitude&longitude=$longitude&'
      'current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&'
      'daily=weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_sum,precipitation_probability_max,'
      'relative_humidity_2m_mean,wind_speed_10m_max,et0_fao_evapotranspiration&'
      'forecast_days=7&'
      'timezone=auto',
    );

    try {
      final response = await http.get(url).timeout(WeatherConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        final weather = WeatherResponse.fromOpenMeteoJson(jsonBody);

        // Cache successful response locally
        await _saveWeatherCache(weather);
        return (weather, false);
      } else {
        final cached = await getCachedWeatherResponse();
        if (cached != null) return (cached, true);
        throw WeatherException(
          WeatherErrorType.serverError,
          'Open-Meteo service temporarily unavailable (HTTP ${response.statusCode}).',
        );
      }
    } on TimeoutException {
      final cached = await getCachedWeatherResponse();
      if (cached != null) return (cached, true);
      throw WeatherException(
        WeatherErrorType.timeout,
        'Connection timed out. Showing latest available weather.',
      );
    } on SocketException {
      final cached = await getCachedWeatherResponse();
      if (cached != null) return (cached, true);
      throw WeatherException(
        WeatherErrorType.noInternet,
        'Unable to connect to Open-Meteo weather service.',
      );
    } catch (e) {
      final cached = await getCachedWeatherResponse();
      if (cached != null) return (cached, true);
      throw WeatherException(
        WeatherErrorType.unknown,
        'Weather service unavailable: ${e.toString()}',
      );
    }
  }

  /// Compatibility wrapper method for registered [farm]
  Future<(WeatherResponse, bool isCached)> fetchFarmWeather(FarmLocationModel farm) async {
    final lat = farm.latitude ?? WeatherConfig.defaultFarmLat;
    final lon = farm.longitude ?? WeatherConfig.defaultFarmLng;
    return await fetchOpenMeteoWeather(lat, lon);
  }

  /// Compatibility wrapper method for raw coordinates
  Future<WeatherResponse> fetchWeatherData(double latitude, double longitude) async {
    final (weather, _) = await fetchOpenMeteoWeather(latitude, longitude);
    return weather;
  }

  /// Caches the latest successful weather response to SharedPreferences
  Future<void> _saveWeatherCache(WeatherResponse weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(weather.toMap());
      await prefs.setString(WeatherConfig.weatherCacheKey, jsonStr);
      await prefs.setInt(
        WeatherConfig.weatherCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Retrieves cached weather response from SharedPreferences
  Future<WeatherResponse?> getCachedWeatherResponse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(WeatherConfig.weatherCacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> map = json.decode(jsonStr);
      return WeatherResponse.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Removes the locally cached weather response.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(WeatherConfig.weatherCacheKey);
      await prefs.remove(WeatherConfig.weatherCacheTimeKey);
    } catch (_) {}
  }
}
