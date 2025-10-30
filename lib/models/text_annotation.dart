import 'package:flutter/material.dart';

/// Represents a text note/annotation attached to a specific bar in the sheet music
class TextAnnotation {
  final String id;
  final int barNumber;
  final String text;
  final Offset position;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Color backgroundColor;
  final Color textColor;

  TextAnnotation({
    required this.id,
    required this.barNumber,
    required this.text,
    required this.position,
    required this.createdAt,
    this.updatedAt,
    this.backgroundColor = const Color(0xFFFFF9C4), // Light yellow
    this.textColor = Colors.black87,
  });

  /// Create a copy with updated fields
  TextAnnotation copyWith({
    String? id,
    int? barNumber,
    String? text,
    Offset? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      barNumber: barNumber ?? this.barNumber,
      text: text ?? this.text,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barNumber': barNumber,
      'text': text,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'backgroundColor': backgroundColor.toARGB32(),
      'textColor': textColor.toARGB32(),
    };
  }

  /// Create from JSON
  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    return TextAnnotation(
      id: json['id'] as String,
      barNumber: json['barNumber'] as int,
      text: json['text'] as String,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      backgroundColor: Color(json['backgroundColor'] as int),
      textColor: Color(json['textColor'] as int),
    );
  }

  @override
  String toString() {
    return 'TextAnnotation(id: $id, barNumber: $barNumber, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TextAnnotation &&
        other.id == id &&
        other.barNumber == barNumber &&
        other.text == text &&
        other.position == position;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        barNumber.hashCode ^
        text.hashCode ^
        position.hashCode;
  }
}
