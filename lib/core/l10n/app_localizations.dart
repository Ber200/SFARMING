import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Ergonomic shorthand: context.l10n.welcome, context.l10n.translate(...)
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// App translations for English, Filipino/Tagalog, and Cebuano/Bisaya.
///
/// Architecture decisions:
/// - All strings live here, never in business logic or providers.
/// - Fallback chain: target language Ã¢â€ â€™ English Ã¢â€ â€™ raw key (never throws).
/// - Dynamic variables use {placeholder} syntax, resolved at call site.
/// - Pluralization uses a dedicated pluralize() method per language rules.
/// - Adding a new language = add one entry to _localizedValues + AppLanguage enum.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fil'),
    Locale('ceb'),
  ];

  // ---------------------------------------------------------------------------
  // Translation data Ã¢â‚¬â€ one map per language code.
  // Keys are snake_case strings. Values are translated strings.
  // Use {placeholder} for dynamic variables (e.g. 'Hello, {name}!').
  // ---------------------------------------------------------------------------
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Ã¢â€â‚¬Ã¢â€â‚¬ Common Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'welcome': 'Welcome',
      'cancel': 'Cancel',
      'save': 'Save',
      'ok': 'OK',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'loading': 'Loading...',
      'tap_for_details': 'Tap for details',
      'view_all': 'View All',
      'date': 'Date',
      'confidence': 'Confidence',
      'no_data': 'N/A',
      'error': 'Error',
      'retry': 'Retry',
      'success': 'Success',
      'unknown': 'Unknown',
      'none': 'None',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      'submit': 'Submit',
      'update': 'Update',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'refresh': 'Refresh',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Navigation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'dashboard': 'Dashboard',
      'schedule': 'Schedule',
      'reports': 'Reports',
      'profile': 'Profile',
      'scan': 'Scan',
      'history': 'History',
      'back': 'Back',
      'back_to_home': 'Back to Home',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Dashboard Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'detect_disease': 'Detect Disease',
      'latest_detection': 'Latest Detection',
      'next_treatment': 'Next Treatment',
      'total_detections': 'Total Detections',
      'pending_treatments': 'Pending Treatments',
      'soil_monitoring': 'Soil Monitoring',
      'weather': 'Weather',
      'no_detections_yet': 'No detections yet',
      'no_upcoming_treatments': 'No upcoming treatments',
      'good_morning': 'Good morning, {name}!',
      'good_afternoon': 'Good afternoon, {name}!',
      'good_evening': 'Good evening, {name}!',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Soil & Environment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'ph_level': 'pH Level',
      'moisture': 'Moisture',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'loading_weather': 'Loading weather...',
      'wind_speed': 'Wind Speed',
      'rainfall': 'Rainfall',
      'soil_status': 'Soil Status',
      'soil_healthy': 'Soil is healthy',
      'soil_needs_attention': 'Soil needs attention',
      'ph_optimal': 'pH is optimal ({value})',
      'ph_low': 'pH is too low ({value}) Ã¢â‚¬â€ consider liming',
      'ph_high': 'pH is too high ({value}) Ã¢â‚¬â€ consider acidifying',
      'moisture_optimal': 'Moisture is optimal ({value}%)',
      'moisture_low': 'Moisture is low ({value}%) Ã¢â‚¬â€ irrigate soon',
      'moisture_high': 'Moisture is high ({value}%) Ã¢â‚¬â€ check drainage',
      'last_updated': 'Last updated: {time}',
      'sensor_offline': 'Sensor offline',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Weather Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'feels_like': 'Feels like {temp}Ã‚Â°C',
      'forecast_days': '{count}-day forecast',
      'weather_alert': 'Weather Alert',
      'high_wind_warning': 'High wind warning: {speed} km/h',
      'heavy_rain_warning': 'Heavy rain expected: {amount} mm',
      'weather_unavailable': 'Weather data unavailable',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Profile Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'edit_profile': 'Edit Profile',
      'edit_profile_subtitle': 'Update your personal information',
      'farm_location': 'Farm Location',
      'not_set': 'Not set',
      'settings': 'Settings',
      'settings_subtitle': 'App preferences and notifications',
      'language': 'Language',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'select_language': 'Select Language',
      'farmer': 'Farmer',
      'account_created': 'Account created {date}',
      'total_farm_area': 'Total farm area: {area} ha',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Authentication Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'login': 'Login',
      'welcome_back': 'Welcome Back',
      'sign_in_to_continue': 'Sign in to continue',
      'email': 'Email',
      'password': 'Password',
      'dont_have_account': "Don't have an account?",
      'sign_up': 'Sign Up',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'password_reset_sent': 'Password reset email sent to {email}',
      'login_failed': 'Login failed: {reason}',
      'register_success': 'Account created successfully',
      'logout_success': 'You have been logged out',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Disease Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'detection': 'Detection',
      'take_photo': 'Take Photo',
      'choose_from_gallery': 'Choose from Gallery',
      'analyzing_image': 'Analyzing image...',
      'disease_detected': '{disease} detected',
      'no_disease_detected': 'No disease detected',
      'detection_confidence': 'Confidence: {value}%',
      'detection_result': 'Detection Result',
      'recommended_action': 'Recommended Action',
      'disease_description': 'About this disease',
      'severity_low': 'Low severity',
      'severity_medium': 'Medium severity',
      'severity_high': 'High severity',
      'detection_saved': 'Detection saved successfully',
      'detection_count': '{count} detection(s) recorded',

      'admin_dashboard': 'Admin Dashboard',
      'add_schedule_tooltip': 'Add schedule for all farmers',
      'assign_to': 'Assign to',
      'all_farmers': 'All Farmers',
      'specific_farmer': 'Specific Farmer',
      'status_cancelled': 'Cancelled',
      'notes': 'Notes',
      'remedy': 'Remedy',
      'type': 'Type',
      'no_treatments_for_date': 'No treatments for {date}',
      'no_treatments_yet': 'No treatments yet',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Treatment Calendar & Add Treatment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'treatment_schedule': 'Treatment Schedule',
      'return_home': 'Return to Home',
      'archived_records_tooltip': 'Archived Records',
      'add_treatment_tooltip': 'Add Treatment',
      'no_treatments_scheduled': 'No treatments scheduled for {date}',
      'notes_optional': 'Notes (Optional)',
      'add_notes_hint': 'Add any additional notes',
      'please_select_disease': 'Please select a disease',
      'please_sign_in': 'Please sign in to add treatments',
      'rain_warning': 'Rain Warning',
      'rain_warning_content': 'Rain is forecasted for the selected date. Do you want to continue?',
      'continue_text': 'Continue',
      'treatment_submitted_pending': 'Treatment submitted. Status: Pending Ã¢â‚¬â€œ awaiting admin approval.',
      'awaiting_admin_approval': 'Awaiting admin approval',
      'archive_confirm_title': 'Archive',
      'archive_confirm_message': 'Archive this {type} record for {disease}?',
      'archived_success': 'Archived',
      'failed_to_archive': 'Failed to archive',
      'failed_to_schedule': 'Failed to schedule treatment',
      'schedule_treatment': 'Schedule Treatment',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Camera & Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'camera_detection': 'Camera Detection',
      'take_photo_title': 'Take Photo',
      'user_not_authenticated': 'User not authenticated',
      'detection_failed': 'Detection failed',
      'camera_unavailable': 'Camera unavailable',
      'assign_to': 'Assign to',
      'all_farmers': 'All Farmers',
      'specific_farmer': 'Specific Farmer',
      'status_cancelled': 'Cancelled',
      'notes': 'Notes',
      'remedy': 'Remedy',
      'type': 'Type',
      'no_treatments_for_date': 'No treatments for {date}',
      'no_treatments_yet': 'No treatments yet',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Treatment Calendar & Add Treatment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'treatment_schedule': 'Treatment Schedule',
      'return_home': 'Return to Home',
      'archived_records_tooltip': 'Archived Records',
      'add_treatment_tooltip': 'Add Treatment',
      'no_treatments_scheduled': 'No treatments scheduled for {date}',
      'notes_optional': 'Notes (Optional)',
      'add_notes_hint': 'Add any additional notes',
      'please_select_disease': 'Please select a disease',
      'please_sign_in': 'Please sign in to add treatments',
      'rain_warning': 'Rain Warning',
      'rain_warning_content': 'Rain is forecasted for the selected date. Do you want to continue?',
      'continue_text': 'Continue',
      'treatment_submitted_pending': 'Treatment submitted. Status: Pending Ã¢â‚¬â€œ awaiting admin approval.',
      'awaiting_admin_approval': 'Awaiting admin approval',
      'archive_confirm_title': 'Archive',
      'archive_confirm_message': 'Archive this {type} record for {disease}?',
      'archived_success': 'Archived',
      'failed_to_archive': 'Failed to archive',
      'failed_to_schedule': 'Failed to schedule treatment',
      'schedule_treatment': 'Schedule Treatment',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Camera & Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'camera_detection': 'Camera Detection',
      'take_photo_title': 'Take Photo',
      'user_not_authenticated': 'User not authenticated',
      'detection_failed': 'Detection failed',
      'camera_unavailable': 'Camera unavailable',
      'camera_error_hint': 'The camera could not be accessed. This can happen if another app is using it, or on emulators without a camera.',
      'hold_steady': 'Hold Steady',
      'hold_steady_hint': 'Please hold your phone steady for better scanning.',
      'camera_unstable': 'Camera Unstable',
      'focusing_camera': 'Focusing camera...',
      'scanning': 'Scanning...',
      'use_gallery_instead': 'Use Gallery Instead',
      'processing_hint': 'Processing...',
      'camera_instruction': 'Position the rice leaf in the center and tap the camera button',
      'photo_proof': 'Photo Proof',
      'photo_proof_instruction': 'Take a real-time photo as proof of completion',
      'treatment_completed_photo': 'Treatment marked as completed with photo proof',
      'failed_to_complete': 'Failed to complete',
      'no_camera_found': 'No camera found',
      'error_taking_picture': 'Error taking picture: {error}',
      'error_generic': 'Error: {error}',
      'disease_detection': 'Disease Detection',
      'detect_rice_leaf_disease': 'Detect Rice Leaf Disease',
      'capture_select_hint': 'Capture or select an image of a rice leaf to detect diseases',
      'error_picking_image': 'Error picking image: {error}',
      'login_failed_simple': 'Login failed',

      // ---- Dashboard extras --------------------------------------
      'weather_offline': 'Weather data offline',

      // ---- AI Assistant (AgriGuide) ------------------------------
      'ai_chat_title': 'AI Farm Assistant',
      'ai_hint': 'Ask about your rice farm...',
      'ai_typing': 'AgriGuide is thinking...',
      'ai_clear_chat': 'Clear chat',
      'ai_clear_confirm': 'Clear this conversation?',
      'ai_clear_confirm_body': 'Your chat history with AgriGuide will be deleted.',
      'ai_retry': 'Retry',
      'ai_no_key': 'The AI assistant is not set up yet. Add your Gemini API key (--dart-define=GEMINI_API_KEY) and restart.',
      'ai_offline': 'You are offline. Connect to the internet to talk to AgriGuide.',
      'ai_error': 'Something went wrong with the AI assistant. Please try again.',
      'ai_timeout': 'AgriGuide took too long to respond. Please try again.',
      'ai_rate_limited': 'You reached the AI request limit. Please wait a moment and try again.',
      'ai_server_error': 'The AI service is temporarily unavailable. Please try again later.',
      'ai_welcome': 'Hi, I am AgriGuide AI, your rice farming assistant. Ask me about soil pH, moisture, pests, or irrigation and I will answer in your language.',
      'ai_soil_context': 'My farm readings just updated: pH {ph}, moisture {moisture}%, humidity {humidity}%. Please analyze these and give me recommendations.',
      'ai_soil_label': 'Soil analysis',
      'ai_chip_ph': 'How do I fix low soil pH?',
      'ai_chip_moisture': 'Best irrigation for dry soil?',
      'ai_chip_disease': 'How to prevent rice blast?',
      'ai_chip_fertilizer': 'When to apply fertilizer?',
      'ai_expand': 'Expand',
      'ai_close': 'Close',
      'ai_send': 'Send',
      'ai_ask_disease': 'Ask AI about {disease}',
      'ai_asking_about': 'Asking about: {disease}',
      'soil_scan': 'Soil Sensor Scanner',
      'scan_device': 'Scan Sensor',
      'capture_device_screen': 'Capture Device Screen',
      'analyzing_device': 'Analyzing Device...',
      'verify_sensor_data': 'Verify Sensor Data',
      'save_sensor_data': 'Save Sensor Data',
      'device_not_detected': 'Device Not Detected',
      'unable_to_read_device': 'Unable to read device screen',
      'retake_photo': 'Retake Photo',
      'confirm_sensor_data': 'Confirm Sensor Data',
      'ai_dashboard_title': 'Ask AI Assistant',
      'ai_dashboard_subtitle': 'Get instant advice on diseases, soil, and weather for your rice farm.',
    
      'no_pending_approvals': 'No pending approvals',
      'all_types': 'All types',
      'search_by_disease': 'Search by disease...',
      'please_enter_password': 'Please enter your password',
      'no_archived_records': 'No archived records',
      'status': 'Status',
      'approve': 'Approve',
      'treatment': 'Treatment',
      'reschedule': 'Reschedule',
      'capturing': 'Capturing...',
      'export_report': 'Export Report',
      'treatment_calendar': 'Treatment Calendar',
      'treatment_protocol': 'Treatment Protocol',
      'no_matching_records': 'No matching records',
      'search_by_disease_or_farmer': 'Search by disease or farmer name...',
      'smartfarming_dashboard': 'SMARTFARMING Dashboard',
      'tips_for_best_results': 'Tips for Best Results',
      'camera_permission': 'Camera permission is required to detect diseases',
      'upcoming_in': 'Upcoming in {days} day(s)',
      'causes': 'Causes',
      'no_farmers_registered': 'No farmers registered',
      'archived_records': 'Archived Records',
      'add_treatment': 'Add Treatment',
      'no_upcoming_treatments_list': 'No upcoming treatments',
      'report_generated': 'Report generated on {date}',
      'treatment_notes': 'Notes',
      'all': 'All',
      'share_report': 'Share Report',
      'report_title': 'Farm Report',
      'please_enter_email': 'Please enter your email',
      'permission_denied': 'Permission denied',
      'archived_treatments_hint': 'Completed or archived treatments will appear here',
      'treatment_name': 'Treatment Name',
      'tip_good_lighting': 'Take photo in good lighting',
      'all_pending_approvals': 'All Pending Approvals',
      'prevention': 'Prevention',
      'total_diseases_found': '{count} disease type(s) found',
      'failed_to_initialize_camera': 'Failed to initialize camera: {error}',
      'status_approved': 'Approved',
      'add_for_all_farmers': 'Add for All Farmers',
      'report_period': 'Period: {start} â€“ {end}',
      'no_treatments_month': 'No treatments this month',
      'description': 'Description',
      'admin_password': 'Admin Password',
      'tip_focus_leaf': 'Focus on the leaf clearly',
      'admin_login': 'Admin Login',
      'field_required': '{field} is required',
      'assign_to_farmer': 'Assign to Farmer',
      'could_not_open_browser': 'Could not open browser',
      'disease': 'Disease',
      'farmer_name': 'Farmer',
      'network_error': 'Network error. Please check your connection.',
      'filter_type': 'Filter type',
      'all_detections': 'All Detections',
      'view_schedule': 'View Schedule',
      'status_completed': 'Completed',
      'done': 'Done',
      'most_common_disease': 'Most common: {disease}',
      'treatment_date': 'Treatment Date',
      'server_error': 'Server error. Please try again later.',
      'access_denied_admin_only': 'Access denied. Admin accounts only. Use the mobile app for farmer login.',
      'date_time_label': 'Date & Time',
      'add_treatment_schedule': 'Add Treatment Schedule',
      'treatment_scheduled': 'Treatment scheduled for {date}',
      'treatment_deleted': 'Treatment deleted',
      'all_upcoming_treatments': 'All Upcoming Treatments',
      'date_time': 'Date & Time',
      'storage_permission': 'Storage permission is required to save images',
      'invalid_email': 'Please enter a valid email address',
      'symptoms': 'Symptoms',
      'disapprove': 'Disapprove',
      'status_pending': 'Pending',
      'more_details': 'More Details',
      'schedule_assigned_count': 'Schedule assigned to {count} farmer(s)',
      'admin_email': 'Admin Email',
      'tip_avoid_shadows': 'Avoid shadows and reflections',
      'password_too_short': 'Password must be at least {min} characters',
      'treatment_completed': 'Treatment marked as completed',
      'tip_capture_entire_leaf': 'Capture the entire leaf if possible',
      'please_enter_valid_email': 'Please enter a valid email',
      'archive': 'Archive',
      'clear_search': 'Clear search',
      'overdue_treatment': 'Overdue by {days} day(s)',
      'fertilization': 'Fertilization',
      'recommended_remedy': 'Recommended remedy',
      'schedule_added_all': 'Schedule added for all farmers',
      'sign_in': 'Sign In',
},

    'fil': {
      // Ã¢â€â‚¬Ã¢â€â‚¬ Common Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'welcome': 'Maligayang pagdating',
      'cancel': 'Kanselahin',
      'save': 'I-save',
      'ok': 'Sige',
      'delete': 'Burahin',
      'confirm': 'Kumpirmahin',
      'loading': 'Naglo-load...',
      'tap_for_details': 'Pindutin para sa detalye',
      'view_all': 'Tingnan Lahat',
      'date': 'Petsa',
      'confidence': 'Katiyakan',
      'no_data': 'N/A',
      'error': 'Error',
      'retry': 'Subukang muli',
      'success': 'Tagumpay',
      'unknown': 'Hindi kilala',
      'none': 'Wala',
      'yes': 'Oo',
      'no': 'Hindi',
      'close': 'Isara',
      'submit': 'Isumite',
      'update': 'I-update',
      'search': 'Maghanap',
      'filter': 'Salain',
      'sort': 'Ayusin',
      'refresh': 'I-refresh',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Navigation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'dashboard': 'Dashboard',
      'schedule': 'Iskedyul',
      'reports': 'Mga Ulat',
      'profile': 'Profile',
      'scan': 'Mag-scan',
      'history': 'Kasaysayan',
      'back': 'Bumalik',
      'back_to_home': 'Bumalik sa Tahanan',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Dashboard Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'detect_disease': 'Tukuyin ang Sakit',
      'latest_detection': 'Pinakabagong Deteksyon',
      'next_treatment': 'Susunod na Lunas',
      'total_detections': 'Kabuuang mga Deteksyon',
      'pending_treatments': 'Nakabinbin na mga Lunas',
      'soil_monitoring': 'Pagsubaybay sa Lupa',
      'weather': 'Panahon',
      'no_detections_yet': 'Wala pang mga deteksyon',
      'no_upcoming_treatments': 'Walang paparating na mga lunas',
      'good_morning': 'Magandang umaga, {name}!',
      'good_afternoon': 'Magandang hapon, {name}!',
      'good_evening': 'Magandang gabi, {name}!',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Soil & Environment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'ph_level': 'Antas ng pH',
      'moisture': 'Kahalumigmigan',
      'temperature': 'Temperatura',
      'humidity': 'Halumigmig',
      'loading_weather': 'Naglo-load ng panahon...',
      'wind_speed': 'Bilis ng Hangin',
      'rainfall': 'Pag-ulan',
      'soil_status': 'Katayuan ng Lupa',
      'soil_healthy': 'Malusog ang lupa',
      'soil_needs_attention': 'Kailangan ng pansin ang lupa',
      'ph_optimal': 'Angkop ang pH ({value})',
      'ph_low': 'Mababa ang pH ({value}) Ã¢â‚¬â€ isaalang-alang ang pagdaragdag ng apog',
      'ph_high': 'Mataas ang pH ({value}) Ã¢â‚¬â€ isaalang-alang ang pag-aasido',
      'moisture_optimal': 'Angkop ang kahalumigmigan ({value}%)',
      'moisture_low': 'Mababa ang kahalumigmigan ({value}%) Ã¢â‚¬â€ mag-irigasyon na',
      'moisture_high': 'Mataas ang kahalumigmigan ({value}%) Ã¢â‚¬â€ suriin ang drainage',
      'last_updated': 'Huling na-update: {time}',
      'sensor_offline': 'Offline ang sensor',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Weather Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'feels_like': 'Pakiramdam ay {temp}Ã‚Â°C',
      'forecast_days': 'Hula sa loob ng {count} araw',
      'weather_alert': 'Babala sa Panahon',
      'high_wind_warning': 'Babala sa malakas na hangin: {speed} km/h',
      'heavy_rain_warning': 'Inaasahang malakas na ulan: {amount} mm',
      'weather_unavailable': 'Hindi available ang datos ng panahon',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Profile Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'edit_profile': 'I-edit ang Profile',
      'edit_profile_subtitle': 'I-update ang iyong personal na impormasyon',
      'farm_location': 'Lokasyon ng Sakahan',
      'not_set': 'Hindi nakatakda',
      'settings': 'Mga Setting',
      'settings_subtitle': 'Mga kagustuhan at abiso ng app',
      'language': 'Wika',
      'logout': 'Mag-logout',
      'logout_confirm': 'Sigurado ka bang gusto mong mag-logout?',
      'select_language': 'Piliin ang Wika',
      'farmer': 'Magsasaka',
      'account_created': 'Nilikha ang account noong {date}',
      'total_farm_area': 'Kabuuang lugar ng sakahan: {area} ha',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Authentication Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'login': 'Mag-login',
      'welcome_back': 'Maligayang Pagbabalik',
      'sign_in_to_continue': 'Mag-sign in para magpatuloy',
      'email': 'Email',
      'password': 'Password',
      'dont_have_account': 'Walang account?',
      'sign_up': 'Mag-sign Up',
      'forgot_password': 'Nakalimutan ang Password?',
      'reset_password': 'I-reset ang Password',
      'password_reset_sent': 'Naipadala ang email para sa pag-reset ng password sa {email}',
      'login_failed': 'Nabigo ang pag-login: {reason}',
      'register_success': 'Matagumpay na nalikha ang account',
      'logout_success': 'Naka-logout ka na',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Disease Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'detection': 'Deteksyon',
      'take_photo': 'Kumuha ng Larawan',
      'choose_from_gallery': 'Pumili mula sa Gallery',
      'analyzing_image': 'Sinusuri ang larawan...',
      'disease_detected': 'Natukoy ang {disease}',
      'no_disease_detected': 'Walang sakit na natukoy',
      'detection_confidence': 'Katiyakan: {value}%',
      'detection_result': 'Resulta ng Deteksyon',
      'recommended_action': 'Inirerekomendang Aksyon',
      'disease_description': 'Tungkol sa sakit na ito',
      'severity_low': 'Mababang antas',
      'severity_medium': 'Katamtamang antas',
      'severity_high': 'Mataas na antas',
      'detection_saved': 'Matagumpay na na-save ang deteksyon',
      'detection_count': '{count} deteksyon ang naitala',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Treatment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'add_treatment': 'Magdagdag ng Lunas',
      'treatment_calendar': 'Kalendaryo ng mga Lunas',
      'treatment_name': 'Pangalan ng Lunas',
      'treatment_date': 'Petsa ng Lunas',
      'treatment_notes': 'Mga Tala',
      'treatment_completed': 'Minarkahan ang lunas bilang kumpleto',
      'treatment_deleted': 'Natanggal ang lunas',
      'treatment_scheduled': 'Naka-iskedyul ang lunas para sa {date}',
      'overdue_treatment': 'Nalagpasan na ng {days} araw',
      'upcoming_in': 'Darating sa loob ng {days} araw',
      'no_treatments_month': 'Walang lunas ngayong buwan',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Reports Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'report_title': 'Ulat ng Sakahan',
      'report_period': 'Panahon: {start} Ã¢â‚¬â€œ {end}',
      'report_generated': 'Nalikha ang ulat noong {date}',
      'total_diseases_found': '{count} uri ng sakit ang natagpuan',
      'most_common_disease': 'Pinaka-karaniwan: {disease}',
      'export_report': 'I-export ang Ulat',
      'share_report': 'Ibahagi ang Ulat',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Errors & Validation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'field_required': 'Kailangan ang {field}',
      'invalid_email': 'Mangyaring maglagay ng wastong email address',
      'password_too_short': 'Ang password ay dapat na hindi bababa sa {min} na karakter',
      'network_error': 'Error sa network. Pakisuri ang iyong koneksyon.',
      'server_error': 'Error sa server. Pakisubukang muli mamaya.',
      'permission_denied': 'Tinanggihan ang pahintulot',
      'camera_permission': 'Kailangan ang pahintulot sa camera para matukoy ang mga sakit',
      'storage_permission': 'Kailangan ang pahintulot sa storage para ma-save ang mga larawan',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Archive Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'archive': 'Archive',
      'archived_records': 'Mga Na-archive na Rekord',
      'no_archived_records': 'Walang na-archive na rekord',
      'no_matching_records': 'Walang tumutugmang rekord',
      'clear_search': 'Burahin ang paghahanap',
      'search_by_disease': 'Maghanap ayon sa sakit...',
      'search_by_disease_or_farmer': 'Maghanap ayon sa sakit o pangalan ng magsasaka...',
      'filter_type': 'Uri ng filter',
      'all_types': 'Lahat ng uri',
      'all': 'Lahat',
      'disease': 'Sakit',
      'treatment': 'Lunas',
      'fertilization': 'Pataba',
      'farmer_name': 'Magsasaka',
      'archived_treatments_hint': 'Ang mga nakumpleto o na-archive na lunas ay lalabas dito',
      'view_schedule': 'Tingnan ang Iskedyul',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Admin Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'admin_dashboard': 'Admin Dashboard',
      'add_schedule_tooltip': 'Magdagdag ng iskedyul para sa lahat ng magsasaka',
      'assign_to': 'Italaga sa',
      'all_farmers': 'Lahat ng Magsasaka',
      'specific_farmer': 'Tiyak na Magsasaka',
      'add_treatment_schedule': 'Magdagdag ng Iskedyul ng Lunas',
      'no_farmers_registered': 'Walang nakarehistrong magsasaka',
      'date_time': 'Petsa at Oras',
      'recommended_remedy': 'Inirerekomendang remedyo',
      'assign_to_farmer': 'Italaga sa Magsasaka',
      'add_for_all_farmers': 'Idagdag para sa Lahat ng Magsasaka',
      'schedule_added_all': 'Naidagdag ang iskedyul para sa lahat ng magsasaka',
      'schedule_assigned_count': 'Itinalaga ang iskedyul sa {count} magsasaka',
      'all_detections': 'Lahat ng mga Deteksyon',
      'all_pending_approvals': 'Lahat ng Nakabinbin na Pag-apruba',
      'all_upcoming_treatments': 'Lahat ng Paparating na Lunas',
      'no_pending_approvals': 'Walang nakabinbing pag-apruba',
      'no_upcoming_treatments_list': 'Walang paparating na lunas',
      'approve': 'Aprubahan',
      'disapprove': 'Tanggihan',
      'reschedule': 'Muling iskedyul',
      'status': 'Katayuan',
      'status_pending': 'Nakabinbin',
      'status_approved': 'Naaprubahan',
      'status_completed': 'Nakumpleto',
      'status_cancelled': 'Nakangansa',
      'notes': 'Mga tala',
      'remedy': 'Remedyo',
      'type': 'Uri',
      'no_treatments_for_date': 'Walang lunas para sa {date}',
      'no_treatments_yet': 'Walang lunas pa',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Treatment Calendar & Add Treatment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'treatment_schedule': 'Iskedyul ng mga Lunas',
      'return_home': 'Bumalik sa Tahanan',
      'archived_records_tooltip': 'Mga Na-archive na Rekord',
      'add_treatment_tooltip': 'Magdagdag ng Lunas',
      'no_treatments_scheduled': 'Walang naka-iskedyul na lunas para sa {date}',
      'notes_optional': 'Mga Tala (Opsyonal)',
      'add_notes_hint': 'Magdagdag ng anumang karagdagang tala',
      'please_select_disease': 'Mangyaring pumili ng sakit',
      'please_sign_in': 'Mangyaring mag-sign in para magdagdag ng lunas',
      'rain_warning': 'Babala sa Ulan',
      'rain_warning_content': 'Inaasahang uulan sa napiling petsa. Gusto mo bang magpatuloy?',
      'continue_text': 'Magpatuloy',
      'treatment_submitted_pending': 'Naipasa ang lunas. Katayuan: Nakabinbin Ã¢â‚¬â€œ naghihintay ng pag-apruba ng admin.',
      'awaiting_admin_approval': 'Naghihintay ng pag-apruba ng admin',
      'archive_confirm_title': 'Archive',
      'archive_confirm_message': 'I-archive ba ang {type} na rekord para sa {disease}?',
      'archived_success': 'Na-archive',
      'failed_to_archive': 'Nabigo ang pag-archive',
      'failed_to_schedule': 'Nabigo ang pag-iskedyul ng lunas',
      'schedule_treatment': 'I-iskedyul ang Lunas',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Camera & Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'camera_detection': 'Deteksyon gamit ang Camera',
      'take_photo_title': 'Kumuha ng Larawan',
      'user_not_authenticated': 'Hindi naka-authenticate ang user',
      'detection_failed': 'Nabigo ang deteksyon',
      'camera_unavailable': 'Hindi available ang camera',
      'camera_error_hint': 'Hindi ma-access ang camera. Maaaring ginagamit ito ng ibang app, o sa mga emulator na walang camera.',
      'hold_steady': 'Manatiling Matatag',
      'hold_steady_hint': 'Paki-steady ang phone para sa mas mahusay na scanning.',
      'camera_unstable': 'Hindi Matatag ang Camera',
      'focusing_camera': 'Nagfo-focus sa camera...',
      'scanning': 'Nag-scan...',
      'use_gallery_instead': 'Gumamit ng Gallery sa Halip',
      'processing_hint': 'Nagpoproseso...',
      'camera_instruction': 'Ilagay ang dahon ng palay sa gitna at pindutin ang camera button',
      'photo_proof': 'Patunay ng Larawan',
      'photo_proof_instruction': 'Kumuha ng real-time na larawan bilang patunay ng pagkumpleto',
      'treatment_completed_photo': 'Minarkahan ang lunas bilang nakumpleto na may patunay ng larawan',
      'failed_to_complete': 'Nabigo ang pagkumpleto',
      'no_camera_found': 'Walang nakitang camera',
      'error_taking_picture': 'Error sa pagkuha ng litrato: {error}',
      'error_generic': 'Error: {error}',
      'disease_detection': 'Deteksyon ng Sakit',
      'detect_rice_leaf_disease': 'Tukuyin ang Sakit ng Dahon ng Palay',
      'capture_select_hint': 'Kunin o pumili ng larawan ng dahon ng palay para matukoy ang mga sakit',
      'error_picking_image': 'Error sa pagpili ng larawan: {error}',
      'tips_for_best_results': 'Mga Tip para sa Pinakamahusay na Resulta',
      'tip_good_lighting': 'Kumuha ng litrato sa magandang ilaw',
      'tip_focus_leaf': 'Tumutok nang malinaw sa dahon',
      'tip_avoid_shadows': 'Iwasan ang anino at repleksyon',
      'tip_capture_entire_leaf': 'Kunin ang buong dahon kung maaari',
      'description': 'Paglalarawan',
      'symptoms': 'Mga Sintomas',
      'causes': 'Mga Sanhi',
      'prevention': 'Pag-iwas',
      'treatment_protocol': 'Protocol sa Paggamot',
      'more_details': 'Maraming Detalye',
      'could_not_open_browser': 'Hindi mabuksan ang browser',
      'capturing': 'Kumukuha...',
      'done': 'Tapos',
      'failed_to_initialize_camera': 'Nabigo ang pag-initialize ng camera: {error}',
      'date_time_label': 'Petsa at Oras',
      'admin_login': 'Admin Login',
      'smartfarming_dashboard': 'SMARTFARMING Dashboard',
      'admin_email': 'Email ng admin',
      'admin_password': 'Password ng admin',
      'sign_in': 'Mag-sign In',
      'please_enter_email': 'Pakilagay ang iyong email',
      'please_enter_valid_email': 'Pakilagay ang valid na email',
      'please_enter_password': 'Pakilagay ang iyong password',
      'access_denied_admin_only': 'Access denied. Admin accounts only. Gamitin ang mobile app para sa farmer login.',
      'login_failed_simple': 'Nabigo ang login',

      // ---- Dashboard extras --------------------------------------
      'weather_offline': 'Offline ang datos ng panahon',

      // ---- AI Assistant (AgriGuide) ------------------------------
      'ai_chat_title': 'AI Katulong sa Bukid',
      'ai_hint': 'Magtanong tungkol sa iyong palayan...',
      'ai_typing': 'Nagiisip si AgriGuide...',
      'ai_clear_chat': 'I-clear ang chat',
      'ai_clear_confirm': 'I-clear ang pag-uusap na ito?',
      'ai_clear_confirm_body': 'Buburahin ang iyong kasaysayan ng chat kay AgriGuide.',
      'ai_retry': 'Subukan muli',
      'ai_no_key': 'Hindi pa naka-set up ang AI assistant. Idagdag ang iyong Gemini API key (--dart-define=GEMINI_API_KEY) at i-restart.',
      'ai_offline': 'Wala kang koneksyon sa internet. Kumonekta para makapag-usap kay AgriGuide.',
      'ai_error': 'May nangyaring mali sa AI assistant. Subukan muli.',
      'ai_timeout': 'Masyadong nagtagal si AgriGuide. Subukan muli.',
      'ai_rate_limited': 'Naabot mo na ang limitasyon ng AI request. Maghintay sandali at subukan muli.',
      'ai_server_error': 'Pansamantalang hindi available ang AI service. Subukan muli mamaya.',
      'ai_welcome': 'Kumusta! Ako si AgriGuide AI, ang iyong katulong sa pagtatanim ng palay. Magtanong tungkol sa pH ng lupa, moisture, peste, o patubig at sasagutin ko sa iyong wika.',
      'ai_soil_context': 'Na-update ang aking farm readings: pH {ph}, moisture {moisture}%, humidity {humidity}%. Pakisuri ito at bigyan ako ng mga rekomendasyon.',
      'ai_soil_label': 'Pagsusuri ng lupa',
      'ai_chip_ph': 'Paano ayusin ang mababang pH ng lupa?',
      'ai_chip_moisture': 'Pinakamahusay na patubig sa tuyong lupa?',
      'ai_chip_disease': 'Paano maiwasan ang rice blast?',
      'ai_chip_fertilizer': 'Kailan maglalagay ng pataba?',
      'ai_expand': 'Palawakin',
      'ai_close': 'Isara',
      'ai_send': 'Ipadala',
      'ai_ask_disease': 'Magtanong sa AI tungkol sa {disease}',
      'ai_asking_about': 'Nagtatanong tungkol sa: {disease}',
      'ai_dashboard_title': 'Magtanong sa AI',
      'ai_dashboard_subtitle': 'Kumuha ng mabilisang payo tungkol sa mga sakit, lupa, at panahon para sa iyong palayan.',
    },

    'ceb': {
      // Ã¢â€â‚¬Ã¢â€â‚¬ Common Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'welcome': 'Maayong pag-abot',
      'cancel': 'Kansela',
      'save': 'Tipigi',
      'ok': 'Sige',
      'delete': 'Papasa',
      'confirm': 'Kumpirma',
      'loading': 'Nag-load...',
      'tap_for_details': 'I-tap alang sa detalye',
      'view_all': 'Tan-awa ang Tanan',
      'date': 'Petsa',
      'confidence': 'Kasiguroan',
      'no_data': 'N/A',
      'error': 'Sayop',
      'retry': 'Sulayi pag-usab',
      'success': 'Kalampusan',
      'unknown': 'Wala mahibaloi',
      'none': 'Wala',
      'yes': 'Oo',
      'no': 'Dili',
      'close': 'Sirado',
      'submit': 'Isumite',
      'update': 'I-update',
      'search': 'Pangita',
      'filter': 'Salain',
      'sort': 'Ayuhon',
      'refresh': 'I-refresh',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Navigation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'dashboard': 'Dashboard',
      'schedule': 'Talaan',
      'reports': 'Mga Report',
      'profile': 'Profile',
      'scan': 'Mag-scan',
      'history': 'Kasaysayan',
      'back': 'Balik',
      'back_to_home': 'Balik sa Balay',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Dashboard Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'detect_disease': 'Tino-i ang Sakit',
      'latest_detection': 'Pinakabag-o nga Deteksyon',
      'next_treatment': 'Sunod nga Tambal',
      'total_detections': 'Tibuok mga Deteksyon',
      'pending_treatments': 'Naghulat nga mga Tambal',
      'soil_monitoring': 'Pag-monitor sa Yuta',
      'weather': 'Panahon',
      'no_detections_yet': 'Wala pay mga deteksyon',
      'no_upcoming_treatments': 'Wala pay umaabot nga mga tambal',
      'good_morning': 'Maayong buntag, {name}!',
      'good_afternoon': 'Maayong hapon, {name}!',
      'good_evening': 'Maayong gabii, {name}!',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Soil & Environment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'ph_level': 'Antas sa pH',
      'moisture': 'Umog',
      'temperature': 'Temperatura',
      'humidity': 'Halumigmig',
      'loading_weather': 'Nag-load sa panahon...',
      'wind_speed': 'Kusog sa Hangin',
      'rainfall': 'Ulan',
      'soil_status': 'Kahimtang sa Yuta',
      'soil_healthy': 'Himsog ang yuta',
      'soil_needs_attention': 'Kinahanglan og pagtagad ang yuta',
      'ph_optimal': 'Angay ang pH ({value})',
      'ph_low': 'Ubos ang pH ({value}) Ã¢â‚¬â€ hunahunaa ang pagdugang og apog',
      'ph_high': 'Taas ang pH ({value}) Ã¢â‚¬â€ hunahunaa ang pag-asido',
      'moisture_optimal': 'Angay ang umog ({value}%)',
      'moisture_low': 'Ubos ang umog ({value}%) Ã¢â‚¬â€ mag-irigasyon na',
      'moisture_high': 'Taas ang umog ({value}%) Ã¢â‚¬â€ susihon ang drainage',
      'last_updated': 'Katapusang gi-update: {time}',
      'sensor_offline': 'Offline ang sensor',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Weather Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'feels_like': 'Gibati nga {temp}Ã‚Â°C',
      'forecast_days': 'Tagna sa {count} ka adlaw',
      'weather_alert': 'Pasidaan sa Panahon',
      'high_wind_warning': 'Pasidaan sa kusog nga hangin: {speed} km/h',
      'heavy_rain_warning': 'Gipaabot nga kusog nga ulan: {amount} mm',
      'weather_unavailable': 'Dili available ang datos sa panahon',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Profile Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'edit_profile': 'Edit ang Profile',
      'edit_profile_subtitle': 'I-update ang imong personal nga impormasyon',
      'farm_location': 'Lokasyon sa Uma',
      'not_set': 'Wala pa na-set',
      'settings': 'Mga Setting',
      'settings_subtitle': 'Mga gusto ug abiso sa app',
      'language': 'Pinulongan',
      'logout': 'Mag-logout',
      'logout_confirm': 'Sigurado ba nga gusto nimo mag-logout?',
      'select_language': 'Pilia ang Pinulongan',
      'farmer': 'Mag-uuma',
      'account_created': 'Gihimo ang account niadtong {date}',
      'total_farm_area': 'Tibuok lugar sa uma: {area} ha',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Authentication Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'login': 'Mag-login',
      'welcome_back': 'Maayong Pagbalik',
      'sign_in_to_continue': 'Mag-sign in aron magpadayon',
      'email': 'Email',
      'password': 'Password',
      'dont_have_account': 'Walay account?',
      'sign_up': 'Mag-sign Up',
      'forgot_password': 'Nakalimtan ang Password?',
      'reset_password': 'I-reset ang Password',
      'password_reset_sent': 'Gipadala ang email sa pag-reset sa password sa {email}',
      'login_failed': 'Napakyas ang pag-login: {reason}',
      'register_success': 'Malampuson nga nahimo ang account',
      'logout_success': 'Naka-logout ka na',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Disease Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'detection': 'Deteksyon',
      'take_photo': 'Kuha ug Litrato',
      'choose_from_gallery': 'Pilia gikan sa Gallery',
      'analyzing_image': 'Gisusi ang litrato...',
      'disease_detected': 'Nakit-an ang {disease}',
      'no_disease_detected': 'Walay sakit nga nakit-an',
      'detection_confidence': 'Kasiguroan: {value}%',
      'detection_result': 'Resulta sa Deteksyon',
      'recommended_action': 'Girekomendang Aksyon',
      'disease_description': 'Mahitungod niini nga sakit',
      'severity_low': 'Ubos nga antas',
      'severity_medium': 'Tunga-tunga nga antas',
      'severity_high': 'Taas nga antas',
      'detection_saved': 'Malampuson nga na-save ang deteksyon',
      'detection_count': '{count} ka deteksyon ang naitala',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Treatment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'add_treatment': 'Dugangi ug Tambal',
      'treatment_calendar': 'Kalendaryo sa mga Tambal',
      'treatment_name': 'Ngalan sa Tambal',
      'treatment_date': 'Petsa sa Tambal',
      'treatment_notes': 'Mga Nota',
      'treatment_completed': 'Gimarkahan ang tambal nga nahuman',
      'treatment_deleted': 'Natanggal ang tambal',
      'treatment_scheduled': 'Naka-iskedyul ang tambal para sa {date}',
      'overdue_treatment': 'Nalabaw na og {days} ka adlaw',
      'upcoming_in': 'Moabot sa {days} ka adlaw',
      'no_treatments_month': 'Walay tambal niining bulana',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Reports Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'report_title': 'Report sa Uma',
      'report_period': 'Panahon: {start} Ã¢â‚¬â€œ {end}',
      'report_generated': 'Nahimo ang report niadtong {date}',
      'total_diseases_found': '{count} ka klase sa sakit ang nakit-an',
      'most_common_disease': 'Pinaka-komon: {disease}',
      'export_report': 'I-export ang Report',
      'share_report': 'Ipaambit ang Report',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Errors & Validation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'field_required': 'Kinahanglan ang {field}',
      'invalid_email': 'Palihug isulod ang usa ka balido nga email address',
      'password_too_short': 'Ang password kinahanglan dili ubos sa {min} ka karakter',
      'network_error': 'Sayop sa network. Palihug susihon ang imong koneksyon.',
      'server_error': 'Sayop sa server. Palihug sulayi pag-usab sa ulahi.',
      'permission_denied': 'Gidumilian ang permiso',
      'camera_permission': 'Kinahanglan ang permiso sa camera aron makit-an ang mga sakit',
      'storage_permission': 'Kinahanglan ang permiso sa storage aron ma-save ang mga litrato',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Archive Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'archive': 'Archive',
      'archived_records': 'Mga Na-archive nga mga Rekord',
      'no_archived_records': 'Walay na-archive nga rekord',
      'no_matching_records': 'Walay nagtugmang rekord',
      'clear_search': 'Papasa ang pagpangita',
      'search_by_disease': 'Pangita sumala sa sakit...',
      'search_by_disease_or_farmer': 'Pangita sumala sa sakit o ngalan sa mag-uuma...',
      'filter_type': 'Klase sa filter',
      'all_types': 'Tanang klase',
      'all': 'Tanan',
      'disease': 'Sakit',
      'treatment': 'Tambal',
      'fertilization': 'Abono',
      'farmer_name': 'Mag-uuma',
      'archived_treatments_hint': 'Ang nahuman o na-archive nga mga tambal makita dinhi',
      'view_schedule': 'Tan-awa ang Talaan',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Admin Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'admin_dashboard': 'Admin Dashboard',
      'add_schedule_tooltip': 'Dugangi ang talaan alang sa tanan nga mag-uuma',
      'assign_to': 'Itudlo ngadto sa',
      'all_farmers': 'Tanang Mag-uuma',
      'specific_farmer': 'Espesipikong Mag-uuma',
      'add_treatment_schedule': 'Dugangi ang Talaan sa Tambal',
      'no_farmers_registered': 'Walay nakarehistrong mag-uuma',
      'date_time': 'Petsa ug Oras',
      'recommended_remedy': 'Girekomendang remedyo',
      'assign_to_farmer': 'Itudlo ngadto sa Mag-uuma',
      'add_for_all_farmers': 'Dugangi alang sa Tanan nga Mag-uuma',
      'schedule_added_all': 'Gidugang ang talaan alang sa tanan nga mag-uuma',
      'schedule_assigned_count': 'Gitudlo ang talaan ngadto sa {count} ka mag-uuma',
      'all_detections': 'Tanang mga Deteksyon',
      'all_pending_approvals': 'Tanang Naghulat nga mga Pag-aproba',
      'all_upcoming_treatments': 'Tanang Umaabot nga mga Tambal',
      'no_pending_approvals': 'Walay naghulat nga pag-aproba',
      'no_upcoming_treatments_list': 'Walay umaabot nga mga tambal',
      'approve': 'Aprubahan',
      'disapprove': 'Dili-aprubahan',
      'reschedule': 'Usbon ang talaan',
      'status': 'Kahimtang',
      'status_pending': 'Naghulat',
      'status_approved': 'Giaprobahan',
      'status_completed': 'Nahuman',
      'status_cancelled': 'Gikansela',
      'notes': 'Mga nota',
      'remedy': 'Remedyo',
      'type': 'Klase',
      'no_treatments_for_date': 'Walay tambal para sa {date}',
      'no_treatments_yet': 'Walay tambal pa',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Treatment Calendar & Add Treatment Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'treatment_schedule': 'Talaan sa mga Tambal',
      'return_home': 'Balik sa Balay',
      'archived_records_tooltip': 'Mga Na-archive nga Rekord',
      'add_treatment_tooltip': 'Dugangi ang Tambal',
      'no_treatments_scheduled': 'Walay naka-tala nga tambal para sa {date}',
      'notes_optional': 'Mga Nota (Opsyonal)',
      'add_notes_hint': 'Dugangi bisan unsang dugang nga nota',
      'please_select_disease': 'Palihug pilia ang sakit',
      'please_sign_in': 'Palihug mag-sign in aron magdugang ug tambal',
      'rain_warning': 'Pasidaan sa Ulan',
      'rain_warning_content': 'Gipaabot nga moulan sa napiling petsa. Gusto ba nimo magpadayon?',
      'continue_text': 'Magpadayon',
      'treatment_submitted_pending': 'Naipasa ang tambal. Kahimtang: Naghulat Ã¢â‚¬â€œ naghulat sa aprobasyon sa admin.',
      'awaiting_admin_approval': 'Naghulat sa aprobasyon sa admin',
      'archive_confirm_title': 'Archive',
      'archive_confirm_message': 'I-archive ba niining {type} nga rekord para sa {disease}?',
      'archived_success': 'Na-archive',
      'failed_to_archive': 'Napakyas ang pag-archive',
      'failed_to_schedule': 'Napakyas ang pag-tala sa tambal',
      'schedule_treatment': 'I-tala ang Tambal',

      // Ã¢â€â‚¬Ã¢â€â‚¬ Camera & Detection Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      'camera_detection': 'Deteksyon gamit ang Camera',
      'take_photo_title': 'Kuha ug Litrato',
      'user_not_authenticated': 'Wala ma-authenticate ang user',
      'detection_failed': 'Napakyas ang deteksyon',
      'camera_unavailable': 'Dili available ang camera',
      'camera_error_hint': 'Dili ma-access ang camera. Mahimo nga gigamit kini sa lain nga app, o sa mga emulator nga walay camera.',
      'hold_steady': 'Magpabilin nga Lig-on',
      'hold_steady_hint': 'Palihug guniti ang imong phone nga lig-on para sa mas maayong pag-scan.',
      'camera_unstable': 'Dili Stable ang Camera',
      'focusing_camera': 'Nag-focus sa camera...',
      'scanning': 'Nag-scan...',
      'use_gallery_instead': 'Gamita ang Gallery sa baylo',
      'processing_hint': 'Nagproseso...',
      'camera_instruction': 'Ibutang ang dahon sa humay sa tunga ug i-tap ang camera button',
      'photo_proof': 'Patunay sa Litrato',
      'photo_proof_instruction': 'Kuha ug real-time nga litrato ingong patunay sa pagkumpleto',
      'treatment_completed_photo': 'Gimarkahan ang tambal nga nahuman nga dunay patunay sa litrato',
      'failed_to_complete': 'Napakyas ang pagkumpleto',
      'no_camera_found': 'Walay nakitang camera',
      'error_taking_picture': 'Error sa pagkuha ug litrato: {error}',
      'error_generic': 'Error: {error}',
      'disease_detection': 'Deteksyon sa Sakit',
      'detect_rice_leaf_disease': 'Susi ang Sakit sa Dahon sa Humay',
      'capture_select_hint': 'Kuha o pilia ang litrato sa dahon sa humay aron makita ang mga sakit',
      'error_picking_image': 'Error sa pagpili ug litrato: {error}',
      'tips_for_best_results': 'Mga Tip para sa Pinakamaayong Resulta',
      'tip_good_lighting': 'Kuha ug litrato sa maayong suga',
      'tip_focus_leaf': 'Fokus ug tarong sa dahon',
      'tip_avoid_shadows': 'Likayi ang landong ug repleksyon',
      'tip_capture_entire_leaf': 'Kuha ang tibuok dahon kung mahimo',
      'description': 'Deskripsyon',
      'symptoms': 'Mga Sintomas',
      'causes': 'Mga Hinungdan',
      'prevention': 'Paglikay',
      'treatment_protocol': 'Protocol sa Pagtambal',
      'more_details': 'Daghan pang Detalye',
      'could_not_open_browser': 'Dili maabli ang browser',
      'capturing': 'Nagkuha...',
      'done': 'Done',
      'failed_to_initialize_camera': 'Napakyas ang pag-initialize sa camera: {error}',
      'date_time_label': 'Petsa ug Oras',
      'admin_login': 'Admin Login',
      'smartfarming_dashboard': 'SMARTFARMING Dashboard',
      'admin_email': 'Email sa admin',
      'admin_password': 'Password sa admin',
      'sign_in': 'Mag-sign In',
      'please_enter_email': 'Palihug ibutang ang imong email',
      'please_enter_valid_email': 'Palihug ibutang ang valid nga email',
      'please_enter_password': 'Palihug ibutang ang imong password',
      'access_denied_admin_only': 'Access denied. Admin accounts only. Gamitaha ang mobile app para sa farmer login.',
      'login_failed_simple': 'Napakyas ang login',

      // ---- Dashboard extras --------------------------------------
      'weather_offline': 'Offline ang datos sa panahon',

      // ---- AI Assistant (AgriGuide) ------------------------------
      'ai_chat_title': 'AI Assistant sa Uma',
      'ai_hint': 'Pangutana mahitungod sa imong palayan...',
      'ai_typing': 'Naghunahuna si AgriGuide...',
      'ai_clear_chat': 'Limpyohi ang chat',
      'ai_clear_confirm': 'Limpyohon kini nga panag-istoryahay?',
      'ai_clear_confirm_body': 'Papurason ang imong kasaysayan sa chat uban ni AgriGuide.',
      'ai_retry': 'Sulayi pag-usab',
      'ai_no_key': 'Wala pa na-set up ang AI assistant. Idugang ang imong Gemini API key (--dart-define=GEMINI_API_KEY) ug i-restart.',
      'ai_offline': 'Wala kay koneksyon sa internet. Konekta aron makig-chat kang AgriGuide.',
      'ai_error': 'Adunay sayop sa AI assistant. Sulayi pag-usab.',
      'ai_timeout': 'Dugay kaayo nga mitubag si AgriGuide. Sulayi pag-usab.',
      'ai_rate_limited': 'Naabot na nimo ang limit sa AI request. Paghulat kadiyot ug sulayi pag-usab.',
      'ai_server_error': 'Dili pa available ang AI service karon. Sulayi pag-usab unya.',
      'ai_welcome': 'Maayong adlaw! Ako si AgriGuide AI, ang imong katabang sa pag-uma og humay. Pangutana mahitungod sa pH sa yuta, moisture, peste, o irigasyon ug motubag ko sa imong pinulongan.',
      'ai_soil_context': 'Bag-o lang na-update ang akong farm readings: pH {ph}, moisture {moisture}%, humidity {humidity}%. Palihug analisaha kini ug hatagi ko og mga rekomendasyon.',
      'ai_soil_label': 'Pagtuki sa yuta',
      'ai_chip_ph': 'Unsaon nako pag-ayo ang ubos nga pH sa yuta?',
      'ai_chip_moisture': 'Labing maayo nga irigasyon sa uga nga yuta?',
      'ai_chip_disease': 'Unsaon paglikay sa rice blast?',
      'ai_chip_fertilizer': 'Kanus-a magbutang og abono?',
      'ai_expand': 'Palapagon',
      'ai_close': 'Irasa',
      'ai_send': 'Ipadala',
      'ai_ask_disease': 'Pangutana sa AI mahitungod sa {disease}',
      'ai_asking_about': 'Gipangutana mahitungod sa: {disease}',
      'ai_dashboard_title': 'Pangutana sa AI',
      'ai_dashboard_subtitle': 'Kuha og dali nga tambag sa mga sakit, yuta, ug panahon para sa imong palayan.',
    },
  };

  // ---------------------------------------------------------------------------
  // Core lookup Ã¢â‚¬â€ fallback chain: target lang Ã¢â€ â€™ English Ã¢â€ â€™ raw key
  // ---------------------------------------------------------------------------
  String _translate(String key) {
    final lang = locale.languageCode;
    if (_localizedValues.containsKey(lang) &&
        _localizedValues[lang]!.containsKey(key)) {
      return _localizedValues[lang]![key]!;
    }
    // Fallback to English
    if (_localizedValues['en']!.containsKey(key)) {
      return _localizedValues['en']![key]!;
    }
    // Last resort: return the key itself so the UI is never blank
    assert(false, '[AppLocalizations] Missing translation key: "$key"');
    return key;
  }

  // ---------------------------------------------------------------------------
  // Dynamic variable interpolation.
  // Usage: l10n.translate('good_morning', {'name': 'Juan'})
  // Template: 'Good morning, {name}!'  Ã¢â€ â€™  'Good morning, Juan!'
  // ---------------------------------------------------------------------------
  String translate(String key, [Map<String, String>? args]) {
    String result = _translate(key);
    if (args != null) {
      args.forEach((placeholder, value) {
        result = result.replaceAll('{$placeholder}', value);
      });
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Pluralization.
  // Filipino and Cebuano do not inflect nouns for number the way English does,
  // but numeric context still matters for natural phrasing.
  //
  // Usage: l10n.pluralize('treatment', count)
  // Provide keys: 'treatment_one', 'treatment_other'  (English-style)
  // For FIL/CEB you can use the same key for both forms if the language
  // doesn't distinguish Ã¢â‚¬â€ just define 'treatment_other' and omit 'treatment_one'.
  // ---------------------------------------------------------------------------
  String pluralize(String baseKey, int count, [Map<String, String>? args]) {
    final effectiveArgs = {...?args, 'count': count.toString()};
    final lang = locale.languageCode;

    // English: singular for 1, plural otherwise
    // Filipino/Cebuano: typically no grammatical plural, use 'other' form
    final pluralKey = _selectPluralKey(lang, count, baseKey);
    return translate(pluralKey, effectiveArgs);
  }

  String _selectPluralKey(String lang, int count, String baseKey) {
    switch (lang) {
      case 'en':
        // Standard English: one vs other
        return count == 1 ? '${baseKey}_one' : '${baseKey}_other';
      case 'fil':
      case 'ceb':
        // Filipino/Cebuano: no grammatical plural distinction in most cases.
        // Use 'one' form only if explicitly defined, otherwise 'other'.
        final oneKey = '${baseKey}_one';
        final lang2 = locale.languageCode;
        if (_localizedValues[lang2]?.containsKey(oneKey) == true && count == 1) {
          return oneKey;
        }
        return '${baseKey}_other';
      default:
        return '${baseKey}_other';
    }
  }

  // ---------------------------------------------------------------------------
  // Convenience: context-aware greeting based on time of day
  // ---------------------------------------------------------------------------
  String greeting(String name) {
    final hour = DateTime.now().hour;
    final key = hour < 12
        ? 'good_morning'
        : hour < 18
            ? 'good_afternoon'
            : 'good_evening';
    return translate(key, {'name': name});
  }

  // ---------------------------------------------------------------------------
  // Typed getters Ã¢â‚¬â€ for the most common static keys.
  // For dynamic keys, use translate() directly.
  // ---------------------------------------------------------------------------

  // Common
  String get welcome => _translate('welcome');
  String get cancel => _translate('cancel');
  String get save => _translate('save');
  String get ok => _translate('ok');
  String get delete => _translate('delete');
  String get confirm => _translate('confirm');
  String get loading => _translate('loading');
  String get tapForDetails => _translate('tap_for_details');
  String get viewAll => _translate('view_all');
  String get date => _translate('date');
  String get confidence => _translate('confidence');
  String get noData => _translate('no_data');
  String get error => _translate('error');
  String get retry => _translate('retry');
  String get success => _translate('success');
  String get unknown => _translate('unknown');
  String get none => _translate('none');
  String get yes => _translate('yes');
  String get no => _translate('no');
  String get close => _translate('close');
  String get submit => _translate('submit');
  String get update => _translate('update');
  String get search => _translate('search');
  String get filter => _translate('filter');
  String get sort => _translate('sort');
  String get refresh => _translate('refresh');

  // Navigation
  String get dashboard => _translate('dashboard');
  String get schedule => _translate('schedule');
  String get reports => _translate('reports');
  String get profile => _translate('profile');
  String get scan => _translate('scan');
  String get history => _translate('history');
  String get back => _translate('back');
  String get backToHome => _translate('back_to_home');

  // Dashboard
  String get detectDisease => _translate('detect_disease');
  String get latestDetection => _translate('latest_detection');
  String get nextTreatment => _translate('next_treatment');
  String get totalDetections => _translate('total_detections');
  String get pendingTreatments => _translate('pending_treatments');
  String get soilMonitoring => _translate('soil_monitoring');
  String get weather => _translate('weather');
  String get noDetectionsYet => _translate('no_detections_yet');
  String get noUpcomingTreatments => _translate('no_upcoming_treatments');

  // Soil & Environment
  String get phLevel => _translate('ph_level');
  String get moisture => _translate('moisture');
  String get temperature => _translate('temperature');
  String get humidity => _translate('humidity');
  String get loadingWeather => _translate('loading_weather');
  String get windSpeed => _translate('wind_speed');
  String get rainfall => _translate('rainfall');
  String get soilStatus => _translate('soil_status');
  String get soilHealthy => _translate('soil_healthy');
  String get soilNeedsAttention => _translate('soil_needs_attention');
  String get sensorOffline => _translate('sensor_offline');
  String get weatherUnavailable => _translate('weather_unavailable');
  String get weatherAlert => _translate('weather_alert');

  // Profile
  String get editProfile => _translate('edit_profile');
  String get editProfileSubtitle => _translate('edit_profile_subtitle');
  String get farmLocation => _translate('farm_location');
  String get notSet => _translate('not_set');
  String get settings => _translate('settings');
  String get settingsSubtitle => _translate('settings_subtitle');
  String get language => _translate('language');
  String get logout => _translate('logout');
  String get logoutConfirm => _translate('logout_confirm');
  String get selectLanguage => _translate('select_language');
  String get farmer => _translate('farmer');

  // Authentication
  String get login => _translate('login');
  String get welcomeBack => _translate('welcome_back');
  String get signInToContinue => _translate('sign_in_to_continue');
  String get email => _translate('email');
  String get password => _translate('password');
  String get dontHaveAccount => _translate('dont_have_account');
  String get signUp => _translate('sign_up');
  String get forgotPassword => _translate('forgot_password');
  String get resetPassword => _translate('reset_password');
  String get registerSuccess => _translate('register_success');
  String get logoutSuccess => _translate('logout_success');
  String get invalidEmail => _translate('invalid_email');
  String get networkError => _translate('network_error');
  String get serverError => _translate('server_error');
  String get permissionDenied => _translate('permission_denied');
  String get cameraPermission => _translate('camera_permission');
  String get storagePermission => _translate('storage_permission');

  // Detection
  String get detection => _translate('detection');
  String get takePhoto => _translate('take_photo');
  String get chooseFromGallery => _translate('choose_from_gallery');
  String get analyzingImage => _translate('analyzing_image');
  String get noDiseaseDetected => _translate('no_disease_detected');
  String get detectionResult => _translate('detection_result');
  String get recommendedAction => _translate('recommended_action');
  String get diseaseDescription => _translate('disease_description');
  String get severityLow => _translate('severity_low');
  String get severityMedium => _translate('severity_medium');
  String get severityHigh => _translate('severity_high');
  String get detectionSaved => _translate('detection_saved');

  // Treatment
  String get addTreatment => _translate('add_treatment');
  String get treatmentCalendar => _translate('treatment_calendar');
  String get treatmentName => _translate('treatment_name');
  String get treatmentDate => _translate('treatment_date');
  String get treatmentNotes => _translate('treatment_notes');
  String get treatmentCompleted => _translate('treatment_completed');
  String get treatmentDeleted => _translate('treatment_deleted');
  String get noTreatmentsMonth => _translate('no_treatments_month');

  // Reports
  String get reportTitle => _translate('report_title');
  String get exportReport => _translate('export_report');
  String get shareReport => _translate('share_report');

  // Archive
  String get archive => _translate('archive');
  String get archivedRecords => _translate('archived_records');
  String get noArchivedRecords => _translate('no_archived_records');
  String get noMatchingRecords => _translate('no_matching_records');
  String get clearSearch => _translate('clear_search');
  String get searchByDisease => _translate('search_by_disease');
  String get searchByDiseaseOrFarmer => _translate('search_by_disease_or_farmer');
  String get filterType => _translate('filter_type');
  String get allTypes => _translate('all_types');
  String get all => _translate('all');
  String get disease => _translate('disease');
  String get treatment => _translate('treatment');
  String get fertilization => _translate('fertilization');
  String get farmerName => _translate('farmer_name');
  String get archivedTreatmentsHint => _translate('archived_treatments_hint');
  String get viewSchedule => _translate('view_schedule');

  // Admin
  String get adminDashboard => _translate('admin_dashboard');
  String get addScheduleTooltip => _translate('add_schedule_tooltip');
  String get assignTo => _translate('assign_to');
  String get allFarmers => _translate('all_farmers');
  String get specificFarmer => _translate('specific_farmer');
  String get addTreatmentSchedule => _translate('add_treatment_schedule');
  String get noFarmersRegistered => _translate('no_farmers_registered');
  String get dateTime => _translate('date_time');
  String get recommendedRemedy => _translate('recommended_remedy');
  String get addForAllFarmers => _translate('add_for_all_farmers');
  String get scheduleAddedAll => _translate('schedule_added_all');
  String get assignToFarmer => _translate('assign_to_farmer');
  String get allDetections => _translate('all_detections');
  String get allPendingApprovals => _translate('all_pending_approvals');
  String get allUpcomingTreatments => _translate('all_upcoming_treatments');
  String get noPendingApprovals => _translate('no_pending_approvals');
  String get noUpcomingTreatmentsList => _translate('no_upcoming_treatments_list');
  String get approve => _translate('approve');
  String get disapprove => _translate('disapprove');
  String get reschedule => _translate('reschedule');
  String get status => _translate('status');
  String get statusPending => _translate('status_pending');
  String get statusApproved => _translate('status_approved');
  String get statusCompleted => _translate('status_completed');
  String get statusCancelled => _translate('status_cancelled');
  String get notes => _translate('notes');
  String get remedy => _translate('remedy');
  String get type => _translate('type');

  // Treatment Calendar & Add Treatment
  String get treatmentSchedule => _translate('treatment_schedule');
  String get returnHome => _translate('return_home');
  String get archivedRecordsTooltip => _translate('archived_records_tooltip');
  String get addTreatmentTooltip => _translate('add_treatment_tooltip');
  String get notesOptional => _translate('notes_optional');
  String get addNotesHint => _translate('add_notes_hint');
  String get pleaseSelectDisease => _translate('please_select_disease');
  String get pleaseSignIn => _translate('please_sign_in');
  String get rainWarning => _translate('rain_warning');
  String get rainWarningContent => _translate('rain_warning_content');
  String get continueText => _translate('continue_text');
  String get treatmentSubmittedPending => _translate('treatment_submitted_pending');
  String get awaitingAdminApproval => _translate('awaiting_admin_approval');
  String get archiveConfirmTitle => _translate('archive_confirm_title');
  String get archivedSuccess => _translate('archived_success');
  String get failedToArchive => _translate('failed_to_archive');
  String get failedToSchedule => _translate('failed_to_schedule');
  String get scheduleTreatment => _translate('schedule_treatment');

  // Camera & Detection
  String get cameraDetection => _translate('camera_detection');
  String get takePhotoTitle => _translate('take_photo_title');
  String get userNotAuthenticated => _translate('user_not_authenticated');
  String get detectionFailed => _translate('detection_failed');
  String get cameraUnavailable => _translate('camera_unavailable');
  String get cameraErrorHint => _translate('camera_error_hint');
  String get holdSteady => _translate('hold_steady');
  String get holdSteadyHint => _translate('hold_steady_hint');
  String get cameraUnstable => _translate('camera_unstable');
  String get focusingCamera => _translate('focusing_camera');
  String get scanning => _translate('scanning');
  String get useGalleryInstead => _translate('use_gallery_instead');
  String get processingHint => _translate('processing_hint');
  String get cameraInstruction => _translate('camera_instruction');
  String get photoProof => _translate('photo_proof');
  String get photoProofInstruction => _translate('photo_proof_instruction');
  String get treatmentCompletedPhoto => _translate('treatment_completed_photo');
  String get failedToComplete => _translate('failed_to_complete');
  String get noCameraFound => _translate('no_camera_found');
  String get diseaseDetection => _translate('disease_detection');
  String get detectRiceLeafDisease => _translate('detect_rice_leaf_disease');
  String get captureSelectHint => _translate('capture_select_hint');
  String get tipsForBestResults => _translate('tips_for_best_results');
  String get tipGoodLighting => _translate('tip_good_lighting');
  String get tipFocusLeaf => _translate('tip_focus_leaf');
  String get tipAvoidShadows => _translate('tip_avoid_shadows');
  String get tipCaptureEntireLeaf => _translate('tip_capture_entire_leaf');
  String get description => _translate('description');
  String get symptoms => _translate('symptoms');
  String get causes => _translate('causes');
  String get prevention => _translate('prevention');
  String get treatmentProtocol => _translate('treatment_protocol');
  String get moreDetails => _translate('more_details');
  String get couldNotOpenBrowser => _translate('could_not_open_browser');
  String get capturing => _translate('capturing');
  String get done => _translate('done');
  String get dateTimeLabel => _translate('date_time_label');
  String get adminLogin => _translate('admin_login');
  String get smartfarmingDashboard => _translate('smartfarming_dashboard');
  String get adminEmail => _translate('admin_email');
  String get adminPassword => _translate('admin_password');
  String get signIn => _translate('sign_in');
  String get pleaseEnterEmail => _translate('please_enter_email');
  String get pleaseEnterValidEmail => _translate('please_enter_valid_email');
  String get pleaseEnterPassword => _translate('please_enter_password');
  String get accessDeniedAdminOnly => _translate('access_denied_admin_only');
  String get loginFailedSimple => _translate('login_failed_simple');

  String errorTakingPicture(String error) =>
      translate('error_taking_picture', {'error': error});
  String errorGeneric(String error) =>
      translate('error_generic', {'error': error});
  String errorPickingImage(String error) =>
      translate('error_picking_image', {'error': error});
  String failedToInitializeCamera(String error) =>
      translate('failed_to_initialize_camera', {'error': error});

  // Dashboard extras
  String get weatherOffline => _translate('weather_offline');

  // Dynamic translate for keys with placeholders
  String get noTreatmentsYet => _translate('no_treatments_yet');
  String noTreatmentsForDate(String date) =>
      translate('no_treatments_for_date', {'date': date});
  String noTreatmentsScheduled(String date) =>
      translate('no_treatments_scheduled', {'date': date});
  String archiveConfirmMessage(String type, String disease) =>
      translate('archive_confirm_message', {'type': type, 'disease': disease});
  String scheduleAssignedCount(int count) =>
      translate('schedule_assigned_count', {'count': count.toString()});
}

// ---------------------------------------------------------------------------
// Delegate Ã¢â‚¬â€ synchronous load, no async needed since data is in-memory.
// ---------------------------------------------------------------------------
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fil', 'ceb'].contains(locale.languageCode);

  @override
  // SynchronousFuture avoids the async gap between locale change and
  // AppLocalizations being available Ã¢â‚¬â€ widgets never see a null instance.
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  // Must return true so Flutter calls load() again when the locale changes.
  // Returning false would reuse the old instance with the wrong language.
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

// ---------------------------------------------------------------------------
// Cebuano bridge delegates.
//
// Flutter 3.41.7's flutter_localizations does NOT ship Cebuano ('ceb') data,
// so when the app locale is 'ceb' the Global*Localizations delegates report
// isSupported == false and Flutter loads NO MaterialLocalizations, crashing
// with "No MaterialLocalizations found". These bridges accept 'ceb' and load
// the framework data for 'fil' (the closest supported Philippine language).
// AppLocalizations itself still serves real Cebuano strings via its own map.
// ---------------------------------------------------------------------------
class CebAwareMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const CebAwareMaterialLocalizationsDelegate();

  static Locale _fallbackLocale(Locale locale) =>
      locale.languageCode == 'ceb' ? const Locale('fil') : locale;

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ceb' ||
      GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallbackLocale(locale));

  @override
  bool shouldReload(CebAwareMaterialLocalizationsDelegate old) => false;
}

class CebAwareWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const CebAwareWidgetsLocalizationsDelegate();

  static Locale _fallbackLocale(Locale locale) =>
      locale.languageCode == 'ceb' ? const Locale('fil') : locale;

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ceb' ||
      GlobalWidgetsLocalizations.delegate.isSupported(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_fallbackLocale(locale));

  @override
  bool shouldReload(CebAwareWidgetsLocalizationsDelegate old) => false;
}

class CebAwareCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CebAwareCupertinoLocalizationsDelegate();

  static Locale _fallbackLocale(Locale locale) =>
      locale.languageCode == 'ceb' ? const Locale('fil') : locale;

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ceb' ||
      GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallbackLocale(locale));

  @override
  bool shouldReload(CebAwareCupertinoLocalizationsDelegate old) => false;
}
