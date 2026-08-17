import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarming/services/tflite_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List modelBytes;
  late Uint8List labelsBytes;

  setUpAll(() async {
    modelBytes = File('assets/models/model_unquant.tflite').readAsBytesSync();
    labelsBytes = File('assets/models/labels.txt').readAsBytesSync();
  });

  test('parses bundled model input/output tensors', () {
    final summary = TfliteValidator.parseSummary(modelBytes);
    expect(summary, isNotNull);
    expect(summary!.inputShape, [1, 224, 224, 3]);
    expect(summary.outputShape, [1, 5]);
    expect(summary.inputType, 0); // FLOAT32
    expect(summary.inputSize, 224);
    expect(summary.classCount, 5);
    expect(summary.isFloat32Input, isTrue);
    expect(summary.isCompatibleSquareInput, isTrue);
  });

  test('bundled model passes full validation checklist', () {
    final checks = TfliteValidator.validate(
      modelBytes: modelBytes,
      labelsBytes: labelsBytes,
      fileName: 'model.tflite',
      version: 'v1.0',
    );
    final failed = checks.where((c) => !c.pass).toList();
    expect(failed, isEmpty, reason: failed.map((c) => '${c.name}: ${c.detail}').join('\n'));
  });

  test('garbage bytes do not parse', () {
    final garbage = Uint8List.fromList(List.generate(64, (i) => i));
    expect(TfliteValidator.parseSummary(garbage), isNull);
  });

  test('invalid version is rejected', () {
    final checks = TfliteValidator.validate(
      modelBytes: modelBytes,
      labelsBytes: labelsBytes,
      fileName: 'model.tflite',
      version: '1.0',
    );
    expect(checks.lastWhere((c) => c.name == 'Model version is valid').pass, isFalse);
  });

  test('wrong extension is rejected', () {
    final checks = TfliteValidator.validate(
      modelBytes: modelBytes,
      labelsBytes: labelsBytes,
      fileName: 'model.bin',
      version: 'v1.0',
    );
    expect(checks.firstWhere((c) => c.name == 'File extension is .tflite').pass, isFalse);
  });
}
