import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Concentric progress rings (outermost = first value), values are 0..1.
class ProgressRings extends StatelessWidget {
  final double size;
  final List<double> values;
  final List<Color> colors;
  final double? stroke;

  const ProgressRings({
    super.key,
    required this.size,
    required this.values,
    required this.colors,
    this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingsPainter(values, colors, stroke ?? size * 0.085),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double stroke;

  _RingsPainter(this.values, this.colors, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    var radius = size.width / 2 - stroke / 2;
    for (var i = 0; i < values.length; i++) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = colors[i].withAlpha(45);
      canvas.drawCircle(center, radius, track);

      final v = values[i].clamp(0.0, 1.0);
      if (v > 0) {
        final arc = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i];
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
            -math.pi / 2, 2 * math.pi * v, false, arc);
      }
      radius -= stroke * 1.55;
      if (radius <= 0) break;
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.values != values || old.colors != colors || old.stroke != stroke;
}
