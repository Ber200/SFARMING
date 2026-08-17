class WeatherConfig {
  /// Open-Meteo Forecast API Endpoint (No API key required)
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  
  /// OpenWeather Icon Base URL (for icon URL resolution)
  static const String iconBaseUrl = 'https://openweathermap.org/img/wn';

  /// Backwards compatibility getters (no key required for Open-Meteo)
  static const String openWeatherApiKey = '';
  static const String apiKey = '';

  /// Automatic weather refresh interval (15 minutes)
  static const Duration refreshInterval = Duration(minutes: 15);

  /// Default HTTP network request timeout
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// Local cache key for SharedPreferences
  static const String weatherCacheKey = 'cached_openmeteo_weather_data';
  static const String weatherCacheTimeKey = 'cached_openmeteo_weather_timestamp';

  /// Registered Farm Location Default Coordinates (Quezon, Panabo City, Davao del Norte)
  static const double defaultFarmLat = 7.330315;
  static const double defaultFarmLng = 125.678657;
  static const String defaultFarmName = "Romie's Rice Field";
  static const String defaultBarangay = 'Quezon';
  static const String defaultCity = 'Panabo City';
  static const String defaultProvince = 'Davao del Norte';
}
