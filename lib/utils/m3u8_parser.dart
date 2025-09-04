import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class M3U8Parser {
  static const Map<String, String> _qualityLabels = {
    '1920x1080': '1080p',
    '1280x720': '720p',
    '960x540': '540p',
    '854x480': '480p',
    '640x360': '360p',
    '426x240': '240p',
  };

  /// Parse M3U8 playlist and extract quality options
  static Future<List<QualityOption>> parseM3U8Qualities(String m3u8Url) async {
    try {
      final response = await http
          .get(
            Uri.parse(m3u8Url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch M3U8: ${response.statusCode}');
      }

      return _parsePlaylistContent(response.body, m3u8Url);
    } catch (e) {
      print('Error parsing M3U8: $e');
      // Return fallback qualities if parsing fails
      return _createFallbackQualities(m3u8Url);
    }
  }

  static List<QualityOption> _parsePlaylistContent(
    String content,
    String baseUrl,
  ) {
    final lines = content.split('\n').map((line) => line.trim()).toList();
    final qualities = <QualityOption>[];

    // Always add Auto option first
    qualities.add(
      QualityOption(
        id: 'auto',
        label: 'Auto',
        url: baseUrl,
        height: 720,
        width: 1280,
        bitrate: 0, // Auto will be determined by player
        isDefault: true,
      ),
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        final streamInfo = _parseStreamInfo(line);

        // Get the next line which should contain the stream URL
        if (i + 1 < lines.length) {
          final streamUrl = lines[i + 1].trim();
          if (streamUrl.isNotEmpty && !streamUrl.startsWith('#')) {
            final quality = _createQualityFromStreamInfo(
              streamInfo,
              streamUrl,
              baseUrl,
            );
            if (quality != null) {
              qualities.add(quality);
            }
          }
        }
      }
    }

    // Sort qualities by resolution (highest first)
    qualities.sort((a, b) {
      if (a.id == 'auto') return -1;
      if (b.id == 'auto') return 1;
      return b.height.compareTo(a.height);
    });

    return qualities.isNotEmpty ? qualities : _createFallbackQualities(baseUrl);
  }

  static Map<String, String> _parseStreamInfo(String streamInfoLine) {
    final info = <String, String>{};

    // Remove the #EXT-X-STREAM-INF: prefix
    final attributesString = streamInfoLine.substring(
      '#EXT-X-STREAM-INF:'.length,
    );

    // Parse attributes
    final regex = RegExp(r'([A-Z-]+)=([^,]+)');
    final matches = regex.allMatches(attributesString);

    for (final match in matches) {
      final key = match.group(1)!;
      var value = match.group(2)!;

      // Remove quotes if present
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }

      info[key] = value;
    }

    return info;
  }

  static QualityOption? _createQualityFromStreamInfo(
    Map<String, String> streamInfo,
    String streamUrl,
    String baseUrl,
  ) {
    try {
      final bandwidth = int.tryParse(streamInfo['BANDWIDTH'] ?? '0') ?? 0;
      final resolution = streamInfo['RESOLUTION'] ?? '';

      if (resolution.isEmpty) return null;

      final resolutionParts = resolution.split('x');
      if (resolutionParts.length != 2) return null;

      final width = int.tryParse(resolutionParts[0]) ?? 0;
      final height = int.tryParse(resolutionParts[1]) ?? 0;

      if (width == 0 || height == 0) return null;

      // Determine quality label
      final qualityKey = '${width}x$height';
      final qualityLabel = _qualityLabels[qualityKey] ?? '${height}p';

      // Format bandwidth for display
      final bandwidthMbps = (bandwidth / 1000000).toStringAsFixed(1);
      final displayLabel = qualityLabel;

      // Construct full URL
      final fullUrl = _constructFullUrl(baseUrl, streamUrl);

      return QualityOption(
        id: qualityLabel.toLowerCase(),
        label: displayLabel,
        url: fullUrl,
        height: height,
        width: width,
        bitrate: bandwidth,
        isDefault: false,
      );
    } catch (e) {
      print('Error creating quality option: $e');
      return null;
    }
  }

  static String _constructFullUrl(String baseUrl, String streamUrl) {
    if (streamUrl.startsWith('http://') || streamUrl.startsWith('https://')) {
      return streamUrl;
    }

    // Extract base path from the original URL
    final uri = Uri.parse(baseUrl);
    final pathSegments = uri.pathSegments.toList();

    // Remove the last segment (filename) to get the directory
    if (pathSegments.isNotEmpty) {
      pathSegments.removeLast();
    }

    // Add the stream URL as the new filename
    pathSegments.add(streamUrl);

    return uri.replace(pathSegments: pathSegments).toString();
  }

  static List<QualityOption> _createFallbackQualities(String baseUrl) {
    return [
      QualityOption(
        id: 'auto',
        label: 'Auto',
        url: baseUrl,
        height: 720,
        width: 1280,
        bitrate: 0,
        isDefault: true,
      ),
      QualityOption(
        id: '1080p',
        label: '1080p',
        url: baseUrl,
        height: 1080,
        width: 1920,
        bitrate: 5000000,
      ),
      QualityOption(
        id: '720p',
        label: '720p',
        url: baseUrl,
        height: 720,
        width: 1280,
        bitrate: 2500000,
      ),
      QualityOption(
        id: '480p',
        label: '480p',
        url: baseUrl,
        height: 480,
        width: 854,
        bitrate: 1000000,
      ),
    ];
  }

  /// Parse audio tracks from M3U8 playlist
  static Future<List<AudioTrack>> parseM3U8AudioTracks(String m3u8Url) async {
    try {
      final response = await http
          .get(
            Uri.parse(m3u8Url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch M3U8: ${response.statusCode}');
      }

      return _parseAudioTracks(response.body, m3u8Url);
    } catch (e) {
      print('Error parsing M3U8 audio tracks: $e');
      return _createFallbackAudioTracks();
    }
  }

  static List<AudioTrack> _parseAudioTracks(String content, String baseUrl) {
    final lines = content.split('\n').map((line) => line.trim()).toList();
    final audioTracks = <AudioTrack>[];

    for (final line in lines) {
      if (line.startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
        final audioTrack = _parseAudioTrack(line, baseUrl);
        if (audioTrack != null) {
          audioTracks.add(audioTrack);
        }
      }
    }

    return audioTracks.isNotEmpty ? audioTracks : _createFallbackAudioTracks();
  }

  static AudioTrack? _parseAudioTrack(String mediaLine, String baseUrl) {
    try {
      final attributes = _parseMediaAttributes(mediaLine);

      final name = attributes['NAME'] ?? '';
      final language = attributes['LANGUAGE'] ?? '';
      final isDefault = attributes['DEFAULT'] == 'YES';
      final uri = attributes['URI'] ?? '';

      if (name.isEmpty || language.isEmpty) return null;

      final fullUrl = uri.isNotEmpty
          ? _constructFullUrl(baseUrl, uri)
          : baseUrl;

      return AudioTrack(
        id: language,
        language: _getLanguageDisplayName(language),
        languageCode: language,
        url: fullUrl,
        isDefault: isDefault,
      );
    } catch (e) {
      print('Error parsing audio track: $e');
      return null;
    }
  }

  static Map<String, String> _parseMediaAttributes(String mediaLine) {
    final attributes = <String, String>{};

    // Remove the #EXT-X-MEDIA: prefix
    final attributesString = mediaLine.substring('#EXT-X-MEDIA:'.length);

    // Parse attributes (handle quoted values properly)
    final regex = RegExp(r'([A-Z-]+)=([^,]+|"[^"]*")');
    final matches = regex.allMatches(attributesString);

    for (final match in matches) {
      final key = match.group(1)!;
      var value = match.group(2)!;

      // Remove quotes if present
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }

      attributes[key] = value;
    }

    return attributes;
  }

  static String _getLanguageDisplayName(String languageCode) {
    const languageNames = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
      'ko': '한국어',
      'zh': '中文',
      'hi': 'हिन्दी',
      'ar': 'العربية',
    };

    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  static List<AudioTrack> _createFallbackAudioTracks() {
    return [
      AudioTrack(
        id: 'en',
        language: 'English',
        languageCode: 'en',
        url: '',
        isDefault: true,
      ),
    ];
  }
}
