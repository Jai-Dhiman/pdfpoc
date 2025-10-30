import 'package:flutter/material.dart';
import '../models/text_annotation.dart';

/// Custom painter that renders text annotations as speech bubble-style notes
class TextAnnotationPainter extends CustomPainter {
  final List<TextAnnotation> annotations;
  final double scale;
  final Offset offset;

  TextAnnotationPainter({
    required this.annotations,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var annotation in annotations) {
      _paintAnnotation(canvas, annotation);
    }
  }

  void _paintAnnotation(Canvas canvas, TextAnnotation annotation) {
    final scaledPosition = Offset(
      annotation.position.dx * scale + offset.dx,
      annotation.position.dy * scale + offset.dy,
    );

    final textSpan = TextSpan(
      text: annotation.text,
      style: TextStyle(
        color: annotation.textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: 200);

    final padding = 12.0;
    final bubbleWidth = textPainter.width + padding * 2;
    final bubbleHeight = textPainter.height + padding * 2;

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        scaledPosition.dx - bubbleWidth / 2,
        scaledPosition.dy,
        bubbleWidth,
        bubbleHeight,
      ),
      const Radius.circular(8),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      bubbleRect.shift(const Offset(2, 2)),
      shadowPaint,
    );

    final bubblePaint = Paint()
      ..color = annotation.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(bubbleRect, bubblePaint);

    final borderPaint = Paint()
      ..color = annotation.textColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(bubbleRect, borderPaint);

    final pointerPath = Path();
    final pointerTipX = scaledPosition.dx;
    final pointerTipY = scaledPosition.dy - 8;
    final pointerBaseY = bubbleRect.top;
    final pointerWidth = 8.0;

    pointerPath.moveTo(pointerTipX, pointerTipY);
    pointerPath.lineTo(pointerTipX - pointerWidth / 2, pointerBaseY);
    pointerPath.lineTo(pointerTipX + pointerWidth / 2, pointerBaseY);
    pointerPath.close();

    canvas.drawPath(pointerPath, bubblePaint);
    canvas.drawPath(pointerPath, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        scaledPosition.dx - textPainter.width / 2,
        bubbleRect.top + padding,
      ),
    );

    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '\u{1F4DD}',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        bubbleRect.right - 24,
        bubbleRect.top + 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant TextAnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
