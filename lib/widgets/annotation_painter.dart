import 'package:flutter/material.dart';
import '../models/annotation.dart';
import '../providers/app_state.dart';

class AnnotationPainter extends StatefulWidget {
  final AppState appState;

  const AnnotationPainter({
    super.key,
    required this.appState,
  });

  @override
  State<AnnotationPainter> createState() => _AnnotationPainterState();
}

class _AnnotationPainterState extends State<AnnotationPainter> {
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        if (!widget.appState.isSelectionMode && !widget.appState.isQualityControlMode) {
          setState(() {
            _currentStroke = [details.localPosition];
          });
          widget.appState.setDrawing(true);
        }
      },
      onPanUpdate: (details) {
        if (!widget.appState.isSelectionMode && !widget.appState.isQualityControlMode && _currentStroke.isNotEmpty) {
          setState(() {
            _currentStroke.add(details.localPosition);
          });
        }
      },
      onPanEnd: (details) {
        if (!widget.appState.isSelectionMode && !widget.appState.isQualityControlMode && _currentStroke.isNotEmpty) {
          final stroke = AnnotationStroke(
            points: List.from(_currentStroke),
            color: widget.appState.currentColor,
            strokeWidth: widget.appState.strokeWidth,
          );
          widget.appState.addStroke(stroke, widget.appState.currentLayer);
        }
        setState(() {
          _currentStroke = [];
        });
        widget.appState.setDrawing(false);
      },
      child: CustomPaint(
        painter: _AnnotationCustomPainter(
          teacherStrokes: widget.appState.getAnnotations(AnnotationLayer.teacher),
          studentStrokes: widget.appState.getAnnotations(AnnotationLayer.student),
          teacherVisible: widget.appState.isLayerVisible(AnnotationLayer.teacher),
          studentVisible: widget.appState.isLayerVisible(AnnotationLayer.student),
          currentStroke: _currentStroke,
          currentColor: widget.appState.currentColor,
          currentStrokeWidth: widget.appState.strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _AnnotationCustomPainter extends CustomPainter {
  final List<AnnotationStroke> teacherStrokes;
  final List<AnnotationStroke> studentStrokes;
  final bool teacherVisible;
  final bool studentVisible;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;

  _AnnotationCustomPainter({
    required this.teacherStrokes,
    required this.studentStrokes,
    required this.teacherVisible,
    required this.studentVisible,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (teacherVisible) {
      _drawStrokes(canvas, teacherStrokes);
    }

    if (studentVisible) {
      _drawStrokes(canvas, studentStrokes);
    }

    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _drawStrokes(Canvas canvas, List<AnnotationStroke> strokes) {
    for (var stroke in strokes) {
      if (stroke.isBarAnnotation) {
        _drawBarAnnotation(canvas, stroke);
      } else {
        _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
      }
    }
  }

  void _drawBarAnnotation(Canvas canvas, AnnotationStroke stroke) {
    if (stroke.points.length < 4) return;

    final fillPaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.8)
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AnnotationCustomPainter oldDelegate) {
    return oldDelegate.teacherStrokes != teacherStrokes ||
        oldDelegate.studentStrokes != studentStrokes ||
        oldDelegate.teacherVisible != teacherVisible ||
        oldDelegate.studentVisible != studentVisible ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}
