/// Configuration for the Gemini AI Farm Assistant.
///
/// Calls the NATIVE Gemini REST endpoint
/// (generativelanguage.googleapis.com/v1beta/models/...:generateContent) and
/// passes the API key in the `x-goog-api-key` header. This supports both
/// legacy `AIza...` keys and the new `AQ...` Authentication keys that Google
/// AI Studio now issues (old `AIza` keys are being retired).
class GeminiConfig {
  GeminiConfig._();

  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String model = 'gemini-flash-latest';

  /// Gemini API Key loaded safely at build/run time via:
  /// flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
  static String get apiKey =>
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');


  static Uri generateContentUri() => Uri.parse('$baseUrl/$model:generateContent');

  static const int maxOutputTokens = 1024;
  static const double temperature = 0.4;
  static const Duration timeout = Duration(seconds: 45);

  static bool get hasApiKey =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE';
}
