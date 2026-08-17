import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/weather_provider.dart';
import '../../../models/weather_model.dart';
import '../../../models/farm_location_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/offline_banner.dart';
import '../../../widgets/app_drawer.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Live Weather Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Detailed Forecast',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.weatherDetails),
          ),
          Consumer<WeatherProvider>(
            builder: (context, wp, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Weather',
              onPressed: wp.isLoading ? null : () => wp.refreshWeather(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.weather),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Consumer<WeatherProvider>(
              builder: (context, wp, _) {
                if (wp.hasMissingFarmLocation) {
                  return _buildMissingFarmLocationView(context, wp);
                }

                if (wp.isLoading && wp.currentWeather == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.adminPrimary),
                        SizedBox(height: 16),
                        Text('Loading farm weather data...'),
                      ],
                    ),
                  );
                }

                final weather = wp.currentWeather;
                if (weather == null) {
                  return _buildErrorState(context, wp);
                }

                return RefreshIndicator(
                  onRefresh: () => wp.refreshWeather(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (wp.isOffline) _buildOfflineCacheNotice(context, weather),
                        _buildFarmInfoCard(context, weather.farmLocation),
                        const SizedBox(height: 16),
                        _buildTodayWeatherSummaryCard(context, weather),
                        const SizedBox(height: 16),
                        _buildFarmerContextMetrics(context, weather),
                        const SizedBox(height: 16),
                        if (weather.activeWarnings.isNotEmpty) ...[
                          _buildEarlyWarningSection(context, weather),
                          const SizedBox(height: 16),
                        ],
                        _buildFarmingRecommendationsSection(context, weather),
                        const SizedBox(height: 16),
                        _buildViewDetailedForecastButton(context),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildMissingFarmLocationView(BuildContext context, WeatherProvider wp) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_rounded, size: 64, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                const Text(
                  'No Farm Location Registered',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Weather monitoring requires a registered rice farm location. Please register or update your farm location in your profile settings.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    wp.setFarmLocation(FarmLocationModel.defaultFarm);
                  },
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Register Rice Farm Location'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: AppTheme.adminPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WeatherProvider wp) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Weather Service Temporarily Unavailable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              wp.errorMessage ?? 'Please check your connection and try again.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => wp.refreshWeather(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineCacheNotice(BuildContext context, WeatherModel weather) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline mode: Displaying cached weather from ${DateFormat('MMM dd • HH:mm').format(weather.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoCard(BuildContext context, FarmLocationModel farm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.adminPrimary, AppTheme.adminPrimary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  farm.farmName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Registered Field',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  farm.fullAddress,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWeatherSummaryCard(BuildContext context, WeatherModel weather) {
    final conditionText = weather.condition;
    final advisoryText = weather.isGoodForSpraying
        ? '☀️ Optimal conditions for field monitoring and crop care.'
        : weather.isRainy
            ? '🌧 Rain expected. Postpone spraying and inspect field drainage.'
            : '⚠️ Exercise caution due to wind or heat conditions.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, color: AppTheme.brandPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Farm Weather",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPrimary,
                        ),
                  ),
                ],
              ),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.network(
                weather.iconUrl,
                height: 72,
                width: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, size: 56, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${weather.temperature.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conditionText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Feels like ${weather.feelsLike.toStringAsFixed(0)}°C',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    advisoryText,
                    style: TextStyle(fontSize: 13, color: Colors.green.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerContextMetrics(BuildContext context, WeatherModel weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meaningful Farming Metrics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPrimary,
              ),
        ),
        const SizedBox(height: 12),

        // Rain Probability Card
        _contextMetricCard(
          icon: Icons.umbrella_rounded,
          iconColor: Colors.blue,
          title: 'Rain Probability',
          value: '${weather.chanceOfRain.toStringAsFixed(0)}%',
          explanation: weather.chanceOfRain > 60
              ? 'Rain is likely today. Consider delaying pesticide or fertilizer spraying to avoid wash-off.'
              : weather.chanceOfRain > 30
                  ? 'Possible scattered rain. Monitor cloud movement before field activities.'
                  : 'Low rain chance. Good conditions for spraying and field maintenance.',
          statusBg: weather.chanceOfRain > 60 ? Colors.blue.shade50 : Colors.green.shade50,
          statusBorder: weather.chanceOfRain > 60 ? Colors.blue.shade200 : Colors.green.shade200,
        ),
        const SizedBox(height: 10),

        // Humidity Card
        _contextMetricCard(
          icon: Icons.water_drop_rounded,
          iconColor: Colors.teal,
          title: 'Humidity Level',
          value: '${weather.humidity.toStringAsFixed(0)}%',
          explanation: weather.humidity > 80
              ? 'High humidity detected. Damp conditions increase the risk of fungal diseases (e.g. Sheath Blight).'
              : weather.humidity < 40
                  ? 'Low humidity level. Crop evaporation is high; verify field irrigation levels.'
                  : 'Moderate humidity. Favorable moisture balance for rice crop growth.',
          statusBg: weather.humidity > 80 ? Colors.orange.shade50 : Colors.green.shade50,
          statusBorder: weather.humidity > 80 ? Colors.orange.shade200 : Colors.green.shade200,
        ),
        const SizedBox(height: 10),

        // Wind Speed Card
        _contextMetricCard(
          icon: Icons.air_rounded,
          iconColor: Colors.purple,
          title: 'Wind Condition',
          value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
          explanation: weather.windSpeed > 20
              ? 'Strong winds present. Postpone chemical spraying to prevent spray drift onto neighboring fields.'
              : 'Gentle wind conditions. Safe for targeted field treatment applications.',
          statusBg: weather.windSpeed > 20 ? Colors.orange.shade50 : Colors.green.shade50,
          statusBorder: weather.windSpeed > 20 ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ],
    );
  }

  Widget _contextMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String explanation,
    required Color statusBg,
    required Color statusBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusBorder),
            ),
            child: Text(
              explanation,
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarlyWarningSection(BuildContext context, WeatherModel weather) {
    final warnings = weather.activeWarnings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              'Weather Alerts',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...warnings.map((w) => _buildWarningCard(w)),
      ],
    );
  }

  Widget _buildWarningCard(WeatherWarning warning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(warning.icon, color: warning.color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  warning.title,
                  style: TextStyle(
                    color: warning.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: warning.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  warning.levelLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            warning.description,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggested Action: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: warning.color),
              ),
              Expanded(
                child: Text(
                  warning.suggestedAction,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingRecommendationsSection(BuildContext context, WeatherModel weather) {

    final recs = weather.farmingRecommendations;
    final wp = Provider.of<WeatherProvider>(context, listen: false);
    final ai = wp.aiAnalysis;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                'AI Farming Advisory & Recommendations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
              ),
            ],
          ),
          if (ai != null && ai.overallSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '7-DAY OUTLOOK PLAN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ai.overallSummary,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF14532D),
                      height: 1.35,
                    ),
                  ),
                  if (ai.bestActionWindow.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '• Best window for field work: ${ai.bestActionWindow}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...recs.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailedForecastButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.weatherDetails),
        icon: const Icon(Icons.calendar_month_rounded),
        label: const Text('View 7-Day Farming Forecast'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.adminPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
