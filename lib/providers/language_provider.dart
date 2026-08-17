import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages.
/// To add a new language:
///   1. Add an entry here with its display name and BCP-47 language code.
///   2. Add a matching map entry in AppLocalizations._localizedValues.
///   3. Done — the rest of the system picks it up automatically.
enum AppLanguage {
  filipino('Filipino / Tagalog', 'fil'),
  cebuano('Cebuano / Bisaya', 'ceb'),
  english('English', 'en');

  const AppLanguage(this.displayName, this.code);
  final String displayName;
  final String code;

  Locale get locale => Locale(code);

  /// Resolve from a stored BCP-47 code, falling back to English.
  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.english;
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Manages the active language and persists the user's choice.
///
/// The [isLoaded] flag prevents the UI from rendering before the persisted
/// preference is read — avoids a one-frame flash of the default language.
class LanguageProvider with ChangeNotifier {
  static const _prefKey = 'app_language';

  AppLanguage _language = AppLanguage.english;
  bool _isLoaded = false;

  AppLanguage get language => _language;

  /// True once SharedPreferences has been read. Use this to show a splash/
  /// loading state instead of rendering with the wrong language for one frame.
  bool get isLoaded => _isLoaded;

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(prefs.getString(_prefKey));
    _isLoaded = true;
    notifyListeners();
  }

  /// Switch the active language and persist the choice immediately.
  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners(); // Update UI instantly — don't wait for prefs write
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.code);
  }
}
