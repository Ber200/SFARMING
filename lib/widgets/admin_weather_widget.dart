import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/treatment_provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../models/weather_ai_analysis.dart';
import '../models/weather_forecast_model.dart';
import '../core/theme/app_theme.dart';
import '../services/ai_context_builder.dart';

/// Admin "Farm Weather Monitoring" section: current weather, a live 7-day
/// forecast from the weather API, and an AI-generated agricultural analysis
/// of the forecast. Weather data and AI output are visually separated.
class AdminWeatherWidget extends StatefulWidget {
  const AdminWeatherWidget({super.key});

  @override
  State<AdminWeatherWidget> createState() => _AdminWeatherWidgetState();
}

class _AdminWeatherWidgetState extends State<AdminWeatherWidget> {
  static const Color _aiAccent = Color(0xFF6A3DC9);
  static const Color _aiBorder = Color(0xFFB7A4E8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _triggerAiAnalysisIfNeeded();
      }
    });
  }

  void _triggerAiAnalysisIfNeeded({bool force = false}) {
    if (!mounted) return;
    final wp = Provider.of<WeatherProvider>(context, listen: false);
    final detProvider = Provider.of<DetectionProvider>(context, listen: false);
    final treatProvider = Provider.of<TreatmentProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final langCode = langProvider.language.code;
    final farmContext = AiContextBuilder.farmSnapshot(
      detections: detProvider.detections,
      treatments: treatProvider.treatments,
      weather: wp.currentWeather,
      farmLocation: authProvider.currentUser?.farmLocation ?? wp.currentFarm.fullAddress,
    );

    if (force) {
      wp.regenerateWeatherAnalysis(
        force: true,
        languageCode: langCode,
        farmContext: farmContext,
      );
    } else {
      wp.ensureWeatherAnalysis(
        languageCode: langCode,
        farmContext: farmContext,
      );
    }
  }

  Future<void> _refresh(BuildContext context, WeatherProvider wp) async {
    await wp.refreshWeather();
    if (!mounted) return;
    _triggerAiAnalysisIfNeeded(force: true);
  }

  Future<void> _regenerateAnalysis(BuildContext context, WeatherProvider wp) async {
    _triggerAiAnalysisIfNeeded(force: true);
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, wp, _) {
        if (wp.isLoading && wp.currentWeather == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.farmCardDecoration(),
            child: const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.adminPrimary),
                ),
                SizedBox(width: 12),
                Text('Fetching live farm weather...'),
              ],
            ),
          );
        }

        final weather = wp.currentWeather;
        if (weather == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.farmCardDecoration(),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Weather Monitoring: Service temporarily offline or farm location missing.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                TextButton(
                  onPressed: () => wp.refreshWeather(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final farm = weather.farmLocation;
        final warnings = weather.activeWarnings;
        final topWarning = warnings.first;

        // Basic Farm Address (Barangay, City)
        final String basicAddress = farm.barangay.toLowerCase().startsWith('brgy') ||
                farm.barangay.toLowerCase().startsWith('barangay')
            ? '${farm.barangay}, ${farm.municipality}'
            : 'Barangay ${farm.barangay}, ${farm.municipality}';

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.adminPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grass_rounded,
                          size: 18,
                          color: AppTheme.adminPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Farm Weather Monitoring',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text(
                              'Updated ${DateFormat('HH:mm').format(weather.timestamp)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: wp.isLoading ? null : () => _refresh(context, wp),
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.adminPrimary),
                        tooltip: 'Refresh Forecast & Analysis',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Farm Location Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        size: 22,
                        color: AppTheme.adminPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                farm.farmName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.adminPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Farm Location',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.adminPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  basicAddress,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Current Weather Information Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Condition Header Row
                    Row(
                      children: [
                        _buildWeatherIcon(weather),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT WEATHER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    weather.condition,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Metric Cards Row
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildMetricChip(
                          icon: Icons.thermostat_rounded,
                          iconColor: const Color(0xFFF97316),
                          bgColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFFEDD5),
                          label: 'Temperature',
                          value: '${weather.temperature.toStringAsFixed(1)}°C',
                        ),
                        _buildMetricChip(
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFFDBEAFE),
                          label: 'Humidity',
                          value: '${weather.humidity.toStringAsFixed(0)}%',
                        ),
                        _buildMetricChip(
                          icon: Icons.air_rounded,
                          iconColor: const Color(0xFF14B8A6),
                          bgColor: const Color(0xFFF0FDFA),
                          borderColor: const Color(0xFFCCFBF1),
                          label: 'Wind Speed',
                          value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dynamic AI Advisory & Warning Status Banner
              Builder(
                builder: (context) {
                  final aiAdvisory = wp.aiAnalysis?.effectiveAdminAdvisory;
                  final String advisoryText;
                  if (aiAdvisory != null && aiAdvisory.trim().isNotEmpty) {
                    advisoryText = aiAdvisory.trim();
                  } else if (weather.farmingRecommendations.isNotEmpty) {
                    advisoryText = weather.farmingRecommendations.first;
                  } else if (topWarning.title.isNotEmpty) {
                    advisoryText = '${topWarning.title}: ${topWarning.suggestedAction}';
                  } else {
                    advisoryText = 'Current conditions are favorable for routine field monitoring and crop maintenance.';
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.shield_outlined, size: 18, color: Color(0xFF16A34A)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Advisory: $advisoryText',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),


              const SizedBox(height: 18),

              // Inline "updating" indicator during a background weather refresh
              if (wp.isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.adminPrimary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Updating weather forecast...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),

              _buildForecastSection(context, wp),
              const SizedBox(height: 18),
              _buildAiAnalysisSection(context, wp),
            ],
          ),
        );
      },
    );
  }

  // ── 7-Day Forecast ─────────────────────────────────────────────────────

  Widget _buildForecastSection(BuildContext context, WeatherProvider wp) {
    final forecast = wp.forecast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.adminPrimary),
            const SizedBox(width: 8),
            const Text(
              '7-Day Forecast',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.adminPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.adminPrimary.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'LIVE WEATHER DATA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.adminPrimary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (forecast.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No forecast data available yet.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _buildForecastDayCard(forecast[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildForecastDayCard(WeatherForecastModel day) {
    final unfavorable = _isUnfavorableDay(day);
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());

    return Container(
      width: 126,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTheme.adminPrimary
              : (unfavorable ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
          width: isToday ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEE').format(day.date).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppTheme.adminPrimary : const Color(0xFF475569),
                ),
              ),
              Text(
                DateFormat('MMM d').format(day.date),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Icon(
              _weatherIcon(day.condition),
              size: 28,
              color: _weatherIconColor(day.condition),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${day.maxTemperature.toStringAsFixed(0)}° / ${day.minTemperature.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              day.condition,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop_rounded, size: 11, color: Color(0xFF2563EB)),
                const SizedBox(width: 3),
                Text(
                  day.rainProbability != null
                      ? '${day.rainProbability!.round()}%'
                      : '${(day.precipitation ?? 0).toStringAsFixed(0)}mm',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                if (unfavorable) ...[
                  const Spacer(),
                  const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFD97706)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isUnfavorableDay(WeatherForecastModel day) {
    final cond = day.condition.toLowerCase();
    final rainy = (day.rainProbability ?? 0) >= 60 ||
        (day.precipitation ?? 0) > 0.1 ||
        cond.contains('rain') ||
        cond.contains('thunder') ||
        cond.contains('storm') ||
        cond.contains('drizzle');
    final windy = (day.windSpeed ?? 0) > 20;
    final hot = day.maxTemperature >= 35;
    return rainy || windy || hot;
  }

  IconData _weatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('thunder') || cond.contains('storm')) return Icons.thunderstorm;
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) return Icons.umbrella;
    if (cond.contains('snow') || cond.contains('sleet') || cond.contains('hail') || cond.contains('ice')) return Icons.ac_unit;
    if (cond.contains('fog') || cond.contains('mist') || cond.contains('haze')) return Icons.blur_on;
    if (cond.contains('wind') || cond.contains('gale') || cond.contains('breeze')) return Icons.air;
    if (cond.contains('overcast')) return Icons.cloud;
    if (cond.contains('cloud')) return Icons.cloud_queue;
    return Icons.wb_sunny;
  }

  Color _weatherIconColor(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('thunder') || cond.contains('storm')) return Colors.deepPurple;
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) return Colors.blue;
    if (cond.contains('fog') || cond.contains('mist') || cond.contains('haze')) return Colors.grey;
    if (cond.contains('overcast')) return Colors.blueGrey;
    if (cond.contains('cloud')) return Colors.orangeAccent;
    return Colors.orange;
  }

  // ── AI Weather Analysis ────────────────────────────────────────────────

  Widget _buildAiAnalysisSection(BuildContext context, WeatherProvider wp) {
    final analysis = wp.aiAnalysis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _aiAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 16, color: _aiAccent),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Agricultural Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _aiAccent,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _aiAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AI-GENERATED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _aiAccent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: wp.isAnalyzing ? null : () => _regenerateAnalysis(context, wp),
                icon: const Icon(Icons.refresh_rounded, size: 18, color: _aiAccent),
                tooltip: 'Regenerate Analysis',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (wp.isAnalyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _aiAccent),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Analyzing forecast & generating agricultural recommendations...',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                ],
              ),
            )
          else if (analysis == null && wp.aiErrorMessage != null)
            _buildAiError(context, wp)
          else if (analysis == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'AI analysis will automatically analyze live weather forecast patterns.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            )
          else ...[
            if (wp.aiErrorMessage != null) _buildAiStaleNote(),
            _buildAiSummary(analysis),
            _buildAiImportantDays(analysis),
            _buildAiGeneralRecommendations(analysis),
          ],
        ],
      ),
    );
  }

  Widget _buildAiError(BuildContext context, WeatherProvider wp) {
    final message = wp.aiErrorMessage ?? 'AI weather analysis is currently unavailable.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(
            onPressed: () => _regenerateAnalysis(context, wp),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStaleNote() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        'AI weather analysis is currently unavailable. Showing the last analysis.',
        style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAiSummary(WeatherAiAnalysis analysis) {
    final color = _riskColor(analysis.riskLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Risk Level: ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                analysis.riskLevel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          analysis.overallSummary,
          style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildAiImportantDays(WeatherAiAnalysis analysis) {
    if (analysis.importantDays.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Upcoming Concerns',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        ...analysis.importantDays.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _aiBorder.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 14, color: _aiAccent),
                      const SizedBox(width: 6),
                      Text(
                        d.date,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  if (d.weatherConcern.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      d.weatherConcern,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[800], height: 1.35),
                    ),
                  ],
                  if (d.recommendation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Recommendation: ${d.recommendation}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF4A2C8A),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildAiGeneralRecommendations(WeatherAiAnalysis analysis) {
    if (analysis.generalRecommendations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'General Recommendations',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        ...analysis.generalRecommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: _aiAccent)),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'moderate':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  Widget _buildWeatherIcon(dynamic weather) {
    String url = weather.iconUrl ?? '';
    if (url.startsWith('//')) {
      url = 'https:$url';
    } else if (url.isNotEmpty && !url.startsWith('http')) {
      url = 'https://$url';
    }

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  _weatherIcon(weather.condition),
                  size: 28,
                  color: _weatherIconColor(weather.condition),
                ),
              ),
            )
          : Icon(
              _weatherIcon(weather.condition),
              size: 28,
              color: _weatherIconColor(weather.condition),
            ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
