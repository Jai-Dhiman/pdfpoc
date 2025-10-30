import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bar.dart';
import '../models/bar_timestamp.dart';
import '../models/video_piece.dart';
import 'midi_parser_service.dart';

class DataService {
  static const String barsPath = 'assets/data/bars.json';
  static const String timestampsPath = 'assets/data/timestamps.json';
  static const String videoLibraryPath = 'data/video_library.json';

  final MIDIParserService _midiParser = MIDIParserService();

  Future<List<Bar>> loadBars() async {
    final String jsonString = await rootBundle.loadString(barsPath);
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> barsJson = jsonData['bars'] as List;

    return barsJson
        .map((barJson) => Bar.fromJson(barJson as Map<String, dynamic>))
        .toList();
  }

  Future<VideoData> loadVideoData([String? videoId, String? midiFilePath]) async {
    // If MIDI file path is provided, try to parse it first
    if (midiFilePath != null && midiFilePath.isNotEmpty) {
      try {
        final timestamps = await _midiParser.parseMIDIFile(midiFilePath);
        if (timestamps.isNotEmpty && videoId != null) {
          return VideoData(
            videoId: videoId,
            barTimestamps: timestamps,
          );
        }
      } catch (e) {
        // Failed to parse MIDI, will fall back to JSON timestamps
      }
    }

    // Fallback to JSON timestamps
    final String jsonString = await rootBundle.loadString(timestampsPath);
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    return VideoData.fromJson(jsonData);
  }

  Future<List<VideoPiece>> loadVideoLibrary() async {
    final String jsonString = await rootBundle.loadString(videoLibraryPath);
    final List<dynamic> videosJson = json.decode(jsonString) as List;

    return videosJson
        .map((videoJson) => VideoPiece.fromJson(videoJson as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> loadAllData() async {
    final bars = await loadBars();
    final videoData = await loadVideoData();

    return {
      'bars': bars,
      'videoData': videoData,
    };
  }
}
