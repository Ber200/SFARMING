class AppConfig {
  // Environment
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDevelopment = !isProduction;

  // Weather API configuration
  static const String weatherApiKey = String.fromEnvironment('WEATHER_API_KEY', defaultValue: '');
  static const String weatherApiKeyPrefsKey = 'user_weather_api_key';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration imageUploadTimeout = Duration(seconds: 60);

  // Cache Durations
  static const Duration weatherCacheDuration = Duration(minutes: 15); // refreshed every 10-15 minutes
  static const Duration soilDataCacheDuration = Duration(minutes: 15);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Settings
  static const int maxImageSize = 1024; // pixels
  static const int imageQuality = 85; // JPEG quality (0-100)
  
  // Notification Settings
  static const Duration treatmentReminderBeforeDays = Duration(days: 1);
  static const Duration fertilizationReminderBeforeDays = Duration(days: 1);
}
