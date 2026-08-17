import 'soil_scan_result.dart';

/// Maps recognized text lines from the physical Intelligent Soil Detector LCD screen
/// to the six known measurement fields using visual labels and geometry:
///
/// Top Group ("Soil"):
/// - Fertility (µS/cm)
/// - Moisture (%)
/// - pH Level
/// - Temperature (°C or °F)
///
/// Bottom Group ("Environment"):
/// - Sunlight (Lux)
/// - Humidity (%)
class SoilScanFieldMapper {
  /// Aliases (alphanumeric-normalized) used to identify each field's label.
  static const Map<SoilScanField, List<String>> _labelAliases = {
    SoilScanField.fertility: [
      'fertility',
      'fertile',
      'fert',
      'soilfertility',
      'ec',
      'us/cm',
      'uscm',
    ],
    SoilScanField.moisture: [
      'moisture',
      'moist',
      'soilmoisture',
    ],
    SoilScanField.ph: [
      'ph',
      'phvalue',
      'phlevel',
      'soilph',
    ],
    SoilScanField.temperature: [
      'temperature',
      'temperatur',
      'temp',
      'soiltemp',
    ],
    SoilScanField.sunlight: [
      'sunlight',
      'sun light',
      'sun',
      'solar',
      'lightintensity',
      'lux',
      'environment',
    ],
    SoilScanField.humidity: [
      'humidity',
      'humi',
      'hum',
      'airhumidity',
    ],
  };

  /// Expected top-to-bottom layout of the device screen:
  /// Group 1 (Soil): Fertility, Moisture, pH, Temperature
  /// Group 2 (Environment): Sunlight, Humidity
  static const List<SoilScanField> _layoutOrder = [
    SoilScanField.fertility,
    SoilScanField.moisture,
    SoilScanField.ph,
    SoilScanField.temperature,
    SoilScanField.sunlight,
    SoilScanField.humidity,
  ];

  static final RegExp _numberPattern = RegExp(r'-?\d+(?:\.\d+)?');

  SoilScanResult mapLines(
    List<RecognizedLine> lines, {
    required double imageWidth,
    required double imageHeight,
  }) {
    final labeled = <SoilScanField, _Candidate>{};
    final valueOnlyLines = <RecognizedLine>[];

    for (final line in lines) {
      final field = _labelField(line.text);
      if (field != null) {
        labeled[field] = _extractCandidate(line, field);
      } else if (containsNumber(line.text)) {
        valueOnlyLines.add(line);
      }
    }

    final values = <SoilScanValue>[];
    final usedValueLines = <RecognizedLine>{};

    // Pass 1: fields whose label and value were recognized together or near each other
    for (final field in _layoutOrder) {
      final cand = labeled[field];
      if (cand == null) continue;

      if (cand.value != null) {
        values.add(SoilScanValue(
          field: field,
          value: cand.value,
          unit: cand.unit,
          confidence: cand.confidence,
          status: cand.confidence < 0.7
              ? ScanDetectionStatus.lowConfidence
              : ScanDetectionStatus.detected,
          raw: cand.raw,
        ));
      } else {
        // Label on its own line -> find the nearest value-only line on the LCD
        final nearest = _nearestValueLine(
          cand.labelLine,
          valueOnlyLines.where((l) => !usedValueLines.contains(l)).toList(),
          imageWidth,
          imageHeight,
        );
        if (nearest != null) {
          usedValueLines.add(nearest);
          var value = _firstNumber(nearest.text);
          if (value != null && field == SoilScanField.ph && value > 14) {
            if (value >= 10 && value <= 140) {
              value = value / 10.0;
            } else if (value > 140 && value <= 1400) {
              value = value / 100.0;
            }
          }
          final unit = _detectUnit(nearest.text, field);
          final conf = unit.isEmpty ? 0.75 : 0.85;
          values.add(SoilScanValue(
            field: field,
            value: value,
            unit: unit,
            confidence: conf,
            status: conf < 0.7
                ? ScanDetectionStatus.lowConfidence
                : ScanDetectionStatus.detected,
            raw: '${cand.labelLine.text} -> ${nearest.text}',
          ));
        }
      }
    }

    // Pass 2: fields whose label was recognized but no value found yet
    final assignedFields = values.map((v) => v.field).toSet();
    for (final field in _layoutOrder) {
      if (assignedFields.contains(field)) continue;
      if (labeled.containsKey(field) && labeled[field]!.value == null) {
        values.add(SoilScanValue(field: field));
      }
    }

    // Pass 3: row-layout fallback when labels are unreadable but values are present
    final missing = _layoutOrder
        .where((f) => !values.any((v) => v.field == f))
        .toList();
    final remaining = valueOnlyLines
        .where((l) => !usedValueLines.contains(l))
        .toList();
    if (missing.length == remaining.length && missing.isNotEmpty) {
      remaining.sort((a, b) => a.box.centerY.compareTo(b.box.centerY));
      final fieldsByRow = [...missing]
        ..sort((a, b) =>
            _layoutOrder.indexOf(a).compareTo(_layoutOrder.indexOf(b)));
      for (var i = 0; i < remaining.length; i++) {
        final line = remaining[i];
        final field = fieldsByRow[i];
        var value = _firstNumber(line.text);
        if (value == null) continue;
        if (field == SoilScanField.ph && value > 14) {
          if (value >= 10 && value <= 140) {
            value = value / 10.0;
          } else if (value > 140 && value <= 1400) {
            value = value / 100.0;
          }
        }
        final unit = _detectUnit(line.text, field);
        values.add(SoilScanValue(
          field: field,
          value: value,
          unit: unit,
          confidence: 0.5,
          status: ScanDetectionStatus.lowConfidence,
          raw: line.text,
        ));
      }
    }

    // Pass 4: add missing placeholders for fields never detected
    final finalFields = values.map((v) => v.field).toSet();
    for (final field in _layoutOrder) {
      if (!finalFields.contains(field)) {
        values.add(SoilScanValue(field: field));
      }
    }

    values.sort((a, b) =>
        _layoutOrder.indexOf(a.field).compareTo(_layoutOrder.indexOf(b.field)));

    return SoilScanResult(values: values, lines: lines);
  }

  /// Returns the field whose label matches this line's text, if any.
  SoilScanField? _labelField(String text) {
    final norm = _alnumNorm(text);
    for (final entry in _labelAliases.entries) {
      for (final alias in entry.value) {
        if (norm == alias) return entry.key;
        if (norm.length > alias.length &&
            norm.startsWith(alias) &&
            containsNumber(text)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Builds a candidate from a line that contains a recognized label.
  _Candidate _extractCandidate(RecognizedLine line, SoilScanField field) {
    final tokens =
        line.text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    // Case A: label and value merged on one line, e.g. "Fertility 80 µS/cm" or "pH 7.0".
    var value = _firstNumber(line.text);
    var fromMergedToken = false;

    if (value == null) {
      // Case B: label merged directly into value token, e.g. "PH7.0" / "TEMP88.8".
      final merged = tokens.where((t) {
        final tn = _alnumNorm(t);
        return _labelAliases[field]!
            .any((a) => tn.startsWith(a) && tn.length > a.length);
      }).toList();
      if (merged.isNotEmpty) {
        value = _firstNumber(merged.first);
        fromMergedToken = true;
      }
    }

    if (value != null) {
      // Handle missing decimal point in pH if OCR merged digits (e.g. 70 -> 7.0, 780 -> 7.80)
      if (field == SoilScanField.ph && value > 14) {
        if (value >= 10 && value <= 140) {
          value = value / 10.0;
        } else if (value > 140 && value <= 1400) {
          value = value / 100.0;
        }
      }

      final unit = _detectUnit(line.text, field);
      var confidence = unit.isEmpty ? 0.85 : 0.95;
      if (fromMergedToken) confidence = 0.75;
      return _Candidate(
        field: field,
        labelLine: line,
        value: value,
        unit: unit,
        confidence: confidence,
        raw: line.text,
      );
    }

    // Case C: label alone; the value lives on a nearby line.
    return _Candidate(field: field, labelLine: line);
  }

  RecognizedLine? _nearestValueLine(
    RecognizedLine labelLine,
    List<RecognizedLine> candidates,
    double imageWidth,
    double imageHeight,
  ) {
    RecognizedLine? best;
    var bestScore = double.infinity;

    for (final cand in candidates) {
      if (cand == labelLine) continue;

      final verticalGap = labelLine.box.verticalGapTo(cand.box);
      if (verticalGap > imageHeight * 0.4) continue;

      var horizontalGap = labelLine.box.horizontalGapTo(cand.box);
      final toRight = cand.box.centerX >= labelLine.box.centerX;
      if (!toRight) horizontalGap *= 3;
      if (horizontalGap > imageWidth * 0.6) continue;

      final score = verticalGap + horizontalGap;
      if (score < bestScore) {
        bestScore = score;
        best = cand;
      }
    }
    return best;
  }

  /// Detects the display unit for [field] from surrounding text.
  String _detectUnit(String text, SoilScanField field) {
    final lower = text.toLowerCase();
    switch (field) {
      case SoilScanField.fertility:
      case SoilScanField.electricalConductivity:
        if (lower.contains('µs') ||
            lower.contains('us/') ||
            lower.contains('uscm') ||
            lower.contains('s/cm')) {
          return 'µS/cm';
        }
        return 'µS/cm';
      case SoilScanField.moisture:
      case SoilScanField.humidity:
        return '%';
      case SoilScanField.temperature:
        if (lower.contains('°f') || lower.contains('° f') || lower.contains('f')) return '°F';
        if (lower.contains('°c') || lower.contains('° c') || lower.contains('c')) return '°C';
        return '°C';
      case SoilScanField.sunlight:
        return 'LUX';
      case SoilScanField.ph:
        return '';
      case SoilScanField.nitrogen:

      case SoilScanField.phosphorus:
      case SoilScanField.potassium:
        return lower.contains('mg/kg') ? 'mg/kg' : (lower.contains('ppm') ? 'ppm' : '');
    }
  }

  static bool containsNumber(String text) =>
      _numberPattern.hasMatch(text);

  static double? _firstNumber(String text) {
    final match = _numberPattern.firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  /// Lowercases and keeps only [a-z0-9] for label matching.
  static String _alnumNorm(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().codeUnits) {
      final c = String.fromCharCode(rune);
      if ((c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) ||
          (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57)) {
        buffer.write(c);
      }
    }
    return buffer.toString();
  }
}

class _Candidate {
  _Candidate({
    required this.field,
    required this.labelLine,
    this.value,
    this.unit = '',
    this.confidence = 0,
    this.raw = '',
  });

  final SoilScanField field;
  final RecognizedLine labelLine;
  final double? value;
  final String unit;
  final double confidence;
  final String raw;
}
