import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_player_provider.dart';
import '../models/video_model.dart';

class EpisodeListOverlay extends StatelessWidget {
  const EpisodeListOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerProvider>(
      builder: (context, provider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context, provider),

              // Episode List
              Expanded(child: _buildEpisodeList(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, VideoPlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.currentVideo?.seriesTitle ?? 'Episodes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (provider.currentVideo?.seriesTitle.isNotEmpty ?? false)
                Text(
                  'Season ${provider.currentVideo!.seasonNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList(VideoPlayerProvider provider) {
    if (provider.episodes.isEmpty) {
      return const Center(
        child: Text(
          'No episodes available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.episodes.length,
      itemBuilder: (context, index) {
        final episode = provider.episodes[index];
        final isCurrentEpisode = index == provider.currentEpisodeIndex;

        return _buildEpisodeCard(
          episode,
          index,
          isCurrentEpisode,
          provider,
          context,
        );
      },
    );
  }

  Widget _buildEpisodeCard(
    EpisodeModel episode,
    int index,
    bool isCurrentEpisode,
    VideoPlayerProvider provider,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCurrentEpisode
            ? Color(0xffAA0000).withOpacity(0.1)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: isCurrentEpisode
            ? Border.all(color:  Color(0xffAA0000), width: 1)
            : null,
      ),
      child: InkWell(
        onTap: () {
          provider.playEpisodeAt(index);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode Thumbnail
              Container(
                width: 120,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[800],
                ),
                child: Stack(
                  children: [
                    // Thumbnail Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: episode.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              episode.thumbnailUrl,
                              width: 120,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildThumbnailPlaceholder(),
                            )
                          : _buildThumbnailPlaceholder(),
                    ),

                    // Play Icon Overlay
                    if (isCurrentEpisode)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color:  Color(0xffAA0000),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),

                    // Duration Badge
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          _formatDuration(episode.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

                    // Progress Bar (if watched)
                    if (episode.watchedDuration > Duration.zero)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value:
                              episode.watchedDuration.inMilliseconds /
                              episode.duration.inMilliseconds,
                          backgroundColor: Colors.grey[600],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                             Color(0xffAA0000),
                          ),
                          minHeight: 2,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Episode Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Episode Number and Title
                    Text(
                      'Episode ${episode.episodeNumber}',
                      style: TextStyle(
                        color: isCurrentEpisode ? Color(0xffAA0000) : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      episode.title,
                      style: TextStyle(
                        color: isCurrentEpisode ? Color(0xffAA0000) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Episode Description
                    Text(
                      episode.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Episode Status
                    Row(
                      children: [
                        if (episode.isWatched)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Watched',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (episode.watchedDuration > Duration.zero &&
                            !episode.isWatched) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'In Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDuration(episode.watchedDuration)} / ${_formatDuration(episode.duration)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 120,
      height: 68,
      color: Colors.grey[800],
      child: const Icon(
        Icons.play_circle_outline,
        color: Colors.white54,
        size: 24,
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
