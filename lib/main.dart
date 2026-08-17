import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/config/firebase_config.dart';
import 'app/farmer_app.dart';
import 'app/admin_web_app.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );

  await Hive.initFlutter();
  await LocalStorageService.init();

  // Set up push + local notifications (idempotent, safe on web/admin).
  await NotificationService().initialize();

  // Override Flutter's default red error box to prevent red translucent overlays on physical devices.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF5FAF7),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 36),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Main app is Farmer. Admin only on web at /admin or ?app=admin
  final isAdminRoute = kIsWeb &&
      (Uri.base.path.contains('admin') ||
          Uri.base.queryParameters['app'] == 'admin');

  runApp(isAdminRoute ? const AdminWebApp() : const FarmerApp());
}
