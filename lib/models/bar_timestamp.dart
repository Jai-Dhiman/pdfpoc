class BarTimestamp {
  final int barNumber;
  final double timestamp;

  BarTimestamp({
    required this.barNumber,
    required this.timestamp,
  });

  factory BarTimestamp.fromJson(Map<String, dynamic> json) {
    return BarTimestamp(
      barNumber: json['barNumber'] as int,
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barNumber': barNumber,
      'timestamp': timestamp,
    };
  }
}

class VideoData {
  final String videoId;
  final List<BarTimestamp> barTimestamps;

  VideoData({
    required this.videoId,
    required this.barTimestamps,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      videoId: json['videoId'] as String,
      barTimestamps: (json['barTimestamps'] as List)
          .map((item) => BarTimestamp.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'barTimestamps': barTimestamps.map((item) => item.toJson()).toList(),
    };
  }

  int? findBarNumberForTimestamp(double currentTime) {
    for (int i = barTimestamps.length - 1; i >= 0; i--) {
      if (currentTime >= barTimestamps[i].timestamp) {
        return barTimestamps[i].barNumber;
      }
    }
    return null;
  }

  double? findTimestampForBar(int barNumber) {
    for (var item in barTimestamps) {
      if (item.barNumber == barNumber) {
        return item.timestamp;
      }
    }
    return null;
  }
}
