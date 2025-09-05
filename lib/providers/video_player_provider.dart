import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/video_model.dart';

class VideoPlayerProvider extends ChangeNotifier {
  VideoPlayerController? _controller;
  VideoModel? _currentVideo;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _controlsManuallyHidden =
      false; // Track if controls were manually hidden
  bool _isLiked = false;
  bool _isDisliked = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  bool _mounted = true; // Track if provider is still mounted
  bool _isTransitioning =
      false; // Track if we're transitioning between episodes

  // Playback settings
  PlaybackSettings _settings = PlaybackSettings();

  // Episode management
  List<EpisodeModel> _episodes = [];
  int _currentEpisodeIndex = 0;

  // Subtitle and quality management
  SubtitleTrack? _currentSubtitleTrack;
  QualityOption? _currentQuality;
  AudioTrack? _currentAudioTrack;

  // UI state
  bool _isSettingsVisible = false;
  String _selectedSettingsTab = 'quality'; // quality, subtitles, audio, speed

  // Safe notifyListeners that checks if mounted
  void _safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  // Getters
  VideoPlayerController? get controller => _controller;
  VideoModel? get currentVideo => _currentVideo;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isFullscreen => _isFullscreen;
  bool get showControls => _showControls;
  bool get isLiked => _isLiked;
  bool get isDisliked => _isDisliked;
  Duration get position => _position;
  Duration get duration => _duration;
  PlaybackSettings get settings => _settings;
  List<EpisodeModel> get episodes => _episodes;
  int get currentEpisodeIndex => _currentEpisodeIndex;
  SubtitleTrack? get currentSubtitleTrack => _currentSubtitleTrack;
  QualityOption? get currentQuality => _currentQuality;
  AudioTrack? get currentAudioTrack => _currentAudioTrack;
  bool get isSettingsVisible => _isSettingsVisible;
  String get selectedSettingsTab => _selectedSettingsTab;

  bool get hasNextEpisode => _currentEpisodeIndex < _episodes.length - 1;
  bool get hasPreviousEpisode => _currentEpisodeIndex > 0;

  double get progress {
    if (_duration.inMilliseconds > 0 && _position.inMilliseconds >= 0) {
      final calculated = _position.inMilliseconds / _duration.inMilliseconds;
      if (calculated.isNaN || calculated.isInfinite) {
        return 0.0;
      }
      return calculated.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  Future<void> initializeVideo(
    VideoModel video, {
    List<EpisodeModel>? episodes,
    int episodeIndex = 0,
  }) async {
    try {
      // Clean up previous video but don't dispose the provider
      await cleanupPreviousVideo();

      _currentVideo = video;
      _episodes = episodes ?? [];
      _currentEpisodeIndex = episodeIndex;

      debugPrint('Initializing video: ${video.m3u8Url}');

      // Initialize video controller
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(video.m3u8Url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Add listener before initialization
      _controller!.addListener(_videoListener);

      debugPrint('Starting video initialization...');
      await _controller!.initialize();
      debugPrint('Video initialized successfully');

      if (!_controller!.value.isInitialized) {
        debugPrint('Video controller not initialized properly');
        return;
      }

      _duration = _controller!.value.duration;
      debugPrint('Video duration: $_duration');

      // Set default quality and tracks
      if (video.qualities.isNotEmpty) {
        _currentQuality = video.qualities.firstWhere(
          (q) => q.isDefault,
          orElse: () => video.qualities.first,
        );
      }

      if (video.subtitles.isNotEmpty) {
        _currentSubtitleTrack = video.subtitles.firstWhere(
          (s) => s.languageCode == _settings.preferredSubtitleLanguage,
          orElse: () => video.subtitles.firstWhere(
            (s) => s.isDefault,
            orElse: () => video.subtitles.first,
          ),
        );
      }

      if (video.audioTracks.isNotEmpty) {
        _currentAudioTrack = video.audioTracks.firstWhere(
          (a) => a.languageCode == _settings.preferredAudioLanguage,
          orElse: () => video.audioTracks.firstWhere(
            (a) => a.isDefault,
            orElse: () => video.audioTracks.first,
          ),
        );
      }

      // Load saved preferences
      await _loadPreferences();

      // Set playback speed
      await _controller!.setPlaybackSpeed(_settings.playbackSpeed);

      // Start progress timer
      _startProgressTimer();

      // Auto-play if enabled
      if (_settings.autoPlay) {
        await play();
      }

      // Enable wakelock
      WakelockPlus.enable();

      debugPrint('Video initialization completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing video here: $e');
      // Notify listeners even on error so UI can show error state
      notifyListeners();
    }
  }

  Future<void> cleanupPreviousVideo() async {
    debugPrint('Cleaning up previous video...');

    _cancelHideControlsTimer();
    _progressTimer?.cancel();

    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      try {
        // Pause the video first to stop any ongoing playback
        if (_controller!.value.isInitialized && _controller!.value.isPlaying) {
          await _controller!.pause();
        }
        // Add a small delay before disposal
        await Future.delayed(const Duration(milliseconds: 100));
        await _controller!.dispose();
        debugPrint('Previous video controller disposed successfully');
      } catch (e) {
        debugPrint('Error disposing previous video controller: $e');
      }
      _controller = null;
    }

    // Reset state
    _isPlaying = false;
    _isBuffering = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isTransitioning = false;
  }

  void _videoListener() {
    if (_controller == null || !_mounted || !_controller!.value.isInitialized)
      return;

    try {
      final value = _controller!.value;
      _isBuffering = value.isBuffering;
      _isPlaying = value.isPlaying;
      _position = value.position;

      if (value.hasError) {
        debugPrint('Video player error: ${value.errorDescription}');
        // Try to recover from error
        if (value.errorDescription != null) {
          debugPrint('Attempting to recover from video error...');
          // Could implement retry logic here if needed
        }
      }

      // Check if video ended (with a small buffer to avoid timing issues)
      if (_duration > Duration.zero &&
          _position >= _duration - const Duration(milliseconds: 500)) {
        _onVideoEnded();
      }

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error in video listener: $e');
    }
  }

  void _onVideoEnded() {
    if (_isTransitioning) return; // Prevent multiple transitions

    if (_settings.autoPlayNextEpisode && hasNextEpisode) {
      _isTransitioning = true;
      // Add a small delay to ensure the current video has fully ended
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_mounted) {
          _isTransitioning = false;
          return;
        }
        playNextEpisode()
            .then((_) {
              _isTransitioning = false;
            })
            .catchError((e) {
              debugPrint('Error during episode transition: $e');
              _isTransitioning = false;
            });
      });
    } else {
      pause();
    }
  }

  Future<void> play() async {
    if (_controller != null) {
      await _controller!.play();
      _isPlaying = true;

      // Only start timer if controls are visible and not manually hidden
      if (_showControls && !_controlsManuallyHidden) {
        _startHideControlsTimer();
      }

      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_controller != null) {
      await _controller!.pause();
      _isPlaying = false;
      _cancelHideControlsTimer();
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_controller != null) {
      await _controller!.seekTo(position);
      _position = position;
      await _saveWatchProgress();
      notifyListeners();
    }
  }

  Future<void> seekForward([
    Duration duration = const Duration(seconds: 10),
  ]) async {
    final newPosition = _position + duration;
    final clampedPosition = newPosition > _duration ? _duration : newPosition;
    await seekTo(clampedPosition);
  }

  Future<void> seekBackward([
    Duration duration = const Duration(seconds: 5),
  ]) async {
    final newPosition = _position - duration;
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : newPosition;
    await seekTo(clampedPosition);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_controller != null) {
      await _controller!.setPlaybackSpeed(speed);
      _settings = _settings.copyWith(playbackSpeed: speed);
      await _savePreferences();
      notifyListeners();
    }
  }

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    notifyListeners();
  }

  void toggleControls() {
    print("Toggling controls");
    _showControls = !_showControls;

    // Cancel any existing timer first
    _cancelHideControlsTimer();

    if (_showControls) {
      // Controls are now visible - start timer only if video is playing
      _controlsManuallyHidden = false; // Reset the flag when showing controls
      if (_isPlaying) {
        _startHideControlsTimer();
      }
    } else {
      // Controls are now hidden - mark as manually hidden
      _controlsManuallyHidden = true;
    }

    notifyListeners();
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!_mounted) return; // Check if provider is still mounted
      if (_isPlaying && !_controlsManuallyHidden) {
        _showControls = false;
        _safeNotifyListeners();
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_mounted) {
        timer.cancel(); // Cancel timer if provider is disposed
        return;
      }
      if (_controller != null && _isPlaying) {
        _position = _controller!.value.position;
        _saveWatchProgress();
        _safeNotifyListeners();
      }
    });
  }

  Future<void> playNextEpisode() async {
    if (hasNextEpisode) {
      _currentEpisodeIndex++;
      final nextEpisode = _episodes[_currentEpisodeIndex];
      await initializeVideo(
        nextEpisode.videoData,
        episodes: _episodes,
        episodeIndex: _currentEpisodeIndex,
      );
    }
  }

  Future<void> playPreviousEpisode() async {
    if (hasPreviousEpisode) {
      _currentEpisodeIndex--;
      final previousEpisode = _episodes[_currentEpisodeIndex];
      await initializeVideo(
        previousEpisode.videoData,
        episodes: _episodes,
        episodeIndex: _currentEpisodeIndex,
      );
    }
  }

  Future<void> playEpisodeAt(int index) async {
    if (index >= 0 && index < _episodes.length) {
      _currentEpisodeIndex = index;
      final episode = _episodes[index];
      await initializeVideo(
        episode.videoData,
        episodes: _episodes,
        episodeIndex: index,
      );
    }
  }

  void setSubtitleTrack(SubtitleTrack? track) {
    _currentSubtitleTrack = track;
    _settings = _settings.copyWith(
      subtitlesEnabled: track != null,
      preferredSubtitleLanguage: track?.languageCode ?? 'off',
    );

    _savePreferences();
    notifyListeners();
  }

  void setQuality(QualityOption quality) {
    switchQuality(quality);
    _settings = _settings.copyWith(preferredQuality: quality.label);
    _savePreferences();
  }

  void setAudioTrack(AudioTrack track) {
    _currentAudioTrack = track;
    _settings = _settings.copyWith(preferredAudioLanguage: track.languageCode);
    _savePreferences();
    notifyListeners();
  }

  void toggleLike() {
    if (_isLiked) {
      _isLiked = false;
    } else {
      _isLiked = true;
      _isDisliked = false;
    }
    notifyListeners();
  }

  void toggleDislike() {
    if (_isDisliked) {
      _isDisliked = false;
    } else {
      _isDisliked = true;
      _isLiked = false;
    }
    notifyListeners();
  }

  void showSettings({String tab = 'quality'}) {
    _isSettingsVisible = true;
    _selectedSettingsTab = tab;
    notifyListeners();
  }

  void hideSettings() {
    _isSettingsVisible = false;
    notifyListeners();
  }

  void setSettingsTab(String tab) {
    _selectedSettingsTab = tab;
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _settings = PlaybackSettings(
        playbackSpeed: prefs.getDouble('playback_speed') ?? 1.0,
        autoPlay: prefs.getBool('auto_play') ?? true,
        autoPlayNextEpisode: prefs.getBool('auto_play_next_episode') ?? true,
        preferredQuality: prefs.getString('preferred_quality') ?? 'auto',
        preferredAudioLanguage:
            prefs.getString('preferred_audio_language') ?? 'en',
        preferredSubtitleLanguage:
            prefs.getString('preferred_subtitle_language') ?? 'off',
        subtitlesEnabled: prefs.getBool('subtitles_enabled') ?? false,
      );

      // Load like/dislike state for current video
      if (_currentVideo != null) {
        _isLiked = prefs.getBool('liked_${_currentVideo!.id}') ?? false;
        _isDisliked = prefs.getBool('disliked_${_currentVideo!.id}') ?? false;
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('playback_speed', _settings.playbackSpeed);
      await prefs.setBool('auto_play', _settings.autoPlay);
      await prefs.setBool(
        'auto_play_next_episode',
        _settings.autoPlayNextEpisode,
      );
      await prefs.setString('preferred_quality', _settings.preferredQuality);
      await prefs.setString(
        'preferred_audio_language',
        _settings.preferredAudioLanguage,
      );
      await prefs.setString(
        'preferred_subtitle_language',
        _settings.preferredSubtitleLanguage,
      );
      await prefs.setBool('subtitles_enabled', _settings.subtitlesEnabled);

      // Save like/dislike state for current video
      if (_currentVideo != null) {
        await prefs.setBool('liked_${_currentVideo!.id}', _isLiked);
        await prefs.setBool('disliked_${_currentVideo!.id}', _isDisliked);
      }
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  Future<void> _saveWatchProgress() async {
    if (_currentVideo == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('progress_${_currentVideo!.id}', _position.inSeconds);
    } catch (e) {
      debugPrint('Error saving watch progress: $e');
    }
  }

  Future<Duration> getWatchProgress(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt('progress_$videoId') ?? 0;
      return Duration(seconds: seconds);
    } catch (e) {
      debugPrint('Error getting watch progress: $e');
      return Duration.zero;
    }
  }

  // Quality switching methods
  Future<void> switchQuality(QualityOption quality) async {
    if (_controller == null || _currentVideo == null) return;

    try {
      final currentPosition = _position;
      final currentDuration = _duration;
      final isPlaying = _isPlaying;

      // Store current state
      await cleanupPreviousVideo();

      // Restore duration immediately to prevent progress bar issues
      _duration = currentDuration;

      // Create new controller with the selected quality URL
      String qualityUrl = quality.url;
      if (quality.id != 'auto' &&
          _currentVideo!.m3u8Url.contains('vrott-production-6.b-cdn.net')) {
        qualityUrl = _currentVideo!.m3u8Url;
      }

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(qualityUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      _controller!.addListener(_videoListener);
      await _controller!.initialize();

      // Update duration from the new controller
      if (_controller!.value.isInitialized) {
        _duration = _controller!.value.duration;
      }

      // Restart progress timer
      _startProgressTimer();

      // Seek to the previous position
      if (currentPosition > Duration.zero) {
        await _controller!.seekTo(currentPosition);
        _position = currentPosition; // Ensure position is maintained
      }

      // Resume playback if it was playing
      if (isPlaying) {
        await _controller!.play();
        _isPlaying = true;
      }

      _currentQuality = quality;
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching quality: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (!_mounted) return; // Already disposed

    _mounted = false; // Mark as disposed
    debugPrint('Disposing VideoPlayerProvider...');

    await cleanupPreviousVideo();

    // Disable wakelock
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('Error disabling wakelock: $e');
    }

    // Reset orientation
    try {
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
    } catch (e) {
      debugPrint('Error resetting system chrome: $e');
    }

    super.dispose();
  }
}
