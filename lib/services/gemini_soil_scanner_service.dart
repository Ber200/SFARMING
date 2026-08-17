import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';
import 'soil_scan/soil_scan_result.dart';

/// Gemini Vision AI service for extracting soil sensor screen measurements.
///
/// Accepts raw device photo bytes, sends them to Gemini Vision REST API as base64,
/// and parses the structured JSON extraction response.
class GeminiSoilScannerService {
  const GeminiSoilScannerService();

  static const String _systemPrompt = '''
You are the dedicated computer vision and OCR extraction system for the physical "Intelligent Soil Detector" handheld agricultural meter in the SMARTFARMING system.

SUPPORTED DEVICE SPECIFICATIONS:
- Device Name: "Intelligent Soil Detector" (black handheld body with probe attachment).
- Screen: Distinctive green backlit LCD display in upper-middle portion.
- Buttons: 3 physical buttons below LCD ("ON/OFF", "Measure", "°C/°F").
- Screen Layout:
  * Top Group ("Soil"):
    - Fertility: [value] µS/cm
    - Moisture: [value] %
    - PH: [value] (e.g. 7.0, 6.5, 7.80)
    - Temp: [value] °F or °C
  * Bottom Group ("Environment"):
    - Sun light: [value] Lux
    - Humidity: [value] %

DEVICE DETECTION & VALIDATION:
1. First, determine if the image actually contains the supported Intelligent Soil Detector or its LCD screen.
2. If the image is a human face, a plant leaf, bare soil without the meter, a random object, a phone screenshot, or an unrelated meter, set "valid_device" to false and all readings to null.
3. Only set "valid_device" to true if the Intelligent Soil Detector or its LCD display is identifiable.

DATA EXTRACTION RULES:
1. Extract ONLY the real values visible on the LCD. Never invent, guess, or calculate values.
2. Preserve exact numbers and decimals (e.g. pH 7.0, temperature 88.8).
3. Accurately detect the temperature unit shown (°C vs °F).
4. If any single value is obscured or unreadable, return null for value and 0.0 for confidence for that specific field.
5. Return structured JSON only matching the schema below.

JSON SCHEMA TO RETURN:
{
  "valid_device": true,
  "overall_confidence": 0.95,
  "readings": {
    "fertility": {"value": 80.0, "unit": "µS/cm", "confidence": 0.95},
    "moisture": {"value": 45.0, "unit": "%", "confidence": 0.98},
    "ph": {"value": 7.0, "unit": "pH", "confidence": 0.92},
    "temperature": {"value": 88.8, "unit": "°F", "confidence": 0.95},
    "sunlight": {"value": 925.0, "unit": "LUX", "confidence": 0.90},
    "humidity": {"value": 58.0, "unit": "%", "confidence": 0.94},
    "electrical_conductivity": {"value": null, "unit": null, "confidence": 0.0},
    "nitrogen": {"value": null, "unit": null, "confidence": 0.0},
    "phosphorus": {"value": null, "unit": null, "confidence": 0.0},
    "potassium": {"value": null, "unit": null, "confidence": 0.0}
  }
}
''';


  /// Sends the captured image bytes to Gemini Vision and parses the resulting scan.
  Future<SoilScanResult> analyzeImage(Uint8List imageBytes) async {
    if (!GeminiConfig.hasApiKey) {
      throw const SoilScanException(SoilScanError.unavailable);
    }

    final base64Image = base64Encode(imageBytes);
    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'Extract all readable sensor display values from this soil detector screen.'},
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      }
    };

    late http.Response response;
    try {
      response = await http
          .post(
            GeminiConfig.generateContentUri(),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': GeminiConfig.apiKey,
            },
            body: jsonEncode(payload),
          )
          .timeout(GeminiConfig.timeout);
    } on TimeoutException {
      throw const SoilScanException(SoilScanError.ocrFailed);
    } catch (_) {
      throw const SoilScanException(SoilScanError.ocrFailed);
    }

    if (response.statusCode != 200) {
      throw const SoilScanException(SoilScanError.ocrFailed);
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List? ?? [];
      final rawText = _extractTextFromCandidates(candidates);
      if (rawText == null || rawText.trim().isEmpty) {
        throw const SoilScanException(SoilScanError.ocrFailed);
      }
      return _parseJsonResult(rawText);
    } catch (e) {
      if (e is SoilScanException) rethrow;
      throw const SoilScanException(SoilScanError.ocrFailed);
    }
  }

  String? _extractTextFromCandidates(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final content = (candidate as Map<String, dynamic>)['content'];
      if (content is Map<String, dynamic>) {
        final parts = content['parts'] as List? ?? [];
        for (final part in parts) {
          final text = (part as Map<String, dynamic>)['text'];
          if (text is String && text.isNotEmpty) return text;
        }
      }
    }
    return null;
  }

  SoilScanResult _parseJsonResult(String rawJson) {
    final cleaned = _cleanJsonString(rawJson);
    final Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw const SoilScanException(SoilScanError.ocrFailed);
    }

    final validDevice = jsonMap['valid_device'] == true;
    if (!validDevice) {
      throw const SoilScanException(SoilScanError.displayNotFound);
    }

    final readings = jsonMap['readings'] as Map<String, dynamic>? ?? {};
    final values = <SoilScanValue>[];

    void parseField(SoilScanField field, String jsonKey) {
      final item = readings[jsonKey] as Map<String, dynamic>?;
      if (item == null) {
        values.add(SoilScanValue(
          field: field,
          status: ScanDetectionStatus.missing,
        ));
        return;
      }

      final rawVal = item['value'];
      final double? numVal = rawVal != null ? (rawVal as num).toDouble() : null;
      final String unit = item['unit'] as String? ?? '';
      final double confidence = (item['confidence'] as num?)?.toDouble() ?? 0.0;

      ScanDetectionStatus status;
      if (numVal == null) {
        status = ScanDetectionStatus.missing;
      } else if (confidence >= 0.75) {
        status = ScanDetectionStatus.detected;
      } else {
        status = ScanDetectionStatus.lowConfidence;
      }

      values.add(SoilScanValue(
        field: field,
        value: numVal,
        unit: unit,
        confidence: confidence,
        status: status,
        raw: numVal != null ? '$numVal $unit' : '',
      ));
    }

    parseField(SoilScanField.fertility, 'fertility');
    parseField(SoilScanField.moisture, 'moisture');
    parseField(SoilScanField.ph, 'ph');
    parseField(SoilScanField.temperature, 'temperature');
    parseField(SoilScanField.sunlight, 'sunlight');
    parseField(SoilScanField.humidity, 'humidity');
    parseField(SoilScanField.nitrogen, 'nitrogen');
    parseField(SoilScanField.phosphorus, 'phosphorus');
    parseField(SoilScanField.potassium, 'potassium');
    parseField(SoilScanField.electricalConductivity, 'electrical_conductivity');

    return SoilScanResult(
      values: values,
      lines: const [],
    );
  }

  String _cleanJsonString(String raw) {
    var trimmed = raw.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = fence.firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();
    return trimmed;
  }
}
