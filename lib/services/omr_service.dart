import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bar.dart';

/// Service for communicating with the OMR (Optical Music Recognition) API
class OMRService {
  final String baseUrl;

  OMRService({this.baseUrl = 'http://localhost:8000'});

  /// Check if OMR service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Detect bars from a PDF file
  Future<OMRResult> detectBars(
    File pdfFile, {
    int page = 0,
    int minBarWidth = 50,
    int minBarHeight = 100,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect-bars').replace(
          queryParameters: {
            'page': page.toString(),
            'min_bar_width': minBarWidth.toString(),
            'min_bar_height': minBarHeight.toString(),
          },
        ),
      );

      request.files.add(await http.MultipartFile.fromPath('pdf', pdfFile.path));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        if (jsonData['success'] == true) {
          final bars = (jsonData['bars'] as List)
              .map((b) => Bar.fromJson(b as Map<String, dynamic>))
              .toList();

          return OMRResult(
            success: true,
            bars: bars,
            imageWidth: jsonData['image_width'] as int?,
            imageHeight: jsonData['image_height'] as int?,
            barsDetected: jsonData['bars_detected'] as int?,
          );
        } else {
          return OMRResult(
            success: false,
            error: 'OMR detection returned success=false',
          );
        }
      } else {
        return OMRResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return OMRResult(
        success: false,
        error: 'Failed to connect to OMR service: $e',
      );
    }
  }

  /// Detect bars from a PDF asset path (for testing/demo)
  Future<OMRResult> detectBarsFromAsset(
    String assetPath, {
    int page = 0,
  }) async {
    // This would require copying the asset to a temporary file first
    // For now, return an error suggesting to use detectBars with a File
    return OMRResult(
      success: false,
      error: 'Asset detection not yet implemented. Use detectBars() with a File instead.',
    );
  }

  /// Advanced bar detection with multiple algorithms
  Future<OMRResult> detectBarsAdvanced(
    File pdfFile, {
    int page = 0,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect-bars-advanced').replace(
          queryParameters: {
            'page': page.toString(),
          },
        ),
      );

      request.files.add(await http.MultipartFile.fromPath('pdf', pdfFile.path));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        if (jsonData['success'] == true) {
          final bars = (jsonData['bars'] as List)
              .map((b) => Bar.fromJson(b as Map<String, dynamic>))
              .toList();

          return OMRResult(
            success: true,
            bars: bars,
            algorithm: jsonData['algorithm'] as String?,
            confidence: jsonData['confidence'] as String?,
          );
        } else {
          return OMRResult(
            success: false,
            error: 'Advanced OMR detection failed',
          );
        }
      } else {
        return OMRResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return OMRResult(
        success: false,
        error: 'Failed to connect to OMR service: $e',
      );
    }
  }
}

/// Result from OMR detection
class OMRResult {
  final bool success;
  final List<Bar>? bars;
  final int? imageWidth;
  final int? imageHeight;
  final int? barsDetected;
  final String? algorithm;
  final String? confidence;
  final String? error;

  OMRResult({
    required this.success,
    this.bars,
    this.imageWidth,
    this.imageHeight,
    this.barsDetected,
    this.algorithm,
    this.confidence,
    this.error,
  });

  @override
  String toString() {
    if (success) {
      return 'OMRResult(success: true, bars: ${bars?.length ?? 0})';
    } else {
      return 'OMRResult(success: false, error: $error)';
    }
  }
}
