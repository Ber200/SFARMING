import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'detection_result_screen.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _cameraError = false;
  String? _cameraErrorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(cameraIndex: _selectedCameraIndex);
    }
  }

  Future<void> _initializeCamera({int cameraIndex = 0}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _selectedCameraIndex = cameraIndex % _cameras!.length;
        _controller = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _cameraError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _cameraErrorMsg = AppLocalizations.of(context)!.noCameraFound;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMsg = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      FlashMode nextMode;
      if (_currentFlashMode == FlashMode.off) {
        nextMode = FlashMode.always;
      } else if (_currentFlashMode == FlashMode.always) {
        nextMode = FlashMode.auto;
      } else {
        nextMode = FlashMode.off;
      }
      await _controller!.setFlashMode(nextMode);
      setState(() => _currentFlashMode = nextMode);
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length <= 1 || _isProcessing) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    setState(() => _isInitialized = false);
    await _initializeCamera(cameraIndex: nextIndex);
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

  Future<void> _pickFromGalleryAndDetect() async {
    if (_isProcessing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);

    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission || !mounted) return;

      setState(() => _isProcessing = true);

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

      dynamic imagePayload;
      if (kIsWeb) {
        imagePayload = await image.readAsBytes();
      } else {
        imagePayload = File(image.path);
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                detectionProvider.errorMessage ?? AppLocalizations.of(context)!.detectionFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _takePicture() async {
    // 1. Controller Initialization & State Guards
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture ||
        _isProcessing) {
      return;
    }

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;
    if (!mounted) return;

    try {
      setState(() => _isProcessing = true);

      final XFile image = await _controller!.takePicture();
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);

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

      dynamic imagePayload;
      if (kIsWeb) {
        imagePayload = await image.readAsBytes();
      } else {
        imagePayload = File(image.path);
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                detectionProvider.errorMessage ?? AppLocalizations.of(context)!.detectionFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorTakingPicture(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.cameraDetection),
        ),
        drawer: const AppDrawer(activeRoute: AppRoutes.cameraDetection),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.cameraUnavailable,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cameraErrorMsg ?? AppLocalizations.of(context)!.cameraErrorHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGalleryAndDetect,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library),
                    label: Text(_isProcessing
                        ? AppLocalizations.of(context)!.processingHint
                        : AppLocalizations.of(context)!.useGalleryInstead),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.cameraDetection),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(activeRoute: AppRoutes.cameraDetection),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final cameraRatio = _controller!.value.aspectRatio;
    double scale = size.aspectRatio * (cameraRatio < 1 ? (1 / cameraRatio) : cameraRatio);
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.takePhotoTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded),
              onPressed: _isProcessing ? null : _toggleCamera,
              tooltip: 'Switch Camera',
            ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.cameraDetection),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Responsive Full-Screen Camera Preview ──
            ClipRect(
              child: Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

            // ── 2. Top Banner Overlay ──
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'Point camera at the rice leaf',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // ── 3. Bottom Control Bar (Responsive & Non-blocking) ──
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery fallback button
                    IconButton.filledTonal(
                      onPressed: _isProcessing ? null : _pickFromGalleryAndDetect,
                      icon: const Icon(Icons.photo_library_rounded, size: 26),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      tooltip: 'Choose from Gallery',
                    ),

                    // Main Capture Shutter Button (Guarded & Reliable)
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: (_isProcessing || !_isInitialized || _controller!.value.isTakingPicture)
                            ? null
                            : _takePicture,
                        customBorder: const CircleBorder(),
                        child: _isProcessing
                            ? Container(
                                width: 76,
                                height: 76,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.7),
                                  border: Border.all(color: Colors.greenAccent, width: 3),
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                ),
                              )
                            : Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.camera,
                                      color: Colors.black87,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Flash mode toggle button
                    IconButton.filledTonal(
                      onPressed: _isProcessing ? null : _toggleFlash,
                      icon: Icon(
                        _currentFlashMode == FlashMode.always
                            ? Icons.flash_on_rounded
                            : _currentFlashMode == FlashMode.auto
                                ? Icons.flash_auto_rounded
                                : Icons.flash_off_rounded,
                        size: 26,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        foregroundColor: _currentFlashMode != FlashMode.off
                            ? Colors.amberAccent
                            : Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      tooltip: 'Toggle Flash',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
