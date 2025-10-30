class Bar {
  final int barNumber;
  final double x;
  final double y;
  final double width;
  final double height;

  Bar({
    required this.barNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      barNumber: json['barNumber'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barNumber': barNumber,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  bool containsPoint(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }
}
