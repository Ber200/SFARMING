import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_config_stub.dart' as configs;
import 'firebase_config_io.dart' if (dart.library.html) 'firebase_config_stub.dart' as platform;

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return configs.web;
    }
    
    // Use platform-specific implementation
    return platform.getMobilePlatform();
  }

  static FirebaseOptions get android => configs.android;
  static FirebaseOptions get ios => configs.ios;
  static FirebaseOptions get web => configs.web;
}
