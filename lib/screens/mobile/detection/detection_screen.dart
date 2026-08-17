import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' if (dart.library.html) 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'detection_result_screen.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // Use XFile which works on both web and mobile

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        _processDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorPickingImage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    final state = await GeoUtils.checkPermissionState();
    if (state == GeoLocationStatus.enabled) return true;

    if (!mounted) return false;

    String title = 'Location Permission Required';
    String message = 'Location access is required to record the GPS coordinates of disease detections on the map.';
    String actionBtnText = 'Enable Location';
    VoidCallback onAction = () async => await GeoUtils.openLocationSettings();

    if (state == GeoLocationStatus.permissionDeniedForever) {
      message = 'Location permissions are permanently denied. Please enable them in App Settings to record GPS coordinates.';
      actionBtnText = 'Open App Settings';
      onAction = () async => await GeoUtils.openAppSettings();
    } else if (state == GeoLocationStatus.serviceDisabled) {
      message = 'Device GPS location services are turned off. Please turn on location services before scanning.';
      actionBtnText = 'Enable GPS';
      onAction = () async => await GeoUtils.openLocationSettings();
    }

    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              onAction();
              Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.settings),
            label: Text(actionBtnText),
          ),
        ],
      ),
    );

    return proceed == true;
  }

  Future<void> _processDetection() async {
    if (_selectedImage == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission || !mounted) return;
    
    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userNotAuthenticated),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Convert XFile to the correct type for TFLite:
    // - Mobile: File (required by tflite_service_io.dart)
    // - Web: Uint8List bytes (handled by mock service)
    dynamic imagePayload;
    if (kIsWeb) {
      imagePayload = await _selectedImage!.readAsBytes();
    } else {
      imagePayload = File(_selectedImage!.path);
    }

    final result = await detectionProvider.detectDisease(imagePayload, userId);
    
    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => DetectionResultScreen(
              imageFile: imagePayload,
              disease: result['disease'] as String,
              confidence: result['confidence'] as double,
              imageUrl: result['imageUrl'] as String,
              latitude: (result['latitude'] as num?)?.toDouble(),
              longitude: (result['longitude'] as num?)?.toDouble(),
              isInsideFarm: result['isInsideFarm'] as bool? ?? true,
              locationStatus: result['locationStatus'] as String?,
              isLowConfidence: result['isLowConfidence'] as bool? ?? false,
              topPredictions: (result['topPredictions'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
            ),
        ),
      );
      setState(() {
        _selectedImage = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(detectionProvider.errorMessage ?? AppLocalizations.of(context)!.detectionFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diseaseDetection),
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.detection),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Icon in tinted circle ──
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 44,
                    color: AppTheme.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.detectRiceLeafDisease,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.captureSelectHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 36),

              if (_selectedImage != null) ...[
                // ── Preview ──
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                    minHeight: 180,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.brandPrimary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FutureBuilder<Uint8List>(
                        future: _selectedImage!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<DetectionProvider>(
                  builder: (context, detectionProvider, _) {
                    if (detectionProvider.isDetecting) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 14),
                            Text(l10n.analyzingImage),
                          ],
                        ),
                      );
                    }
                    return ElevatedButton.icon(
                      onPressed: _processDetection,
                      icon: const Icon(Icons.search_rounded),
                      label: Text(l10n.detectDisease),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  },
                ),
              ] else ...[
                // ── Primary: Camera Button ──
                _buildActionCard(
                  icon: Icons.camera_alt_rounded,
                  label: l10n.takePhoto,
                  subtitle: 'Use live camera for best results',
                  isPrimary: true,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.cameraDetection);
                  },
                ),
                const SizedBox(height: 12),
                // ── Secondary: Gallery Button ──
                _buildActionCard(
                  icon: Icons.photo_library_rounded,
                  label: l10n.chooseFromGallery,
                  subtitle: 'Select an existing photo',
                  isPrimary: false,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],

              // ── Tips Section ──
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, size: 18, color: AppTheme.brandPrimary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.tipsForBestResults,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(l10n.tipGoodLighting),
                    _buildTip(l10n.tipFocusLeaf),
                    _buildTip(l10n.tipAvoidShadows),
                    _buildTip(l10n.tipCaptureEntireLeaf),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: isPrimary
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.brandPrimary,
                  AppTheme.brandMid,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : AppTheme.farmCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isPrimary ? Colors.white : AppTheme.brandPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPrimary ? Colors.white : null,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPrimary
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.brandLight),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
