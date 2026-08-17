import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/weather_config.dart';
import '../models/farm_location_model.dart';
import '../models/weather_ai_analysis.dart';
import '../models/weather_model.dart';
import '../models/weather_forecast_model.dart';
import '../models/weather_response_model.dart';
import '../services/notification_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/weather_ai_service.dart';
import '../services/weather_service.dart';
import '../services/local_storage_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/geo_utils.dart';
import 'settings_provider.dart';
import 'notification_provider.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final WeatherAiService _weatherAiService = const WeatherAiService();
  final NotificationService _notificationService = NotificationService();

  WeatherResponse? _weatherResponse;
  WeatherModel? _currentWeather;
  FarmLocationModel _currentFarm = FarmLocationModel.defaultFarm;
  bool _isLoading = false;
  String? _errorMessage;
  WeatherErrorType? _errorType;
  bool _isOffline = false;
  bool _hasMissingFarmLocation = false;
  Timer? _refreshTimer;
  bool _isInitialized = false;
  SettingsProvider? _settings;
  NotificationProvider? _notifications;
  bool _lastRainNotified = false;

  // AI weather analysis state (supports both mobile farmer and admin)
  bool _aiAnalysisEnabled = true;
  WeatherAiAnalysis? _aiAnalysis;
  bool _isAnalyzing = false;
  String? _aiErrorMessage;
  String _analysisFingerprint = '';
  String _activeLanguageCode = 'en';
  String? _activeFarmContext;

  WeatherResponse? get weatherResponse => _weatherResponse;
  WeatherModel? get currentWeather => _currentWeather;
  FarmLocationModel get currentFarm => _currentFarm;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WeatherErrorType? get errorType => _errorType;
  bool get isOffline => _isOffline;
  bool get hasMissingFarmLocation => _hasMissingFarmLocation;
  bool get isInitialized => _isInitialized;

  // AI weather analysis getters
  WeatherAiAnalysis? get aiAnalysis => _aiAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  String? get aiErrorMessage => _aiErrorMessage;

  // Compatibility getters
  String get activeApiKey => 'open-meteo';
  List<HourlyForecastModel> get hourlyForecast => const [];

  List<WeatherForecastModel> get forecast {
    if (_weatherResponse == null || _weatherResponse!.daily.isEmpty) return const [];
    return _weatherResponse!.daily.map((d) {
      return WeatherForecastModel(
        date: d.date,
        temperature: (d.temperature2mMax + d.temperature2mMin) / 2,
        minTemperature: d.temperature2mMin,
        maxTemperature: d.temperature2mMax,
        humidity: d.relativeHumidity2mMean ?? _currentWeather?.humidity ?? 0.0,
        condition: WeatherCodeMapper.conditionFor(d.weatherCode),
        precipitation: d.precipitationSum,
        rainProbability: d.precipitationProbabilityMax,
        windSpeed: d.windSpeed10mMax,
        description: d.rainPrediction,
        icon: WeatherCodeMapper.iconFor(d.weatherCode),
      );
    }).toList();
  }

  String? get lastQuery => 'Panabo City';

  WeatherProvider() {
    initProvider();
  }

  /// Initial setup: loads registered farm weather, restores cached AI advice, and starts the 15-minute auto-refresh timer.
  Future<void> initProvider() async {
    if (_isInitialized) return;

    _loadCachedAiAnalysis();
    _startRefreshTimer();
    _isInitialized = true;
    await loadFarmWeather(forceRefresh: true);
  }

  /// Loads cached AI analysis from Hive local storage
  void _loadCachedAiAnalysis() {
    try {
      final cached = LocalStorageService.getWeatherAiAnalysis();
      if (cached != null) {
        _aiAnalysis = WeatherAiAnalysis.fromJson({
          ...cached,
          'is_cached': true,
        });
      }
    } catch (_) {}
  }

  /// Gives this provider access to the persisted settings so the weather
  /// refresh cycle can fire real-time rain warnings when alerts are enabled.
  void attachSettings(SettingsProvider settings) {
    _settings = settings;
  }

  /// Gives this provider access to the Notification Center so weather
  /// advisories are persisted (deduplicated by day + type).
  void attachNotifications(NotificationProvider notifications) {
    _notifications = notifications;
  }

  /// Updates the target farm location and immediately reloads weather
  Future<void> setFarmLocation(FarmLocationModel farm) async {
    _currentFarm = farm;
    notifyListeners();
    await loadFarmWeather(forceRefresh: true);
  }

  /// Starts periodic 15-minute auto-refresh timer
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(WeatherConfig.refreshInterval, (_) {
      loadFarmWeather(forceRefresh: true);
    });
  }

  /// Fetches real-time & forecast weather from Open-Meteo API using dynamic GPS or farm coordinates
  Future<void> loadFarmWeather({
    FarmLocationModel? farmLocation,
    bool forceRefresh = false,
    bool isOnline = true,
  }) async {
    final targetFarm = farmLocation ?? _currentFarm;
    _currentFarm = targetFarm;

    try {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
      _hasMissingFarmLocation = false;
      notifyListeners();

      // Dynamic GPS location lookup with registered farm fallback
      double lat = targetFarm.latitude ?? WeatherConfig.defaultFarmLat;
      double lon = targetFarm.longitude ?? WeatherConfig.defaultFarmLng;

      try {
        final currentPos = await GeoUtils.getCurrentLocation();
        if (currentPos != null) {
          lat = currentPos.$1;
          lon = currentPos.$2;
        }
      } catch (_) {
        // Use default farm coordinates if GPS is unavailable
      }

      final (response, isCached) = await _weatherService.fetchOpenMeteoWeather(lat, lon);
      _weatherResponse = response;
      _currentWeather = WeatherModel.fromOpenMeteoResponse(response, targetFarm);
      _isOffline = isCached || !isOnline;
    } on WeatherException catch (e) {
      _errorType = e.type;
      _errorMessage = e.message;
      if (e.type == WeatherErrorType.noInternet) {
        _isOffline = true;
      }

      // Try loading cached fallback
      final cached = await _weatherService.getCachedWeatherResponse();
      if (cached != null) {
        _weatherResponse = cached;
        _currentWeather = WeatherModel.fromOpenMeteoResponse(cached, targetFarm);
        _isOffline = true;
      }
    } catch (e) {
      _errorType = WeatherErrorType.unknown;
      _errorMessage = 'Failed to load weather: ${e.toString()}';

      final cached = await _weatherService.getCachedWeatherResponse();
      if (cached != null) {
        _weatherResponse = cached;
        _currentWeather = WeatherModel.fromOpenMeteoResponse(cached, targetFarm);
        _isOffline = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      _maybeSendRainWarning();
      _maybeSendWeatherAdvisory();
      unawaited(_autoReanalyzeIfChanged());
    }
  }

  /// Enables AI weather analysis.
  void enableAiWeatherAnalysis() {
    _aiAnalysisEnabled = true;
  }

  /// Ensures an AI analysis exists for the current forecast. Analyzes immediately
  /// if weather is already loaded; otherwise restores offline cache or triggers reanalysis.
  Future<void> ensureWeatherAnalysis({
    String languageCode = 'en',
    String? farmContext,
  }) async {
    enableAiWeatherAnalysis();
    _activeLanguageCode = languageCode;
    _activeFarmContext = farmContext;
    if (_aiAnalysis == null) {
      _loadCachedAiAnalysis();
    }
    if (_weatherResponse == null || _weatherResponse!.daily.isEmpty) return;
    await regenerateWeatherAnalysis(
      languageCode: languageCode,
      farmContext: farmContext,
    );
  }

  /// Sends the live forecast to Google AI and stores the result locally. Unless
  /// [force] is true, the analysis is skipped when the forecast and language have not
  /// changed since the last analysis.
  Future<void> regenerateWeatherAnalysis({
    bool force = false,
    String? languageCode,
    String? farmContext,
  }) async {
    enableAiWeatherAnalysis();
    final lang = languageCode ?? _activeLanguageCode;
    final ctx = farmContext ?? _activeFarmContext;
    _activeLanguageCode = lang;
    _activeFarmContext = ctx;

    final weather = _weatherResponse;
    if (weather == null || weather.daily.isEmpty) {
      _loadCachedAiAnalysis();
      return;
    }

    final fingerprint = '${_computeForecastFingerprint(weather)}|$lang';
    if (!force && _aiAnalysis != null && fingerprint == _analysisFingerprint && _aiAnalysis!.languageCode == lang) {
      return;
    }

    _isAnalyzing = true;
    _aiErrorMessage = null;
    notifyListeners();
    try {
      final result = await _weatherAiService.analyze(
        weather,
        current: _currentWeather,
        languageCode: lang,
        farmContext: ctx,
      );
      _aiAnalysis = result;
      _analysisFingerprint = fingerprint;
      await LocalStorageService.saveWeatherAiAnalysis(result.toJson());
    } catch (e) {
      if (e is AiAssistantException && (e.code == 'rate_limited' || e.statusCode == 429)) {
        _aiErrorMessage = 'Google Gemini API credits/quota depleted (HTTP 429). Please top up in Google AI Studio.';
      } else {
        _aiErrorMessage = 'AI weather analysis is currently unavailable.';
      }
      _aiAnalysis ??= WeatherAiAnalysis.fallbackFromForecast(weather, languageCode: lang);

    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Re-runs the AI analysis after a weather refresh only when the forecast
  /// has meaningfully changed, avoiding repeated calls to Google AI.
  Future<void> _autoReanalyzeIfChanged() async {
    if (!_aiAnalysisEnabled) return;
    final weather = _weatherResponse;
    if (weather == null || weather.daily.isEmpty) return;
    if (_aiAnalysis == null) {
      await regenerateWeatherAnalysis();
      return;
    }
    if ('${_computeForecastFingerprint(weather)}|$_activeLanguageCode' == _analysisFingerprint) return;
    await regenerateWeatherAnalysis();
  }

  /// Fingerprint of the forecast data used to skip unchanged re-analyses.
  String _computeForecastFingerprint(WeatherResponse weather) {
    final sb = StringBuffer()
      ..write(weather.latitude.toStringAsFixed(4))
      ..write('|')
      ..write(weather.longitude.toStringAsFixed(4));
    for (final d in weather.daily) {
      sb
        ..write('|${d.date.toIso8601String()}')
        ..write(',${d.temperature2mMax}')
        ..write(',${d.temperature2mMin}')
        ..write(',${d.precipitationSum}')
        ..write(',${d.precipitationProbabilityMax}')
        ..write(',${d.relativeHumidity2mMean}')
        ..write(',${d.windSpeed10mMax}')
        ..write(',${d.weatherCode}');
    }
    return sb.toString();
  }


  /// Fires a real-time rain warning once per rain event when weather alerts are
  /// enabled. Triggered on every refresh cycle (15-minute timer), on toggling
  /// the setting ON, and on pull-to-refresh.
  void _maybeSendRainWarning() {
    if (!(_settings?.weatherAlertsEnabled ?? false)) return;

    final daily = _weatherResponse?.daily ?? const <DailyForecast>[];
    final heavyRainDays = daily
        .where((d) => d.rainPrediction == 'Heavy Rain Expected')
        .toList();
    final heavyRainExpected = heavyRainDays.isNotEmpty;
    final highRainProbability = (_currentWeather?.rainProbability ?? 0) >= 50;

    final rainWarning = heavyRainExpected || highRainProbability;

    if (rainWarning && !_lastRainNotified) {
      _lastRainNotified = true;
      final message = _buildRainWarningMessage(heavyRainDays);
      _notificationService.showRainWarning(message);
      debugPrint('[WeatherProvider] Rain warning sent: $message');
    } else if (!rainWarning) {
      _lastRainNotified = false;
    }
  }

  String _buildRainWarningMessage(List<DailyForecast> heavyRainDays) {
    if (heavyRainDays.isNotEmpty) {
      final day = heavyRainDays.first;
      return 'Heavy rain expected (${DateFormat('EEE, MMM d').format(day.date)}) '
          '- about ${day.precipitationSum.toStringAsFixed(1)}mm precipitation. '
          'Secure your farm and delay spraying.';
    }
    final pct = (_currentWeather?.rainProbability ?? 0).round();
    return 'High rain probability ($pct%) expected in your area. '
        'Take precaution and protect your crops.';
  }

  /// Persists weather advisories for the current forecast window (today + next
  /// 2 days) into the Notification Center. Each advisory is deduplicated by
  /// day + type, so refresh cycles never create duplicates.
  void _maybeSendWeatherAdvisory() {
    if (!(_settings?.weatherAlertsEnabled ?? false)) return;
    final notifications = _notifications;
    if (notifications == null) return;
    final userId = notifications.currentUserId;
    if (userId == null || userId.isEmpty) return;
    final weather = _weatherResponse;
    if (weather == null || weather.daily.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final day in weather.daily) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      if (date.isBefore(today) || date.isAfter(today.add(const Duration(days: 2)))) {
        continue;
      }

      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dateLabel = DateFormat('EEE, MMM d').format(date);

      if (day.rainPrediction == 'Heavy Rain Expected') {
        notifications.addNotification(
          userId: userId,
          type: NotificationType.weatherAdvisory,
          title: 'Heavy Rain Advisory',
          body: 'Heavy rain expected on $dateLabel '
              '(about ${day.precipitationSum.toStringAsFixed(1)}mm). '
              'Secure your farm and delay spraying.',
          actionRoute: AppRoutes.weatherDetails,
          relatedId: dateKey,
          eventKey: 'weather|$userId|$dateKey|heavy-rain',
          showLocal: true,
        );
      }

      if (day.temperature2mMax >= 35.0) {
        notifications.addNotification(
          userId: userId,
          type: NotificationType.weatherAdvisory,
          title: 'Extreme Heat Advisory',
          body: 'Temperatures may reach ${day.temperature2mMax.round()}°C on '
              '$dateLabel. Water crops early and provide shade where possible.',
          actionRoute: AppRoutes.weatherDetails,
          relatedId: dateKey,
          eventKey: 'weather|$userId|$dateKey|heat',
          showLocal: true,
        );
      }
    }
  }

  /// Compatibility methods
  Future<void> loadWeather(String query, {bool forceRefresh = false, bool isOnline = true}) async {
    await loadFarmWeather(forceRefresh: forceRefresh, isOnline: isOnline);
  }

  Future<void> loadWeatherByCoordinates(double lat, double lon, {bool forceRefresh = false, bool isOnline = true}) async {
    await loadFarmWeather(forceRefresh: forceRefresh, isOnline: isOnline);
  }

  /// Manual refresh triggered by user or pull-to-refresh
  Future<void> refreshWeather({bool isOnline = true}) async {
    await loadFarmWeather(forceRefresh: true, isOnline: isOnline);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
