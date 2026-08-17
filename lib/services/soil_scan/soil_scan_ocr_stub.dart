import 'dart:typed_data';

import 'soil_scan_result.dart';

/// Web placeholder for the soil sensor scanner.
///
/// ML Kit text recognition does not support web, so on web the scanner
/// surfaces a graceful "available on the mobile app" message instead.
class SoilScanOcr {
  Future<List<RecognizedLine>> recognize(Uint8List imageBytes) async {
    throw const SoilScanException(SoilScanError.unavailable);
  }

  void dispose() {}
}
