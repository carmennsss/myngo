import 'dart:math';
import 'package:flutter/material.dart';

class CatFeedBackground extends StatelessWidget {
  const CatFeedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CatPatternPainter(),
      size: Size.infinite,
    );
  }
}

class _CatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC35E34).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintFill = Paint()
      ..color = const Color(0xFFC35E34).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final cellW = 200.0;
    final cellH = 200.0;
    final cols = (size.width / cellW).ceil() + 1;
    final rows = (size.height / cellH).ceil() + 1;
    final rng = Random(42);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * cellW + (row.isEven ? 0 : cellW / 2);
        final cy = row * cellH;
        final type = rng.nextInt(4);
        canvas.save();
        canvas.translate(cx, cy);
        switch (type) {
          case 0:
            _drawSleepingCat(canvas, paint, paintFill);
            break;
          case 1:
            _drawCatChasingYarn(canvas, paint, paintFill);
            break;
          case 2:
            _drawCatInBox(canvas, paint, paintFill);
            break;
          case 3:
            _drawStretchingCat(canvas, paint, paintFill);
            break;
        }
        canvas.restore();
      }
    }
  }

  void _drawSleepingCat(Canvas c, Paint p, Paint pf) {
    final path = Path()
      ..moveTo(0, 30)
      ..quadraticBezierTo(30, 10, 60, 30)
      ..quadraticBezierTo(70, 35, 60, 50)
      ..quadraticBezierTo(40, 60, 20, 50)
      ..quadraticBezierTo(10, 35, 0, 30);
    c.drawOval(Rect.fromCircle(center: const Offset(30, 30), radius: 22), pf);
    c.drawOval(Rect.fromCircle(center: const Offset(30, 30), radius: 22), p);
    c.drawOval(Rect.fromCenter(center: Offset(20, 30), width: 8, height: 4), p);
    c.drawOval(Rect.fromCenter(center: Offset(40, 30), width: 8, height: 4), p);
    c.drawLine(const Offset(15, 50), const Offset(45, 50), p);
    c.drawLine(const Offset(10, 55), const Offset(50, 55), p);
  }

  void _drawCatChasingYarn(Canvas c, Paint p, Paint pf) {
    final body = Path()
      ..moveTo(10, 50)
      ..lineTo(10, 20)
      ..quadraticBezierTo(10, 10, 25, 10)
      ..quadraticBezierTo(40, 10, 40, 20)
      ..lineTo(40, 50)
      ..close();
    c.drawPath(body, pf);
    c.drawPath(body, p);
    c.drawOval(Rect.fromCenter(center: Offset(18, 18), width: 10, height: 7), p);
    c.drawOval(Rect.fromCenter(center: Offset(32, 18), width: 10, height: 7), p);
    c.drawLine(const Offset(25, 55), const Offset(55, 65), p);
    c.drawLine(const Offset(25, 55), const Offset(55, 70), p);
    c.drawOval(Rect.fromCenter(center: Offset(60, 68), width: 14, height: 10), p);
    c.drawLine(const Offset(60, 78), const Offset(60, 85), p);
    c.drawLine(const Offset(65, 78), const Offset(65, 82), p);
  }

  void _drawCatInBox(Canvas c, Paint p, Paint pf) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(5, 35, 50, 25), const Radius.circular(3)), p);
    final body = Path()
      ..moveTo(10, 35)
      ..lineTo(10, 20)
      ..quadraticBezierTo(10, 10, 30, 10)
      ..quadraticBezierTo(50, 10, 50, 20)
      ..lineTo(50, 35)
      ..close();
    c.drawPath(body, pf);
    c.drawPath(body, p);
    c.drawOval(Rect.fromCenter(center: Offset(20, 18), width: 8, height: 6), p);
    c.drawOval(Rect.fromCenter(center: Offset(40, 18), width: 8, height: 6), p);
  }

  void _drawStretchingCat(Canvas c, Paint p, Paint pf) {
    final body = Path()
      ..moveTo(5, 15)
      ..cubicTo(5, 5, 25, -5, 45, 5)
      ..cubicTo(55, 10, 55, 30, 45, 40)
      ..lineTo(5, 40)
      ..close();
    c.drawPath(body, pf);
    c.drawPath(body, p);
    c.drawOval(Rect.fromCenter(center: Offset(15, 12), width: 10, height: 7), p);
    c.drawOval(Rect.fromCenter(center: Offset(30, 12), width: 10, height: 7), p);
    c.drawLine(const Offset(0, 40), const Offset(-5, 55), p);
    c.drawLine(const Offset(10, 40), const Offset(15, 55), p);
    c.drawLine(const Offset(45, 40), const Offset(50, 50), p);
    c.drawLine(const Offset(45, 40), const Offset(55, 55), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
