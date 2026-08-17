import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../services/tflite_service.dart';
import '../../../utils/camera_stability.dart';
import '../../../utils/constants.dart';
import 'detection_result_screen.dart';

enum ScannerState { initializing, focusing, scanning, unstable }

class RealTimeScanScreen extends StatefulWidget {
  const RealTimeScanScreen({super.key});

  @override
  State<RealTimeScanScreen> createState() => _RealTimeScanScreenState();
}

class _RealTimeScanScreenState extends State<RealTimeScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _cameraError = false;
  String? _cameraErrorMsg;

  final TFLiteService _tfliteService = TFLiteService();
  Timer? _analysisTimer;
  bool _isAnalyzingFrame = false;

  final CameraStabilityDetector _stabilityDetector = CameraStabilityDetector();
  ScannerState _scannerState = ScannerState.initializing;

  String _currentDisease = 'Scanning...';
  double _currentConfidence = 0.0;
  String _scanStatus = 'Detecting...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndTFLite();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _analysisTimer?.cancel();
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraAndTFLite(cameraIndex: _selectedCameraIndex);
    }
  }

  Future<void> _initializeCameraAndTFLite({int cameraIndex = 0}) async {
    try {
      if (!kIsWeb) {
        await _tfliteService.initialize();
      }

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _selectedCameraIndex = cameraIndex % _cameras!.length;
        _controller = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _cameraError = false;
            _scannerState = ScannerState.focusing;
          });
          _stabilityDetector.reset();
          await _configureCameraFocus();
          _startRealTimeAnalysisTimer();
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

  Future<void> _configureCameraFocus() async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    // Continuous autofocus is the plugin default; make the desired modes
    // explicit and center the focus point. Each call is guarded so devices
    // without a given capability degrade gracefully instead of crashing.
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}
    try {
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}
    try {
      await controller.setFocusPoint(const Offset(0.5, 0.5));
    } catch (_) {}
  }

  Future<void> _handleTapToFocus(TapDownDetails details, Size size) async {
    final CameraController? controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    final Offset point = Offset(
      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    try {
      await controller.setFocusPoint(point);
    } catch (_) {}
    try {
      await controller.setExposurePoint(point);
    } catch (_) {}
  }

  void _startRealTimeAnalysisTimer() {
    _analysisTimer?.cancel();
    // Throttled frame analysis interval: analyze frame every 500ms
    _analysisTimer = Timer.periodic(
        const Duration(milliseconds: AppConstants.scanFrameIntervalMs), (_) {
      _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_isAnalyzingFrame ||
        _isProcessing ||
        _controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture ||
        kIsWeb) {
      return;
    }

    try {
      _isAnalyzingFrame = true;
      final XFile shot = await _controller!.takePicture();
      final Uint8List imageBytes = await shot.readAsBytes();
      final File imgFile = File(shot.path);
      try {
        if (await imgFile.exists()) {
          await imgFile.delete();
        }
      } catch (_) {}

      // Motion/stability gate: unstable frames are not valid inference
      // candidates and must never be predicted or saved.
      final bool unstable = _stabilityDetector.update(imageBytes);
      if (mounted && _scannerState != ScannerState.unstable && unstable) {
        setState(() {
          _scannerState = ScannerState.unstable;
          _scanStatus = AppLocalizations.of(context)!.holdSteady;
        });
      } else if (mounted && _scannerState == ScannerState.unstable && !unstable) {
        setState(() {
          _scannerState = ScannerState.scanning;
          _scanStatus = 'Detecting...';
        });
      }

      if (unstable) {
        // Do NOT run or trust inference on a rapidly moving frame.
        return;
      }

      final result = await _tfliteService.predict(imageBytes);

      if (mounted) {
        setState(() {
          if (_scannerState == ScannerState.focusing) {
            _scannerState = ScannerState.scanning;
          }
          _currentDisease = result['disease'] as String? ?? 'Healthy Rice Leaf';
          _currentConfidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
          _scanStatus = _currentConfidence > 0.65 ? 'Detected' : 'Analyzing...';
        });
      }
    } catch (_) {
      // Ignore frame drop hiccups during stream
    } finally {
      _isAnalyzingFrame = false;
    }
  }

  Future<bool> _checkLocationPermission() async {
    final state = await GeoUtils.checkPermissionState();
    if (state == GeoLocationStatus.enabled) return true;

    if (!mounted) return false;

    String title = 'Location Permission Required';
    String message =
        'Location access is required to record the GPS coordinates of disease detections on the map.';
    String actionBtnText = 'Enable Location';
    VoidCallback onAction = () async => await GeoUtils.openLocationSettings();

    if (state == GeoLocationStatus.permissionDeniedForever) {
      message =
          'Location permissions are permanently denied. Please enable them in App Settings to record GPS coordinates.';
      actionBtnText = 'Open App Settings';
      onAction = () async => await GeoUtils.openAppSettings();
    } else if (state == GeoLocationStatus.serviceDisabled) {
      message =
          'Device GPS location services are turned off. Please turn on location services before scanning.';
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

  Future<void> _captureResult() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture ||
        _isProcessing) {
      return;
    }

    if (_scannerState == ScannerState.unstable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.holdSteady}. '
            '${AppLocalizations.of(context)!.holdSteadyHint}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.userNotAuthenticated),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission || !mounted) return;

    try {
      _analysisTimer?.cancel();
      setState(() => _isProcessing = true);

      final XFile image = await _controller!.takePicture();
      if (!mounted) return;

      dynamic imagePayload;
      if (kIsWeb) {
        imagePayload = await image.readAsBytes();
      } else {
        imagePayload = File(image.path);
      }

      final result = await detectionProvider.detectDisease(imagePayload, userId, crop: 'Rice');

      if (!mounted) return;

      if (result != null) {
        Navigator.of(context).pushReplacement(
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
        _startRealTimeAnalysisTimer();
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
        _startRealTimeAnalysisTimer();
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
    _analysisTimer?.cancel();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    setState(() {
      _isInitialized = false;
      _scannerState = ScannerState.initializing;
    });
    await _initializeCameraAndTFLite(cameraIndex: nextIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _analysisTimer?.cancel();
    _controller?.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Real-Time Scanner'),
        ),
        drawer: const AppDrawer(activeRoute: AppRoutes.realTimeScan),
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
          title: const Text('Real-Time Scanner'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(activeRoute: AppRoutes.realTimeScan),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final cameraRatio = _controller!.value.aspectRatio;
    double scale = size.aspectRatio * (cameraRatio < 1 ? (1 / cameraRatio) : cameraRatio);
    if (scale < 1) scale = 1 / scale;
    final confidencePercent = (_currentConfidence * 100).toStringAsFixed(1);
    final l10n = AppLocalizations.of(context)!;
    final bool isUnstable = _scannerState == ScannerState.unstable;
    final bool isFocusing = _scannerState == ScannerState.focusing;
    final Color indicatorColor = isUnstable
        ? Colors.orangeAccent
        : (isFocusing ? Colors.amberAccent : Colors.greenAccent);
    final String statusLabel = isUnstable
        ? l10n.cameraUnstable
        : (isFocusing ? l10n.focusingCamera : 'Status: $_scanStatus');
    final String diseaseLabel =
        isUnstable ? l10n.holdSteady : _currentDisease;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Real-Time Scanner'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded),
              onPressed: _isProcessing ? null : _toggleCamera,
              tooltip: 'Switch Camera',
            ),
          IconButton(
            icon: Icon(
              _currentFlashMode == FlashMode.always
                  ? Icons.flash_on_rounded
                  : _currentFlashMode == FlashMode.auto
                      ? Icons.flash_auto_rounded
                      : Icons.flash_off_rounded,
              color: _currentFlashMode != FlashMode.off ? Colors.amberAccent : Colors.white,
            ),
            onPressed: _isProcessing ? null : _toggleFlash,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.realTimeScan),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Full Screen Camera Live Preview (Fitted & Responsive) ──
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleTapToFocus(details, size),
              child: ClipRect(
                child: Transform.scale(
                  scale: scale,
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),

            // ── 2. Live Floating HUD Box (Top Overlay) ──
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: indicatorColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: indicatorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE AI SCANNER',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        diseaseLabel,
                        style: TextStyle(
                          color: isUnstable ? Colors.orangeAccent : Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isUnstable && !isFocusing) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: $confidencePercent%',
                          style: TextStyle(
                            color: _currentConfidence >= 0.85
                                ? Colors.greenAccent
                                : (_currentConfidence >= 0.65 ? Colors.amberAccent : Colors.orangeAccent),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. Bottom Control: Capture Result Button ──
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
                child: _isProcessing
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.greenAccent,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Saving Detection...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: (_isProcessing ||
                                !_isInitialized ||
                                _scannerState == ScannerState.unstable ||
                                _controller!.value.isTakingPicture)
                            ? null
                            : _captureResult,
                        icon: const Icon(Icons.camera_alt_rounded, size: 24),
                        label: const Text(
                          'Capture Result',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black45,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
