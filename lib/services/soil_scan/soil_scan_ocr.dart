/// Conditional export so the mobile-only ML Kit implementation is never
/// compiled into the web build. On web, `SoilScanOcr` surfaces the
/// `SoilScanError.unavailable` error.
library;

export 'soil_scan_ocr_io.dart'
    if (dart.library.js_interop) 'soil_scan_ocr_stub.dart';
