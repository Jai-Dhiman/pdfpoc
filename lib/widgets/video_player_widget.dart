import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../providers/app_state.dart';
import 'video_library_widget.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  YoutubePlayerController? _controller;
  Timer? _updateTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.registerSeekToBarAndPlayCallback((barNumber) {
        seekToBarAndPlay(barNumber);
      });
    });
  }

  Future<void> _initializePlayer([String? videoId]) async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.videoData == null) {
      await appState.loadData();
    }

    final videoIdToUse = videoId ?? appState.currentVideoId ?? appState.videoData?.videoId;

    if (videoIdToUse != null && mounted) {
      if (_controller != null) {
        await _controller!.close();
        _updateTimer?.cancel();
      }

      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoIdToUse,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          mute: false,
          showFullscreenButton: true,
          loop: false,
        ),
      );

      _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (_controller != null && mounted) {
          try {
            final currentTime = await _controller!.currentTime;
            if (currentTime > 0 && mounted) {
              Provider.of<AppState>(context, listen: false)
                  .updateCurrentBarFromTimestamp(currentTime);
            }
          } catch (e) {
            // Ignore errors when getting current time
          }
        }
      });

      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _showVideoLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Video Library',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: VideoLibraryWidget(
                  onVideoSelected: (videoId) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    appState.setCurrentVideoId(videoId);
                    _initializePlayer(videoId);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seekToBar(int barNumber) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final timestamp = appState.getTimestampForBar(barNumber);

    if (timestamp != null && _controller != null) {
      try {
        await _controller!.seekTo(seconds: timestamp);
      } catch (e) {
        debugPrint('Error seeking to timestamp: $e');
      }
    }
  }

  Future<void> seekToBarAndPlay(int barNumber) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final timestamp = appState.getTimestampForBar(barNumber);

    if (timestamp != null && _controller != null) {
      try {
        await _controller!.seekTo(seconds: timestamp);
        await _controller!.playVideo();
      } catch (e) {
        debugPrint('Error seeking and playing: $e');
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _controller!,
                aspectRatio: 16 / 9,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showVideoLibrary,
                      icon: const Icon(Icons.video_library, size: 20),
                      label: const Text('Change Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D4D7B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (appState.currentBarNumber != null)
              ElevatedButton.icon(
                onPressed: () => _seekToBar(appState.currentBarNumber!),
                icon: const Icon(Icons.play_arrow),
                label: Text('Play Bar ${appState.currentBarNumber}'),
              ),
          ],
        );
      },
    );
  }
}
