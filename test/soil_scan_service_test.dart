import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smartfarming/core/routes/app_routes.dart';
import 'package:smartfarming/models/soil_data_model.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_field_mapper.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_ocr.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_processor.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_result.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_validator.dart';

RecognizedLine _line(String text, double x, double y,
    {double w = 150, double h = 30}) {
  return RecognizedLine(text, ScanBox(x, y, w, h));
}

void main() {
  final mapper = SoilScanFieldMapper();
  const imageWidth = 800.0;
  const imageHeight = 600.0;

  group('SoilScanFieldMapper (scanfarm.md §6 field mapping)', () {
    test('maps label+value lines to all six fields with correct units', () {
      final lines = [
        _line('Fertility 8 µS/cm', 50, 50),
        _line('Moisture 8 %', 50, 150),
        _line('pH 7.7', 50, 250),
        _line('Temp 88 °F', 50, 350),
        _line('Sunlight 888 LUX', 50, 450),
        _line('Humidity 36 %', 50, 550),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.hasAnyValue, isTrue);
      expect(result.detectedCount, 6);

      final fertility = result.valueFor(SoilScanField.fertility)!;
      expect(fertility.value, 8);
      expect(fertility.unit, 'µS/cm');
      expect(fertility.status, ScanDetectionStatus.detected);

      final moisture = result.valueFor(SoilScanField.moisture)!;
      expect(moisture.value, 8);
      expect(moisture.unit, '%');

      final ph = result.valueFor(SoilScanField.ph)!;
      expect(ph.value, 7.7);
      expect(ph.unit, '');

      final temperature = result.valueFor(SoilScanField.temperature)!;
      expect(temperature.value, 88);
      expect(temperature.unit, '°F');

      final sunlight = result.valueFor(SoilScanField.sunlight)!;
      expect(sunlight.value, 888);
      expect(sunlight.unit, 'LUX');

      final humidity = result.valueFor(SoilScanField.humidity)!;
      expect(humidity.value, 36);
      expect(humidity.unit, '%');
    });

    test('maps label on its own line to the nearest value line', () {
      final lines = [
        _line('Fertility', 50, 50),
        _line('8 µS/cm', 250, 50),
        _line('Moisture', 50, 150),
        _line('8 %', 250, 150),
        _line('pH', 50, 250),
        _line('7.7', 250, 250),
        _line('Temp', 50, 350),
        _line('88 °F', 250, 350),
        _line('Sunlight', 50, 450),
        _line('888 LUX', 250, 450),
        _line('Humidity', 50, 550),
        _line('36 %', 250, 550),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.detectedCount, 6);
      expect(result.valueFor(SoilScanField.fertility)!.value, 8);
      expect(result.valueFor(SoilScanField.ph)!.value, 7.7);
      expect(result.valueFor(SoilScanField.temperature)!.unit, '°F');
      expect(result.valueFor(SoilScanField.sunlight)!.unit, 'LUX');
      expect(result.valueFor(SoilScanField.humidity)!.value, 36);
    });

    test('falls back to row-layout assignment with low confidence', () {
      final lines = [
        _line('8 µS/cm', 200, 50),
        _line('8 %', 200, 150),
        _line('7.7', 200, 250),
        _line('88 °F', 200, 350),
        _line('888 LUX', 200, 450),
        _line('36 %', 200, 550),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.detectedCount, 6);
      final fertility = result.valueFor(SoilScanField.fertility)!;
      expect(fertility.value, 8);
      expect(fertility.unit, 'µS/cm');
      expect(fertility.status, ScanDetectionStatus.lowConfidence);
      expect(fertility.confidence, 0.5);
      expect(result.valueFor(SoilScanField.humidity)!.value, 36);
    });

    test('keeps partial results and marks missing fields', () {
      final lines = [
        _line('Fertility 8 µS/cm', 50, 50),
        _line('Humidity 36 %', 50, 550),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.detectedCount, 2);
      expect(result.valueFor(SoilScanField.moisture)!.hasValue, isFalse);
      expect(result.valueFor(SoilScanField.ph)!.status, ScanDetectionStatus.missing);
      expect(result.valueFor(SoilScanField.moisture)!.value, isNull);
    });

    test('never silently modifies the detected reading', () {
      final lines = [
        _line('Humidity 36 %', 50, 50),
        _line('pH 6.5', 50, 150),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.valueFor(SoilScanField.humidity)!.value, 36);
      expect(result.valueFor(SoilScanField.ph)!.value, 6.5);
    });

    test('merges label and value tokens like PH7.7', () {
      final lines = [
        _line('Fertility 8 µS/cm', 50, 50),
        _line('PH7.7', 50, 150),
        _line('Temp 88 °F', 50, 250),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.valueFor(SoilScanField.ph)!.value, 7.7);
      expect(result.valueFor(SoilScanField.ph)!.hasValue, isTrue);
    });

    test('detects °C temperature unit', () {
      final lines = [
        _line('Temp 31 °C', 50, 50),
      ];

      final result = mapper.mapLines(lines,
          imageWidth: imageWidth, imageHeight: imageHeight);

      expect(result.valueFor(SoilScanField.temperature)!.value, 31);
      expect(result.valueFor(SoilScanField.temperature)!.unit, '°C');
    });
  });

  group('SoilScanValidator (scanfarm.md §9 validation)', () {
    test('rejects out-of-range pH, moisture, humidity', () {
      expect(validatePh('15'), isNotNull);
      expect(validatePh('-1'), isNotNull);
      expect(validatePh('7.7'), isNull);
      expect(validateMoisture('150'), isNotNull);
      expect(validateMoisture('82'), isNull);
      expect(validateHumidity('-5'), isNotNull);
      expect(validateHumidity('36'), isNull);
    });

    test('rejects non-numeric input', () {
      expect(validateFertility('abc'), isNotNull);
      expect(validateSunlight('high'), isNotNull);
      expect(validateTemperature('warm', '°C'), isNotNull);
    });

    test('allows empty fields (not provided)', () {
      expect(validatePh(''), isNull);
      expect(validateMoisture('  '), isNull);
      expect(validateFertility(null), isNull);
    });

    test('validates temperature by unit', () {
      expect(validateTemperature('31', '°C'), isNull);
      expect(validateTemperature('88', '°F'), isNull);
      expect(validateTemperature('88', '°C'), isNotNull);
      expect(validateTemperature('31', '°F'), isNotNull);
    });

    test('warns but does not block unusual readings', () {
      expect(warningForTemperature(88, '°C'), isNotNull);
      expect(warningForTemperature(31, '°C'), isNull);
      expect(warningForFertility(2000), isNotNull);
      expect(warningForFertility(8), isNull);
    });
  });

  group('SoilDataModel (scanfarm.md §14 storage)', () {
    test('round-trips sensor scan fields through toMap/fromMap', () {
      final model = SoilDataModel(
        userId: 'farmer_1',
        ph: 7.7,
        moisture: 8,
        humidity: 36,
        fertility: 8,
        temperature: 88,
        temperatureUnit: '°F',
        sunlight: 888,
        source: 'sensor_scan',
        scanImage: 'https://example.com/scan.jpg',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1755000000000),
      );

      final restored = SoilDataModel.fromMap(model.toMap());

      expect(restored.fertility, 8);
      expect(restored.temperature, 88);
      expect(restored.temperatureUnit, '°F');
      expect(restored.sunlight, 888);
      expect(restored.source, 'sensor_scan');
      expect(restored.scanImage, 'https://example.com/scan.jpg');
      expect(restored.ph, 7.7);
    });
  });

  group('SoilScanProcessor (scanfarm.md §4/§5 pipeline)', () {
    test('preprocesses an image and maps the recognized lines', () async {
      final base = img.Image(width: 200, height: 300);
      img.fill(base, color: img.ColorRgb8(120, 120, 120));
      final bytes = Uint8List.fromList(img.encodeJpg(base, quality: 90));

      final lines = [
        _line('Fertility 8 µS/cm', 20, 20),
        _line('Moisture 8 %', 20, 60),
        _line('pH 7.7', 20, 100),
        _line('Temp 88 °F', 20, 140),
        _line('Sunlight 888 LUX', 20, 180),
        _line('Humidity 36 %', 20, 220),
      ];

      final processor = SoilScanProcessor(ocr: _FakeOcr(lines), enableOnlineAi: false);
      final result = await processor.process(bytes);

      expect(result.hasAnyValue, isTrue);
      expect(result.detectedCount, 6);
      expect(result.valueFor(SoilScanField.temperature)!.unit, '°F');
      expect(result.valueFor(SoilScanField.sunlight)!.value, 888);
    });

    test('throws displayNotFound when nothing is recognized', () async {
      final base = img.Image(width: 200, height: 300);
      img.fill(base, color: img.ColorRgb8(120, 120, 120));
      final bytes = Uint8List.fromList(img.encodeJpg(base, quality: 90));

      final processor = SoilScanProcessor(ocr: _FakeOcr(const []), enableOnlineAi: false);

      expect(
        () => processor.process(bytes),
        throwsA(isA<SoilScanException>()
            .having((e) => e.error, 'error', SoilScanError.displayNotFound)),
      );
    });

    test('uses the framed region when preview geometry is provided', () async {
      final base = img.Image(width: 200, height: 300);
      img.fill(base, color: img.ColorRgb8(120, 120, 120));
      final bytes = Uint8List.fromList(img.encodeJpg(base, quality: 90));

      final lines = [
        _line('Fertility 8 µS/cm', 30, 30),
        _line('Moisture 8 %', 30, 70),
        _line('pH 7.7', 30, 110),
        _line('Temp 88 °F', 30, 150),
        _line('Sunlight 888 LUX', 30, 190),
        _line('Humidity 36 %', 30, 230),
      ];

      final processor = SoilScanProcessor(ocr: _FakeOcr(lines), enableOnlineAi: false);
      final result = await processor.process(
        bytes,
        previewSize: const Size(200, 300),
        frame: const Rect.fromLTWH(40, 60, 120, 180),
      );

      expect(result.hasAnyValue, isTrue);
      expect(result.detectedCount, 6);
      expect(result.valueFor(SoilScanField.temperature)!.unit, '°F');
    });

    test('throws invalidImage for garbage bytes', () async {
      final processor = SoilScanProcessor(ocr: _FakeOcr(const []), enableOnlineAi: false);

      expect(
        () => processor.process(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<SoilScanException>()
            .having((e) => e.error, 'error', SoilScanError.invalidImage)),
      );
    });
  });

  group('Route registration (scanfarm.md §19 flow)', () {
    test('registers the soil scan camera route for farmers', () {
      expect(AppRoutes.farmerRoutes.containsKey(AppRoutes.soilScanCamera), isTrue);
      expect(AppRoutes.farmerRoutes[AppRoutes.soilScanCamera], isNotNull);
    });
  });
}

class _FakeOcr implements SoilScanOcr {
  _FakeOcr(this.output);

  final List<RecognizedLine> output;

  @override
  Future<List<RecognizedLine>> recognize(Uint8List imageBytes) async => output;

  @override
  void dispose() {}
}
