import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;
import 'firebase_config_stub.dart' as configs;

FirebaseOptions getMobilePlatform() {
  if (Platform.isAndroid) {
    return configs.android;
  } else if (Platform.isIOS) {
    return configs.ios;
  } else {
    return configs.web;
  }
}
