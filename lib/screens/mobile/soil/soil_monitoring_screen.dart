import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/soil_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/app_drawer.dart';

class SoilMonitoringScreen extends StatefulWidget {
  const SoilMonitoringScreen({super.key});

  @override
  State<SoilMonitoringScreen> createState() => _SoilMonitoringScreenState();
}

class _SoilMonitoringScreenState extends State<SoilMonitoringScreen> {
  final _phController = TextEditingController();
  final _moistureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSoilData();
  }

  void _loadSoilData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      Provider.of<SoilProvider>(context, listen: false).loadSoilData(userId);
    }
  }

  @override
  void dispose() {
    _phController.dispose();
    _moistureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _updateSoilData() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final soilProvider = Provider.of<SoilProvider>(context, listen: false);
    
    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    final ph = _phController.text.isEmpty ? null : double.tryParse(_phController.text);
    final moisture = _moistureController.text.isEmpty
        ? null
        : double.tryParse(_moistureController.text);
    final humidity = _humidityController.text.isEmpty
        ? null
        : double.tryParse(_humidityController.text);

    if (ph == null && moisture == null && humidity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one value'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await soilProvider.updateSoilData(
      userId: userId,
      ph: ph,
      moisture: moisture,
      humidity: humidity,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soil & Environmental data updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _phController.clear();
      _moistureController.clear();
      _humidityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Soil & Environment'),
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.soilMonitoring),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Soil Cards
            Consumer<SoilProvider>(
              builder: (context, soilProvider, _) {
                final soilData = soilProvider.soilData;
                
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showSoilDetails(context, soilData);
                      },
                      child: _buildSoilCard(
                        context,
                        'pH Level',
                        soilData?.ph?.toStringAsFixed(1) ?? 'N/A',
                        soilData?.phStatus ?? 'Unknown',
                        Icons.science_rounded,
                        _getPHColor(soilData?.ph),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _showSoilDetails(context, soilData);
                      },
                      child: _buildSoilCard(
                        context,
                        'Soil Moisture',
                        soilData?.moisture != null
                            ? '${soilData!.moisture!.toStringAsFixed(0)}%'
                            : 'N/A',
                        soilData?.moistureStatus ?? 'Unknown',
                        Icons.water_drop_rounded,
                        _getMoistureColor(soilData?.moisture),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _showSoilDetails(context, soilData);
                      },
                      child: _buildSoilCard(
                        context,
                        'Farm Humidity',
                        soilData?.humidity != null
                            ? '${soilData!.humidity!.toStringAsFixed(0)}%'
                            : 'N/A',
                        soilData?.humidity != null && soilData!.humidity! > 70
                            ? 'High Risk'
                            : 'Normal',
                        Icons.opacity_rounded,
                        AppTheme.brandMid,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Scan Sensor Entry
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.farmCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.document_scanner_rounded,
                          color: AppTheme.brandPrimary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Soil Sensor Scanner',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandPrimary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Point your camera at the Intelligent Soil Detector '
                    'display to read soil and environment measurements.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Scan Sensor',
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.soilScanCamera);
                    },
                    backgroundColor: AppTheme.brandPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be asked to confirm the detected values before '
                    'they are saved.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual Entry Form Section Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.farmCardDecoration(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: AppTheme.brandPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Enter Manually',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phController,
                      label: 'pH Level (Optional)',
                      hint: 'Enter pH value (0-14)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.science_outlined,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final ph = double.tryParse(value);
                          if (ph == null || ph < 0 || ph > 14) {
                            return 'pH must be between 0 and 14';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _moistureController,
                      label: 'Soil Moisture % (Optional)',
                      hint: 'Enter moisture percentage (0-100)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.water_drop_outlined,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final moisture = double.tryParse(value);
                          if (moisture == null || moisture < 0 || moisture > 100) {
                            return 'Moisture must be between 0 and 100';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _humidityController,
                      label: 'Farm Humidity % (Optional)',
                      hint: 'Enter relative humidity percentage (0-100)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.opacity_rounded,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final humidity = double.tryParse(value);
                          if (humidity == null || humidity < 0 || humidity > 100) {
                            return 'Humidity must be between 0 and 100';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<SoilProvider>(
                      builder: (context, soilProvider, _) {
                        return CustomButton(
                          text: 'Save Readings',
                          onPressed: soilProvider.isLoading ? null : _updateSoilData,
                          isLoading: soilProvider.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reference Ranges Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.farmCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.brandPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Rice Cultivation Ideal Ranges',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandPrimary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow('pH Level', '5.5 - 7.5 (Optimal)'),
                  const Divider(height: 12),
                  _buildInfoRow('Soil Moisture', '30% - 70% (Optimal)'),
                  const Divider(height: 12),
                  _buildInfoRow('Humidity', '< 70% (Prevents Spores)'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilCard(
    BuildContext context,
    String title,
    String value,
    String status,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: AppTheme.farmCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 22,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPHColor(double? ph) {
    if (ph == null) return Colors.grey;
    if (ph < 5.5) return Colors.red.shade700;
    if (ph > 7.5) return Colors.orange.shade700;
    return AppTheme.brandPrimary;
  }

  Color _getMoistureColor(double? moisture) {
    if (moisture == null) return Colors.grey;
    if (moisture < 30) return Colors.orange.shade700;
    if (moisture > 70) return Colors.blue.shade700;
    return AppTheme.brandPrimary;
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }

  void _showSoilDetails(BuildContext context, soilData) {
    if (soilData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No soil data available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Soil Metrics Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPrimary,
                      ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('pH Level', soilData.ph?.toStringAsFixed(1) ?? 'N/A', soilData.phStatus),
                const SizedBox(height: 12),
                _buildDetailRow('Moisture', '${soilData.moisture?.toStringAsFixed(0) ?? 'N/A'}%', soilData.moistureStatus),
                if (soilData.status != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Status', soilData.status!, ''),
                ],
                if (soilData.description != null && soilData.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(soilData.description!, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getMoistureColor(soilData.moisture).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getMoistureColor(soilData.moisture).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            soilData.moisture != null && soilData.moisture! < 30
                                ? Icons.water_drop_rounded
                                : soilData.moisture != null && soilData.moisture! > 70
                                    ? Icons.water_rounded
                                    : Icons.check_circle_rounded,
                            color: _getMoistureColor(soilData.moisture),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recommendation',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(soilData.recommendation, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Soil & Disease Impact',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        soilData.diseaseRelationshipDescription,
                        style: TextStyle(color: Colors.grey[800], height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status.isNotEmpty)
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
