import 'package:flutter/material.dart';
import '../models/bar.dart';

class BarOverlayPainter extends CustomPainter {
  final List<Bar> bars;
  final int? currentBarNumber;

  BarOverlayPainter({
    required this.bars,
    this.currentBarNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue.withValues(alpha: 0.2);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;

    for (var bar in bars) {
      if (bar.barNumber == currentBarNumber) {
        final rect = Rect.fromLTWH(bar.x, bar.y, bar.width, bar.height);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(BarOverlayPainter oldDelegate) {
    return oldDelegate.currentBarNumber != currentBarNumber ||
        oldDelegate.bars != bars;
  }
}
