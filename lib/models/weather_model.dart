import 'package:flutter/material.dart';
import 'farm_location_model.dart';
import '../config/weather_config.dart';

enum WeatherWarningLevel {
  green, // Good Conditions
  yellow, // Caution
  orange, // Warning
  red, // High Risk
}

class WeatherWarning {
  final WeatherWarningLevel level;
  final IconData icon;
  final String title;
  final String description;
  final String suggestedAction;

  const WeatherWarning({
    required this.level,
    required this.icon,
    required this.title,
    required this.description,
    required this.suggestedAction,
  });

  Color get color {
    switch (level) {
      case WeatherWarningLevel.green:
        return const Color(0xFF2E7D32); // Green
      case WeatherWarningLevel.yellow:
        return const Color(0xFFF9A825); // Yellow/Amber
      case WeatherWarningLevel.orange:
        return const Color(0xFFEF6C00); // Orange
      case WeatherWarningLevel.red:
        return const Color(0xFFC62828); // Red
    }
  }

  Color get backgroundColor {
    switch (level) {
      case WeatherWarningLevel.green:
        return const Color(0xFFE8F5E9);
      case WeatherWarningLevel.yellow:
        return const Color(0xFFFFFDE7);
      case WeatherWarningLevel.orange:
        return const Color(0xFFFFF3E0);
      case WeatherWarningLevel.red:
        return const Color(0xFFFFEBEE);
    }
  }

  String get levelLabel {
    switch (level) {
      case WeatherWarningLevel.green:
        return 'GOOD CONDITIONS';
      case WeatherWarningLevel.yellow:
        return 'CAUTION';
      case WeatherWarningLevel.orange:
        return 'WARNING';
      case WeatherWarningLevel.red:
        return 'HIGH RISK';
    }
  }
}

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed; // stored in km/h
  final double pressure; // in hPa
  final String condition; // e.g. 'Sunny', 'Cloudy', 'Rain', etc.
  final String description;
  final String icon;
  final double chanceOfRain; // 0 - 100 %
  final DateTime timestamp;
  final FarmLocationModel farmLocation;

  // Compatibility fields
  final String? airQuality;
  final double? uvIndex;
  final String? windDirection;
  final double? cloudCoverage;
  final double? visibility;
  final double? rainAmount;
  final String? sunrise;
  final String? sunset;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.condition,
    required this.description,
    required this.icon,
    required this.chanceOfRain,
    required this.timestamp,
    required this.farmLocation,
    this.airQuality = 'Good',
    this.uvIndex = 5.0,
    this.windDirection = 'NE',
    this.cloudCoverage = 20.0,
    this.visibility = 10.0,
    this.rainAmount = 0.0,
    this.sunrise = '05:45 AM',
    this.sunset = '06:15 PM',
  });

  factory WeatherModel.fromOpenMeteoResponse(
    dynamic response,
    FarmLocationModel farm,
  ) {
    final cur = response.current;
    final isRain = cur.precipitation > 0.1;
    final cond = isRain
        ? (cur.precipitation > 5.0 ? 'Heavy Rain' : 'Rain')
        : (cur.temperature2m > 30 ? 'Sunny' : 'Partly Cloudy');

    return WeatherModel(
      temperature: cur.temperature2m,
      feelsLike: cur.temperature2m,
      humidity: cur.relativeHumidity2m,
      windSpeed: cur.windSpeed10m,
      pressure: 1013.0,
      condition: cond,
      description: isRain
          ? 'Precipitation ${cur.precipitation.toStringAsFixed(1)} mm'
          : 'Clear skies & suitable conditions',
      icon: isRain ? '10d' : '01d',
      chanceOfRain: cur.precipitation > 0 ? 80.0 : 10.0,
      timestamp: response.timestamp,
      farmLocation: farm,
      rainAmount: cur.precipitation,
    );
  }

  // Backwards compatibility getters
  double get rainProbability => chanceOfRain;
  String get locationName => farmLocation.farmName;
  String get farmAddress => farmLocation.fullAddress;
  DateTime get updatedTime => timestamp;
  double? get latitude => farmLocation.latitude;
  double? get longitude => farmLocation.longitude;

  bool get isRainy =>
      condition.toLowerCase().contains('rain') ||
      condition.toLowerCase().contains('shower') ||
      condition.toLowerCase().contains('drizzle') ||
      condition.toLowerCase().contains('storm') ||
      chanceOfRain > 60;

  bool get isGoodForSpraying => !isRainy && windSpeed <= 20.0;

  String get status {
    if (chanceOfRain > 70) return 'BAD';
    if (windSpeed > 20.0) return 'WARNING';
    return 'GOOD';
  }

  String get iconUrl {
    if (icon.startsWith('http://') || icon.startsWith('https://')) return icon;
    if (icon.startsWith('//')) return 'https:$icon';
    if (icon.contains('//')) return 'https:${icon.substring(icon.indexOf('//'))}';
    return '${WeatherConfig.iconBaseUrl}/$icon@2x.png';
  }

  /// Generates a natural human-readable summary of the weather
  String get weatherSummary {
    final tempStr = temperature > 30
        ? 'Hot'
        : temperature > 24
            ? 'Warm'
            : 'Cool';

    final windStr = windSpeed > 25
        ? 'strong winds'
        : windSpeed > 15
            ? 'moderate breeze'
            : 'light winds';

    final condLower = condition.toLowerCase();
    if (condLower.contains('rain') || condLower.contains('drizzle')) {
      return '$tempStr and rainy conditions with $windStr.';
    } else if (condLower.contains('cloud')) {
      return '$tempStr and partly cloudy conditions with $windStr.';
    } else if (condLower.contains('thunder') || condLower.contains('storm')) {
      return 'Stormy conditions with $windStr and heavy rain likelihood.';
    } else {
      return '$tempStr and clear sunny conditions with $windStr.';
    }
  }

  /// Generates intelligent rice farming recommendations based on weather
  List<String> get farmingRecommendations {
    final list = <String>[];
    final condLower = condition.toLowerCase();
    final descLower = description.toLowerCase();

    // 1. Weather condition specific rules
    if (condLower.contains('thunder') || condLower.contains('storm')) {
      list.add('Avoid outdoor farming activities until the storm passes.');
      list.add('Secure farming equipment and inspect crops after the storm.');
    } else if (condLower.contains('heavy rain') || descLower.contains('heavy')) {
      list.add('Inspect rice field drainage immediately.');
      list.add('Delay fertilizer application to prevent runoff.');
      list.add('Watch closely for field flooding.');
    } else if (condLower.contains('rain') || condLower.contains('drizzle')) {
      if (condLower.contains('light') || descLower.contains('light')) {
        list.add('Delay artificial irrigation.');
        list.add('Observe soil moisture level.');
      } else {
        list.add('Monitor field water levels.');
        list.add('Check drainage systems.');
      }
    } else if (condLower.contains('cloud') || condLower.contains('overcast')) {
      list.add('Good conditions for crop monitoring.');
      list.add('Continue regular field maintenance.');
    } else {
      // Clear / Sunny
      list.add('Good day for rice field inspection.');
      list.add('Suitable weather for fertilizer and pesticide application.');
      list.add('Continue normal rice farming activities.');
    }

    // 2. High Humidity (>85%)
    if (humidity >= 85) {
      list.add('High humidity increases risk of fungal diseases. Inspect rice leaves for blast or blight.');
    }

    // 3. Strong Wind (>20 km/h)
    if (windSpeed >= 20) {
      list.add('Check young rice plants for wind damage and postpone chemical spraying.');
    }

    // 4. Extreme Heat (>35°C)
    if (temperature >= 35) {
      list.add('Monitor soil moisture closely. Increase irrigation to prevent heat stress.');
    } else if (temperature <= 20) {
      list.add('Observe crops for signs of cold stress.');
    }

    return list;
  }

  /// Generates color-coded Early Warning System alert cards
  List<WeatherWarning> get activeWarnings {
    final warnings = <WeatherWarning>[];
    final condLower = condition.toLowerCase();
    final descLower = description.toLowerCase();

    // 1. Storm / Thunderstorm Warning
    if (condLower.contains('thunder') || condLower.contains('storm')) {
      warnings.add(const WeatherWarning(
        level: WeatherWarningLevel.red,
        icon: Icons.thunderstorm_rounded,
        title: 'STORM WARNING',
        description: 'Thunderstorms and severe weather detected in the area.',
        suggestedAction: 'Avoid field activities. Secure equipment and inspect crops after the storm.',
      ));
    }

    // 2. Heavy Rain / Flood Warning
    if (condLower.contains('heavy rain') || descLower.contains('heavy') || chanceOfRain >= 80) {
      warnings.add(const WeatherWarning(
        level: WeatherWarningLevel.orange,
        icon: Icons.flood_rounded,
        title: 'HEAVY RAIN & FLOOD WARNING',
        description: 'Heavy rainfall detected. Rice fields are at risk of waterlogging and flooding.',
        suggestedAction: 'Check irrigation canals and inspect field drainage immediately.',
      ));
    }

    // 3. High Humidity Warning (>85%)
    if (humidity >= 85) {
      warnings.add(WeatherWarning(
        level: WeatherWarningLevel.yellow,
        icon: Icons.water_drop_rounded,
        title: 'HIGH HUMIDITY WARNING',
        description: 'High relative humidity (${humidity.toStringAsFixed(0)}%) increases fungal disease risk.',
        suggestedAction: 'Monitor rice leaves closely for fungal pathogens or leaf blight.',
      ));
    }

    // 4. Strong Wind Warning (>20 km/h)
    if (windSpeed >= 20) {
      warnings.add(WeatherWarning(
        level: WeatherWarningLevel.yellow,
        icon: Icons.air_rounded,
        title: 'STRONG WIND WARNING',
        description: 'Strong winds (${windSpeed.toStringAsFixed(1)} km/h) detected.',
        suggestedAction: 'Inspect young rice plants and postpone pesticide/fertilizer spraying.',
      ));
    }

    // 5. Extreme Heat Warning (>35°C)
    if (temperature >= 35) {
      warnings.add(WeatherWarning(
        level: WeatherWarningLevel.orange,
        icon: Icons.wb_sunny_rounded,
        title: 'EXTREME HEAT WARNING',
        description: 'High temperatures (${temperature.toStringAsFixed(1)}°C) may stress crops.',
        suggestedAction: 'Increase irrigation monitoring and maintain water depth in paddies.',
      ));
    }

    // Default Good Conditions warning if no active risks
    if (warnings.isEmpty) {
      warnings.add(const WeatherWarning(
        level: WeatherWarningLevel.green,
        icon: Icons.check_circle_outline_rounded,
        title: 'FAVORABLE WEATHER CONDITIONS',
        description: 'Weather conditions are optimal for rice farming activities.',
        suggestedAction: 'Proceed with normal field inspection and scheduled maintenance.',
      ));
    }

    return warnings;
  }

  factory WeatherModel.fromOpenWeatherJson(
    Map<String, dynamic> weatherJson,
    Map<String, dynamic>? forecastJson,
    FarmLocationModel farm,
  ) {
    final main = weatherJson['main'] ?? {};
    final wind = weatherJson['wind'] ?? {};
    final weatherList = weatherJson['weather'] as List? ?? [];
    final firstWeather = weatherList.isNotEmpty ? weatherList[0] as Map<String, dynamic> : {};

    final temp = (main['temp'] as num?)?.toDouble() ?? 0.0;
    final feels = (main['feels_like'] as num?)?.toDouble() ?? temp;
    final hum = (main['humidity'] as num?)?.toDouble() ?? 0.0;
    final press = (main['pressure'] as num?)?.toDouble() ?? 1013.0;

    final windMs = (wind['speed'] as num?)?.toDouble() ?? 0.0;
    final windKmh = windMs * 3.6;

    final mainCond = firstWeather['main'] ?? 'Clear';
    final desc = firstWeather['description'] ?? 'clear sky';
    final iconCode = firstWeather['icon'] ?? '01d';

    double popMax = 0.0;
    if (forecastJson != null && forecastJson['list'] != null) {
      final list = forecastJson['list'] as List? ?? [];
      if (list.isNotEmpty) {
        for (var item in list.take(8)) {
          final itemMap = item as Map<String, dynamic>;
          final itemPop = (itemMap['pop'] as num?)?.toDouble() ?? 0.0;
          if (itemPop > popMax) popMax = itemPop;
        }
      }
    }
    final chanceRain = (popMax * 100).clamp(0.0, 100.0);

    return WeatherModel(
      temperature: temp,
      feelsLike: feels,
      humidity: hum,
      windSpeed: windKmh,
      pressure: press,
      condition: mainCond,
      description: desc,
      icon: iconCode,
      chanceOfRain: chanceRain,
      timestamp: DateTime.now(),
      farmLocation: farm,
      airQuality: 'Good',
      uvIndex: 5.0,
      windDirection: 'NE',
      cloudCoverage: 20.0,
      visibility: 10.0,
      rainAmount: 0.0,
      sunrise: '05:45 AM',
      sunset: '06:15 PM',
    );
  }

  factory WeatherModel.fromMap(Map<String, dynamic> map) {
    return WeatherModel(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (map['feelsLike'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (map['windSpeed'] as num?)?.toDouble() ?? 0.0,
      pressure: (map['pressure'] as num?)?.toDouble() ?? 1013.0,
      condition: map['condition'] ?? 'Clear',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '01d',
      chanceOfRain: (map['chanceOfRain'] as num?)?.toDouble() ?? (map['rainProbability'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      farmLocation: map['farmLocation'] != null
          ? FarmLocationModel.fromMap(Map<String, dynamic>.from(map['farmLocation']))
          : FarmLocationModel.defaultFarm,
      airQuality: map['airQuality'] ?? 'Good',
      uvIndex: (map['uvIndex'] as num?)?.toDouble() ?? 5.0,
      windDirection: map['windDirection'] ?? 'NE',
      cloudCoverage: (map['cloudCoverage'] as num?)?.toDouble() ?? 20.0,
      visibility: (map['visibility'] as num?)?.toDouble() ?? 10.0,
      rainAmount: (map['rainAmount'] as num?)?.toDouble() ?? 0.0,
      sunrise: map['sunrise'] ?? '05:45 AM',
      sunset: map['sunset'] ?? '06:15 PM',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'pressure': pressure,
      'condition': condition,
      'description': description,
      'icon': icon,
      'chanceOfRain': chanceOfRain,
      'rainProbability': chanceOfRain,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'farmLocation': farmLocation.toMap(),
      'airQuality': airQuality,
      'uvIndex': uvIndex,
      'windDirection': windDirection,
      'cloudCoverage': cloudCoverage,
      'visibility': visibility,
      'rainAmount': rainAmount,
      'sunrise': sunrise,
      'sunset': sunset,
    };
  }
}
