import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'constants.dart';

/// Detects rapid camera movement between sampled camera frames.
///
/// Frames are decoded, downscaled to a small square grid, converted to
/// grayscale (luma), and compared against the previous frame. The result is a
/// normalized motion score in the range 0..1. This runs on sampled frames from
/// the existing scanner loop, so it adds no extra camera stream and requires no
/// extra dependencies (works on every supported device, no gyroscope needed).
class FrameMotionDetector {
  FrameMotionDetector({this.sampleSize = 24});

  /// Edge length of the square grayscale grid used for comparison. Smaller is
  /// faster; 24 balances speed and sensitivity.
  final int sampleSize;

  List<int>? _previousLuma;
  bool _hasPrevious = false;

  /// Returns a normalized (0..1) motion score for [jpegBytes] relative to the
  /// previously scored frame. Returns 0 when a frame cannot be decoded so an
  /// undecodable frame never triggers the unstable state on its own.
  double scoreFrame(Uint8List jpegBytes) {
    final img.Image? decoded = img.decodeImage(jpegBytes);
    if (decoded == null) return 0.0;

    final img.Image small =
        img.copyResize(decoded, width: sampleSize, height: sampleSize);
    final int total = sampleSize * sampleSize;

    final List<int> luma = List<int>.generate(total, (i) {
      final img.Pixel p = small.getPixel(i % sampleSize, i ~/ sampleSize);
      return _luma(p);
    });

    if (!_hasPrevious) {
      _previousLuma = luma;
      _hasPrevious = true;
      return 0.0;
    }

    final List<int> prev = _previousLuma!;
    int diff = 0;
    for (int i = 0; i < total; i++) {
      diff += (luma[i] - prev[i]).abs();
    }
    _previousLuma = luma;

    final double averageDiff = diff / total;
    return averageDiff / 255.0;
  }

  void reset() {
    _previousLuma = null;
    _hasPrevious = false;
  }

  static int _luma(img.Pixel p) {
    final num r = p.r;
    final num g = p.g;
    final num b = p.b;
    return (0.299 * r.toDouble() +
            0.587 * g.toDouble() +
            0.114 * b.toDouble())
        .round();
  }
}

/// Tracks per-frame motion scores with hysteresis so the scanner does not
/// flicker between stable and unstable states on every individual frame.
///
/// The scanner becomes UNSTABLE only after [enterUnstableFrames] consecutive
/// frames score above [unstableThreshold], and recovers only after
/// [exitUnstableFrames] consecutive frames score below it.
class StabilityBuffer {
  StabilityBuffer({
    this.unstableThreshold = AppConstants.motionThreshold,
    this.enterUnstableFrames = AppConstants.motionEnterUnstableFrames,
    this.exitUnstableFrames = AppConstants.motionExitUnstableFrames,
  });

  final double unstableThreshold;
  final int enterUnstableFrames;
  final int exitUnstableFrames;

  bool _isUnstable = false;
  int _consecutive = 0;

  bool get isUnstable => _isUnstable;

  /// Feeds one frame's [score]. Returns the updated stability flag.
  bool update(double score) {
    final bool high = score > unstableThreshold;
    if (_isUnstable) {
      _consecutive = high ? 0 : _consecutive + 1;
      if (_consecutive >= exitUnstableFrames) {
        _isUnstable = false;
        _consecutive = 0;
      }
    } else {
      _consecutive = high ? _consecutive + 1 : 0;
      if (_consecutive >= enterUnstableFrames) {
        _isUnstable = true;
        _consecutive = 0;
      }
    }
    return _isUnstable;
  }

  void reset() {
    _isUnstable = false;
    _consecutive = 0;
  }
}

/// Combines frame differencing and hysteresis into a single stability detector
/// used by the real-time scanner.
class CameraStabilityDetector {
  CameraStabilityDetector({FrameMotionDetector? motion, StabilityBuffer? buffer})
      : _motion = motion ?? FrameMotionDetector(),
        _buffer = buffer ?? StabilityBuffer();

  final FrameMotionDetector _motion;
  final StabilityBuffer _buffer;

  bool get isUnstable => _buffer.isUnstable;

  /// Scores [jpegBytes] against the previous frame and updates the stability
  /// state. Returns the current unstable flag.
  bool update(Uint8List jpegBytes) {
    final double score = _motion.scoreFrame(jpegBytes);
    return _buffer.update(score);
  }

  void reset() {
    _motion.reset();
    _buffer.reset();
  }
}
