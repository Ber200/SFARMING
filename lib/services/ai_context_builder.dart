import '../models/detection_model.dart';
import '../models/soil_data_model.dart';
import '../models/treatment_model.dart';
import '../models/weather_model.dart';

/// Builds the prompts sent to Gemini so answers are grounded in the farmer's
/// own data and given in their language.
class AiContextBuilder {
  AiContextBuilder._();

  /// System instruction: makes the model behave as a concise, safety-aware
  /// rice-agronomy assistant that replies in the farmer's language.
  static String systemPrompt({
    required String languageCode,
    String? diseaseContext,
  }) {
    final langName = switch (languageCode) {
      'fil' => 'Filipino (Tagalog)',
      'ceb' => 'Cebuano (Bisaya)',
      _ => 'English',
    };
    final diseaseLine = (diseaseContext != null && diseaseContext.isNotEmpty)
        ? ' The farmer just scanned a rice leaf and the result was: $diseaseContext. '
            'Give practical advice specific to this condition.'
        : '';

    return 'You are AgriGuide, a friendly rice-farming assistant for smallholder '
        'farmers. Answer in $langName. Be concise and practical, using bullet '
        'points for lists of steps. Ground your advice in the farmer data '
        'provided below when relevant. Never state exact pesticide or fertilizer '
        'dosages as fact - always recommend checking with a local agronomist. '
        'Never give advice that could harm crops or people. If asked something '
        'unrelated to rice farming or agriculture, politely redirect back to '
        'farming topics.$diseaseLine';
  }

  /// A compact snapshot of the farmer's current data, rendered as plain text
  /// that the model can cite. Missing data is stated explicitly.
  static String farmSnapshot({
    List<DetectionModel>? detections,
    List<TreatmentModel>? treatments,
    SoilDataModel? soil,
    WeatherModel? weather,
    String? farmLocation,
  }) {
    final lines = <String>['FARMER DATA (current status):'];

    if (farmLocation != null && farmLocation.isNotEmpty) {
      lines.add('- Farm location: $farmLocation');
    }

    final rawDetections =
        (detections ?? const <DetectionModel>[]).where((d) => !d.isArchived).toList();
    if (rawDetections.isNotEmpty) {
      int healthy = 0, brownSpot = 0, sheathBlight = 0, bacterialLeafBlight = 0;
      for (final d in rawDetections) {
        final dLower = d.disease.toLowerCase();
        if (dLower.contains('healthy')) {
          healthy++;
        } else if (dLower.contains('brown')) {
          brownSpot++;
        } else if (dLower.contains('sheath')) {
          sheathBlight++;
        } else if (dLower.contains('bacterial') || dLower.contains('blight')) {
          bacterialLeafBlight++;
        }
      }
      lines.add('- Disease Detection Summary (${rawDetections.length} total active scans):');
      lines.add('  * Healthy: $healthy, Brown Spot: $brownSpot, Sheath Blight: $sheathBlight, Bacterial Leaf Blight: $bacterialLeafBlight');
      lines.add('- Recent scan records:');
      for (final d in rawDetections.take(5)) {
        final conf = (d.confidence * 100).toStringAsFixed(0);
        lines.add('  * ${d.disease} ($conf% confidence, ${_fmtDate(d.timestamp)})');
      }
    } else {
      lines.add('- Disease detections: none recorded');
    }


    final relevantTreatments =
        (treatments ?? const <TreatmentModel>[]).where((t) => !t.archived);
    if (relevantTreatments.isNotEmpty) {
      lines.add('- Treatments:');
      for (final t in relevantTreatments.take(5)) {
        final remedy = (t.remedy != null && t.remedy!.isNotEmpty)
            ? ' | remedy: ${t.remedy}'
            : '';
        lines.add(
          '  * ${t.disease} (${t.type}, status: ${t.status}, '
          'scheduled: ${_fmtDate(t.scheduleDate)})$remedy',
        );
      }
    } else {
      lines.add('- Treatments: none scheduled');
    }

    if (soil != null) {
      final parts = <String>[
        if (soil.ph != null) 'pH ${soil.ph!.toStringAsFixed(1)}',
        if (soil.moisture != null) 'moisture ${soil.moisture!.toStringAsFixed(0)}%',
        if (soil.humidity != null) 'humidity ${soil.humidity!.toStringAsFixed(0)}%',
      ];
      lines.add(parts.isNotEmpty
          ? '- Latest soil readings: ${parts.join(', ')}'
          : '- Latest soil readings: no values recorded');
    } else {
      lines.add('- Latest soil readings: not available');
    }

    if (weather != null) {
      lines.add(
        '- Current weather: ${weather.temperature.toStringAsFixed(1)}C, '
        'humidity ${weather.humidity.toStringAsFixed(0)}%, wind '
        '${weather.windSpeed.toStringAsFixed(1)} km/h, rain chance '
        '${weather.chanceOfRain.toStringAsFixed(0)}%',
      );
      if (weather.isRainy) {
        lines.add('  * Note: rain expected - consider postponing '
            'fertilizer or pesticide application.');
      }
    } else {
      lines.add('- Current weather: not available');
    }

    return lines.join('\n');
  }

  static String _fmtDate(DateTime? dt) {
    if (dt == null) return 'unknown date';
    final local = dt.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
