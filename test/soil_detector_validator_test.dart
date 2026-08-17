import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smartfarming/services/soil_scan/soil_detector_validator.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_result.dart';

RecognizedLine _line(String text) {
  return RecognizedLine(text, const ScanBox(0, 0, 100, 30));
}

void main() {
  const validator = SoilDetectorValidator();

  group('SoilDetectorValidator Tests', () {
    test('validates device when recognized lines contain device keywords', () {
      final lines = [
        _line('INTELLIGENT SOIL DETECTOR'),
        _line('Fertility 80 uS/cm'),
        _line('Moisture 45 %'),
        _line('pH 7.0'),
        _line('Temp 88.8 °F'),
        _line('Sun light 925 Lux'),
        _line('Humidity 58 %'),
      ];

      final image = img.Image(width: 100, height: 100);
      final result = validator.validate(image: image, recognizedLines: lines);

      expect(result.isValidDevice, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(0.90));
    });

    test('validates device when green LCD screen color signature is detected', () {
      // Create image with green LCD backlit pixels
      final image = img.Image(width: 50, height: 50);
      for (var y = 0; y < 50; y++) {
        for (var x = 0; x < 50; x++) {
          image.setPixelRgb(x, y, 40, 180, 50); // Bright green LCD backlight
        }
      }

      final lines = [
        _line('7.0'),
        _line('88.8'),
      ];

      final result = validator.validate(image: image, recognizedLines: lines);

      expect(result.isValidDevice, isTrue);
      expect(result.colorAnalysis.isLcdColorMatched, isTrue);
    });

    test('rejects invalid inputs like faces, leaves, or arbitrary text without device signature', () {
      // Plain grey image
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(120, 120, 120));

      final lines = [
        _line('Chapter 1: The Great Gatsby'),
        _line('Page 45 of 200'),
      ];

      final result = validator.validate(image: image, recognizedLines: lines);

      expect(result.isValidDevice, isFalse);
      expect(result.confidence, lessThan(0.50));
    });

    test('rejects empty inputs', () {
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(30, 30, 30));

      final result = validator.validate(image: image, recognizedLines: const []);

      expect(result.isValidDevice, isFalse);
    });
  });
}
