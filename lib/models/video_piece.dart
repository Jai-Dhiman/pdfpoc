class VideoPiece {
  final String id;
  final String title;
  final String composer;
  final String performer;
  final String youtubeId;
  final String thumbnailUrl;
  final String? midiFilePath;

  VideoPiece({
    required this.id,
    required this.title,
    required this.composer,
    required this.performer,
    required this.youtubeId,
    this.midiFilePath,
  }) : thumbnailUrl = 'https://img.youtube.com/vi/$youtubeId/0.jpg';

  factory VideoPiece.fromJson(Map<String, dynamic> json) {
    return VideoPiece(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String,
      performer: json['performer'] as String,
      youtubeId: json['youtubeId'] as String,
      midiFilePath: json['midiFilePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'composer': composer,
      'performer': performer,
      'youtubeId': youtubeId,
      if (midiFilePath != null) 'midiFilePath': midiFilePath,
    };
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        composer.toLowerCase().contains(lowerQuery) ||
        performer.toLowerCase().contains(lowerQuery);
  }
}
