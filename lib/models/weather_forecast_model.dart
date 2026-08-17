import 'package:flutter/material.dart';

/// Forecast model representing a single day's weather outlook.
class WeatherForecastModel {
  final DateTime date;
  final double temperature; // Average temp
  final double minTemperature;
  final double maxTemperature;
  final double humidity;
  final String condition;
  final double? windSpeed; // km/h
  final double? precipitation; // mm
  final double? rainProbability; // 0-100%
  final String description;
  final String? icon;

  WeatherForecastModel({
    required this.date,
    required this.temperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.humidity,
    required this.condition,
    this.windSpeed,
    this.precipitation,
    this.rainProbability,
    required this.description,
    this.icon,
  });

  factory WeatherForecastModel.fromMap(Map<String, dynamic> map) {
    return WeatherForecastModel(
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      minTemperature: (map['minTemperature'] ?? (map['temperature'] ?? 0.0)).toDouble(),
      maxTemperature: (map['maxTemperature'] ?? (map['temperature'] ?? 0.0)).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      condition: map['condition'] ?? 'unknown',
      windSpeed: map['windSpeed'] != null ? (map['windSpeed'] as num).toDouble() : null,
      precipitation: map['precipitation'] != null ? (map['precipitation'] as num).toDouble() : null,
      rainProbability: map['rainProbability'] != null ? (map['rainProbability'] as num).toDouble() : null,
      description: map['description'] ?? '',
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'temperature': temperature,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'humidity': humidity,
      'condition': condition,
      'windSpeed': windSpeed,
      'precipitation': precipitation,
      'rainProbability': rainProbability,
      'description': description,
      'icon': icon,
    };
  }

  String get status {
    if (rainProbability != null && rainProbability! > 60) return 'BAD';
    if (windSpeed != null && windSpeed! > 20.0) return 'WARNING';
    return 'GOOD';
  }

  Color get statusColor {
    switch (status) {
      case 'BAD':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

/// Forecast model representing a single hour's weather outlook.
class HourlyForecastModel {
  final DateTime time;
  final double temperature;
  final double humidity;
  final String condition;
  final double? windSpeed; // km/h
  final double? precipitation; // mm
  final double? rainProbability; // 0-100%
  final String description;
  final String? icon;

  HourlyForecastModel({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.condition,
    this.windSpeed,
    this.precipitation,
    this.rainProbability,
    required this.description,
    this.icon,
  });

  factory HourlyForecastModel.fromMap(Map<String, dynamic> map) {
    return HourlyForecastModel(
      time: map['time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['time'])
          : DateTime.now(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      condition: map['condition'] ?? 'unknown',
      windSpeed: map['windSpeed'] != null ? (map['windSpeed'] as num).toDouble() : null,
      precipitation: map['precipitation'] != null ? (map['precipitation'] as num).toDouble() : null,
      rainProbability: map['rainProbability'] != null ? (map['rainProbability'] as num).toDouble() : null,
      description: map['description'] ?? '',
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time.millisecondsSinceEpoch,
      'temperature': temperature,
      'humidity': humidity,
      'condition': condition,
      'windSpeed': windSpeed,
      'precipitation': precipitation,
      'rainProbability': rainProbability,
      'description': description,
      'icon': icon,
    };
  }
}
