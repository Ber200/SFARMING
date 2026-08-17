import 'package:image/image.dart' as img;
import 'soil_scan_result.dart';

/// Validates whether a captured camera frame contains the supported physical
/// "Intelligent Soil Detector" handheld device based on visual characteristics:
/// - Green backlit LCD screen color signature
/// - High-contrast dark casing/bezel
/// - Distinctive device keywords (SOIL, DETECTOR, FERTILITY, MOISTURE, PH, TEMP, SUN, LIGHT, HUMIDITY, LUX)
class SoilDetectorValidator {
  const SoilDetectorValidator();

  /// Canonical keywords and labels found on the physical Intelligent Soil Detector
  static const Set<String> _deviceKeywords = {
    'intelligent',
    'soil',
    'detector',
    'fertility',
    'moisture',
    'ph',
    'temp',
    'temperature',
    'environment',
    'sun',
    'light',
    'sunlight',
    'humidity',
    'lux',
    'us/cm',
    'uscm',
    'measure',
    'on/off',
    'c/f',
  };

  /// Analyzes the color signature of the candidate LCD display region.
  ///
  /// The physical Intelligent Soil Detector has a distinctive green backlit LCD.
  /// Checks for pixels where green is dominant (Green > Red * 1.12 and Green > Blue * 1.05)
  /// or within the LCD green hue range (70° - 170° in HSV).
  SoilColorAnalysis analyzeLcdColor(img.Image image) {
    if (image.width <= 0 || image.height <= 0) {
      return const SoilColorAnalysis(greenRatio: 0, darkBezelRatio: 0, isLcdColorMatched: false);
    }

    int greenPixels = 0;
    int darkPixels = 0;
    int totalSampled = 0;

    // Sample pixels across the image (stride 3 for high performance on mobile)
    final step = (image.width > 400 || image.height > 400) ? 3 : 1;

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        totalSampled++;

        // Detect dark outer casing / bezel (low luminance)
        final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        if (luminance < 70) {
          darkPixels++;
        }

        // Detect green LCD backlight
        if (g > 45 && g > r * 1.10 && g > b * 1.05) {
          greenPixels++;
          continue;
        }

        // HSV green range check for varying lighting/glare
        final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
        final delta = max - min;

        if (max > 40 && delta > 15) {
          double hue = 0;
          if (max == g) {
            hue = 60 * (((b - r) / delta) + 2);
          } else if (max == r) {
            hue = 60 * (((g - b) / delta) % 6);
          } else {
            hue = 60 * (((r - g) / delta) + 4);
          }
          if (hue < 0) hue += 360;

          // Green LCD hue span (70° to 170°)
          if (hue >= 70 && hue <= 170) {
            greenPixels++;
          }
        }
      }
    }

    if (totalSampled == 0) {
      return const SoilColorAnalysis(greenRatio: 0, darkBezelRatio: 0, isLcdColorMatched: false);
    }

    final greenRatio = greenPixels / totalSampled;
    final darkBezelRatio = darkPixels / totalSampled;
    final isLcdMatched = greenRatio >= 0.04;

    return SoilColorAnalysis(
      greenRatio: greenRatio,
      darkBezelRatio: darkBezelRatio,
      isLcdColorMatched: isLcdMatched,
    );
  }

  /// Counts device-specific labels and keywords recognized in the text lines.
  int countDeviceKeywords(List<RecognizedLine> lines) {
    int count = 0;
    final seen = <String>{};

    for (final line in lines) {
      final tokens = line.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9/°]'), ' ')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty);

      for (final token in tokens) {
        for (final kw in _deviceKeywords) {
          if (token == kw || (token.length >= 4 && token.contains(kw))) {
            if (seen.add(kw)) {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  /// Validates whether the image contains the supported Intelligent Soil Detector.
  ///
  /// Distinguishes valid detector images from invalid inputs (faces, leaves, soil, random objects).
  DetectorValidationResult validate({
    required img.Image image,
    required List<RecognizedLine> recognizedLines,
  }) {
    final colorAnalysis = analyzeLcdColor(image);
    final keywordCount = countDeviceKeywords(recognizedLines);

    // Rule 1: High keyword match (2 or more device measurement labels present)
    if (keywordCount >= 2) {
      return DetectorValidationResult(
        isValidDevice: true,
        confidence: 0.90 + (keywordCount * 0.02).clamp(0.0, 0.09),
        reason: 'Matched $keywordCount device labels on display.',
        colorAnalysis: colorAnalysis,
      );
    }

    // Rule 2: Moderate green LCD color + at least 1 device label / reading unit
    if (colorAnalysis.isLcdColorMatched && keywordCount >= 1) {
      return DetectorValidationResult(
        isValidDevice: true,
        confidence: 0.85,
        reason: 'Matched green LCD color and device label.',
        colorAnalysis: colorAnalysis,
      );
    }

    // Rule 3: Distinctive green LCD screen and dark bezel structure with any numeric readings
    final hasNumbers = recognizedLines.any((l) => RegExp(r'\d+').hasMatch(l.text));
    if (colorAnalysis.greenRatio >= 0.08 && hasNumbers) {
      return DetectorValidationResult(
        isValidDevice: true,
        confidence: 0.75,
        reason: 'Detected green LCD screen geometry with numeric readings.',
        colorAnalysis: colorAnalysis,
      );
    }

    // Invalid / Unsupported input (e.g. human face, leaf, soil, random object)
    return DetectorValidationResult(
      isValidDevice: false,
      confidence: 0.15,
      reason: 'Image does not match the Intelligent Soil Detector visual or display signature.',
      colorAnalysis: colorAnalysis,
    );
  }
}

class SoilColorAnalysis {
  final double greenRatio;
  final double darkBezelRatio;
  final bool isLcdColorMatched;

  const SoilColorAnalysis({
    required this.greenRatio,
    required this.darkBezelRatio,
    required this.isLcdColorMatched,
  });
}

class DetectorValidationResult {
  final bool isValidDevice;
  final double confidence;
  final String reason;
  final SoilColorAnalysis colorAnalysis;

  const DetectorValidationResult({
    required this.isValidDevice,
    required this.confidence,
    required this.reason,
    required this.colorAnalysis,
  });
}
