import 'dart:typed_data';

/// Result of a single validation rule.
class ValidationCheck {
  final String name;
  final bool pass;
  final String detail;

  const ValidationCheck({
    required this.name,
    required this.pass,
    required this.detail,
  });
}

/// Summary parsed from a TFLite flatbuffer.
class TfliteModelSummary {
  final List<int> inputShape;
  final List<int> outputShape;
  final int inputType;
  final int outputType;


  TfliteModelSummary({
    required this.inputShape,
    required this.outputShape,
    required this.inputType,
    required this.outputType,
  });

  int get inputSize => inputShape.length == 4 ? inputShape[1] : 0;
  int get classCount => outputShape.length == 2 ? outputShape[1] : 0;

  bool get isFloat32Input => inputType == 0;
  bool get isCompatibleSquareInput =>
      inputShape.length == 4 &&
      inputShape[0] == 1 &&
      inputShape[3] == 3 &&
      inputShape[1] == inputShape[2] &&
      inputShape[1] >= 32 &&
      inputShape[1] <= 512;
}

/// Pure-Dart inspection of a TensorFlow Lite file.
///
/// TFLite uses Google FlatBuffers. We walk only the tables we need
/// (Model -> SubGraph -> Tensor) to read input/output shapes and dtypes.
/// This runs on any platform (including the web Admin Panel) without
/// native TensorFlow bindings.
class TfliteValidator {
  static const int maxModelBytes = 50 * 1024 * 1024; // 50 MB
  static const String tfliteMagic = 'TFL3';

  /// Parses a TFLite model's input/output tensor metadata. Returns null when
  /// the file is not a readable TFLite flatbuffer.
  static TfliteModelSummary? parseSummary(Uint8List bytes) {
    try {
      final r = _FbReader(bytes);
      if (bytes.length < 12) return null;
      final root = r.u32(0);
      if (root >= bytes.length) return null;
      // The root Model table must expose a subgraphs vector (field 2;
      // field 4 is `buffers`).
      if (!r.hasField(root, 2)) return null;

      final subgraphsVec = r.field(root, 2);
      if (subgraphsVec == null || r.vectorLength(subgraphsVec) < 1) return null;
      final subgraph = r.vectorElemTable(subgraphsVec, 0);
      if (subgraph == null) return null;

      final tensorsVec = r.field(subgraph, 0);
      final inputsVec = r.field(subgraph, 1);
      final outputsVec = r.field(subgraph, 2);
      if (tensorsVec == null || inputsVec == null || outputsVec == null) {
        return null;
      }
      if (r.vectorLength(inputsVec) < 1 || r.vectorLength(outputsVec) < 1) {
        return null;
      }

      final inputTensor = r.vectorElemTable(tensorsVec, r.vectorI32(inputsVec, 0));
      final outputTensor = r.vectorElemTable(tensorsVec, r.vectorI32(outputsVec, 0));
      if (inputTensor == null || outputTensor == null) return null;

      final inputShape = _readShape(r, inputTensor);
      final outputShape = _readShape(r, outputTensor);
      // Tensor.type defaults to FLOAT32 (0) when the field is omitted.
      final inputRaw = r.fieldRaw(inputTensor, 1);
      final outputRaw = r.fieldRaw(outputTensor, 1);
      final inputType = inputRaw == null ? 0 : r.u8(inputRaw);
      final outputType = outputRaw == null ? 0 : r.u8(outputRaw);

      if (inputShape.isEmpty || outputShape.isEmpty) return null;

      return TfliteModelSummary(
        inputShape: inputShape,
        outputShape: outputShape,
        inputType: inputType,
        outputType: outputType,
      );
    } catch (_) {
      return null;
    }
  }

  static List<int> _readShape(_FbReader r, int tensorTable) {
    final shapeVec = r.field(tensorTable, 0);
    if (shapeVec == null) return const [];
    final len = r.vectorLength(shapeVec);
    if (len <= 0 || len > 8) return const [];
    return [for (var i = 0; i < len; i++) r.vectorI32(shapeVec, i)];
  }

  /// Runs the full pre-deploy validation checklist (spec section 9).
  static List<ValidationCheck> validate({
    required Uint8List modelBytes,
    required Uint8List labelsBytes,
    required String fileName,
    required String version,
  }) {
    final checks = <ValidationCheck>[];

    void add(String name, bool pass, String detail) {
      checks.add(ValidationCheck(name: name, pass: pass, detail: detail));
    }

    // 1. File exists / not empty.
    add('Model file present', modelBytes.isNotEmpty,
        modelBytes.isEmpty ? 'File is empty.' : 'File received (${_kb(modelBytes.length)}).');

    // 2. Extension.
    final extOk = fileName.toLowerCase().endsWith('.tflite');
    add('File extension is .tflite', extOk,
        extOk ? fileName : 'Expected .tflite, got "$fileName".');

    // 3. Size limit.
    final sizeOk = modelBytes.length <= maxModelBytes;
    add('Model file size within limit (≤ 50 MB)', sizeOk,
        sizeOk ? '${_kb(modelBytes.length)}' : '${_kb(modelBytes.length)} exceeds the 50 MB limit.');

    // 4. Flatbuffer magic "TFL3".
    final magicOk = modelBytes.length >= 8 &&
        String.fromCharCodes(modelBytes.sublist(4, 8)) == tfliteMagic;
    add('TFLite format recognized', magicOk,
        magicOk ? 'Flatbuffer identifier "TFL3" found.' : 'Not a TensorFlow Lite file.');

    // 5. Model can be loaded / parsed.
    final summary = parseSummary(modelBytes);
    add('Model can be loaded', summary != null,
        summary != null
            ? 'Input ${summary!.inputShape} -> Output ${summary.outputShape}.'
            : 'Could not read model tensors.');

    if (summary == null) return checks;

    // 6. Input tensor exists (implied by parse) and is compatible.
    final inputOk = summary.isCompatibleSquareInput;
    add('Input shape compatible with Android detector',
        inputOk,
        inputOk
            ? '${summary.inputShape} (${summary.inputSize}×${summary.inputSize} RGB).'
            : 'Input ${summary.inputShape} is not a 1×H×W×3 square tensor.');

    // 7. Input datatype supported (the Android detector feeds float [0,1]).
    final typeOk = summary.isFloat32Input;
    add('Input datatype supported (float32)',
        typeOk,
        typeOk
            ? 'FLOAT32 as required by the Android detector.'
            : 'Type ${_typeName(summary.inputType)}. Quantized models are not supported by the current detector.');

    // 8. Output shape [1, N].
    final outShapeOk = summary.outputShape.length == 2 && summary.outputShape[0] == 1;
    add('Output shape valid', outShapeOk,
        outShapeOk
            ? '${summary.outputShape}'
            : 'Expected [1, N] class scores, got ${summary.outputShape}.');

    // 9. Labels file readable.
    final labelsText = _decodeUtf8(labelsBytes);
    final labelsOk = labelsText != null && labelsText.trim().isNotEmpty;
    add('Labels file readable', labelsOk,
        labelsOk ? 'labels.txt parsed (${_countLabels(labelsText!)} labels).' : 'labels.txt could not be read.');

    // 10. Labels not duplicated.
    final dupes = _duplicateLabels(labelsText);
    add('Labels are not duplicated', dupes.isEmpty,
        dupes.isEmpty ? 'No duplicate labels.' : 'Duplicate labels: ${dupes.join(', ')}.');

    // 11. Label count matches model outputs.
    final countOk = labelsText != null && _countLabels(labelsText) == summary.classCount;
    add('Number of labels matches model outputs',
        countOk,
        countOk
            ? '${summary.classCount} labels = ${summary.classCount} classes.'
            : 'labels.txt has ${_countLabels(labelsText ?? '')} labels but the model outputs ${summary.classCount}.');

    // 12. Model version valid.
    final versionOk = RegExp(r'^v\d+\.\d+$').hasMatch(version.trim());
    add('Model version is valid', versionOk,
        versionOk ? version.trim() : 'Version must look like "v1.3" (got "$version").');

    return checks;
  }

  static bool get allPass => false; // helper marker, not used

  static int _countLabels(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).length;

  static List<String> _duplicateLabels(String? text) {
    if (text == null) return const [];
    final seen = <String>{};
    final dupes = <String>[];
    for (final line in text.split('\n')) {
      final label = line.trim();
      if (label.isEmpty) continue;
      if (!seen.add(label)) dupes.add(label);
    }
    return dupes.toSet().toList();
  }

  static String? _decodeUtf8(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _kb(int b) => '${(b / 1024).toStringAsFixed(1)} KB';

  static String _typeName(int type) {
    switch (type) {
      case 0:
        return 'FLOAT32';
      case 1:
        return 'FLOAT16';
      case 2:
        return 'INT32';
      case 3:
        return 'UINT8';
      case 9:
        return 'INT8';
      default:
        return 'type $type';
    }
  }
}

/// Minimal FlatBuffers reader (little-endian) for the TFLite schema.
///
/// Supports both the standard 2-byte vtable soffset and the 4-byte signed
/// soffset emitted by some TFLite converters (including this repo's bundled
/// `model_unquant.tflite`), where vtables may be referenced in either
/// direction. All reads are bounds-checked so malformed files yield null
/// rather than throwing.
class _FbReader {
  final Uint8List bytes;

  _FbReader(this.bytes);

  int get length => bytes.length;

  bool _inBounds(int pos, int size) => pos >= 0 && pos + size <= bytes.length;

  int u8(int pos) => _inBounds(pos, 1) ? bytes[pos] : 0;

  int u16(int pos) =>
      _inBounds(pos, 2) ? bytes[pos] | (bytes[pos + 1] << 8) : 0;

  int u32(int pos) =>
      _inBounds(pos, 4)
          ? bytes[pos] |
              (bytes[pos + 1] << 8) |
              (bytes[pos + 2] << 16) |
              (bytes[pos + 3] << 24)
          : 0;

  int i32(int pos) {
    final v = u32(pos);
    return v >= 0x80000000 ? v - 0x100000000 : v;
  }

  /// Position of the object (vector / table / string) referenced by
  /// [fieldIndex] of the table at [tablePos], or null when absent/invalid.
  int? field(int tablePos, int fieldIndex) {
    final valuePos = _fieldValuePos(tablePos, fieldIndex);
    if (valuePos == null) return null;
    final target = valuePos + u32(valuePos);
    return _inBounds(target, 1) ? target : null;
  }

  /// Raw position of [fieldIndex]'s stored value, for inline fields such as
  /// the Tensor `type` enum. Returns null when the field is absent.
  int? fieldRaw(int tablePos, int fieldIndex) =>
      _fieldValuePos(tablePos, fieldIndex);

  bool hasField(int tablePos, int fieldIndex) =>
      _fieldValuePos(tablePos, fieldIndex) != null;

  int? _fieldValuePos(int tablePos, int fieldIndex) {
    final vt = _vtable(tablePos);
    if (vt == null) return null;
    final vtSize = u16(vt);
    if (vtSize < 4 + (fieldIndex + 1) * 2) return null;
    final voffset = u16(vt + 4 + fieldIndex * 2);
    if (voffset == 0) return null;
    final valuePos = tablePos + voffset;
    return _inBounds(valuePos, 1) ? valuePos : null;
  }

  int vectorLength(int vectorPos) =>
      _inBounds(vectorPos, 4) ? u32(vectorPos) : 0;

  /// Absolute position of element [index] of a vector of tables.
  int? vectorElemTable(int vectorPos, int index) {
    final elemPos = vectorPos + 4 + index * 4;
    if (!_inBounds(elemPos, 4)) return null;
    final table = elemPos + u32(elemPos);
    return _inBounds(table, 1) ? table : null;
  }

  int vectorI32(int vectorPos, int index) => i32(vectorPos + 4 + index * 4);

  /// Resolves a table's vtable position, trying the 4-byte signed soffset
  /// first and falling back to the standard 2-byte soffset.
  int? _vtable(int tablePos) {
    if (!_inBounds(tablePos, 4)) return null;
    final candidates = <int>{};
    final soff32 = i32(tablePos);
    if (soff32 != 0) candidates.add(tablePos - soff32);
    final soff16 = u16(tablePos);
    if (soff16 != 0) candidates.add(tablePos - soff16);
    for (final vt in candidates) {
      if (_validVtable(vt)) return vt;
    }
    return null;
  }

  bool _validVtable(int vt) {
    if (!_inBounds(vt, 4)) return false;
    final vtSize = u16(vt);
    if (vtSize < 4 || vtSize > 4096) return false;
    final objSize = u16(vt + 2);
    if (objSize < 4 || objSize > 4096) return false;
    return _inBounds(vt, vtSize);
  }
}
