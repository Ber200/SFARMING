import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smartfarming/utils/camera_stability.dart';

Uint8List _frame(int rgb) {
  final img.Image image = img.Image(width: 64, height: 64);
  img.fill(image, color: img.ColorRgb8(rgb, rgb, rgb));
  return Uint8List.fromList(img.encodeJpg(image));
}

final Uint8List _dark = _frame(10);
final Uint8List _bright = _frame(245);

void main() {
  group('FrameMotionDetector', () {
    test('returns 0 for the first frame (no reference yet)', () {
      final detector = FrameMotionDetector();
      expect(detector.scoreFrame(_dark), 0.0);
    });

    test('returns ~0 for identical consecutive frames', () {
      final detector = FrameMotionDetector();
      detector.scoreFrame(_dark);
      final score = detector.scoreFrame(_dark);
      expect(score, lessThan(0.01));
    });

    test('returns a high score when consecutive frames differ sharply', () {
      final detector = FrameMotionDetector();
      detector.scoreFrame(_dark);
      final score = detector.scoreFrame(_bright);
      expect(score, greaterThan(0.8));
    });

    test('reset clears the previous frame reference', () {
      final detector = FrameMotionDetector();
      detector.scoreFrame(_bright);
      detector.reset();
      expect(detector.scoreFrame(_bright), 0.0);
    });
  });

  group('StabilityBuffer', () {
    test('enters unstable only after N consecutive high scores', () {
      final buffer = StabilityBuffer(
        unstableThreshold: 0.25,
        enterUnstableFrames: 3,
        exitUnstableFrames: 5,
      );
      expect(buffer.update(0.1), isFalse);
      expect(buffer.update(0.9), isFalse);
      expect(buffer.update(0.9), isFalse);
      expect(buffer.update(0.9), isTrue);
      expect(buffer.isUnstable, isTrue);
    });

    test('does not trigger on isolated high scores (no flicker)', () {
      final buffer = StabilityBuffer(
        unstableThreshold: 0.25,
        enterUnstableFrames: 3,
        exitUnstableFrames: 5,
      );
      buffer.update(0.9);
      buffer.update(0.1);
      buffer.update(0.9);
      buffer.update(0.1);
      buffer.update(0.9);
      expect(buffer.isUnstable, isFalse);
    });

    test('recovery requires M consecutive low scores', () {
      final buffer = StabilityBuffer(
        unstableThreshold: 0.25,
        enterUnstableFrames: 3,
        exitUnstableFrames: 3,
      );
      buffer.update(0.9);
      buffer.update(0.9);
      buffer.update(0.9);
      expect(buffer.isUnstable, isTrue);

      buffer.update(0.1);
      expect(buffer.isUnstable, isTrue);
      buffer.update(0.1);
      expect(buffer.isUnstable, isTrue);
      buffer.update(0.1);
      expect(buffer.isUnstable, isFalse);
    });

    test('one high frame during recovery keeps the unstable state', () {
      final buffer = StabilityBuffer(
        unstableThreshold: 0.25,
        enterUnstableFrames: 3,
        exitUnstableFrames: 3,
      );
      buffer.update(0.9);
      buffer.update(0.9);
      buffer.update(0.9);
      buffer.update(0.1);
      buffer.update(0.1);
      buffer.update(0.9);
      buffer.update(0.1);
      buffer.update(0.1);
      expect(buffer.isUnstable, isTrue);
    });

    test('reset returns to a stable state', () {
      final buffer = StabilityBuffer(
        unstableThreshold: 0.25,
        enterUnstableFrames: 2,
        exitUnstableFrames: 2,
      );
      buffer.update(0.9);
      buffer.update(0.9);
      expect(buffer.isUnstable, isTrue);
      buffer.reset();
      expect(buffer.isUnstable, isFalse);
    });
  });

  group('CameraStabilityDetector', () {
    test('shakes rapidly -> unstable; holds steady -> recovers', () {
      final detector = CameraStabilityDetector(
        buffer: StabilityBuffer(
          unstableThreshold: 0.25,
          enterUnstableFrames: 3,
          exitUnstableFrames: 5,
        ),
      );

      // Alternating bright/dark frames = rapid movement.
      detector.update(_dark); // first frame: score 0
      detector.update(_bright);
      detector.update(_dark);
      detector.update(_bright);
      expect(detector.isUnstable, isTrue, reason: 'after 3 high scores');

      // Hold the phone steady: identical frames in a row.
      detector.update(_dark);
      expect(detector.isUnstable, isTrue);
      detector.update(_dark);
      detector.update(_dark);
      detector.update(_dark);
      detector.update(_dark);
      expect(detector.isUnstable, isTrue);
      detector.update(_dark);
      expect(detector.isUnstable, isFalse, reason: 'after 5 low scores');
    });
  });
}
