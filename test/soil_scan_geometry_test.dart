import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarming/services/soil_scan/soil_scan_geometry.dart';

void main() {
  group('mapFrameToImage', () {
    test('maps a centered frame when image fits by width (portrait preview)',
        () {
      // Preview 1080x2280 (aspect 0.474). Image 1000x1500 (aspect 0.667).
      // imageAspect > previewAspect -> fit width, bars top/bottom.
      const frame = Rect.fromLTWH(
        1080 * 0.22,
        2280 * 0.20,
        1080 * 0.56,
        2280 * 0.60,
      );

      final rect = mapFrameToImage(frame, const Size(1080, 2280), 1000, 1500);

      expect(rect, isNotNull);
      expect(rect!.center.dx, closeTo(500, 1));
      expect(rect.center.dy, closeTo(750, 1));
    });

    test('maps a full-width frame when image fits by height (side bars)', () {
      // Preview 1000x1500 (aspect 0.667). Image 800x1600 (aspect 0.5).
      // imageAspect < previewAspect -> fit height, bars on left/right.
      const frame = Rect.fromLTWH(125, 0, 750, 1500);


      final rect = mapFrameToImage(frame, const Size(1000, 1500), 800, 1600);

      expect(rect, isNotNull);
      expect(rect!.left, closeTo(0, 0.01));
      expect(rect.top, closeTo(0, 0.01));
      expect(rect.right, closeTo(800, 0.01));
      expect(rect.bottom, closeTo(1600, 0.01));
      expect(rect.center.dx, closeTo(400, 1));
      expect(rect.center.dy, closeTo(800, 1));
    });

    test('returns null for degenerate preview or image sizes', () {
      expect(
        mapFrameToImage(
            const Rect.fromLTWH(0, 0, 100, 100), Size.zero, 100, 100),
        isNull,
      );
      expect(
        mapFrameToImage(
            const Rect.fromLTWH(0, 0, 100, 100), const Size(100, 100), 0, 100),
        isNull,
      );
    });

    test('clamps frame edges inside the image bounds', () {
      // Same aspect (0.667) -> no letterbox, 1:2 scale from preview to image.
      final rect = mapFrameToImage(
        const Rect.fromLTWH(700, 100, 300, 800),
        const Size(1000, 1500),
        500,
        750,
      );

      expect(rect, isNotNull);
      expect(rect!.right, lessThanOrEqualTo(500));
      expect(rect.left, greaterThanOrEqualTo(0));
    });

    test('returns null for a frame that lands outside the visible image', () {
      // Frame in the top letterbox bar of a fit-width preview.
      final rect = mapFrameToImage(
        const Rect.fromLTWH(400, 20, 100, 60),
        const Size(1080, 2280),
        1000,
        1500,
      );

      expect(rect, isNull);
    });

    test('keeps mapping stable at the exact image boundary', () {
      final rect = mapFrameToImage(
        const Rect.fromLTWH(0, 0, 1000, 1500),
        const Size(1000, 1500),
        1000,
        1500,
      );

      expect(rect, isNotNull);
      expect(rect!.width, closeTo(1000, 1));
      expect(rect.height, closeTo(1500, 1));
    });
  });
}
