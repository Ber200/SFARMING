/// Current weather metrics from Open-Meteo API
class CurrentWeather {
  final double temperature2m;
  final double relativeHumidity2m;
  final double precipitation;
  final double windSpeed10m;
  final DateTime time;

  CurrentWeather({
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.precipitation,
    required this.windSpeed10m,
    required this.time,
  });

  factory CurrentWeather.fromOpenMeteoJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature2m: (json['temperature_2m'] as num? ?? 0.0).toDouble(),
      relativeHumidity2m: (json['relative_humidity_2m'] as num? ?? 0.0).toDouble(),
      precipitation: (json['precipitation'] as num? ?? 0.0).toDouble(),
      windSpeed10m: (json['wind_speed_10m'] as num? ?? 0.0).toDouble(),
      time: json['time'] != null
          ? DateTime.tryParse(json['time'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory CurrentWeather.fromMap(Map<String, dynamic> map) {
    return CurrentWeather(
      temperature2m: (map['temperature2m'] ?? 0.0).toDouble(),
      relativeHumidity2m: (map['relativeHumidity2m'] ?? 0.0).toDouble(),
      precipitation: (map['precipitation'] ?? 0.0).toDouble(),
      windSpeed10m: (map['windSpeed10m'] ?? 0.0).toDouble(),
      time: map['time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['time'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature2m': temperature2m,
      'relativeHumidity2m': relativeHumidity2m,
      'precipitation': precipitation,
      'windSpeed10m': windSpeed10m,
      'time': time.millisecondsSinceEpoch,
    };
  }
}

/// Daily forecast metrics for rice farming from Open-Meteo API
class DailyForecast {
  final DateTime date;
  final int? weatherCode;
  final double precipitationSum;
  final double? precipitationProbabilityMax;
  final double temperature2mMax;
  final double temperature2mMin;
  final double? relativeHumidity2mMean;
  final double? windSpeed10mMax;
  final double et0FaoEvapotranspiration;

  DailyForecast({
    required this.date,
    this.weatherCode,
    required this.precipitationSum,
    this.precipitationProbabilityMax,
    required this.temperature2mMax,
    required this.temperature2mMin,
    this.relativeHumidity2mMean,
    this.windSpeed10mMax,
    required this.et0FaoEvapotranspiration,
  });

  factory DailyForecast.fromMap(Map<String, dynamic> map) {
    return DailyForecast(
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
      weatherCode: (map['weatherCode'] as num?)?.toInt(),
      precipitationSum: (map['precipitationSum'] ?? 0.0).toDouble(),
      precipitationProbabilityMax:
          (map['precipitationProbabilityMax'] as num?)?.toDouble(),
      temperature2mMax: (map['temperature2mMax'] ?? 0.0).toDouble(),
      temperature2mMin: (map['temperature2mMin'] ?? 0.0).toDouble(),
      relativeHumidity2mMean:
          (map['relativeHumidity2mMean'] as num?)?.toDouble(),
      windSpeed10mMax: (map['windSpeed10mMax'] as num?)?.toDouble(),
      et0FaoEvapotranspiration: (map['et0FaoEvapotranspiration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'weatherCode': weatherCode,
      'precipitationSum': precipitationSum,
      'precipitationProbabilityMax': precipitationProbabilityMax,
      'temperature2mMax': temperature2mMax,
      'temperature2mMin': temperature2mMin,
      'relativeHumidity2mMean': relativeHumidity2mMean,
      'windSpeed10mMax': windSpeed10mMax,
      'et0FaoEvapotranspiration': et0FaoEvapotranspiration,
    };
  }

  String get rainPrediction {
    if (precipitationSum > 10.0) return 'Heavy Rain Expected';
    if (precipitationSum > 2.0) return 'Moderate Rain';
    if (precipitationSum > 0.1) return 'Light Rain Showers';
    return 'No Rain Expected';
  }
}

/// Maps Open-Meteo WMO weather codes to human-readable conditions and
/// OpenWeather-style icon codes. This is a code lookup, not a forecast source.
class WeatherCodeMapper {
  WeatherCodeMapper._();

  static String conditionFor(int? code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
        return 'Foggy';
      case 48:
        return 'Rime Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
        return 'Light Rain';
      case 63:
        return 'Rain';
      case 65:
        return 'Heavy Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow Grains';
      case 80:
        return 'Light Rain Showers';
      case 81:
        return 'Rain Showers';
      case 82:
        return 'Violent Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with Hail';
      default:
        return 'Clear/Cloudy';
    }
  }

  static String iconFor(int? code) {
    switch (code) {
      case 0:
      case 1:
        return '01d';
      case 2:
        return '02d';
      case 3:
        return '03d';
      case 45:
      case 48:
        return '50d';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return '09d';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return '10d';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '13d';
      case 95:
      case 96:
      case 99:
        return '11d';
      default:
        return '02d';
    }
  }
}

/// Top-level Open-Meteo Weather Response Model
class WeatherResponse {
  final double latitude;
  final double longitude;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final DateTime timestamp;

  WeatherResponse({
    required this.latitude,
    required this.longitude,
    required this.current,
    required this.daily,
    required this.timestamp,
  });

  factory WeatherResponse.fromOpenMeteoJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num? ?? 0.0).toDouble();
    final lon = (json['longitude'] as num? ?? 0.0).toDouble();

    final currentJson = json['current'] as Map<String, dynamic>? ?? {};
    final currentWeather = CurrentWeather.fromOpenMeteoJson(currentJson);

    final dailyList = <DailyForecast>[];
    final dailyJson = json['daily'] as Map<String, dynamic>?;

    if (dailyJson != null && dailyJson['time'] is List) {
      final times = dailyJson['time'] as List;
      final weatherCodes = (dailyJson['weather_code'] as List?) ?? [];
      final precips = (dailyJson['precipitation_sum'] as List?) ?? [];
      final precipProbs = (dailyJson['precipitation_probability_max'] as List?) ?? [];
      final maxTemps = (dailyJson['temperature_2m_max'] as List?) ?? [];
      final minTemps = (dailyJson['temperature_2m_min'] as List?) ?? [];
      final humidities = (dailyJson['relative_humidity_2m_mean'] as List?) ?? [];
      final windSpeeds = (dailyJson['wind_speed_10m_max'] as List?) ?? [];
      final et0s = (dailyJson['et0_fao_evapotranspiration'] as List?) ?? [];

      for (int i = 0; i < times.length; i++) {
        final dateStr = times[i].toString();
        final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now().add(Duration(days: i));
        dailyList.add(DailyForecast(
          date: parsedDate,
          weatherCode: i < weatherCodes.length ? (weatherCodes[i] as num?)?.toInt() : null,
          precipitationSum: i < precips.length ? (precips[i] as num? ?? 0.0).toDouble() : 0.0,
          precipitationProbabilityMax:
              i < precipProbs.length ? (precipProbs[i] as num?)?.toDouble() : null,
          temperature2mMax: i < maxTemps.length ? (maxTemps[i] as num? ?? 0.0).toDouble() : 0.0,
          temperature2mMin: i < minTemps.length ? (minTemps[i] as num? ?? 0.0).toDouble() : 0.0,
          relativeHumidity2mMean:
              i < humidities.length ? (humidities[i] as num?)?.toDouble() : null,
          windSpeed10mMax: i < windSpeeds.length ? (windSpeeds[i] as num?)?.toDouble() : null,
          et0FaoEvapotranspiration: i < et0s.length ? (et0s[i] as num? ?? 0.0).toDouble() : 0.0,
        ));
      }
    }

    return WeatherResponse(
      latitude: lat,
      longitude: lon,
      current: currentWeather,
      daily: dailyList,
      timestamp: DateTime.now(),
    );
  }

  factory WeatherResponse.fromMap(Map<String, dynamic> map) {
    return WeatherResponse(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      current: CurrentWeather.fromMap(map['current'] as Map<String, dynamic>? ?? {}),
      daily: ((map['daily'] as List?) ?? [])
          .map((item) => DailyForecast.fromMap(item as Map<String, dynamic>))
          .toList(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'current': current.toMap(),
      'daily': daily.map((d) => d.toMap()).toList(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Rice Farming Recommendation Engine
  List<String> get riceFarmingAdvice {
    final advice = <String>[];

    final maxDailyPrecip = daily.isNotEmpty
        ? daily.map((d) => d.precipitationSum).reduce((a, b) => a > b ? a : b)
        : current.precipitation;

    final maxDailyEt0 = daily.isNotEmpty
        ? daily.map((d) => d.et0FaoEvapotranspiration).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final maxTemp = daily.isNotEmpty
        ? daily.map((d) => d.temperature2mMax).reduce((a, b) => a > b ? a : b)
        : current.temperature2m;

    // 1. Rainfall evaluation
    if (current.precipitation > 5.0 || maxDailyPrecip > 15.0) {
      advice.add('Heavy rainfall expected. Avoid irrigation and monitor field drainage.');
    } else if (current.precipitation > 0.5 || maxDailyPrecip > 3.0) {
      advice.add('Moderate rain expected. Delay unnecessary watering.');
    }

    // 2. Temperature evaluation
    if (current.temperature2m > 33.0 || maxTemp > 34.0) {
      advice.add('High temperature detected. Monitor water level to reduce crop heat stress.');
    }

    // 3. Evapotranspiration evaluation
    if (maxDailyEt0 > 5.0) {
      advice.add('High water loss detected (${maxDailyEt0.toStringAsFixed(1)} mm/day ET0). Consider adjusting irrigation.');
    }

    // 4. Relative humidity evaluation
    if (current.relativeHumidity2m > 85.0) {
      advice.add('High humidity detected (${current.relativeHumidity2m.toStringAsFixed(0)}%). Monitor rice leaves for fungal diseases.');
    }

    // 5. Wind speed evaluation
    if (current.windSpeed10m > 20.0) {
      advice.add('Strong wind detected (${current.windSpeed10m.toStringAsFixed(0)} km/h). Postpone chemical spraying.');
    }

    // 6. Normal condition
    if (advice.isEmpty) {
      advice.add('Weather conditions are suitable for healthy rice growth.');
      advice.add('Good day for field inspection and crop maintenance.');
    }

    return advice;
  }
}
