import 'package:flutter/material.dart';
import 'package:netflix_video_player/widgets/episode_list_overlay.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/video_player_provider.dart';
import '../utils/responsive_spacing.dart';

class VideoControls extends StatelessWidget {
  final VoidCallback onTap;
  final Future<void> Function()? onBackPressed;

  const VideoControls({super.key, required this.onTap, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap:
              onTap, // This will call toggleControls when tapping on empty areas
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Top Controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(child: _buildTopControls(context, provider)),
                ),

                // Center Play/Pause Button
                Center(child: _buildCenterControls(context, provider)),

                // Bottom Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: _buildBottomControls(context, provider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopControls(BuildContext context, VideoPlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            onPressed: () async {
              if (onBackPressed != null) {
                await onBackPressed!();
              } else {
                final provider = Provider.of<VideoPlayerProvider>(
                  context,
                  listen: false,
                );
                await provider.dispose();
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),

          // Video Title
          if (provider.currentVideo != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.currentVideo!.seriesTitle.isNotEmpty
                          ? provider.currentVideo!.seriesTitle
                          : provider.currentVideo!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (provider.currentVideo!.seriesTitle.isNotEmpty)
                      Text(
                        'S${provider.currentVideo!.seasonNumber}:E${provider.currentVideo!.episodeNumber} ${provider.currentVideo!.title}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          if (provider.episodes.isNotEmpty)
            IconButton(
              onPressed: () => _showEpisodeList(context),
              icon: const Icon(Icons.list, color: Colors.white, size: 28),
            ),
          // Settings Button
          IconButton(
            onPressed: () => provider.showSettings(),
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  void _showEpisodeList(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (modalContext) =>
          ChangeNotifierProvider<VideoPlayerProvider>.value(
            value: provider,
            child: const EpisodeListOverlay(),
          ),
    );
  }

  Widget _buildCenterControls(
    BuildContext context,
    VideoPlayerProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Backward 5s
        _buildControlButton(
          icon: FontAwesomeIcons.backward,
          onPressed: () => provider.seekBackward(),
        ),

        ResponsiveSpacing.horizontalSpacing(context, customSize: 40),

        // Play/Pause
        _buildControlButton(
          icon: provider.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 50,
          onPressed: () => provider.togglePlayPause(),
        ),

        ResponsiveSpacing.horizontalSpacing(context, customSize: 40),

        // Forward 10s
        _buildControlButton(
          icon: FontAwesomeIcons.forward,
          onPressed: () => provider.seekForward(),
        ),
      ],
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    VideoPlayerProvider provider,
  ) {
    return Padding(
      padding: ResponsiveSpacing.getPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          _buildProgressBar(context, provider),

          ResponsiveSpacing.verticalSpacing(context),

          // Bottom Control Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time Display
              Text(
                '${_formatDuration(provider.position)} / ${_formatDuration(provider.duration)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveSpacing.getSmallFontSize(context),
                ),
              ),

              // Control Buttons Row
              Row(
                children: [
                  // Like/Dislike
                  _buildLikeDislikeButtons(provider),

                  ResponsiveSpacing.horizontalSpacing(context),

                  // Speed Control
                  _buildSpeedButton(context, provider),

                  ResponsiveSpacing.horizontalSpacing(context),

                  // Quality Button
                  _buildQualityButton(provider),

                  ResponsiveSpacing.horizontalSpacing(context),

                  // Subtitle Toggle
                  _buildSubtitleButton(provider),

                  ResponsiveSpacing.horizontalSpacing(context),

                  // Episode Navigation
                  if (provider.episodes.isNotEmpty) ...[
                    _buildEpisodeNavigationButtons(provider),
                    ResponsiveSpacing.horizontalSpacing(context),
                  ],

                  // Fullscreen Toggle
                  // IconButton(
                  //   onPressed: () => provider.toggleFullscreen(),
                  //   icon: Icon(
                  //     provider.isFullscreen
                  //         ? Icons.fullscreen_exit
                  //         : Icons.fullscreen,
                  //     color: Colors.white,
                  //     size: ResponsiveSpacing.getIconSize(
                  //       context,
                  //       isLarge: true,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, VideoPlayerProvider provider) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.red,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: provider.progress.isNaN || provider.progress.isInfinite
                ? 0.0
                : provider.progress.clamp(0.0, 1.0),
            onChanged: provider.duration.inMilliseconds > 0
                ? (value) {
                    final position = Duration(
                      milliseconds: (value * provider.duration.inMilliseconds)
                          .round(),
                    );
                    provider.seekTo(position);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    double size = 32,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: size),
            if (label != null)
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeDislikeButtons(VideoPlayerProvider provider) {
    return Builder(
      builder: (context) => Row(
        children: [
          IconButton(
            onPressed: () => provider.toggleLike(),
            icon: Icon(
              provider.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: provider.isLiked ? Colors.red : Colors.white,
              size: ResponsiveSpacing.getIconSize(context),
            ),
          ),
          IconButton(
            onPressed: () => provider.toggleDislike(),
            icon: Icon(
              provider.isDisliked
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              color: provider.isDisliked ? Colors.red : Colors.white,
              size: ResponsiveSpacing.getIconSize(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(BuildContext context, VideoPlayerProvider provider) {
    return GestureDetector(
      onTap: () => _showSpeedDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${provider.settings.playbackSpeed}x',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveSpacing.getSmallFontSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityButton(VideoPlayerProvider provider) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => provider.showSettings(tab: 'quality'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hd,
                color: Colors.white,
                size: ResponsiveSpacing.getIconSize(context),
              ),
              const SizedBox(width: 4),
              Text(
                provider.currentQuality?.label ?? 'Auto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveSpacing.getSmallFontSize(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleButton(VideoPlayerProvider provider) {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () => provider.showSettings(tab: 'subtitles'),
        icon: Icon(
          Icons.closed_caption,
          color: provider.settings.subtitlesEnabled ? Colors.red : Colors.white,
          size: ResponsiveSpacing.getIconSize(context),
        ),
      ),
    );
  }

  Widget _buildEpisodeNavigationButtons(VideoPlayerProvider provider) {
    return Builder(
      builder: (context) => Row(
        children: [
          if (provider.hasPreviousEpisode)
            IconButton(
              onPressed: () => provider.playPreviousEpisode(),
              icon: Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: ResponsiveSpacing.getIconSize(context, isLarge: true),
              ),
            ),
          if (provider.hasNextEpisode)
            IconButton(
              onPressed: () => provider.playNextEpisode(),
              icon: Icon(
                Icons.skip_next,
                color: Colors.white,
                size: ResponsiveSpacing.getIconSize(context, isLarge: true),
              ),
            ),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, VideoPlayerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: Colors.black87,
        title: const Text(
          'Playback Speed',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
            return ListTile(
              title: Text(
                '${speed}x',
                style: TextStyle(
                  color: provider.settings.playbackSpeed == speed
                      ? Colors.red
                      : Colors.white,
                ),
              ),
              onTap: () {
                provider.setPlaybackSpeed(speed);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
