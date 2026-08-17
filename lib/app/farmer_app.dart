import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../core/routes/app_routes.dart';
import '../core/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/treatment_provider.dart';
import '../providers/soil_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/language_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ai_assistant_provider.dart';
import '../providers/notification_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/unknown_route_screen.dart';

/// Mobile-only farmer app. No admin functionality.
class FarmerApp extends StatelessWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
        ChangeNotifierProvider(create: (_) => TreatmentProvider()),
        ChangeNotifierProvider(create: (_) => SoilProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: _SettingsWirer(
        child: _SyncWirer(
          child: _AppRoot(),
        ),
      ),
    );
  }
}

/// Hosts the single long-lived [MaterialApp].
///
/// Only [locale] is updated when the language changes — the [MaterialApp]
/// itself is never torn down and remounted, so [MaterialLocalizations] stays
/// alive across language switches and the "No MaterialLocalizations found"
/// crash cannot occur.
class _AppRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Read isLoaded once; after that we only watch locale changes.
    final isLoaded = context.select<LanguageProvider, bool>((p) => p.isLoaded);

    if (!isLoaded) {
      // Still reading SharedPreferences — show a minimal loading screen.
      // This MaterialApp is replaced exactly once (when isLoaded flips to
      // true) and never again, so there is no mid-session teardown.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Watch only the locale — changing language updates this property in-place
    // without rebuilding MaterialApp, so the widget tree (and its
    // MaterialLocalizations ancestor) is never destroyed mid-session.
    final locale =
        context.select<LanguageProvider, Locale>((p) => p.language.locale);

    return MaterialApp(
      title: 'SMARTFARMING - Farmer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        CebAwareMaterialLocalizationsDelegate(),
        CebAwareWidgetsLocalizationsDelegate(),
        CebAwareCupertinoLocalizationsDelegate(),
      ],
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.farmerRoutes,
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const UnknownRouteScreen(),
      ),
      navigatorKey: AppRoutes.navigatorKey,
    );
  }
}

/// Wires AuthProvider.onUserLoaded → ConnectivityProvider.setUserId
/// once the provider tree is ready.
class _SyncWirer extends StatefulWidget {
  final Widget child;
  const _SyncWirer({required this.child});

  @override
  State<_SyncWirer> createState() => _SyncWirerState();
}

class _SyncWirerState extends State<_SyncWirer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final connectivity = context.read<ConnectivityProvider>();
      final ai = context.read<AiAssistantProvider>();
      final notifications = context.read<NotificationProvider>();
      auth.onUserLoaded = (userId) {
        connectivity.setUserId(userId);
        ai.bindUser(userId);
        notifications.bindUser(userId);
      };
      auth.onUserLogout = () {
        notifications.unbind();
        connectivity.clearUserId();
      };
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Wires SettingsProvider → WeatherProvider & TreatmentProvider so real-time
/// rain alerts and treatment reminders respect the persisted settings.
class _SettingsWirer extends StatefulWidget {
  final Widget child;
  const _SettingsWirer({required this.child});

  @override
  State<_SettingsWirer> createState() => _SettingsWirerState();
}

class _SettingsWirerState extends State<_SettingsWirer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      context.read<WeatherProvider>().attachSettings(settings);
      context.read<TreatmentProvider>().attachSettings(settings);
      context.read<WeatherProvider>().attachNotifications(
        context.read<NotificationProvider>(),
      );
      context.read<TreatmentProvider>().attachNotifications(
        context.read<NotificationProvider>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
