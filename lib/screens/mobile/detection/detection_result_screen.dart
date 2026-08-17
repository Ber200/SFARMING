import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/disease_info_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/soil_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../services/photo_download_service.dart';

class DetectionResultScreen extends StatelessWidget {
  final dynamic imageFile; // Can be File (mobile) or XFile/bytes (web)
  final String disease;
  final double confidence;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isInsideFarm;
  final String? locationStatus;
  final bool isLowConfidence;
  final List<Map<String, dynamic>> topPredictions;

  const DetectionResultScreen({
    super.key,
    required this.imageFile,
    required this.disease,
    required this.confidence,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.isInsideFarm = true,
    this.locationStatus,
    this.isLowConfidence = false,
    this.topPredictions = const [],
  });

  Future<void> _searchGoogle(BuildContext context) async {
    final query = Uri.encodeComponent('$disease rice treatment');
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenBrowser)),
        );
      }
    }
  }

  Future<void> _scheduleTreatment(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    // Navigate to add treatment screen with pre-filled disease
    Navigator.of(context).pushNamed(
      AppRoutes.addTreatment,
      arguments: disease,
    );
  }

  @override
  Widget build(BuildContext context) {
    final diseaseInfo = DiseaseInfoModel.getDiseaseInfo(disease);
    final displayDisease = diseaseInfo?.name ?? disease;
    final statusText = locationStatus ??
        (isInsideFarm ? 'Inside Registered Farm' : 'Outside Registered Farm');
    final statusColor = isInsideFarm ? Colors.green : Colors.orange.shade800;
    final confidencePercent = (confidence * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.detectionResult),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image ──
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
                minHeight: 180,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: kIsWeb
                      ? ((imageUrl.isNotEmpty)
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error, size: 48),
                                );
                              },
                            )
                          : (imageFile is Uint8List
                              ? Image.memory(
                                  imageFile,
                                  fit: BoxFit.cover,
                                )
                              : const Center(child: Icon(Icons.error))))
                      : Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Disease & Confidence Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.farmCardDecoration(),
              child: Column(
                children: [
                  Text(
                    displayDisease,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPrimary,
                          fontSize: 22,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Confidence chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(confidence).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$confidencePercent% confidence',
                      style: TextStyle(
                        color: _getConfidenceColor(confidence),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location & Farm Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isInsideFarm
                              ? Icons.location_on_rounded
                              : Icons.wrong_location_rounded,
                          color: statusColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (latitude != null && longitude != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (isLowConfidence) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Low confidence result (${(confidence * 100).toStringAsFixed(1)}%). '
                        'The model is not fully sure about this detection. Please retake the photo '
                        'in good lighting with the leaf filling the frame.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.orange.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Environmental Advisory ──
            _buildEnvironmentalAdvisory(context),
            const SizedBox(height: 14),

            // ── Disease Information Sections ──
            if (diseaseInfo != null) ...[
              _buildInfoSection(
                context,
                AppLocalizations.of(context)!.description,
                diseaseInfo.description,
                Icons.info_outline_rounded,
              ),
              const SizedBox(height: 10),
              if (diseaseInfo.symptoms.isNotEmpty)
                _buildInfoSection(
                  context,
                  AppLocalizations.of(context)!.symptoms,
                  diseaseInfo.symptoms.join('\n• '),
                  Icons.warning_amber_rounded,
                  prefix: '• ',
                ),
              if (diseaseInfo.symptoms.isNotEmpty) const SizedBox(height: 10),
              if (diseaseInfo.causes.isNotEmpty)
                _buildInfoSection(
                  context,
                  AppLocalizations.of(context)!.causes,
                  diseaseInfo.causes.join('\n• '),
                  Icons.bug_report_rounded,
                  prefix: '• ',
                ),
              if (diseaseInfo.causes.isNotEmpty) const SizedBox(height: 10),
              _buildInfoSection(
                context,
                AppLocalizations.of(context)!.prevention,
                diseaseInfo.prevention.join('\n• '),
                Icons.shield_rounded,
                prefix: '• ',
              ),
              const SizedBox(height: 10),
              _buildInfoSection(
                context,
                AppLocalizations.of(context)!.treatmentProtocol,
                diseaseInfo.treatmentProtocol,
                Icons.medical_services_rounded,
              ),
            ],

            // ── Action Buttons ──
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.aiAssistant,
                  arguments: disease,
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!.translate(
                  'ai_ask_disease',
                  {'disease': disease},
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _searchGoogle(context),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(AppLocalizations.of(context)!.moreDetails),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleTreatment(context),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(AppLocalizations.of(context)!.scheduleTreatment),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                PhotoDownloadService.downloadPhoto(
                  context: context,
                  imageUrl: imageUrl,
                  fileName: 'scan_${disease.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.green.shade700;
    if (confidence >= 0.65) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Widget _buildEnvironmentalAdvisory(BuildContext context) {
    final soilProvider = Provider.of<SoilProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);

    final soil = soilProvider.soilData;
    final weather = weatherProvider.currentWeather;

    final double? moisture = soil?.moisture;
    final double? humidity = soil?.humidity ?? weather?.humidity;
    final double? temp = weather?.temperature;

    final List<String> warnings = [];

    if (humidity != null && humidity > 70) {
      warnings.add('⚠️ High relative humidity (${humidity.toStringAsFixed(0)}%) creates a favorable environment for fungal disease proliferation like $disease.');
    }
    if (moisture != null) {
      if (moisture > 70) {
        warnings.add('⚠️ High soil moisture (${moisture.toStringAsFixed(0)}%) increases root disease vulnerability and waterlogging stress.');
      } else if (moisture < 30) {
        warnings.add('⚠️ Low soil moisture (${moisture.toStringAsFixed(0)}%) stresses plants, weakening immunity against secondary infections.');
      }
    }
    if (temp != null && temp > 28) {
      warnings.add('🌡️ Temperature (${temp.toStringAsFixed(1)}°C) along with humidity accelerates spore incubation.');
    }

    if (warnings.isEmpty) {
      warnings.add('✅ Current environmental conditions (soil moisture & humidity) are within normal thresholds for your farm area.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_outlined, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Environmental Disease Risk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                w,
                style: TextStyle(fontSize: 12, color: Colors.brown.shade800, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon, {
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$prefix$content',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }
}
