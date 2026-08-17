import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/firebase_config.dart';
import 'services/local_storage_service.dart';
import 'app/admin_web_app.dart';

/// Admin dashboard entry point. Run with: flutter run -t lib/main_admin.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );

  await Hive.initFlutter();
  await LocalStorageService.init();

  runApp(const AdminWebApp());
}

