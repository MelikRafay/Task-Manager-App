import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original illustration for the welcome screen: a stack of tilted task cards
/// with sparkles. Drawn with a CustomPainter so no image assets are needed.
class WelcomeArt extends StatelessWidget {
  const WelcomeArt({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _WelcomeArtPainter()),
    );
  }
}

class _WelcomeArtPainter extends CustomPainter {
  Path _star(Offset c, double r) {
    final p = Path()..moveTo(c.dx, c.dy - r);
    p.quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy);
    p.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r);
    p.quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy);
    p.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // soft glow
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.46,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.blue.withAlpha(90),
          AppColors.blue.withAlpha(0),
        ]).createShader(Rect.fromCircle(
            center: Offset(w * 0.5, h * 0.5), radius: w * 0.46)),
    );

    final cardW = w * 0.66;
    final cardH = h * 0.2;

    void card(Offset center, double angle, Color c1, Color c2, bool checked,
        double line1, double line2) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
        const Radius.circular(20),
      );
      canvas.drawShadow(Path()..addRRect(rrect), Colors.black, 10, true);
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(colors: [c1, c2])
              .createShader(rrect.outerRect),
      );
      final left = -cardW / 2;
      final circle = Offset(left + 32, 0);
      canvas.drawCircle(
          circle, 14, Paint()..color = Colors.white.withAlpha(checked ? 255 : 80));
      if (checked) {
        final tick = Path()
          ..moveTo(circle.dx - 6, circle.dy)
          ..lineTo(circle.dx - 1.5, circle.dy + 5)
          ..lineTo(circle.dx + 7, circle.dy - 5);
        canvas.drawPath(
            tick,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = c1);
      }
      final linePaint = Paint()..color = Colors.white.withAlpha(215);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(left + 60, -9, cardW * line1, 9), const Radius.circular(5)),
          linePaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(left + 60, 7, cardW * line2, 7), const Radius.circular(4)),
          Paint()..color = Colors.white.withAlpha(120));
      canvas.restore();
    }

    card(Offset(w * 0.46, h * 0.70), 0.10, const Color(0xFFF2704A),
        const Color(0xFFFF9A62), false, 0.42, 0.26);
    card(Offset(w * 0.54, h * 0.50), -0.07, const Color(0xFF1FB8A6),
        AppColors.teal, true, 0.36, 0.30);
    card(Offset(w * 0.48, h * 0.30), 0.05, const Color(0xFF2F6BDB),
        const Color(0xFF5B8DF0), true, 0.46, 0.22);

    // sparkles and dots
    canvas.drawPath(_star(Offset(w * 0.84, h * 0.12), w * 0.045),
        Paint()..color = AppColors.teal);
    canvas.drawPath(_star(Offset(w * 0.12, h * 0.46), w * 0.03),
        Paint()..color = AppColors.yellow);
    canvas.drawCircle(Offset(w * 0.90, h * 0.62), 5, Paint()..color = AppColors.orange);
    canvas.drawCircle(Offset(w * 0.08, h * 0.16), 4, Paint()..color = AppColors.blue);
    canvas.drawCircle(Offset(w * 0.78, h * 0.90), 3.5, Paint()..color = AppColors.teal);

    // small diamond
    canvas.save();
    canvas.translate(w * 0.16, h * 0.84);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(const Rect.fromLTWH(-5, -5, 10, 10),
        Paint()..color = AppColors.orange);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
