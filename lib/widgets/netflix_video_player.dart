import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../providers/video_player_provider.dart';
import '../providers/connectivity_provider.dart';
import '../models/video_model.dart';
import 'video_controls.dart';
import 'settings_overlay.dart';
import 'connectivity_wrapper.dart';

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

  // --- Double-tap handling ---
  TapDownDetails? _lastTapDown;
  bool _showLeftSeekIndicator = false;
  bool _showRightSeekIndicator = false;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _videoPlayerProvider = VideoPlayerProvider();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
      if (connectivity.isConnected) {
        _initializePlayer();
      }
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
      child: ConnectivityWrapper(
        offlineWidget: _buildOfflinePlayerWidget(),
        child: PopScope(
          canPop: false,
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
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (d) => _lastTapDown = d,
                      onTap: () => provider.toggleControls(),
                      onDoubleTap: () => _handleDoubleTap(provider),
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

                    // Seek indicators
                    if (_showLeftSeekIndicator)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Center(
                                  child: Icon(Icons.replay_5,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 70),
                                ),
                              ),
                              const Spacer(flex: 6),
                            ],
                          ),
                        ),
                      ),

                    if (_showRightSeekIndicator)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Row(
                            children: [
                              const Spacer(flex: 6),
                              Expanded(
                                flex: 4,
                                child: Center(
                                  child: Icon(Icons.forward_10,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (provider.isBuffering)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xffAA0000),
                          strokeWidth: 3,
                        ),
                      ),

                    if (provider.showControls)
                      VideoControls(
                        onTap: () => provider.toggleControls(),
                        onBackPressed: _handleBackNavigation,
                      ),

                    if (provider.isSettingsVisible)
                      SettingsOverlay(onClose: () => provider.hideSettings()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflinePlayerWidget() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '',  
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please connect to the internet to play videos',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Consumer<ConnectivityProvider>(
              builder: (context, connectivity, child) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffAA0000),
                  ),
                  onPressed: connectivity.isConnected ? _initializePlayer : null,
                  child: Text(
                    connectivity.isConnected ? 'Try Now' : 'Waiting for connection...',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Double-tap methods remain the same...
  void _handleDoubleTap(VideoPlayerProvider provider) {
    if (_lastTapDown == null) return;
    final width = MediaQuery.of(context).size.width;
    final dx = _lastTapDown!.globalPosition.dx;

    final leftRegionEnd = width * 0.40;
    final rightRegionStart = width * 0.60;

    if (dx < leftRegionEnd) {
      provider.seekBackward();
      _showSeekFeedback(isForward: false);
    } else if (dx > rightRegionStart) {
      provider.seekForward();
      _showSeekFeedback(isForward: true);
    } else {
      provider.togglePlayPause();
    }
  }

  void _showSeekFeedback({required bool isForward}) {
    setState(() {
      _showLeftSeekIndicator = !isForward;
      _showRightSeekIndicator = isForward;
    });
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _showLeftSeekIndicator = false;
        _showRightSeekIndicator = false;
      });
    });
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    _videoPlayerProvider.dispose();
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
