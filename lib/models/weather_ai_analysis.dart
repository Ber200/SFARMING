import 'package:intl/intl.dart';
import 'weather_response_model.dart';

/// A single upcoming day flagged by the AI as important.
class WeatherAiImportantDay {
  final String date;
  final String weatherConcern;
  final String recommendation;

  const WeatherAiImportantDay({
    required this.date,
    required this.weatherConcern,
    required this.recommendation,
  });

  factory WeatherAiImportantDay.fromJson(Map<String, dynamic> json) {
    return WeatherAiImportantDay(
      date: (json['date'] ?? '').toString(),
      weatherConcern: (json['weather_concern'] ?? json['weatherConcern'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'weather_concern': weatherConcern,
        'recommendation': recommendation,
      };
}

/// Structured AI-generated agricultural analysis of the live weather forecast.
///
/// Provides actionable 7-day recommendations for farmers and admins.
/// `riskLevel` is normalized to one of `Low`, `Moderate`, or `High`.
class WeatherAiAnalysis {
  final String overallSummary;
  final String adminAdvisory;
  final String riskLevel;
  final String bestActionWindow;
  final List<WeatherAiImportantDay> importantDays;
  final List<String> generalRecommendations;
  final List<String> weatherRisks;
  final List<String> monitoringAdvice;
  final Map<String, String> dailyAdvice;
  final DateTime? cachedAt;
  final String languageCode;
  final bool isCached;

  const WeatherAiAnalysis({
    required this.overallSummary,
    this.adminAdvisory = '',
    required this.riskLevel,
    this.bestActionWindow = '',
    required this.importantDays,
    required this.generalRecommendations,
    this.weatherRisks = const [],
    this.monitoringAdvice = const [],
    this.dailyAdvice = const {},
    this.cachedAt,
    this.languageCode = 'en',
    this.isCached = false,
  });

  String get effectiveAdminAdvisory =>
      adminAdvisory.trim().isNotEmpty ? adminAdvisory : overallSummary;

  factory WeatherAiAnalysis.fromJson(Map<String, dynamic> json) {
    final rawDailyAdvice = json['daily_advice'] ?? json['dailyAdvice'];
    final Map<String, String> parsedDailyAdvice = {};
    if (rawDailyAdvice is Map) {
      for (final entry in rawDailyAdvice.entries) {
        parsedDailyAdvice[entry.key.toString()] = entry.value.toString();
      }
    }

    final rawImportant = (json['important_days'] ?? json['importantDays']) as List? ?? [];
    final importantDays = rawImportant
        .map((e) => e is WeatherAiImportantDay
            ? e
            : WeatherAiImportantDay.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawGeneral = (json['general_recommendations'] ?? json['generalRecommendations']) as List? ?? [];
    final generalRecommendations = rawGeneral.map((e) => e.toString()).toList();

    final rawRisks = (json['weather_risks'] ?? json['weatherRisks']) as List? ?? [];
    final weatherRisks = rawRisks.map((e) => e.toString()).toList();

    final rawMonitoring = (json['monitoring_advice'] ?? json['monitoringAdvice']) as List? ?? [];
    final monitoringAdvice = rawMonitoring.map((e) => e.toString()).toList();

    return WeatherAiAnalysis(
      overallSummary: (json['overall_summary'] ?? json['overallSummary'] ?? json['summary'] ?? '').toString(),
      adminAdvisory: (json['admin_advisory'] ?? json['adminAdvisory'] ?? json['advisory'] ?? '').toString(),
      riskLevel: _normalizeRiskLevel((json['risk_level'] ?? json['riskLevel'] ?? json['priority'] ?? '').toString()),
      bestActionWindow: (json['best_action_window'] ?? json['bestActionWindow'] ?? '').toString(),
      importantDays: importantDays,
      generalRecommendations: generalRecommendations,
      weatherRisks: weatherRisks,
      monitoringAdvice: monitoringAdvice,
      dailyAdvice: parsedDailyAdvice,
      cachedAt: json['cached_at'] != null ? DateTime.tryParse(json['cached_at'].toString()) : null,
      languageCode: (json['language_code'] ?? 'en').toString(),
      isCached: json['is_cached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall_summary': overallSummary,
        'admin_advisory': adminAdvisory,
        'risk_level': riskLevel,
        'best_action_window': bestActionWindow,
        'important_days': importantDays.map((d) => d.toJson()).toList(),
        'general_recommendations': generalRecommendations,
        'weather_risks': weatherRisks,
        'monitoring_advice': monitoringAdvice,
        'daily_advice': dailyAdvice,
        'cached_at': cachedAt?.toIso8601String(),
        'language_code': languageCode,
        'is_cached': isCached,
      };

  WeatherAiAnalysis copyWith({
    String? overallSummary,
    String? riskLevel,
    String? bestActionWindow,
    List<WeatherAiImportantDay>? importantDays,
    List<String>? generalRecommendations,
    List<String>? weatherRisks,
    List<String>? monitoringAdvice,
    Map<String, String>? dailyAdvice,
    DateTime? cachedAt,
    String? languageCode,
    bool? isCached,
  }) {
    return WeatherAiAnalysis(
      overallSummary: overallSummary ?? this.overallSummary,
      riskLevel: riskLevel ?? this.riskLevel,
      bestActionWindow: bestActionWindow ?? this.bestActionWindow,
      importantDays: importantDays ?? this.importantDays,
      generalRecommendations: generalRecommendations ?? this.generalRecommendations,
      weatherRisks: weatherRisks ?? this.weatherRisks,
      monitoringAdvice: monitoringAdvice ?? this.monitoringAdvice,
      dailyAdvice: dailyAdvice ?? this.dailyAdvice,
      cachedAt: cachedAt ?? this.cachedAt,
      languageCode: languageCode ?? this.languageCode,
      isCached: isCached ?? this.isCached,
    );
  }

  static String _normalizeRiskLevel(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.contains('high')) return 'High';
    if (lower.contains('moderate') || lower.contains('medium')) return 'Moderate';
    return 'Low';
  }

  bool get isEmpty =>
      overallSummary.trim().isEmpty &&
      importantDays.isEmpty &&
      generalRecommendations.isEmpty;

  /// Deterministic fallback recommendations derived from real Open-Meteo forecast metrics
  /// when AI service is offline or rate-limited.
  factory WeatherAiAnalysis.fallbackFromForecast(
    WeatherResponse weather, {
    String languageCode = 'en',
  }) {
    final daily = weather.daily;
    if (daily.isEmpty) {
      return WeatherAiAnalysis(
        overallSummary: _tr('No weather forecast data available to analyze.', languageCode),
        riskLevel: 'Low',
        importantDays: const [],
        generalRecommendations: const [],
        languageCode: languageCode,
      );
    }

    final rainyDays = <DailyForecast>[];
    final dryDays = <DailyForecast>[];
    final hotDays = <DailyForecast>[];
    final windyDays = <DailyForecast>[];
    final dailyAdvice = <String, String>{};
    final importantDays = <WeatherAiImportantDay>[];

    for (final d in daily) {
      final dateKey = DateFormat('yyyy-MM-dd').format(d.date);
      final isRain = (d.precipitationProbabilityMax ?? 0) >= 50 || d.precipitationSum >= 2.0;
      final isHot = d.temperature2mMax >= 34.0;
      final isWind = (d.windSpeed10mMax ?? 0) >= 20.0;

      if (isRain) {
        rainyDays.add(d);
        final advice = _tr(
          'Rain expected (${d.precipitationProbabilityMax ?? 60}%). Postpone pesticide/fertilizer application and inspect field drainage.',
          languageCode,
        );
        dailyAdvice[dateKey] = advice;
        importantDays.add(WeatherAiImportantDay(
          date: dateKey,
          weatherConcern: _tr('Rain & potential field water accumulation', languageCode),
          recommendation: advice,
        ));
      } else if (isWind) {
        windyDays.add(d);
        final advice = _tr(
          'Strong winds (${d.windSpeed10mMax?.toStringAsFixed(1)} km/h). Avoid foliar spraying to prevent drift.',
          languageCode,
        );
        dailyAdvice[dateKey] = advice;
      } else if (isHot) {
        hotDays.add(d);
        final advice = _tr(
          'High temperature (${d.temperature2mMax.toStringAsFixed(0)}°C). Ensure adequate paddy water depth to reduce heat stress.',
          languageCode,
        );
        dailyAdvice[dateKey] = advice;
      } else {
        dryDays.add(d);
        final advice = _tr(
          'Favorable weather for field inspection, weeding, and scheduled farm maintenance.',
          languageCode,
        );
        dailyAdvice[dateKey] = advice;
      }
    }

    String riskLevel = 'Low';
    if (rainyDays.length >= 4 || (rainyDays.any((d) => d.precipitationSum >= 15.0))) {

      riskLevel = 'High';
    } else if (rainyDays.isNotEmpty || windyDays.isNotEmpty || hotDays.isNotEmpty) {
      riskLevel = 'Moderate';
    }

    String summary;
    String bestWindow;
    if (rainyDays.length >= 5) {
      summary = _tr(
        'Persistent rainfall expected throughout most of the 7 days. Focus on drainage maintenance and disease monitoring.',
        languageCode,
      );
      bestWindow = _tr('Brief dry periods between morning rain showers', languageCode);
    } else if (dryDays.length >= 4) {
      summary = _tr(
        'Relatively dry and stable 7-day outlook. Ideal for scheduled fertilizing, foliar treatments, and field upkeep.',
        languageCode,
      );
      bestWindow = dryDays.isNotEmpty
          ? '${DateFormat('EEEE').format(dryDays.first.date)}–${DateFormat('EEEE').format(dryDays.last.date)}'
          : _tr('Mid-week dry days', languageCode);
    } else {
      summary = _tr(
        'Mixed weather conditions with alternating dry and wet days across the 7-day period.',
        languageCode,
      );
      bestWindow = dryDays.isNotEmpty
          ? DateFormat('EEEE, MMM d').format(dryDays.first.date)
          : _tr('Dry afternoon windows', languageCode);
    }

    final weatherRisks = <String>[];
    if (rainyDays.isNotEmpty) {
      weatherRisks.add(_tr(
        '${rainyDays.length} day(s) with rain risk may wash away sprayed chemicals.',
        languageCode,
      ));
    }
    if (windyDays.isNotEmpty) {
      weatherRisks.add(_tr(
        'Gusty winds may cause pesticide spray drift and uneven application.',
        languageCode,
      ));
    }

    final monitoringAdvice = <String>[
      _tr('Check water levels and clear drainage outlets before rain showers.', languageCode),
      _tr('Inspect rice leaf canopies for fungal disease signs after damp, humid days.', languageCode),
    ];

    final generalRecommendations = <String>[
      _tr('Schedule chemical spraying strictly during dry windows with calm wind.', languageCode),
      _tr('Maintain optimal water depth (2–5 cm) during critical rice development stages.', languageCode),
    ];

    return WeatherAiAnalysis(
      overallSummary: summary,
      adminAdvisory: summary,
      riskLevel: riskLevel,
      bestActionWindow: bestWindow,
      importantDays: importantDays,
      generalRecommendations: generalRecommendations,
      weatherRisks: weatherRisks,
      monitoringAdvice: monitoringAdvice,
      dailyAdvice: dailyAdvice,
      cachedAt: DateTime.now(),
      languageCode: languageCode,
      isCached: false,
    );

  }

  static String _tr(String text, String languageCode) {
    if (languageCode == 'fil') {
      if (text.contains('No weather forecast')) return 'Walang available na weather forecast na susuriin.';
      if (text.contains('Persistent rainfall expected')) return 'Inaasahan ang tuloy-tuloy na pag-ulan sa susunod na 7 araw. Pagtuunan ang drainage at pagsubaybay sa peste/sakit.';
      if (text.contains('Relatively dry and stable')) return 'Medyo tuyo at maaliwalas ang 7-araw na panahon. Mainam para sa pagpapataba, pag-spray, at pag-aalaga ng palay.';
      if (text.contains('Mixed weather conditions')) return 'Pabago-bagong panahon na may salitang tuyo at maulang mga araw sa susunod na 7 araw.';
      if (text.contains('Rain expected')) return 'Inaasahan ang ulan. Ipagpaliban ang pag-spray/pataba at suriin ang daluyan ng tubig sa palayan.';
      if (text.contains('Strong winds')) return 'Malakas ang hangin. Iwasan ang pag-spray upang maiwasan ang paglipad ng gamot.';
      if (text.contains('High temperature')) return 'Mataas ang temperatura. Panatilihing may sapat na tubig ang palayan laban sa init.';
      if (text.contains('Favorable weather')) return 'Magandang panahon para sa pag-inspeksyon ng palay, pag-aalis ng damo, at regular na gawain sa bukid.';
      if (text.contains('Check water levels')) return 'Suriin ang lebel ng tubig at linisin ang mga drainage bago dumating ang ulan.';
      if (text.contains('Inspect rice leaf')) return 'Suriin ang mga dahon ng palay kung may sintomas ng sakit pagkatapos ng mahalumigmig na panahon.';
      if (text.contains('Schedule chemical spraying')) return 'Mag-spray lamang sa mga tuyong oras na walang malakas na hangin.';
      if (text.contains('Maintain optimal water')) return 'Panatilihin ang tamang lalim ng tubig (2–5 cm) sa palayan.';
      if (text.contains('Brief dry periods')) return 'Maikling tuyong panahon sa pagitan ng mga pag-ulan';
      if (text.contains('Mid-week dry days')) return 'Mga tuyong araw sa kalagitnaan ng linggo';
      if (text.contains('Dry afternoon windows')) return 'Tuyo sa bandang hapon';
      if (text.contains('Rain & potential field')) return 'Ulan at posibleng pag-ipon ng tubig sa palayan';
      if (text.contains('day(s) with rain risk')) return 'Maaaring maanod ng ulan ang mga kemikal na ini-spray.';
      if (text.contains('Gusty winds may cause')) return 'Maaaring tangayin ng hangin ang spray at maging hindi pantay ang paglalagay.';
    } else if (languageCode == 'ceb') {
      if (text.contains('No weather forecast')) return 'Walay available nga weather forecast nga masusi.';
      if (text.contains('Persistent rainfall expected')) return 'Gilauman ang sige-sige nga ulan sulod sa 7 ka adlaw. Tutoki ang kanal ug pagbantay sa sakit sa humay.';
      if (text.contains('Relatively dry and stable')) return 'Uga ug maayong panahon sulod sa 7 ka adlaw. Maayo para sa pag-abono, pag-spray, ug pagmentinar sa basakan.';
      if (text.contains('Mixed weather conditions')) return 'Sumpay-sumpay nga uga ug ting-ulan sulod sa 7 ka adlaw.';
      if (text.contains('Rain expected')) return 'Gilauman ang ulan. I-uswag ang pag-spray/abono ug susiha ang agianan sa tubig sa basakan.';
      if (text.contains('Strong winds')) return 'Kusog ang hangin. Likayi ang pag-spray aron dili mapalid ang tambal.';
      if (text.contains('High temperature')) return 'Init ang panahon. Siguroa nga igo ang tubig sa humayan batok sa kainit.';
      if (text.contains('Favorable weather')) return 'Maayong panahon para sa pag-inspeksyon, pagtangtang sa sagbot, ug regular nga trabaho sa basakan.';
      if (text.contains('Check water levels')) return 'Susiha ang lebel sa tubig ug hinloi ang mga kanal sa dili pa mobundak ang ulan.';
      if (text.contains('Inspect rice leaf')) return 'Susiha ang mga dahon sa humay kon dunay timailhan sa sakit human sa ting-ulan.';
      if (text.contains('Schedule chemical spraying')) return 'Pag-spray lang sa uga nga panahon ug walay kusog nga hangin.';
      if (text.contains('Maintain optimal water')) return 'Hupti ang sakto nga giladmon sa tubig (2–5 cm) sa basakan.';
      if (text.contains('Brief dry periods')) return 'Mubo nga uga nga panahon taliwala sa mga ulan';
      if (text.contains('Mid-week dry days')) return 'Uga nga mga adlaw sa tunga-tunga sa semana';
      if (text.contains('Dry afternoon windows')) return 'Uga nga panahon sa hapon';
      if (text.contains('Rain & potential field')) return 'Ulan ug posibleng pagpundo sa tubig sa basakan';
      if (text.contains('day(s) with rain risk')) return 'Mahimong maanod sa ulan ang gi-spray nga tambal.';
      if (text.contains('Gusty winds may cause')) return 'Mahimong mapalid sa hangin ang spray ug dili patas ang pagbutang.';
    }
    return text;
  }
}

