import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/soil_scan/soil_scan_processor.dart';
import '../../../services/soil_scan/soil_scan_result.dart';
import '../../../widgets/app_drawer.dart';
import 'soil_scan_review_screen.dart';

/// Live camera scanning flow for the Intelligent Soil Detector display.
class SoilScanCameraScreen extends StatefulWidget {
  const SoilScanCameraScreen({super.key});

  @override
  State<SoilScanCameraScreen> createState() => _SoilScanCameraScreenState();
}

class _SoilScanCameraScreenState extends State<SoilScanCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _cameraError = false;
  String? _cameraErrorMsg;
  SoilScanProcessor? _processor;
  Size _previewSize = Size.zero;
  Rect _scanFrame = Rect.zero;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    WidgetsBinding.instance.addObserver(this);
    _processor = SoilScanProcessor();
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
        try {
          await _controller!.setFocusMode(FocusMode.auto);
          await _controller!.setFocusPoint(const Offset(0.5, 0.5));
          await _controller!.setExposurePoint(const Offset(0.5, 0.5));
        } catch (_) {
          // Focus/exposure points are not supported on every device.
        }
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
            _cameraErrorMsg = 'No camera found on this device.';
          });
        }
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      final isPermissionDenied = message.contains('CameraAccessDenied') ||
          message.contains('permission') ||
          message.contains('CameraPermission');
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMsg = message;
        });
      }
      if (isPermissionDenied) {
        _showPermissionDialog();
      }
    }
  }

  Future<void> _showPermissionDialog() async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera permission is required to scan the sensor display.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await GeoUtils.openAppSettings();
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

  /// Refocuses and re-exposes on the tapped preview position (normalized to the
  /// preview widget) so LCD digits are as sharp as the device allows.
  Future<void> _focusAt(Offset localPosition) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }
    if (_previewSize.width <= 0 || _previewSize.height <= 0) return;
    final point = Offset(
      (localPosition.dx / _previewSize.width).clamp(0.0, 1.0),
      (localPosition.dy / _previewSize.height).clamp(0.0, 1.0),
    );
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture ||
        _isProcessing) {
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false)
        .currentUser
        ?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to save sensor data.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final XFile image = await _controller!.takePicture();
      if (!mounted) return;
      final bytes = await image.readAsBytes();

      final processor = _processor;
      if (processor == null) return;

      final result = await processor.process(
        bytes,
        previewSize: _previewSize,
        frame: _scanFrame,
      );

      if (!mounted) return;
      if (!result.hasAnyValue) {
        _showOcrError(SoilScanError.ocrFailed);
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SoilScanReviewScreen(
            result: result,
            imageBytes: bytes,
          ),
        ),
      );
    } on SoilScanException catch (e) {
      if (mounted) _showOcrError(e.error);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to scan the sensor display. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showOcrError(SoilScanError error) {
    switch (error) {
      case SoilScanError.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sensor scanning is only available in the mobile app.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case SoilScanError.invalidImage:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to read the captured image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case SoilScanError.displayNotFound:
        _showNotDetectedDialog();
        break;
      case SoilScanError.ocrFailed:
        _showOcrFailedDialog();
        break;
    }
  }

  void _showNotDetectedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Device Not Detected'),
          ],
        ),
        content: const Text(
          'Please position the Intelligent Soil Detector inside the camera frame and make sure the green LCD screen is clearly visible and well-lit.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retake Photo'),
          ),
        ],
      ),
    );
  }

  void _showOcrFailedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Readings Unclear'),
        content: const Text(
          'The sensor readings are unclear. Please move closer, avoid glare on the green LCD, and make sure the display is clearly visible.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    WidgetsBinding.instance.removeObserver(this);
    _processor?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Soil Sensor')),
        drawer: const AppDrawer(activeRoute: AppRoutes.soilMonitoring),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sensor scanning is available in the mobile app. '
              'On this device you can enter soil readings manually.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(activeRoute: AppRoutes.soilMonitoring),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Soil Sensor'),
        actions: [
          IconButton(
            onPressed: _isInitialized && !_isProcessing ? _toggleFlash : null,
            icon: Icon(
              _currentFlashMode == FlashMode.off
                  ? Icons.flash_off_rounded
                  : _currentFlashMode == FlashMode.always
                      ? Icons.flash_on_rounded
                      : Icons.flash_auto_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cameraError
          ? _buildCameraError()
          : !_isInitialized || _controller == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final previewSize = constraints.biggest;
                    final frame = Rect.fromCenter(
                      center: Offset(
                          previewSize.width / 2, previewSize.height / 2),
                      width: previewSize.width * 0.56,
                      height: previewSize.height * 0.60,
                    );
                    _previewSize = previewSize;
                    _scanFrame = frame;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) =>
                                _focusAt(details.localPosition),
                            child: CameraPreview(_controller!),
                          ),
                        ),
                        Positioned.fill(
                          child: _ScanFrameOverlay(frame: frame),
                        ),
                        const Positioned(
                          left: 16,
                          right: 16,
                          top: 12,
                          child: _ScanInstructions(),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildControlBar(),
                        ),
                        if (_isProcessing)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Reading sensor display...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildCameraError() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
              const SizedBox(height: 20),
              const Text(
                'Camera Unavailable',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _cameraErrorMsg ?? 'The camera could not be accessed.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() {
                    _cameraError = false;
                    _cameraErrorMsg = null;
                  });
                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      color: Colors.black.withValues(alpha: 0.35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          GestureDetector(
            onTap: _isProcessing ? null : _capture,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _ScanInstructions extends StatelessWidget {
  const _ScanInstructions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.crop_free_rounded, size: 16, color: Color(0xFF4ADE80)),
              SizedBox(width: 6),
              Text(
                'Intelligent Soil Detector Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '1. Place the Intelligent Soil Detector inside the frame.\n'
            '2. Make sure the green LCD screen is clearly visible.\n'
            '3. Hold the device steady and tap the capture button.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay({required this.frame});

  final Rect frame;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ScanFramePainter(frame),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(20)));
    canvas.drawPath(
      scrim,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Device outer body outline (slate / white border)
    final deviceOutlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(20)),
      deviceOutlinePaint,
    );

    // Inner LCD Screen region (upper-middle portion with green glowing reticle)
    final lcdRect = Rect.fromLTWH(
      frame.left + 16,
      frame.top + 28,
      frame.width - 32,
      frame.height * 0.52,
    );

    final lcdPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(lcdRect, const Radius.circular(10)),
      lcdPaint,
    );

    // 4 Corner Brackets around LCD
    final cornerPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLength = 20.0;
    const inset = 2.0;

    final tl = Offset(lcdRect.left - inset, lcdRect.top - inset);
    final tr = Offset(lcdRect.right + inset, lcdRect.top - inset);
    final bl = Offset(lcdRect.left - inset, lcdRect.bottom + inset);
    final br = Offset(lcdRect.right + inset, lcdRect.bottom + inset);

    final path = Path();
    path
      ..moveTo(tl.dx, tl.dy + cornerLength)
      ..lineTo(tl.dx, tl.dy)
      ..lineTo(tl.dx + cornerLength, tl.dy)
      ..moveTo(tr.dx - cornerLength, tr.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(tr.dx, tr.dy + cornerLength)
      ..moveTo(bl.dx, bl.dy - cornerLength)
      ..lineTo(bl.dx, bl.dy)
      ..lineTo(bl.dx + cornerLength, bl.dy)
      ..moveTo(br.dx - cornerLength, br.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(br.dx, br.dy - cornerLength);

    canvas.drawPath(path, cornerPaint);

    // 3 Button Placement indicators below LCD (ON/OFF, Measure, °C/°F)
    final buttonY = lcdRect.bottom + 34;
    const buttonRadius = 10.0;
    final buttonPaint = Paint()

      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(frame.left + frame.width * 0.28, buttonY), buttonRadius, buttonPaint);
    canvas.drawCircle(Offset(frame.center.dx, buttonY), buttonRadius, buttonPaint);
    canvas.drawCircle(Offset(frame.right - frame.width * 0.28, buttonY), buttonRadius, buttonPaint);

  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.frame != frame;
}

