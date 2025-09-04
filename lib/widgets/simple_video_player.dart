import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_player_provider.dart';
import '../models/video_model.dart';

class SimpleVideoPlayer extends StatefulWidget {
  final VideoModel video;
  final List<EpisodeModel>? episodes;
  final int initialEpisodeIndex;
  final bool autoStartInLandscape;

  const SimpleVideoPlayer({
    super.key,
    required this.video,
    this.episodes,
    this.initialEpisodeIndex = 0,
    this.autoStartInLandscape = true,
  });

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
      if (widget.autoStartInLandscape) {
        _setLandscapeMode();
      }
    });
  }

  void _initializePlayer() {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    provider.initializeVideo(
      widget.video,
      episodes: widget.episodes,
      episodeIndex: widget.initialEpisodeIndex,
    );
  }

  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Video Player Test',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<VideoPlayerProvider>(
        builder: (context, provider, child) {
          if (provider.controller == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Initializing video controller...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!provider.controller!.value.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Show video info for debugging
          final videoValue = provider.controller!.value;

          return Column(
            children: [
              // Debug info
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[900],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Initialized: ${videoValue.isInitialized}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Size: ${videoValue.size}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Aspect Ratio: ${videoValue.aspectRatio}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Duration: ${videoValue.duration}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Position: ${videoValue.position}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Is Playing: ${videoValue.isPlaying}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Has Error: ${videoValue.hasError}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (videoValue.hasError)
                      Text(
                        'Error: ${videoValue.errorDescription}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Video Player
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: videoValue.aspectRatio > 0
                        ? AspectRatio(
                            aspectRatio: videoValue.aspectRatio,
                            child: VideoPlayer(provider.controller!),
                          )
                        : const Text(
                            'Invalid aspect ratio',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),

              // Simple controls
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => provider.togglePlayPause(),
                      icon: Icon(
                        videoValue.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: () => provider.seekBackward(),
                      icon: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: () => provider.seekForward(),
                      icon: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation when leaving the player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
}
