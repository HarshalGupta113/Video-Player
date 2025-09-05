import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_player_provider.dart';
import '../models/video_model.dart';
import 'video_controls.dart';
import 'settings_overlay.dart';

class NetflixVideoPlayer extends StatefulWidget {
  final VideoModel video;
  final List<EpisodeModel>? episodes;
  final int initialEpisodeIndex;
  final bool autoStartInLandscape;

  const NetflixVideoPlayer({
    super.key,
    required this.video,
    this.episodes,
    this.initialEpisodeIndex = 0,
    this.autoStartInLandscape = true,
  });

  @override
  State<NetflixVideoPlayer> createState() => _NetflixVideoPlayerState();
}

class _NetflixVideoPlayerState extends State<NetflixVideoPlayer> {
  late VideoPlayerProvider _videoPlayerProvider;

  @override
  void initState() {
    super.initState();
    _videoPlayerProvider = VideoPlayerProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
      if (widget.autoStartInLandscape) {
        _setLandscapeMode();
      }
    });
  }

  void _initializePlayer() {
    _videoPlayerProvider.initializeVideo(
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

  Future<void> _handleBackNavigation() async {
    await _videoPlayerProvider.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoPlayerProvider>.value(
      value: _videoPlayerProvider,
      child: PopScope(
        canPop: false, // Handle back button manually
        onPopInvoked: (didPop) async {
          if (didPop) return;
          await _handleBackNavigation();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Consumer<VideoPlayerProvider>(
            builder: (context, provider, child) {
              if (provider.controller == null ||
                  !provider.controller!.value.isInitialized) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xffAA0000)),
                      SizedBox(height: 16),
                      Text(
                        'Loading video...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  // Video Player - Try multiple approaches for better compatibility
                  GestureDetector(
                    onTap: () => provider.toggleControls(),
                    onDoubleTap: () => provider.togglePlayPause(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio:
                              provider.controller!.value.aspectRatio > 0
                              ? provider.controller!.value.aspectRatio
                              : 16 / 9,
                          child: VideoPlayer(provider.controller!),
                        ),
                      ),
                    ),
                  ),

                  // Buffering Indicator
                  if (provider.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color:  Color(0xffAA0000),
                        strokeWidth: 3,
                      ),
                    ),

                  // Video Controls
                  if (provider.showControls)
                    VideoControls(
                      onTap: () => provider.toggleControls(),
                      onBackPressed: _handleBackNavigation,
                    ),

                  // Settings Overlay
                  if (provider.isSettingsVisible)
                    SettingsOverlay(onClose: () => provider.hideSettings()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the local video player provider
    _videoPlayerProvider.dispose();

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
