import 'package:flutter/material.dart';
import '../services/crt_settings.dart';

class CrtOverlay extends StatelessWidget {
  final Widget child;
  const CrtOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CrtSettings.intensity,
      builder: (context, level, _) {
        return Stack(
          children: [
            child,
            if (level > CrtSettings.levelOff)
              IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('crt-overlay-paint'),
                  painter: _CrtPainter(level),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CrtPainter extends CustomPainter {
  final int level;

  // Scanline alpha (0-255) at each level: OFF, LOW, MED, FULL.
  static const _scanAlpha = [0, 10, 18, 26];
  // Vignette intensity multiplier per level.
  static const _vignetteScale = [0.0, 0.45, 0.75, 1.0];

  _CrtPainter(this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final scan = _scanAlpha[level];
    if (scan > 0) {
      final linePaint = Paint()
        ..color = Color.fromARGB(scan, 0, 0, 0)
        ..strokeWidth = 1.0;
      for (double y = 0; y < size.height; y += 4) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }

    final scale = _vignetteScale[level];
    if (scale <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final midAlpha = (0x44 * scale).round();
    final edgeAlpha = (0x99 * scale).round();
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [
          const Color(0x00000000),
          Color.fromARGB(midAlpha, 0, 0, 0),
          Color.fromARGB(edgeAlpha, 0, 0, 0),
        ],
        stops: const [0.5, 0.82, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(_CrtPainter oldDelegate) => oldDelegate.level != level;
}
