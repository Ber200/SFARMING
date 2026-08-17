import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings for the farmer app.
///
/// Values are read once from SharedPreferences on startup and every setter
/// writes through immediately, so toggles take effect in real time.
class SettingsProvider with ChangeNotifier {
  static const _weatherAlertsKey = 'settings_weather_alerts';
  static const _treatmentRemindersKey = 'settings_treatment_reminders';

  bool _weatherAlertsEnabled = true;
  bool _treatmentRemindersEnabled = true;
  bool _isLoaded = false;

  bool get weatherAlertsEnabled => _weatherAlertsEnabled;
  bool get treatmentRemindersEnabled => _treatmentRemindersEnabled;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _weatherAlertsEnabled = prefs.getBool(_weatherAlertsKey) ?? true;
      _treatmentRemindersEnabled = prefs.getBool(_treatmentRemindersKey) ?? true;
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  /// Persist the weather/rain alert preference and notify immediately.
  Future<void> setWeatherAlertsEnabled(bool enabled) async {
    if (_weatherAlertsEnabled == enabled) return;
    _weatherAlertsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weatherAlertsKey, enabled);
  }

  /// Persist the treatment reminder preference and notify immediately.
  Future<void> setTreatmentRemindersEnabled(bool enabled) async {
    if (_treatmentRemindersEnabled == enabled) return;
    _treatmentRemindersEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_treatmentRemindersKey, enabled);
  }
}
