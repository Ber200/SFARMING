import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/soil_provider.dart';
import '../providers/treatment_provider.dart';
import '../providers/weather_provider.dart';
import '../services/local_storage_service.dart';
import '../services/weather_service.dart';

class FarmerSettingsSheet extends StatefulWidget {
  const FarmerSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FarmerSettingsSheet(),
    );
  }

  @override
  State<FarmerSettingsSheet> createState() => _FarmerSettingsSheetState();
}

class _FarmerSettingsSheetState extends State<FarmerSettingsSheet> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langProvider = Provider.of<LanguageProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.settings_rounded, color: AppTheme.brandPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n.settings,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Weather & Rain Alerts'),
                  subtitle: const Text('Notify in real time when heavy rain (>50%) is expected'),
                  value: settings.weatherAlertsEnabled,
                  activeThumbColor: AppTheme.brandPrimary,
                  onChanged: (val) {
                    settings.setWeatherAlertsEnabled(val);
                    if (val) _refreshWeatherNow();
                  },
                ),
                SwitchListTile(
                  title: const Text('Treatment Reminders'),
                  subtitle: const Text('Receive reminders for scheduled crop treatments'),
                  value: settings.treatmentRemindersEnabled,
                  activeThumbColor: AppTheme.brandPrimary,
                  onChanged: (val) async {
                    final treatmentProvider =
                        Provider.of<TreatmentProvider>(context, listen: false);
                    await settings.setTreatmentRemindersEnabled(val);
                    await treatmentProvider.applyReminderSetting(val);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppTheme.brandPrimary),
                  title: Text(l10n.language),
                  subtitle: Text(langProvider.language.displayName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _showLanguagePicker(context, langProvider);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: AppTheme.brandPrimary),
                  title: const Text('Clear Local Cache'),
                  subtitle: const Text('Clear cached weather and offline detection logs'),
                  trailing: _isClearing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.brandPrimary,
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  enabled: !_isClearing,
                  onTap: _isClearing ? null : () => _clearCache(context),
                ),
                const SizedBox(height: 20),
                Text(
                  'ABOUT APPLICATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppTheme.brandPrimary),
                  title: Text('SFARM Smart Farming Assistant'),
                  subtitle: Text('Version 1.2.0 (Build 2026.02)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger an immediate weather refresh so a rain warning fires right away
  /// when the alert is switched on and heavy rain is already forecast.
  void _refreshWeatherNow() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    final isOnline = connectivity.isOnline && !auth.isOfflineMode;
    Provider.of<WeatherProvider>(context, listen: false).refreshWeather(
      isOnline: isOnline,
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Local Cache?'),
        content: const Text(
          'This deletes cached weather and offline detection/treatment logs. '
          'Online records will be restored from the server, but records created '
          'offline that were not yet synced will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _isClearing = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
    final treatmentProvider = Provider.of<TreatmentProvider>(context, listen: false);
    final soilProvider = Provider.of<SoilProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);

    final userId = auth.currentUser?.id ?? '';
    final isOnline = connectivity.isOnline && !auth.isOfflineMode;

    await LocalStorageService.clearAllData();
    await WeatherService().clearCache();

    if (userId.isNotEmpty) {
      await detectionProvider.loadDetections(userId, isOnline: isOnline);
      await treatmentProvider.loadTreatments(userId, isOnline: isOnline);
      await soilProvider.loadSoilData(userId, isOnline: isOnline);
    }
    await weatherProvider.refreshWeather(isOnline: isOnline);

    if (!context.mounted) return;
    setState(() => _isClearing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local cache cleared. Data reloaded from the server.'),
        backgroundColor: AppTheme.brandMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LanguageProvider langProvider) {
    AppLanguage? picked = langProvider.language;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Language',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...AppLanguage.values.map(
                  (lang) => ListTile(
                    leading: Icon(
                      picked == lang
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: picked == lang ? AppTheme.brandPrimary : Colors.grey,
                    ),
                    title: Text(lang.displayName),
                    trailing: picked == lang
                        ? const Icon(Icons.check_rounded, color: AppTheme.brandPrimary)
                        : null,
                    onTap: () => setSheetState(() => picked = lang),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          langProvider.setLanguage(picked!);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
