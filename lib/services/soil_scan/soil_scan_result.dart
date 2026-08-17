/// Pure data types used by the Soil Sensor Screen Scanner.
///
/// These types deliberately avoid Flutter/plugin dependencies so the
/// recognition and mapping logic can be unit tested in isolation.
library;

/// Axis-aligned bounding box in image pixel coordinates.
class ScanBox {
  const ScanBox(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  double get area => width * height;

  bool overlapsX(ScanBox other) => left < other.right && right > other.left;

  /// Vertical gap between this box and [other] (0 when they overlap).
  double verticalGapTo(ScanBox other) {
    if (top < other.bottom && bottom > other.top) return 0;
    if (bottom <= other.top) return other.top - bottom;
    return top - other.bottom;
  }

  /// Horizontal gap between this box and [other] (0 when they overlap).
  double horizontalGapTo(ScanBox other) {
    if (left < other.right && right > other.left) return 0;
    if (right <= other.left) return other.left - right;
    return left - other.right;
  }
}

/// A single line of text recognized by the OCR engine.
class RecognizedLine {
  const RecognizedLine(this.text, this.box);

  final String text;
  final ScanBox box;
}

/// The measurements the scanner extracts from the sensor display.
enum SoilScanField {
  fertility,
  moisture,
  ph,
  temperature,
  sunlight,
  humidity,
  nitrogen,
  phosphorus,
  potassium,
  electricalConductivity;

  String get label => switch (this) {
        SoilScanField.fertility => 'Fertility (EC)',
        SoilScanField.moisture => 'Moisture',
        SoilScanField.ph => 'pH Level',
        SoilScanField.temperature => 'Temperature',
        SoilScanField.sunlight => 'Sunlight',
        SoilScanField.humidity => 'Air Humidity',
        SoilScanField.nitrogen => 'Nitrogen (N)',
        SoilScanField.phosphorus => 'Phosphorus (P)',
        SoilScanField.potassium => 'Potassium (K)',
        SoilScanField.electricalConductivity => 'Electrical Conductivity',
      };
}

/// How confident the scanner is in a detected value.
enum ScanDetectionStatus { detected, lowConfidence, missing }

/// A detected (or missing) value for a single measurement field.
class SoilScanValue {
  const SoilScanValue({
    required this.field,
    this.value,
    this.unit = '',
    this.confidence = 0,
    this.status = ScanDetectionStatus.missing,
    this.raw = '',
  });

  final SoilScanField field;

  /// The numeric reading exactly as extracted (never silently corrected).
  final double? value;

  /// Preserved display unit, e.g. `µS/cm`, `%`, `°C`, `°F`, `LUX`.
  final String unit;

  /// Heuristic confidence in the range 0..1.
  final double confidence;

  final ScanDetectionStatus status;

  /// The raw OCR text the value was parsed from (for the farmer's reference).
  final String raw;

  bool get hasValue => value != null && status != ScanDetectionStatus.missing;
}

/// Outcome of a full scan + recognition pass.
class SoilScanResult {
  const SoilScanResult({required this.values, required this.lines});

  final List<SoilScanValue> values;
  final List<RecognizedLine> lines;

  SoilScanValue? valueFor(SoilScanField field) {
    for (final v in values) {
      if (v.field == field) return v;
    }
    return null;
  }

  bool get hasAnyValue => values.any((v) => v.hasValue);

  int get detectedCount => values.where((v) => v.hasValue).length;
}

/// Errors the scanner can surface to the UI.
enum SoilScanError {
  /// OCR is not available on this platform (e.g. web).
  unavailable,

  /// The captured image could not be decoded.
  invalidImage,

  /// No sensor display was found in the capture.
  displayNotFound,

  /// Text was found but no usable readings could be extracted.
  ocrFailed,
}

class SoilScanException implements Exception {
  const SoilScanException(this.error);

  final SoilScanError error;

  @override
  String toString() => 'SoilScanException($error)';
}
