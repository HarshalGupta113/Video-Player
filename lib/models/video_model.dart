class VideoModel {
  final String id;
  final String title;
  final String description;
  final String m3u8Url;
  final String thumbnailUrl;
  final Duration duration;
  final List<SubtitleTrack> subtitles;
  final List<QualityOption> qualities;
  final List<AudioTrack> audioTracks;
  final int? nextEpisodeId;
  final int? previousEpisodeId;
  final int seasonNumber;
  final int episodeNumber;
  final String seriesTitle;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.m3u8Url,
    required this.thumbnailUrl,
    required this.duration,
    this.subtitles = const [],
    this.qualities = const [],
    this.audioTracks = const [],
    this.nextEpisodeId,
    this.previousEpisodeId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.seriesTitle,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      m3u8Url: json['m3u8_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      duration: Duration(seconds: json['duration'] ?? 0),
      subtitles:
          (json['subtitles'] as List<dynamic>?)
              ?.map((e) => SubtitleTrack.fromJson(e))
              .toList() ??
          [],
      qualities:
          (json['qualities'] as List<dynamic>?)
              ?.map((e) => QualityOption.fromJson(e))
              .toList() ??
          [],
      audioTracks:
          (json['audio_tracks'] as List<dynamic>?)
              ?.map((e) => AudioTrack.fromJson(e))
              .toList() ??
          [],
      nextEpisodeId: json['next_episode_id'],
      previousEpisodeId: json['previous_episode_id'],
      seasonNumber: json['season_number'] ?? 1,
      episodeNumber: json['episode_number'] ?? 1,
      seriesTitle: json['series_title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'm3u8_url': m3u8Url,
      'thumbnail_url': thumbnailUrl,
      'duration': duration.inSeconds,
      'subtitles': subtitles.map((e) => e.toJson()).toList(),
      'qualities': qualities.map((e) => e.toJson()).toList(),
      'audio_tracks': audioTracks.map((e) => e.toJson()).toList(),
      'next_episode_id': nextEpisodeId,
      'previous_episode_id': previousEpisodeId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'series_title': seriesTitle,
    };
  }
}

class SubtitleTrack {
  final String id;
  final String language;
  final String languageCode;
  final String url;
  final bool isDefault;

  SubtitleTrack({
    required this.id,
    required this.language,
    required this.languageCode,
    required this.url,
    this.isDefault = false,
  });

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      id: json['id'] ?? '',
      language: json['language'] ?? '',
      languageCode: json['language_code'] ?? '',
      url: json['url'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'language_code': languageCode,
      'url': url,
      'is_default': isDefault,
    };
  }
}

class QualityOption {
  final String id;
  final String label; // e.g., "720p", "1080p", "4K"
  final String url;
  final int height;
  final int width;
  final int bitrate;
  final bool isDefault;

  QualityOption({
    required this.id,
    required this.label,
    required this.url,
    required this.height,
    required this.width,
    required this.bitrate,
    this.isDefault = false,
  });

  factory QualityOption.fromJson(Map<String, dynamic> json) {
    return QualityOption(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      url: json['url'] ?? '',
      height: json['height'] ?? 0,
      width: json['width'] ?? 0,
      bitrate: json['bitrate'] ?? 0,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'url': url,
      'height': height,
      'width': width,
      'bitrate': bitrate,
      'is_default': isDefault,
    };
  }
}

class AudioTrack {
  final String id;
  final String language;
  final String languageCode;
  final String url;
  final bool isDefault;

  AudioTrack({
    required this.id,
    required this.language,
    required this.languageCode,
    required this.url,
    this.isDefault = false,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'] ?? '',
      language: json['language'] ?? '',
      languageCode: json['language_code'] ?? '',
      url: json['url'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'language_code': languageCode,
      'url': url,
      'is_default': isDefault,
    };
  }
}

class EpisodeModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int seasonNumber;
  final int episodeNumber;
  final Duration duration;
  final VideoModel videoData;
  final bool isWatched;
  final Duration watchedDuration;

  EpisodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.duration,
    required this.videoData,
    this.isWatched = false,
    this.watchedDuration = Duration.zero,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      seasonNumber: json['season_number'] ?? 1,
      episodeNumber: json['episode_number'] ?? 1,
      duration: Duration(seconds: json['duration'] ?? 0),
      videoData: VideoModel.fromJson(json['video_data'] ?? {}),
      isWatched: json['is_watched'] ?? false,
      watchedDuration: Duration(seconds: json['watched_duration'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'duration': duration.inSeconds,
      'video_data': videoData.toJson(),
      'is_watched': isWatched,
      'watched_duration': watchedDuration.inSeconds,
    };
  }
}

class PlaybackSettings {
  final double playbackSpeed;
  final bool autoPlay;
  final bool autoPlayNextEpisode;
  final String preferredQuality;
  final String preferredAudioLanguage;
  final String preferredSubtitleLanguage;
  final bool subtitlesEnabled;
  final Duration bufferDuration;
  final Duration initialBufferDuration;

  PlaybackSettings({
    this.playbackSpeed = 1.0,
    this.autoPlay = true,
    this.autoPlayNextEpisode = true,
    this.preferredQuality = 'auto',
    this.preferredAudioLanguage = 'en',
    this.preferredSubtitleLanguage = 'off',
    this.subtitlesEnabled = false,
    this.bufferDuration = const Duration(seconds: 10),
    this.initialBufferDuration = const Duration(seconds: 30),
  });

  PlaybackSettings copyWith({
    double? playbackSpeed,
    bool? autoPlay,
    bool? autoPlayNextEpisode,
    String? preferredQuality,
    String? preferredAudioLanguage,
    String? preferredSubtitleLanguage,
    bool? subtitlesEnabled,
    Duration? bufferDuration,
    Duration? initialBufferDuration,
  }) {
    return PlaybackSettings(
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      autoPlay: autoPlay ?? this.autoPlay,
      autoPlayNextEpisode: autoPlayNextEpisode ?? this.autoPlayNextEpisode,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      preferredAudioLanguage:
          preferredAudioLanguage ?? this.preferredAudioLanguage,
      preferredSubtitleLanguage:
          preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      bufferDuration: bufferDuration ?? this.bufferDuration,
      initialBufferDuration:
          initialBufferDuration ?? this.initialBufferDuration,
    );
  }
}
