import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/weather_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../providers/treatment_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/weather_model.dart';
import '../../../models/weather_forecast_model.dart';
import '../../../services/ai_context_builder.dart';


/// Screen listing meaningful farming weather metrics and an AI-driven 7-day forecast
/// with actionable, practical agronomic recommendations grounded in the live forecast.
class WeatherDetailsScreen extends StatefulWidget {
  const WeatherDetailsScreen({super.key});

  @override
  State<WeatherDetailsScreen> createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAiAnalysisIfNeeded();
    });
  }

  void _triggerAiAnalysisIfNeeded({bool force = false}) {
    if (!mounted) return;
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
    final treatmentProvider = Provider.of<TreatmentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final langCode = langProvider.language.code;
    final farmContext = AiContextBuilder.farmSnapshot(
      detections: detectionProvider.detections,
      treatments: treatmentProvider.treatments,
      weather: weatherProvider.currentWeather,
      farmLocation: authProvider.currentUser?.farmLocation ?? weatherProvider.currentFarm.fullAddress,
    );


    if (force) {
      weatherProvider.regenerateWeatherAnalysis(
        force: true,
        languageCode: langCode,
        farmContext: farmContext,
      );
    } else {
      weatherProvider.ensureWeatherAnalysis(
        languageCode: langCode,
        farmContext: farmContext,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'BAD':
        return Colors.red.shade700;
      case 'WARNING':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
        return Colors.red.shade700;
      case 'MODERATE':
      case 'MEDIUM':
        return Colors.orange.shade800;
      default:
        return AppTheme.brandPrimary;
    }
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

  Color _getWeatherColor(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('thunder') || cond.contains('storm')) return Colors.deepPurple;
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) return Colors.blue;
    if (cond.contains('snow') || cond.contains('sleet') || cond.contains('hail') || cond.contains('ice')) return Colors.lightBlueAccent;
    if (cond.contains('fog') || cond.contains('mist') || cond.contains('haze')) return Colors.grey;
    if (cond.contains('wind') || cond.contains('gale') || cond.contains('breeze')) return Colors.teal;
    if (cond.contains('cloudy') || cond.contains('overcast')) return Colors.blueGrey;
    if (cond.contains('partly')) return Colors.orangeAccent;
    if (cond.contains('sun') || cond.contains('clear')) return Colors.orange;
    return Colors.teal;
  }

  Widget _getWeatherIconWidget(String? iconUrl, String condition, {double size = 32}) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      final fullUrl = iconUrl.startsWith('http') ? iconUrl : 'https:$iconUrl';
      return Image.network(
        fullUrl,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Icon(_getWeatherIcon(condition), size: size, color: _getWeatherColor(condition));
        },
      );
    }
    return Icon(_getWeatherIcon(condition), size: size, color: _getWeatherColor(condition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('7-Day Farming Forecast'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Re-analyze with AI',
            onPressed: () => _triggerAiAnalysisIfNeeded(force: true),
          ),
        ],
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          final weather = weatherProvider.currentWeather;
          final forecast = weatherProvider.forecast;

          if (weather == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Weather data not available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final isOnline = connectivity.isOnline && !auth.isOfflineMode;
                      weatherProvider.refreshWeather(isOnline: isOnline);
                      _triggerAiAnalysisIfNeeded(force: true);
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final isOnline = connectivity.isOnline && !auth.isOfflineMode;
              await weatherProvider.refreshWeather(isOnline: isOnline);
              _triggerAiAnalysisIfNeeded(force: true);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner
                  _buildStatusCard(context, weather),
                  const SizedBox(height: 16),

                  // AI 7-Day Farming Recommendation Card
                  _buildAi7DayAdvisoryCard(context, weatherProvider),
                  const SizedBox(height: 16),

                  // Farmer Key Weather Parameters Grid
                  _buildFarmerKeyParameters(context, weather),
                  const SizedBox(height: 20),

                  // Actionable 7-Day Forecast Section with AI daily guidance
                  _buildForecastSection(context, forecast, weatherProvider),
                  const SizedBox(height: 20),

                  // General Smart Recommendations Section
                  _buildRecommendationsSection(context, weather),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, WeatherModel weather) {
    final statusColor = _getStatusColor(weather.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              weather.status == 'BAD'
                  ? Icons.warning_amber_rounded
                  : weather.status == 'WARNING'
                      ? Icons.info_outline
                      : Icons.check_circle_outline_rounded,
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FARMING STATUS: ${weather.status}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.isGoodForSpraying
                      ? 'Optimal weather conditions for field activities and spraying.'
                      : weather.isRainy
                          ? 'Rain forecasted. Protect crops and postpone spraying or irrigation.'
                          : 'Wind or temperature levels require caution. Check advice below.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Strategic AI 7-Day Farming Recommendation Card answering:
  /// "What is the best thing to do during the next 7 days?"
  Widget _buildAi7DayAdvisoryCard(BuildContext context, WeatherProvider wp) {
    final analysis = wp.aiAnalysis;
    final isAnalyzing = wp.isAnalyzing;

    if (isAnalyzing && analysis == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.farmCardDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.brandPrimary),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'AI is analyzing the 7-day forecast for your farm...',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
              ),
            ),


          ],
        ),
      );
    }

    if (analysis == null || analysis.isEmpty) {
      return const SizedBox.shrink();
    }

    final riskColor = _getRiskColor(analysis.riskLevel);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AI badge, Risk Level, and Cached Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI 7-Day Farming Advisory',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary),
                    ),
                    Text(
                      'Action plan based on live forecast & crop status',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${analysis.riskLevel} Risk',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Strategic summary: "What is the best thing to do during the next 7 days?"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 16, color: AppTheme.brandPrimary),
                    SizedBox(width: 6),
                    Text(
                      'BEST ACTION THIS WEEK',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  analysis.overallSummary,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF14532D), height: 1.4, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Best action window chip
          if (analysis.bestActionWindow.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        children: [
                          const TextSpan(text: 'Best Window for Field Work: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: analysis.bestActionWindow, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Weather Risks
          if (analysis.weatherRisks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Weather Risks to Watch:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 6),
            ...analysis.weatherRisks.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        risk,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Crop / Disease Monitoring Advice
          if (analysis.monitoringAdvice.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Crop & Disease Monitoring Advice:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 6),
            ...analysis.monitoringAdvice.map(
              (advice) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.brandPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        advice,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Footer info & Refresh AI action
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                analysis.isCached ? 'Offline Cached Advice' : 'Updated just now with AI',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
              InkWell(
                onTap: isAnalyzing ? null : () => _triggerAiAnalysisIfNeeded(force: true),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAnalyzing)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandPrimary),
                        )
                      else
                        const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.brandPrimary),
                      const SizedBox(width: 4),
                      const Text(
                        'Refresh Advice',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerKeyParameters(BuildContext context, WeatherModel weather) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farming Weather Overview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPrimary,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildParameterTile(
                  'Temperature',
                  '${weather.temperature.toStringAsFixed(0)}°C',
                  weather.temperature > 34 ? 'High heat stress risk' : 'Normal growth range',
                  Icons.thermostat_rounded,
                  Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildParameterTile(
                  'Rain Chance',
                  '${weather.chanceOfRain.toStringAsFixed(0)}%',
                  weather.chanceOfRain > 60 ? 'Delay spraying' : 'Safe for field work',
                  Icons.umbrella_rounded,
                  Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildParameterTile(
                  'Humidity',
                  '${weather.humidity.toStringAsFixed(0)}%',
                  weather.humidity > 80 ? 'Elevated fungal risk' : 'Good moisture level',
                  Icons.water_drop_rounded,
                  Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildParameterTile(
                  'Wind Speed',
                  '${weather.windSpeed.toStringAsFixed(1)} km/h',
                  weather.windSpeed > 20 ? 'Spray drift hazard' : 'Calm breeze',
                  Icons.air_rounded,
                  Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterTile(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(
    BuildContext context,
    List<WeatherForecastModel> forecast,
    WeatherProvider weatherProvider,
  ) {
    if (forecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.farmCardDecoration(),
        child: const Center(child: Text('Loading forecast data...')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Farming Forecast',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPrimary,
              ),
        ),
        const SizedBox(height: 12),
        ...forecast.map((day) => _buildForecastCard(context, day, weatherProvider)),
      ],
    );
  }

  Widget _buildForecastCard(
    BuildContext context,
    WeatherForecastModel day,
    WeatherProvider weatherProvider,
  ) {
    final dayStr = DateFormat('EEEE, MMM d').format(day.date);
    final dateKey = DateFormat('yyyy-MM-dd').format(day.date);
    final isRainy = (day.rainProbability ?? 0) > 50 || day.condition.toLowerCase().contains('rain');
    final isWindy = (day.windSpeed ?? 0) > 20;

    // Retrieve AI-generated recommendation for this specific date
    final aiAnalysis = weatherProvider.aiAnalysis;
    String recommendation = aiAnalysis?.dailyAdvice[dateKey] ?? '';

    // If AI daily advice is not present yet, use intelligent deterministic rule
    if (recommendation.isEmpty) {
      if (isRainy) {
        recommendation = 'Avoid pesticide spraying due to possible rainfall. Inspect field drainage.';
      } else if (isWindy) {
        recommendation = 'Strong winds expected. Avoid chemical spraying to prevent drift.';
      } else if (day.maxTemperature > 34) {
        recommendation = 'High temperatures expected. Ensure adequate crop irrigation.';
      } else {
        recommendation = 'Favorable conditions for field inspection, weeding, and maintenance.';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getWeatherIconWidget(day.icon, day.condition, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      day.condition,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${day.maxTemperature.toStringAsFixed(0)}°C / ${day.minTemperature.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.umbrella, size: 12, color: Colors.blue),
                      const SizedBox(width: 2),
                      Text(
                        'Rain: ${day.rainProbability?.toStringAsFixed(0) ?? "0"}%',
                        style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isRainy ? Colors.amber.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isRainy ? Colors.amber.shade300 : Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isRainy ? Icons.warning_amber_rounded : Icons.lightbulb_rounded,
                  size: 16,
                  color: isRainy ? Colors.amber.shade900 : Colors.green.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommendation: $recommendation',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isRainy ? Colors.amber.shade900 : Colors.green.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, WeatherModel weather) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Farming Guidelines',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPrimary,
                ),
          ),
          const SizedBox(height: 12),
          ...weather.farmingRecommendations.map((rec) => Padding(
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
              )),
        ],
      ),
    );
  }
}
