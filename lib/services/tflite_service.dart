// Conditional import: use mobile implementation on mobile platforms, stub on web
// On web: imports tflite_service_stub.dart (throws UnsupportedError)
// On mobile (Android/iOS): imports tflite_service_io.dart (actual TFLite implementation)
export 'tflite_service_stub.dart' if (dart.library.io) 'tflite_service_io.dart';
