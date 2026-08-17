/// Web-safe stub implementation of TFLiteService
/// TFLite is not available on web platform
/// 
/// Note: This stub uses dynamic types to avoid importing dart:io on web
class TFLiteService {

  Future<void> initialize() async {
    // On web, TFLite is not available
    throw UnsupportedError(
      'TFLite model inference is not supported on web platform. '
      'Please use the mobile app (Android/iOS) for disease detection.'
    );
  }

  Future<Map<String, dynamic>> predict(dynamic imageFile) async {
    throw UnsupportedError(
      'TFLite model inference is not supported on web platform. '
      'Please use the mobile app (Android/iOS) for disease detection.'
    );
  }

  void dispose() {
    // No-op on web
  }
}
