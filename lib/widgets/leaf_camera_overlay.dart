import 'package:flutter/material.dart';

class LeafCameraOverlay extends StatefulWidget {
  final Widget child;
  final String instructionText;
  final String subInstructionText;

  const LeafCameraOverlay({
    super.key,
    required this.child,
    this.instructionText = 'Place one rice leaf inside the guide.',
    this.subInstructionText = 'Keep the background clear for better AI detection.',
  });

  @override
  State<LeafCameraOverlay> createState() => _LeafCameraOverlayState();
}

class _LeafCameraOverlayState extends State<LeafCameraOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Preview child
        widget.child,

        // Custom Leaf Overlay Mask with scanning animation
        AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _LeafOverlayPainter(
                scanProgress: _scanAnimation.value,
              ),
            );
          },
        ),

        // Top Instruction Banners
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 22),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.instructionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.subInstructionText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Centered Positioning Helper Pill
        Positioned(
          left: 0,
          right: 0,
          bottom: 120,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.center_focus_strong_rounded, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Center leaf along midrib • 1 leaf only',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeafOverlayPainter extends CustomPainter {
  final double scanProgress;

  _LeafOverlayPainter({required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 30;

    final leafWidth = (size.width * 0.55).clamp(180.0, 240.0);
    final leafHeight = (size.height * 0.46).clamp(320.0, 440.0);

    final topY = centerY - leafHeight / 2;
    final bottomY = centerY + leafHeight / 2;
    final rightX = centerX + leafWidth / 2;
    final leftX = centerX - leafWidth / 2;

    // Construct rice leaf cutout path
    final leafPath = Path();
    leafPath.moveTo(centerX, topY);
    leafPath.cubicTo(
      rightX + 12,
      centerY - leafHeight * 0.18,
      rightX + 12,
      centerY + leafHeight * 0.18,
      centerX,
      bottomY,
    );
    leafPath.cubicTo(
      leftX - 12,
      centerY + leafHeight * 0.18,
      leftX - 12,
      centerY - leafHeight * 0.18,
      centerX,
      topY,
    );
    leafPath.close();

    // 1. Dark semi-transparent mask outside leaf cutout
    final fullScreenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath = Path.combine(PathOperation.difference, fullScreenPath, leafPath);

    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, maskPaint);

    // 2. Glowing Leaf Border Outline
    final glowPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(leafPath, glowPaint);

    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(leafPath, borderPaint);

    // 3. Central Leaf Midrib / Vein Line (Dashed guide line)
    final veinPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashHeight = 8.0;
    const dashGap = 6.0;
    double startY = topY + 20;
    while (startY < bottomY - 20) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, (startY + dashHeight).clamp(topY, bottomY - 20)),
        veinPaint,
      );
      startY += dashHeight + dashGap;
    }

    // 4. Scanning beam line moving vertically inside leaf cutout
    final scanY = topY + (bottomY - topY) * scanProgress;
    final scanBeamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.greenAccent.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(leftX, scanY - 10, leafWidth, 20));

    canvas.save();
    canvas.clipPath(leafPath);
    canvas.drawRect(Rect.fromLTWH(leftX, scanY - 2, leafWidth, 4), scanBeamPaint);
    canvas.restore();

    // 5. Corner alignment ticks at top and bottom tips
    final tickPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Top tip tick
    canvas.drawLine(Offset(centerX - 10, topY - 5), Offset(centerX + 10, topY - 5), tickPaint);
    canvas.drawLine(Offset(centerX, topY - 15), Offset(centerX, topY - 5), tickPaint);

    // Bottom tip tick
    canvas.drawLine(Offset(centerX - 10, bottomY + 5), Offset(centerX + 10, bottomY + 5), tickPaint);
    canvas.drawLine(Offset(centerX, bottomY + 5), Offset(centerX, bottomY + 15), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _LeafOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
