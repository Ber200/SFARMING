import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarming/models/weather_ai_analysis.dart';
import 'package:smartfarming/models/weather_response_model.dart';

void main() {
  group('WeatherAiAnalysis Tests', () {
    test('fallbackFromForecast produces structured recommendations from weather data', () {
      final mockWeather = WeatherResponse(
        latitude: 7.3303,
        longitude: 125.6787,
        timestamp: DateTime.now(),
        current: CurrentWeather(
          time: DateTime.now(),
          temperature2m: 31.0,
          relativeHumidity2m: 78.0,
          precipitation: 0.0,
          windSpeed10m: 12.0,
        ),
        daily: [
          DailyForecast(
            date: DateTime.now(),
            weatherCode: 61,
            temperature2mMax: 32.0,
            temperature2mMin: 24.0,
            precipitationSum: 8.5,
            precipitationProbabilityMax: 80,
            relativeHumidity2mMean: 82.0,
            windSpeed10mMax: 14.0,
            et0FaoEvapotranspiration: 4.2,
          ),
          DailyForecast(
            date: DateTime.now().add(const Duration(days: 1)),
            weatherCode: 0,
            temperature2mMax: 33.0,
            temperature2mMin: 23.0,
            precipitationSum: 0.0,
            precipitationProbabilityMax: 15,
            relativeHumidity2mMean: 68.0,
            windSpeed10mMax: 10.0,
            et0FaoEvapotranspiration: 5.1,
          ),
        ],
      );

      final analysisEn = WeatherAiAnalysis.fallbackFromForecast(mockWeather, languageCode: 'en');
      expect(analysisEn.overallSummary.isNotEmpty, isTrue);
      expect(analysisEn.effectiveAdminAdvisory.isNotEmpty, isTrue);
      expect(analysisEn.riskLevel, isNotNull);
      expect(analysisEn.dailyAdvice.isNotEmpty, isTrue);

      final analysisFil = WeatherAiAnalysis.fallbackFromForecast(mockWeather, languageCode: 'fil');
      expect(analysisFil.languageCode, equals('fil'));
      expect(analysisFil.overallSummary.isNotEmpty, isTrue);
      expect(analysisFil.effectiveAdminAdvisory.isNotEmpty, isTrue);

      final analysisCeb = WeatherAiAnalysis.fallbackFromForecast(mockWeather, languageCode: 'ceb');
      expect(analysisCeb.languageCode, equals('ceb'));
      expect(analysisCeb.overallSummary.isNotEmpty, isTrue);
      expect(analysisCeb.effectiveAdminAdvisory.isNotEmpty, isTrue);
    });

    test('WeatherAiAnalysis serialization round-trip', () {
      const original = WeatherAiAnalysis(
        overallSummary: 'Prepare drainage before expected heavy rainfall.',
        adminAdvisory: 'Incoming rainfall mid-week; prioritize checking fields with recent disease scans.',
        riskLevel: 'High',
        bestActionWindow: 'Wednesday–Thursday',
        importantDays: [
          WeatherAiImportantDay(
            date: '2026-08-18',
            weatherConcern: 'Heavy rain',
            recommendation: 'Clear field ditches',
          ),
        ],
        generalRecommendations: ['Check paddy water depth'],
        weatherRisks: ['Rain wash risk for sprayed chemicals'],
        monitoringAdvice: ['Inspect leaves for Brown Spot'],
        dailyAdvice: {'2026-08-18': 'Avoid foliar spraying'},
        languageCode: 'en',
      );

      final json = original.toJson();
      final restored = WeatherAiAnalysis.fromJson(json);

      expect(restored.overallSummary, equals(original.overallSummary));
      expect(restored.adminAdvisory, equals(original.adminAdvisory));
      expect(restored.effectiveAdminAdvisory, equals(original.adminAdvisory));
      expect(restored.riskLevel, equals(original.riskLevel));
      expect(restored.bestActionWindow, equals(original.bestActionWindow));
      expect(restored.importantDays.length, equals(1));
      expect(restored.weatherRisks.length, equals(1));
      expect(restored.monitoringAdvice.length, equals(1));
      expect(restored.dailyAdvice['2026-08-18'], equals('Avoid foliar spraying'));
    });
  });
}
