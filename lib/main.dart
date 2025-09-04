import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/video_model.dart';
import 'widgets/netflix_video_player.dart';
import 'utils/m3u8_parser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const VideoPlayerDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoPlayerDemo extends StatelessWidget {
  const VideoPlayerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Video Player',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<List<List<EpisodeModel>>>(
                future:
                    Future.wait([
                      _createSampleEpisodes('Out Come The Wolves'),
                      _createSampleEpisodes('A Mother\'s Special Love'),
                    ]).timeout(
                      const Duration(seconds: 30),
                    ), // Overall timeout for episode loading
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading episodes: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final episodeLists = snapshot.data ?? [[], []];
                  final outComeEpisodes = episodeLists.isNotEmpty
                      ? episodeLists[0]
                      : <EpisodeModel>[];
                  final motherEpisodes = episodeLists.length > 1
                      ? episodeLists[1]
                      : <EpisodeModel>[];

                  return ListView(
                    children: [
                      _buildVideoCard(
                        context,
                        'Out Come The Wolves',
                        'English Trailer - HLS Adaptive Streaming',
                        'https://vrott-production-6.b-cdn.net/Out_Come_The_Wolves_English_Trailer/playlist.m3u8',
                        'https://api.vrott.tv/uploads/airtelxstream/movies/OCTW_1920_548_Eng.jpg',
                        outComeEpisodes,
                      ),
                      const SizedBox(height: 16),
                      _buildVideoCard(
                        context,
                        'A Mother\'s Special Love',
                        'French Trailer - HLS Adaptive Streaming',
                        'https://vrott-production-6.b-cdn.net/A%20Mother\'s_Special_Love_French_Trailer/playlist.m3u8',
                        'https://api.vrott.tv/uploads/images/video/bd33f00f33742989eb3cf19a430de584-1742277503480-blob.png',
                        motherEpisodes,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    String title,
    String description,
    String videoUrl,
    String thumbnailUrl,
    List<EpisodeModel> episodes,
  ) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _playVideo(
          context,
          title,
          description,
          videoUrl,
          thumbnailUrl,
          episodes,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${episodes.length} episodes',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
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

  void _playVideo(
    BuildContext context,
    String title,
    String description,
    String videoUrl,
    String thumbnailUrl,
    List<EpisodeModel> episodes,
  ) async {
    // Calculate duration based on the video type
    Duration videoDuration = const Duration(minutes: 10); // Default
    if (videoUrl.contains('vrott-production-6.b-cdn.net')) {
      // Based on the M3U8 segment information: ~123.567 seconds
      videoDuration = const Duration(minutes: 2, seconds: 4);
    }

    // Show loading indicator while parsing qualities
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.red),
        );
      },
    );

    try {
      // Parse qualities dynamically from M3U8
      final qualities = await _createDynamicQualities(videoUrl);
      final audioTracks = await _createDynamicAudioTracks(videoUrl);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final video = VideoModel(
        id: title.toLowerCase().replaceAll(' ', '_'),
        title: title,
        description: description,
        m3u8Url: videoUrl,
        thumbnailUrl: thumbnailUrl,
        duration: videoDuration,
        subtitles: _createSampleSubtitles(),
        qualities: qualities,
        audioTracks: audioTracks,
        seasonNumber: 1,
        episodeNumber: 1,
        seriesTitle: '$title Series',
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NetflixVideoPlayer(
              video: video,
              episodes: episodes,
              autoStartInLandscape: true,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error and fallback to static qualities
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video qualities: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Create video with fallback qualities
        final video = VideoModel(
          id: title.toLowerCase().replaceAll(' ', '_'),
          title: title,
          description: description,
          m3u8Url: videoUrl,
          thumbnailUrl: thumbnailUrl,
          duration: videoDuration,
          subtitles: _createSampleSubtitles(),
          qualities: _createSampleQualities(videoUrl),
          audioTracks: _createSampleAudioTracks(),
          seasonNumber: 1,
          episodeNumber: 1,
          seriesTitle: '$title Series',
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NetflixVideoPlayer(
              video: video,
              episodes: episodes,
              autoStartInLandscape: true,
            ),
          ),
        );
      }
    }
  }

  /// Create dynamic qualities by parsing M3U8 playlist
  Future<List<QualityOption>> _createDynamicQualities(String videoUrl) async {
    try {
      // For M3U8 URLs, parse the playlist to get actual qualities
      if (videoUrl.contains('.m3u8')) {
        return await M3U8Parser.parseM3U8Qualities(
          videoUrl,
        ).timeout(const Duration(seconds: 10));
      }

      // For non-M3U8 URLs, return static qualities
      return _createSampleQualities(videoUrl);
    } catch (e) {
      print('Error creating dynamic qualities: $e');
      return _createSampleQualities(videoUrl);
    }
  }

  /// Create dynamic audio tracks by parsing M3U8 playlist
  Future<List<AudioTrack>> _createDynamicAudioTracks(String videoUrl) async {
    try {
      // For M3U8 URLs, try to parse audio tracks from playlist
      if (videoUrl.contains('.m3u8')) {
        final tracks = await M3U8Parser.parseM3U8AudioTracks(
          videoUrl,
        ).timeout(const Duration(seconds: 10));
        // If no tracks found in M3U8, fallback to sample tracks
        return tracks.isNotEmpty ? tracks : _createSampleAudioTracks();
      }

      // For non-M3U8 URLs, return static audio tracks
      return _createSampleAudioTracks();
    } catch (e) {
      print('Error creating dynamic audio tracks: $e');
      return _createSampleAudioTracks();
    }
  }

  Future<List<EpisodeModel>> _createSampleEpisodes(String seriesTitle) async {
    final episodes = <EpisodeModel>[];

    for (int index = 0; index < 2; index++) {
      final episodeNumber = index + 1;
      final videoUrl = _getSampleVideoUrl(index);

      try {
        // Get dynamic qualities and audio tracks for each episode with timeout
        final futures = await Future.wait([
          _createDynamicQualities(videoUrl),
          _createDynamicAudioTracks(videoUrl),
        ]).timeout(const Duration(seconds: 10));

        final qualities = futures[0] as List<QualityOption>;
        final audioTracks = futures[1] as List<AudioTrack>;

        episodes.add(
          EpisodeModel(
            id: '${seriesTitle.toLowerCase().replaceAll(' ', '_')}_ep_$episodeNumber',
            title: 'Episode $episodeNumber',
            description:
                'This is the description for episode $episodeNumber of $seriesTitle series.',
            thumbnailUrl:
                'https://via.placeholder.com/320x180?text=Episode+$episodeNumber',
            seasonNumber: 1,
            episodeNumber: episodeNumber,
            duration: Duration(minutes: 8 + (index * 2)),
            videoData: VideoModel(
              id: '${seriesTitle.toLowerCase().replaceAll(' ', '_')}_ep_$episodeNumber',
              title: 'Episode $episodeNumber',
              description: 'This is the description for episode $episodeNumber',
              m3u8Url: videoUrl,
              thumbnailUrl:
                  'https://via.placeholder.com/320x180?text=Episode+$episodeNumber',
              duration: Duration(minutes: 8 + (index * 2)),
              subtitles: _createSampleSubtitles(),
              qualities: qualities,
              audioTracks: audioTracks,
              seasonNumber: 1,
              episodeNumber: episodeNumber,
              seriesTitle: '$seriesTitle Series',
            ),
            // isWatched: index < 2, // Mark first two episodes as watched
            watchedDuration: index == 2
                ? const Duration(minutes: 3)
                : Duration.zero,
          ),
        );
      } catch (e) {
        print('Error creating episode $episodeNumber: $e');
        // Fallback to static qualities/audio if dynamic parsing fails
        episodes.add(
          EpisodeModel(
            id: '${seriesTitle.toLowerCase().replaceAll(' ', '_')}_ep_$episodeNumber',
            title: 'Episode $episodeNumber',
            description:
                'This is the description for episode $episodeNumber of $seriesTitle series.',
            thumbnailUrl:
                'https://via.placeholder.com/320x180?text=Episode+$episodeNumber',
            seasonNumber: 1,
            episodeNumber: episodeNumber,
            duration: Duration(minutes: 8 + (index * 2)),
            videoData: VideoModel(
              id: '${seriesTitle.toLowerCase().replaceAll(' ', '_')}_ep_$episodeNumber',
              title: 'Episode $episodeNumber',
              description: 'This is the description for episode $episodeNumber',
              m3u8Url: videoUrl,
              thumbnailUrl:
                  'https://via.placeholder.com/320x180?text=Episode+$episodeNumber',
              duration: Duration(minutes: 8 + (index * 2)),
              subtitles: _createSampleSubtitles(),
              qualities: _createSampleQualities(videoUrl), // Fallback to static
              audioTracks: _createSampleAudioTracks(), // Fallback to static
              seasonNumber: 1,
              episodeNumber: episodeNumber,
              seriesTitle: '$seriesTitle Series',
            ),
            isWatched: index < 2, // Mark first two episodes as watched
            watchedDuration: index == 2
                ? const Duration(minutes: 3)
                : Duration.zero,
          ),
        );
      }
    }

    return episodes;
  }

  String _getSampleVideoUrl(int index) {
    final urls = [
      'https://vrott-production-6.b-cdn.net/Out_Come_The_Wolves_English_Trailer/playlist.m3u8',
      'https://vrott-production-6.b-cdn.net/A%20Mother\'s_Special_Love_French_Trailer/playlist.m3u8',
    ];
    return urls[index % urls.length];
  }

  List<SubtitleTrack> _createSampleSubtitles() {
    return [
      SubtitleTrack(
        id: 'en',
        language: 'English',
        languageCode: 'en',
        url: 'https://example.com/subtitles/en.vtt',
        isDefault: true,
      ),
      SubtitleTrack(
        id: 'hi',
        language: 'Hindi',
        languageCode: 'hi',
        url: 'https://example.com/subtitles/hi.vtt',
      ),
      SubtitleTrack(
        id: 'es',
        language: 'Spanish',
        languageCode: 'es',
        url: 'https://example.com/subtitles/es.vtt',
      ),
    ];
  }

  List<QualityOption> _createSampleQualities(String baseUrl) {
    // If it's one of the HLS URLs, provide actual qualities from the playlists
    if (baseUrl.contains('vrott-production-6.b-cdn.net')) {
      return [
        QualityOption(
          id: 'auto',
          label: 'Auto',
          url: baseUrl,
          height: 720,
          width: 1280,
          bitrate: 3144,
          isDefault: true,
        ),
        QualityOption(
          id: '1080p',
          label: '1080p (5.7 Mbps)',
          url: baseUrl,
          height: 1080,
          width: 1920,
          bitrate: 5720,
        ),
        QualityOption(
          id: '720p',
          label: '720p (3.5 Mbps)',
          url: baseUrl,
          height: 720,
          width: 1280,
          bitrate: 3475,
        ),
        QualityOption(
          id: '540p',
          label: '540p (2.8 Mbps)',
          url: baseUrl,
          height: 540,
          width: 960,
          bitrate: 2753,
        ),
        QualityOption(
          id: '360p',
          label: '360p (1.2 Mbps)',
          url: baseUrl,
          height: 360,
          width: 640,
          bitrate: 1203,
        ),
      ];
    }

    // Default qualities for MP4 videos
    return [
      QualityOption(
        id: 'auto',
        label: 'Auto',
        url: baseUrl,
        height: 720,
        width: 1280,
        bitrate: 2500,
        isDefault: true,
      ),
      QualityOption(
        id: '1080p',
        label: '1080p',
        url: baseUrl,
        height: 1080,
        width: 1920,
        bitrate: 5000,
      ),
      QualityOption(
        id: '720p',
        label: '720p',
        url: baseUrl,
        height: 720,
        width: 1280,
        bitrate: 2500,
      ),
      QualityOption(
        id: '480p',
        label: '480p',
        url: baseUrl,
        height: 480,
        width: 854,
        bitrate: 1000,
      ),
    ];
  }

  List<AudioTrack> _createSampleAudioTracks() {
    return [
      AudioTrack(
        id: 'en',
        language: 'English',
        languageCode: 'en',
        url: 'https://example.com/audio/en.m4a',
        isDefault: true,
      ),
      AudioTrack(
        id: 'fr',
        language: 'Français',
        languageCode: 'fr',
        url: 'https://example.com/audio/fr.m4a',
      ),
    ];
  }
}
