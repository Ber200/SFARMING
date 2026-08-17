import 'package:flutter/material.dart';
import '../../models/treatment_model.dart';

// Farmer (mobile only)
import '../../screens/splash/farmer_splash_screen.dart';
import '../../screens/auth/farmer_login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/mobile/dashboard_screen.dart';
import '../../screens/mobile/detection/detection_screen.dart';
import '../../screens/mobile/detection/detection_history_screen.dart';
import '../../screens/mobile/detection/farmer_map_screen.dart';
import '../../screens/mobile/treatment/treatment_calendar_screen.dart';
import '../../screens/mobile/treatment/add_treatment_screen.dart';
import '../../screens/mobile/treatment/complete_treatment_photo_screen.dart';
import '../../screens/mobile/soil/soil_monitoring_screen.dart';
import '../../screens/mobile/soil/soil_scan_camera_screen.dart';
import '../../screens/mobile/weather/weather_screen.dart';
import '../../screens/mobile/reports/reports_screen.dart';
import '../../screens/mobile/profile/profile_screen.dart';
import '../../screens/mobile/detection/camera_detection_screen.dart';
import '../../screens/mobile/detection/realtime_scan_screen.dart';
import '../../screens/mobile/weather/weather_details_screen.dart';
import '../../screens/mobile/ai/ai_assistant_screen.dart';

// Admin (web only)
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_login_screen.dart';
import '../../screens/admin/farmer_management_screen.dart';
import '../../screens/admin/detection_records_screen.dart';
import '../../screens/admin/admin_profile_screen.dart';
import '../../screens/admin/admin_calendar_screen.dart';
import '../../screens/admin/admin_soil_weather_screen.dart';
import '../../screens/admin/admin_archive_screen.dart';
import '../../screens/admin/admin_treatment_list_screen.dart';
import '../../screens/admin/admin_map_screen.dart';
import '../../screens/admin/admin_model_trainer_screen.dart';
import '../../screens/admin/admin_announcement_screen.dart';
import '../../widgets/admin_route_guard.dart';
import '../../screens/mobile/treatment/farmer_archive_screen.dart';
import '../../screens/splash/admin_splash_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Farmer routes (mobile only)
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String detection = '/detection';
  static const String detectionHistory = '/detection-history';
  static const String treatmentCalendar = '/treatment-calendar';
  static const String addTreatment = '/add-treatment';
  static const String completeTreatmentPhoto = '/complete-treatment-photo';
  static const String soilMonitoring = '/soil-monitoring';
  static const String soilScanCamera = '/soil-scan-camera';
  static const String weather = '/weather';
  static const String reports = '/reports';
  static const String profile = '/profile';
  static const String cameraDetection = '/camera-detection';
  static const String realTimeScan = '/realtime-scan';
  static const String weatherDetails = '/weather-details';
  static const String myLocations = '/my-locations';
  static const String aiAssistant = '/ai-assistant';

  // Admin routes (web only)
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';
  static const String farmerManagement = '/farmer-management';
  static const String detectionRecords = '/detection-records';
  static const String adminProfile = '/admin-profile';
  static const String adminCalendar = '/admin-calendar';
  static const String adminSoilWeather = '/admin-soil-weather';
  static const String adminArchive = '/admin-archive';
  static const String adminPendingList = '/admin-pending-list';
  static const String adminUpcomingList = '/admin-upcoming-list';
  static const String adminMap = '/admin-map';
  static const String adminModelTrainer = '/admin-model-trainer';
  static const String adminAnnouncement = '/admin-announcement';

  // Farmer routes
  static const String farmerArchive = '/farmer-archive';

  /// Farmer-only routes (mobile app)
  static Map<String, WidgetBuilder> get farmerRoutes {
    return {
      splash: (context) => FarmerSplashScreen(),
      login: (context) => FarmerLoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      dashboard: (context) => const DashboardScreen(),
      detection: (context) => const DetectionScreen(),
      detectionHistory: (context) => const DetectionHistoryScreen(),
      treatmentCalendar: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return TreatmentCalendarScreen(
          highlightTreatmentId: args is String ? args : null,
        );
      },
      addTreatment: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return AddTreatmentScreen(
          preFilledDisease: args is String ? args : null,
        );
      },
      completeTreatmentPhoto: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as TreatmentModel;
        return CompleteTreatmentPhotoScreen(treatment: args);
      },
      soilMonitoring: (context) => const SoilMonitoringScreen(),
      soilScanCamera: (context) => const SoilScanCameraScreen(),
      weather: (context) => const WeatherScreen(),
      reports: (context) => const ReportsScreen(),
      profile: (context) => const ProfileScreen(),
      cameraDetection: (context) => const CameraDetectionScreen(),
      realTimeScan: (context) => const RealTimeScanScreen(),
      weatherDetails: (context) => const WeatherDetailsScreen(),
      myLocations: (context) => const FarmerMapScreen(),
      aiAssistant: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return AiAssistantScreen(disease: args is String ? args : null);
      },
      farmerArchive: (context) => const FarmerArchiveScreen(),
    };
  }

  /// Admin-only routes (web dashboard)
  static Map<String, WidgetBuilder> get adminWebRoutes {
    return {
      splash: (context) => AdminSplashScreen(),
      adminLogin: (context) => AdminLoginScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      adminDashboard: (context) => const AdminRouteGuard(child: AdminDashboardScreen()),
      farmerManagement: (context) => const AdminRouteGuard(child: FarmerManagementScreen()),
      detectionRecords: (context) => const AdminRouteGuard(child: DetectionRecordsScreen()),
      adminProfile: (context) => const AdminRouteGuard(child: AdminProfileScreen()),
      adminCalendar: (context) => const AdminRouteGuard(child: AdminCalendarScreen()),
      adminSoilWeather: (context) => const AdminRouteGuard(child: AdminSoilWeatherScreen()),
      adminArchive: (context) => const AdminRouteGuard(child: AdminArchiveScreen()),
      adminPendingList: (context) => const AdminRouteGuard(child: AdminTreatmentListScreen(
        mode: TreatmentListMode.pending,
      )),
      adminUpcomingList: (context) => const AdminRouteGuard(child: AdminTreatmentListScreen(
        mode: TreatmentListMode.upcoming,
      )),
      adminMap: (context) => const AdminRouteGuard(child: AdminMapScreen()),
      adminModelTrainer: (context) => const AdminRouteGuard(child: AdminModelTrainerScreen()),
      adminAnnouncement: (context) => const AdminRouteGuard(child: AdminAnnouncementScreen()),
    };
  }
}
