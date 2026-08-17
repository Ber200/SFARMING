import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds unique, labeled teardrop map pins as [BitmapDescriptor]s so each
/// category (disease, treatment, fertilization) is visually distinct.
class MarkerIconUtils {
  static const double _width = 96;
  static const double _height = 110;
  static const Offset _headCenter = Offset(48, 40);
  static const double _headRadius = 32;

  /// Paints a teardrop pin filled with [color], a white outline, and [label]
  /// centered on the pin head. The pin tip anchors the map coordinate.
  static Future<BitmapDescriptor> buildPinMarker({
    required String label,
    required Color color,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final pinShape = Path()
      ..addOval(Rect.fromCircle(center: _headCenter, radius: _headRadius))
      ..moveTo(_headCenter.dx - _headRadius + 6, _headCenter.dy)
      ..lineTo(_headCenter.dx, _height - 4)
      ..lineTo(_headCenter.dx + _headRadius - 6, _headCenter.dy)
      ..close();

    canvas.drawPath(pinShape, fill);
    canvas.drawPath(pinShape, stroke);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: label.length <= 2 ? 26 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _headRadius * 2 - 8);

    textPainter.paint(
      canvas,
      Offset(
        _headCenter.dx - textPainter.width / 2,
        _headCenter.dy - textPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(_width.round(), _height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(Uint8List.fromList(bytes));
  }

  /// Paints a modern, minimal circular dot marker filled with [color],
  /// a crisp white outline, and a subtle drop-shadow halo for satellite visibility.
  static Future<BitmapDescriptor> buildCircleDotMarker({
    required Color color,
    double radius = 10.0,
    Color strokeColor = Colors.white,
    double strokeWidth = 2.5,
  }) async {
    const double size = 32.0;
    const Offset center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Subtle drop-shadow ring
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(center, radius + strokeWidth + 1.0, shadowPaint);

    // 2. White outer stroke ring
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius + (strokeWidth / 2), strokePaint);

    // 3. Inner solid color fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // 4. Subtle inner center highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, highlightPaint);

    final image = await recorder.endRecording().toImage(size.round(), size.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(Uint8List.fromList(bytes));
  }
}
