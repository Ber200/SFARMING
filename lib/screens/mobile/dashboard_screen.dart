import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/detection_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/soil_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/farmer_bottom_nav_bar.dart';
import '../../widgets/farmer_notifications_modal.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    final isOnline = connectivity.isOnline && !authProvider.isOfflineMode;

    if (userId.isNotEmpty) {
      Provider.of<DetectionProvider>(context, listen: false)
          .loadDetections(userId, isOnline: isOnline);
      Provider.of<TreatmentProvider>(context, listen: false)
          .loadTreatments(userId, isOnline: isOnline);
      Provider.of<SoilProvider>(context, listen: false)
          .loadSoilData(userId, isOnline: isOnline);
      _loadDashboardWeather(isOnline);
    }
  }

  Future<void> _loadDashboardWeather(bool isOnline) async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.loadFarmWeather(isOnline: isOnline);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: Text(l10n.dashboard),
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifications, _) {
              final unread = notifications.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      FarmerNotificationsModal.show(context);
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 4,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.dashboard),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.brandPrimary,
              Color(0xFF0B6B43),
              Color(0xFFF5FAF7),
            ],
            stops: [0.0, 0.12, 0.35],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: AppTheme.brandPrimary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Welcome Header ──
                        _buildWelcomeHeader(context, l10n),
                        const SizedBox(height: 20),

                        // ── Primary Action: Real-Time Scan Button ──
                        QuickActionButton(
                          icon: Icons.center_focus_strong_rounded,
                          label: 'Real-Time Scan',
                          color: Colors.greenAccent,
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.realTimeScan);
                          },
                        ),
                        const SizedBox(height: 10),

                        // ── Secondary Actions: Capture Image & Detection History ──
                        Row(
                          children: [
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.camera_alt_rounded,
                                label: 'Capture Image',
                                color: AppTheme.brandLight,
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRoutes.cameraDetection);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.history_rounded,
                                label: 'Detection History',
                                color: AppTheme.brandMid,
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRoutes.detectionHistory);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        QuickActionButton(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Ask AI Farm Assistant',
                          color: AppTheme.brandPrimary,
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.aiAssistant);
                          },
                        ),

                        // ── Overview Section ──
                        const SizedBox(height: 28),
                        _sectionHeader(context, 'Overview'),
                        const SizedBox(height: 12),
                        _buildStatsRow(context, l10n),
                        const SizedBox(height: 14),
                        _buildCardsRow(
                          context,
                          l10n.latestDetection,
                          l10n.nextTreatment,
                          l10n,
                        ),
                        const SizedBox(height: 14),
                        _buildArchiveCard(context, l10n),

                        // ── Environment Section ──
                        const SizedBox(height: 28),
                        _sectionHeader(context, 'Environment'),
                        const SizedBox(height: 12),
                        _buildSoilCard(context, l10n),
                        const SizedBox(height: 14),
                        _buildWeatherCard(context, l10n),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FarmerBottomNavBar(currentIndex: 0),
    );
  }

  // ── Welcome Header with date ──
  Widget _buildWelcomeHeader(BuildContext context, AppLocalizations l10n) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.welcome}, ${authProvider.currentUser?.name ?? l10n.farmer}!',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Section header ──
  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.brandPrimary,
          ),
    );
  }

  Widget _buildCardsRow(
    BuildContext context,
    String latestTitle,
    String nextTitle,
    AppLocalizations l10n,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Consumer<DetectionProvider>(
              builder: (context, detectionProvider, _) {
                final latest = detectionProvider.getLatestDetection();
                return DashboardCard(
                  title: latestTitle,
                  child: latest != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              latest.disease,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${l10n.confidence}: ${(latest.confidence * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${l10n.date}: ${_formatDate(latest.timestamp)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        )
                      : Text(
                          l10n.noDetectionsYet,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<TreatmentProvider>(
              builder: (context, treatmentProvider, _) {
                final upcoming = treatmentProvider.pendingTreatments
                  ..sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
                final next = upcoming.isNotEmpty ? upcoming.first : null;

                return DashboardCard(
                  title: nextTitle,
                  child: next != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              next.disease,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.date}: ${_formatDate(next.scheduleDate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.treatmentCalendar);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                child: Text(l10n.viewAll),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          l10n.noUpcomingTreatments,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Consumer<DetectionProvider>(
              builder: (context, detectionProvider, _) {
                return DashboardCard(
                  title: l10n.totalDetections,
                  child: Text(
                    '${detectionProvider.totalDetections}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<TreatmentProvider>(
              builder: (context, treatmentProvider, _) {
                return DashboardCard(
                  title: l10n.pendingTreatments,
                  child: Text(
                    '${treatmentProvider.pendingTreatments.length}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(BuildContext context, AppLocalizations l10n) {
    return Consumer<TreatmentProvider>(
      builder: (context, treatmentProvider, _) {
        final count = treatmentProvider.archivedTreatments.length;
        return GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.farmerArchive),
          child: DashboardCard(
            title: l10n.archivedRecords,
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.brandPrimary.withValues(alpha: 0.5),
              size: 14,
            ),
            child: Text(
              '$count archived',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoilCard(BuildContext context, AppLocalizations l10n) {
    return Consumer<SoilProvider>(
      builder: (context, soilProvider, _) {
        final soilData = soilProvider.soilData;
        return GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.soilMonitoring),
          child: DashboardCard(
            title: l10n.soilMonitoring,
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.brandPrimary.withValues(alpha: 0.5),
              size: 14,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn(
                      context,
                      Icons.water_drop_rounded,
                      soilData?.ph?.toStringAsFixed(1) ?? l10n.noData,
                      l10n.phLevel,
                    ),
                    _statColumn(
                      context,
                      Icons.opacity_rounded,
                      soilData?.moisture != null
                          ? '${soilData!.moisture!.toStringAsFixed(0)}%'
                          : l10n.noData,
                      l10n.moisture,
                    ),
                  ],
                ),
                if (soilData != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getMoistureStatusColor(soilData.moisture)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      soilData.calculatedStatus,
                      style: TextStyle(
                        color: _getMoistureStatusColor(soilData.moisture),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statColumn(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 26, color: AppTheme.brandPrimary),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(BuildContext context, AppLocalizations l10n) {
    return Consumer2<WeatherProvider, ConnectivityProvider>(
      builder: (context, weatherProvider, connectivity, _) {
        final weather = weatherProvider.currentWeather;
        final response = weatherProvider.weatherResponse;
        final forecasts = weatherProvider.forecast;
        final isOffline = weatherProvider.isOffline;
        final isLoading = weatherProvider.isLoading;

        return GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.weatherDetails),
          child: DashboardCard(
            title: l10n.weather,
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.brandPrimary.withValues(alpha: 0.5),
              size: 14,
            ),
            child: isLoading && weather == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Loading Open-Meteo farm weather...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  )
                : isOffline && weather == null
                    ? Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.grey[500], size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.weatherOffline,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      )
                    : weather != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getWeatherIcon(weather.condition),
                                          color: AppTheme.brandPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            weather.locationName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOffline)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Cached',
                                        style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 2×2 Weather Metrics Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _weatherMetric(
                                      context,
                                      Icons.thermostat_rounded,
                                      '${weather.temperature.toStringAsFixed(0)}°C',
                                      l10n.temperature,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _weatherMetric(
                                      context,
                                      Icons.water_drop_rounded,
                                      '${weather.humidity.toStringAsFixed(0)}%',
                                      l10n.humidity,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _weatherMetric(
                                      context,
                                      Icons.umbrella_rounded,
                                      '${(weather.rainAmount ?? 0.0).toStringAsFixed(1)} mm',
                                      'Rainfall',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _weatherMetric(
                                      context,
                                      Icons.air_rounded,
                                      '${weather.windSpeed.toStringAsFixed(0)} km/h',
                                      'Wind',
                                    ),
                                  ),
                                ],
                              ),

                              // Forecast Section
                              if (forecasts.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                const Text(
                                  'Daily Forecast',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 64,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: forecasts.take(4).length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (ctx, idx) {
                                      final f = forecasts[idx];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Day ${idx + 1}',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${f.minTemperature.toStringAsFixed(0)}° - ${f.maxTemperature.toStringAsFixed(0)}°C',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              f.description,
                                              style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Rice Farming Recommendation Banner
                              if (response != null && response.riceFarmingAdvice.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.nature_people_rounded, color: AppTheme.brandPrimary, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          response.riceFarmingAdvice.first,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.brandPrimary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Text(
                            l10n.loadingWeather,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
          ),
        );
      },
    );
  }

  // ── Compact weather metric tile for 2×2 grid ──
  Widget _weatherMetric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.brandPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('thunder') || cond.contains('storm')) return Icons.thunderstorm;
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) return Icons.umbrella;
    if (cond.contains('snow') || cond.contains('sleet') || cond.contains('hail') || cond.contains('ice')) return Icons.ac_unit;
    if (cond.contains('fog') || cond.contains('mist') || cond.contains('haze')) return Icons.blur_on;
    if (cond.contains('wind') || cond.contains('gale') || cond.contains('breeze')) return Icons.air;
    if (cond.contains('cloudy') || cond.contains('overcast')) return Icons.cloud;
    if (cond.contains('partly')) return Icons.cloud_queue;
    if (cond.contains('sun') || cond.contains('clear')) return Icons.wb_sunny;
    return Icons.cloud_queue;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getMoistureStatusColor(double? moisture) {
    if (moisture == null) return Colors.grey;
    if (moisture < 30) return Colors.orange;
    if (moisture > 70) return Colors.blue;
    return AppTheme.brandLight;
  }
}
