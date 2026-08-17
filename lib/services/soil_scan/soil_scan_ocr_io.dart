import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'soil_scan_result.dart';

/// On-device text recognition powered by Google ML Kit.
///
/// Mobile-only (Android / iOS / macOS). This file is never compiled into the
/// web build thanks to the conditional import in `soil_scan_ocr.dart`.
class SoilScanOcr {
  SoilScanOcr()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<List<RecognizedLine>> recognize(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw const SoilScanException(SoilScanError.invalidImage);
    }

    final inputImage = InputImage.fromBitmap(
      bitmap: image.getBytes(order: img.ChannelOrder.rgba),
      width: image.width,
      height: image.height,
    );

    final recognized = await _recognizer.processImage(inputImage);
    final lines = <RecognizedLine>[];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        final text = line.text.trim();
        if (text.isEmpty) continue;
        lines.add(RecognizedLine(
          text,
          ScanBox(box.left, box.top, box.width, box.height),
        ));
      }
    }
    return lines;
  }

  void dispose() {
    _recognizer.close();
  }
}
