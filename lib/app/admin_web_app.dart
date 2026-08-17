import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/routes/app_routes.dart';
import '../core/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/treatment_provider.dart';
import '../providers/soil_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/unknown_route_screen.dart';

/// Web-only admin dashboard. All admin features.
class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

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
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'SMARTFARMING - Admin Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.adminWebTheme,
            darkTheme: AppTheme.adminWebDarkTheme,
            themeMode: ThemeMode.light,
            locale: langProvider.language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              CebAwareMaterialLocalizationsDelegate(),
              CebAwareWidgetsLocalizationsDelegate(),
              CebAwareCupertinoLocalizationsDelegate(),
            ],
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.adminWebRoutes,
            onUnknownRoute: (_) => MaterialPageRoute(
              builder: (_) => const UnknownRouteScreen(),
            ),
            navigatorKey: AppRoutes.navigatorKey,
          );
        },
      ),
    );
  }
}
