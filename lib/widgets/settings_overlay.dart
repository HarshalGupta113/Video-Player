import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_player_provider.dart';

class SettingsOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8)),
      child: Consumer<VideoPlayerProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              _buildTabBar(provider),

              // Content
              Expanded(child: _buildTabContent(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar(VideoPlayerProvider provider) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('Quality', 'quality', provider),
          _buildTab('Subtitles', 'subtitles', provider),
          _buildTab('Audio', 'audio', provider),
          _buildTab('Speed', 'speed', provider),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String tabKey, VideoPlayerProvider provider) {
    final isSelected = provider.selectedSettingsTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setSettingsTab(tabKey),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color(0xffAA0000) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Color(0xffAA0000) : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(VideoPlayerProvider provider) {
    switch (provider.selectedSettingsTab) {
      case 'quality':
        return _buildQualityTab(provider);
      case 'subtitles':
        return _buildSubtitlesTab(provider);
      case 'audio':
        return _buildAudioTab(provider);
      case 'speed':
        return _buildSpeedTab(provider);
      default:
        return _buildQualityTab(provider);
    }
  }

  Widget _buildQualityTab(VideoPlayerProvider provider) {
    if (provider.currentVideo?.qualities.isEmpty ?? true) {
      return const Center(
        child: Text(
          'No quality options available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.currentVideo!.qualities.length,
      itemBuilder: (context, index) {
        final quality = provider.currentVideo!.qualities[index];
        final isSelected = provider.currentQuality?.id == quality.id;

        return ListTile(
          title: Text(
            quality.label,
            style: TextStyle(
              color: isSelected ? Color(0xffAA0000) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${quality.width}x${quality.height}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(0xffAA0000))
              : null,
          onTap: () {
            provider.setQuality(quality);
            // Show loading indicator briefly
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switching to ${quality.label}...'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.black87,
              ),
            );
            // Close after a brief delay
            Future.delayed(const Duration(milliseconds: 800), () {
              onClose();
            });
          },
        );
      },
    );
  }

  Widget _buildSubtitlesTab(VideoPlayerProvider provider) {
    final subtitles = provider.currentVideo?.subtitles ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subtitles.length + 1, // +1 for "Off" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // "Off" option
          final isSelected = provider.currentSubtitleTrack == null;
          return ListTile(
            title: Text(
              'Off',
              style: TextStyle(
                color: isSelected ? Color(0xffAA0000) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: Color(0xffAA0000))
                : null,
            onTap: () {
              provider.setSubtitleTrack(null);
              onClose();
            },
          );
        }

        final subtitle = subtitles[index - 1];
        final isSelected = provider.currentSubtitleTrack?.id == subtitle.id;

        return ListTile(
          title: Text(
            subtitle.language,
            style: TextStyle(
              color: isSelected ? Color(0xffAA0000) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            subtitle.languageCode.toUpperCase(),
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(0xffAA0000))
              : null,
          onTap: () {
            provider.setSubtitleTrack(subtitle);
            onClose();
          },
        );
      },
    );
  }

  Widget _buildAudioTab(VideoPlayerProvider provider) {
    if (provider.currentVideo?.audioTracks.isEmpty ?? true) {
      return const Center(
        child: Text(
          'No audio tracks available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.currentVideo!.audioTracks.length,
      itemBuilder: (context, index) {
        final audioTrack = provider.currentVideo!.audioTracks[index];
        final isSelected = provider.currentAudioTrack?.id == audioTrack.id;

        return ListTile(
          title: Text(
            audioTrack.language,
            style: TextStyle(
              color: isSelected ? Color(0xffAA0000) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            audioTrack.languageCode.toUpperCase(),
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(0xffAA0000))
              : null,
          onTap: () {
            provider.setAudioTrack(audioTrack);
            onClose();
          },
        );
      },
    );
  }

  Widget _buildSpeedTab(VideoPlayerProvider provider) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: speeds.length,
      itemBuilder: (context, index) {
        final speed = speeds[index];
        final isSelected = provider.settings.playbackSpeed == speed;

        return ListTile(
          title: Text(
            '${speed}x',
            style: TextStyle(
              color: isSelected ? Color(0xffAA0000) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            _getSpeedDescription(speed),
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(0xffAA0000))
              : null,
          onTap: () {
            provider.setPlaybackSpeed(speed);
            onClose();
          },
        );
      },
    );
  }

  String _formatBitrate(int bitrate) {
    if (bitrate < 1000) {
      return '${bitrate}kbps';
    } else {
      return '${(bitrate / 1000).toStringAsFixed(1)}Mbps';
    }
  }

  String _getSpeedDescription(double speed) {
    switch (speed) {
      case 0.5:
        return 'Half speed';
      case 0.75:
        return 'Slow';
      case 1.0:
        return 'Normal';
      case 1.25:
        return 'Fast';
      case 1.5:
        return 'Faster';
      case 1.75:
        return 'Very fast';
      case 2.0:
        return 'Double speed';
      default:
        return 'Custom';
    }
  }
}
