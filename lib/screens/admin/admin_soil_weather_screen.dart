import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/soil_data_model.dart';
import '../../models/weather_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/admin_status_badge.dart';

/// Admin view: soil diagnostics (moisture, pH/acidity, NPK) and regional climate conditions for all farmers.
class AdminSoilWeatherScreen extends StatefulWidget {
  const AdminSoilWeatherScreen({super.key});

  @override
  State<AdminSoilWeatherScreen> createState() => _AdminSoilWeatherScreenState();
}

class _AdminSoilWeatherScreenState extends State<AdminSoilWeatherScreen> {
  final FirebaseService _firebase = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _farmers = [];
  final Map<String, SoilDataModel?> _soilByUser = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _firebase.getAllUsers().first;
      final farmers = users.where((u) => u.isFarmer).toList();

      final soil = <String, SoilDataModel?>{};
      for (final u in farmers) {
        soil[u.id] = await _firebase.getSoilData(u.id);
      }

      if (mounted) {
        setState(() {
          _farmers = farmers;
          _soilByUser.clear();
          _soilByUser.addAll(soil);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load soil & weather data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Provider.of<WeatherProvider>(context, listen: false).loadFarmWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFarmers = _farmers.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          (f.farmLocation?.toLowerCase().contains(q) ?? false);
    }).toList();

    return AdminScaffold(
      title: 'Soil Diagnostics & Climate',
      subtitle: 'Nutrient balances, moisture thresholds & environmental conditions across rice plots',
      activeRoute: AppRoutes.adminSoilWeather,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Telemetry',
          onPressed: _loading ? null : _load,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Regional Live Weather Hero ──
                    _buildWeatherCard(context),
                    const SizedBox(height: 24),

                    // ── Farmer Soil Profiles Header & Search ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.grass_rounded, size: 19, color: AppTheme.adminPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Plot Soil Readings & Health Matrix',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.adminTextPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 240,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.adminBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Filter by farmer / plot...',
                              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.adminTextMuted),
                              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.adminTextSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(bottom: 12),
                              isDense: true,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 14),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (filteredFarmers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: AppTheme.adminCardDecoration(),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.search_off_rounded, size: 44, color: AppTheme.adminTextMuted),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No registered farmers found.'
                                    : 'No matching farmers found for "$_searchQuery".',
                                style: const TextStyle(color: AppTheme.adminTextSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredFarmers.map((u) => _buildSoilCard(context, u)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, wp, _) {
        final w = wp.currentWeather;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.adminCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.adminPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, size: 22, color: AppTheme.adminPrimary),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Regional Farm Climate Telemetry',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.adminTextPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Live meteorological conditions influencing soil moisture & plant transpiration',
                            style: TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AdminStatusBadge.fromStatus('Optimal'),
                ],
              ),
              const SizedBox(height: 16),
              if (wp.isLoading)
                const LinearProgressIndicator(color: AppTheme.adminPrimary)
              else if (w != null)
                _weatherContent(context, w)
              else
                Text(
                  wp.errorMessage ?? 'Unable to load live weather.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.5),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _weatherContent(BuildContext context, WeatherModel w) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _weatherChip(Icons.thermostat_rounded, '${w.temperature.toStringAsFixed(1)}°C', 'Ambient Temp', const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
        _weatherChip(Icons.water_drop_rounded, '${w.humidity.toStringAsFixed(0)}%', 'Rel. Humidity', const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
        _weatherChip(Icons.wb_sunny_rounded, w.condition, 'Sky Condition', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
        _weatherChip(Icons.umbrella_rounded, '${w.chanceOfRain.toStringAsFixed(0)}%', 'Precipitation', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _weatherChip(Icons.air_rounded, '${w.windSpeed.toStringAsFixed(1)} km/h', 'Wind Velocity', const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
      ],
    );
  }

  Widget _weatherChip(IconData icon, String value, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.adminTextPrimary)),
              Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.adminTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoilCard(BuildContext context, UserModel user) {
    final soil = _soilByUser[user.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Farmer name, farm location, and status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.adminPrimaryLight,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'F',
                      style: const TextStyle(color: AppTheme.adminPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.adminTextPrimary),
                      ),
                      if (user.farmLocation != null && user.farmLocation!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.adminTextMuted),
                            const SizedBox(width: 3),
                            Text(user.farmLocation!, style: const TextStyle(fontSize: 11, color: AppTheme.adminTextSecondary)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              if (soil?.status != null)
                AdminStatusBadge.fromStatus(soil!.status!)
              else
                AdminStatusBadge.fromStatus(soil != null ? 'Active' : 'No Data'),
            ],
          ),
          const SizedBox(height: 14),

          if (soil == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.adminSurfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.adminTextMuted),
                  SizedBox(width: 8),
                  Text('No soil readings reported yet for this farmer.', style: TextStyle(color: AppTheme.adminTextSecondary, fontSize: 12.5)),
                ],
              ),
            )
          else ...[
            // Primary Metrics: Moisture & pH gauges
            Row(
              children: [
                Expanded(
                  child: _soilMetricGauge(
                    Icons.water_drop_rounded,
                    'Moisture Content',
                    soil.moisture != null ? '${soil.moisture!.toStringAsFixed(1)}%' : 'N/A',
                    _moistureColor(soil.moisture),
                    'Safe range: 30% – 70%',
                    soil.moisture != null ? (soil.moisture! / 100.0).clamp(0.0, 1.0) : 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _soilMetricGauge(
                    Icons.science_rounded,
                    'Soil pH Acidity',
                    soil.ph != null ? soil.ph!.toStringAsFixed(1) : 'N/A',
                    _phColor(soil.ph),
                    'Optimal range: 5.5 – 7.5',
                    soil.ph != null ? ((soil.ph! - 3.0) / 7.0).clamp(0.0, 1.0) : 0.0,
                  ),
                ),
              ],
            ),

            // Secondary NPK, EC, Temperature chips
            if (soil.fertility != null ||
                soil.temperature != null ||
                soil.sunlight != null ||
                soil.nitrogen != null ||
                soil.phosphorus != null ||
                soil.potassium != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (soil.fertility != null)
                    _nutrientChip(Icons.flash_on_rounded, 'Conductivity (EC)', '${soil.fertility!.toStringAsFixed(1)} µS/cm', const Color(0xFF7C3AED)),
                  if (soil.temperature != null)
                    _nutrientChip(Icons.thermostat_rounded, 'Soil Temperature', '${soil.temperature!.toStringAsFixed(1)}°${soil.temperatureUnit == '°F' ? 'F' : 'C'}', const Color(0xFFEA580C)),
                  if (soil.sunlight != null)
                    _nutrientChip(Icons.wb_sunny_rounded, 'Sunlight Lux', '${soil.sunlight!.toStringAsFixed(0)} LUX', const Color(0xFFD97706)),
                  if (soil.nitrogen != null)
                    _nutrientChip(Icons.eco_outlined, 'Nitrogen (N)', '${soil.nitrogen!.toStringAsFixed(1)} mg/kg', AppTheme.brandPrimary),
                  if (soil.phosphorus != null)
                    _nutrientChip(Icons.grain_rounded, 'Phosphorus (P)', '${soil.phosphorus!.toStringAsFixed(1)} mg/kg', const Color(0xFF0284C7)),
                  if (soil.potassium != null)
                    _nutrientChip(Icons.filter_vintage_rounded, 'Potassium (K)', '${soil.potassium!.toStringAsFixed(1)} mg/kg', const Color(0xFF0D9488)),
                ],
              ),
            ],

            // Verification & Source Badges
            if (soil.source == 'device_scan' || soil.source == 'sensor_scan' || soil.verifiedByFarmer == true) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (soil.source == 'device_scan' || soil.source == 'sensor_scan')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors_rounded, size: 12, color: AppTheme.adminPrimary),
                          SizedBox(width: 4),
                          Text('Hardware Sensor Telemetry', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.adminPrimary)),
                        ],
                      ),
                    ),
                  if (soil.verifiedByFarmer == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text('Verified by Farmer', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _soilMetricGauge(IconData icon, String label, String value, Color color, String threshold, double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(threshold, style: const TextStyle(fontSize: 10.5, color: AppTheme.adminTextSecondary)),
        ],
      ),
    );
  }

  Widget _nutrientChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _moistureColor(double? m) {
    if (m == null) return Colors.grey;
    if (m < 30) return Colors.orange.shade700;
    if (m > 70) return Colors.blue.shade700;
    return Colors.green.shade700;
  }

  Color _phColor(double? ph) {
    if (ph == null) return Colors.grey;
    if (ph < 5.5) return Colors.orange.shade700;
    if (ph > 7.5) return Colors.blue.shade700;
    return Colors.green.shade700;
  }
}

