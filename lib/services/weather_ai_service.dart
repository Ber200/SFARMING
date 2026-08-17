import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/weather_ai_analysis.dart';
import '../models/weather_model.dart';
import '../models/weather_response_model.dart';
import 'ai_assistant_service.dart';

/// Analyzes the live Open-Meteo 7-day forecast with Google Gemini and returns
/// structured agricultural advice for both the farmer mobile app and admin dashboard.
///
/// Grounded strictly in the live forecast JSON with optional farm context (crop,
/// recent scans, treatments, soil status) and localized in English, Tagalog, or Bisaya.
class WeatherAiService {
  const WeatherAiService();

  static const String _jsonSchema = '''
{
  "admin_advisory": "A concise 1-2 sentence executive advisory for the farm administrator synthesizing forecast, recent disease detections breakdown, and priority field risks",
  "overall_summary": "Comprehensive recommendation for the next 7 days answering 'What is the best thing to do during the next 7 days?'",
  "risk_level": "Low | Moderate | High",
  "best_action_window": "Specific days with the most favorable farming conditions (e.g. 'Wednesday–Thursday')",
  "daily_advice": {
    "YYYY-MM-DD": "Specific action recommendation for this day"
  },
  "weather_risks": [
    "Identified weather hazard or constraint"
  ],
  "monitoring_advice": [
    "Practical crop / disease monitoring recommendation based on weather and recent scan context"
  ],
  "important_days": [
    {"date": "YYYY-MM-DD", "weather_concern": "...", "recommendation": "..."}
  ],
  "general_recommendations": ["...", "..."]
}''';

  String _buildSystemPrompt({
    required String languageCode,
    String? farmContext,
  }) {
    final langName = switch (languageCode) {
      'fil' => 'Filipino (Tagalog)',
      'ceb' => 'Cebuano (Bisaya)',
      _ => 'English',
    };

    final contextBlock = (farmContext != null && farmContext.trim().isNotEmpty)
        ? '\nFARM & CROP CONTEXT:\n$farmContext\n'
        : '';

    return '''
You are the agricultural weather and farm analytics advisor for the SMARTFARMING rice farming system.
You provide clear, practical, action-oriented recommendations in $langName.

$contextBlock
CRITICAL RULES:
1. Analyze ONLY the actual weather forecast data and farm context provided in the prompt. Never invent weather conditions, never fabricate rainfall or temperatures.
2. The "admin_advisory" must be a concise, high-level summary of the most important current concern or opportunity for the farm administrator (e.g. synthesizing incoming rain/humidity with recent disease detection distributions).
3. The "overall_summary" is a practical 7-day outlook answering what is the best thing to do during the next 7 days (e.g. best window for field work, drainage preparation before heavy rain, foliar spraying safety).
4. The SMARTFARMING system monitors these rice disease categories: Healthy, Brown Spot, Sheath Blight, and Bacterial Leaf Blight. If recent disease scans or high humidity (>80%) indicate risk, advise on visual inspection and priority zones, but NEVER claim weather alone proves a disease is present.
5. Recommendations are practical decision support. Do not invent chemical dosages; encourage checking product labels and local agronomists.
6. All text values in your JSON response must be fluently written in $langName.

Return your response as strict JSON only (no markdown code blocks, no extraneous text), matching exactly this structure:
$_jsonSchema
''';
  }


  String _buildForecastPayload(WeatherResponse weather, WeatherModel? current) {
    final days = weather.daily.map((d) {
      return {
        'date': DateFormat('yyyy-MM-dd').format(d.date),
        'weekday': DateFormat('EEEE').format(d.date),
        'condition': WeatherCodeMapper.conditionFor(d.weatherCode),
        'max_temp_c': d.temperature2mMax,
        'min_temp_c': d.temperature2mMin,
        'precipitation_mm': d.precipitationSum,
        'rain_probability_percent': d.precipitationProbabilityMax,
        'relative_humidity_percent': d.relativeHumidity2mMean,
        'wind_speed_kmh': d.windSpeed10mMax,
        'evapotranspiration_mm': d.et0FaoEvapotranspiration,
      };
    }).toList();

    final currentObj = current == null
        ? null
        : {
            'temperature_c': current.temperature,
            'condition': current.condition,
            'humidity_percent': current.humidity,
            'wind_speed_kmh': current.windSpeed,
            'precipitation_mm': current.rainAmount,
          };

    return const JsonEncoder.withIndent('  ').convert({
      'location': {
        'latitude': weather.latitude,
        'longitude': weather.longitude,
      },
      'current_weather': currentObj,
      'daily_forecast': days,
    });
  }

  /// Sends the actual 7-day forecast to Gemini and returns the parsed analysis.
  Future<WeatherAiAnalysis> analyze(
    WeatherResponse weather, {
    WeatherModel? current,
    String languageCode = 'en',
    String? farmContext,
  }) async {
    const service = AiAssistantService();
    final payload = _buildForecastPayload(weather, current);
    final question = 'Analyze this 7-day weather forecast for the farm and generate 7-day action recommendations in $languageCode:\n$payload';

    try {
      final raw = await service.ask(
        question: question,
        systemPrompt: _buildSystemPrompt(
          languageCode: languageCode,
          farmContext: farmContext,
        ),
        responseMimeType: 'application/json',
        maxOutputTokens: 2048,
      );

      final result = _parse(raw, languageCode: languageCode);
      return result.copyWith(
        cachedAt: DateTime.now(),
        languageCode: languageCode,
        isCached: false,
      );
    } catch (e) {
      debugPrint('[WeatherAiService] Gemini analysis error, using deterministic forecast fallback: $e');
      return WeatherAiAnalysis.fallbackFromForecast(
        weather,
        languageCode: languageCode,
      );
    }
  }

  WeatherAiAnalysis _parse(String raw, {String languageCode = 'en'}) {
    final text = _extractJson(raw);
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI returned a non-object response.');
    }
    return WeatherAiAnalysis.fromJson({
      ...decoded,
      'language_code': languageCode,
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  String _extractJson(String raw) {
    final trimmed = raw.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = fence.firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();
    return trimmed;
  }
}

