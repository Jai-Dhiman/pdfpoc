import 'dart:ui';

enum QualityLevel {
  needsWork,
  improving,
  almostThere,
  good,
  mastered,
  none;

  Color get color {
    switch (this) {
      case QualityLevel.needsWork:
        return const Color(0xFFE74C3C);
      case QualityLevel.improving:
        return const Color(0xFFE67E22);
      case QualityLevel.almostThere:
        return const Color(0xFFF1C40F);
      case QualityLevel.good:
        return const Color(0xFF9CCC65);
      case QualityLevel.mastered:
        return const Color(0xFF27AE60);
      case QualityLevel.none:
        return const Color(0xFF000000);
    }
  }

  String get label {
    switch (this) {
      case QualityLevel.needsWork:
        return 'Needs Work';
      case QualityLevel.improving:
        return 'Improving';
      case QualityLevel.almostThere:
        return 'Almost There';
      case QualityLevel.good:
        return 'Good';
      case QualityLevel.mastered:
        return 'Mastered';
      case QualityLevel.none:
        return 'Normal';
    }
  }
}

class AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DateTime createdAt;
  final int? barNumber;
  final QualityLevel? qualityLevel;
  final bool isBarAnnotation;

  AnnotationStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 3.0,
    DateTime? createdAt,
    this.barNumber,
    this.qualityLevel,
    this.isBarAnnotation = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'points': points
          .map((p) => {'x': p.dx, 'y': p.dy})
          .toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createdAt': createdAt.toIso8601String(),
      'barNumber': barNumber,
      'qualityLevel': qualityLevel?.name,
      'isBarAnnotation': isBarAnnotation,
    };
  }

  factory AnnotationStroke.fromJson(Map<String, dynamic> json) {
    return AnnotationStroke(
      points: (json['points'] as List)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      barNumber: json['barNumber'] as int?,
      qualityLevel: json['qualityLevel'] != null
          ? QualityLevel.values.firstWhere(
              (e) => e.name == json['qualityLevel'],
              orElse: () => QualityLevel.none,
            )
          : null,
      isBarAnnotation: json['isBarAnnotation'] as bool? ?? false,
    );
  }

  AnnotationStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DateTime? createdAt,
    int? barNumber,
    QualityLevel? qualityLevel,
    bool? isBarAnnotation,
  }) {
    return AnnotationStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      createdAt: createdAt ?? this.createdAt,
      barNumber: barNumber ?? this.barNumber,
      qualityLevel: qualityLevel ?? this.qualityLevel,
      isBarAnnotation: isBarAnnotation ?? this.isBarAnnotation,
    );
  }
}

enum AnnotationLayer {
  teacher,
  student,
}

extension AnnotationLayerExtension on AnnotationLayer {
  Color get defaultColor {
    switch (this) {
      case AnnotationLayer.teacher:
        return const Color(0xFFAB47BC);
      case AnnotationLayer.student:
        return const Color(0xFF3D4D7B);
    }
  }

  String get displayName {
    switch (this) {
      case AnnotationLayer.teacher:
        return 'Teacher';
      case AnnotationLayer.student:
        return 'Student';
    }
  }
}

class CollaboratorInfo {
  final String id;
  final String name;
  final Color color;
  final AnnotationLayer layer;
  final DateTime addedAt;

  CollaboratorInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.layer,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'layer': layer.name,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CollaboratorInfo.fromJson(Map<String, dynamic> json) {
    return CollaboratorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      layer: AnnotationLayer.values.firstWhere(
        (e) => e.name == json['layer'],
        orElse: () => AnnotationLayer.student,
      ),
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

class AnnotationData {
  final AnnotationLayer layer;
  final List<AnnotationStroke> strokes;
  bool isVisible;
  final String? collaboratorId;

  AnnotationData({
    required this.layer,
    this.strokes = const [],
    this.isVisible = true,
    this.collaboratorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'layer': layer.name,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'isVisible': isVisible,
      'collaboratorId': collaboratorId,
    };
  }

  factory AnnotationData.fromJson(Map<String, dynamic> json) {
    return AnnotationData(
      layer: AnnotationLayer.values.firstWhere(
        (e) => e.name == json['layer'],
        orElse: () => AnnotationLayer.student,
      ),
      strokes: (json['strokes'] as List)
          .map((s) => AnnotationStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      isVisible: json['isVisible'] as bool? ?? true,
      collaboratorId: json['collaboratorId'] as String?,
    );
  }
}
