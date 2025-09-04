# Netflix-Style Video Player for Flutter

A comprehensive, Netflix-style video player built with Flutter that supports M3U8 streams and provides a rich viewing experience similar to popular streaming platforms.

## Features

### 🎥 Video Playback

- **M3U8 Support**: Full support for HLS (HTTP Live Streaming) M3U8 files
- **Auto Landscape**: Automatically switches to landscape mode when video starts
- **Adaptive Buffering**: 30-second initial buffer, 10-second ongoing buffering
- **Multiple Formats**: Supports various video formats beyond M3U8

### 📱 Cross-Platform Compatibility

- **Android**: Optimized for Android phones and tablets
- **iOS**: Full iOS support for phones and tablets
- **Responsive Design**: Adapts to different screen sizes and orientations

### 🎛️ Advanced Controls

- **Play/Pause**: Standard video controls
- **Seek Controls**: Forward 10 seconds, backward 5 seconds
- **Speed Control**: Adjustable playback speed (0.5x to 2x)
- **Progress Bar**: Interactive timeline with seeking capability
- **Fullscreen Mode**: Toggle between normal and fullscreen viewing

### 🌐 Multi-Language Support

- **Subtitle Options**: Support for multiple subtitle tracks
- **Audio Languages**: Multiple audio track selection (Hindi, English, etc.)
- **Language Selection**: Easy switching between available languages

### 📺 Episode Management

- **Series Support**: Handle episodic content with seasons and episodes
- **Episode Navigation**: Next/Previous episode buttons
- **Episode List**: Comprehensive episode browser with thumbnails
- **Watch Progress**: Track viewing progress per episode
- **Auto-Play Next**: Automatic progression to next episode

### ⚙️ Quality & Settings

- **Quality Selection**: Choose from available video qualities (720p, 1080p, etc.)
- **Bitrate Control**: Manual quality/bitrate selection
- **Settings Overlay**: Comprehensive settings panel for quality, subtitles, audio, and speed
- **Persistent Preferences**: Save user preferences across sessions

### 👍 User Interaction

- **Like/Dislike**: Rate content with thumbs up/down
- **Gesture Controls**: Tap to show/hide controls, double-tap to play/pause
- **Auto-Hide Controls**: Controls automatically hide during playback

### 🎨 Netflix-Style UI

- **Dark Theme**: Netflix-inspired dark interface
- **Gradient Overlays**: Smooth gradients for control overlays
- **Red Accent**: Netflix-style red accent color
- **Modern Design**: Clean, modern interface with intuitive controls

## Installation

1. **Clone the repository**:

```bash
git clone <repository-url>
cd video_player
```

2. **Install dependencies**:

```bash
flutter pub get
```

3. **Run the app**:

```bash
flutter run
```

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_player_provider.dart';
import 'widgets/netflix_video_player.dart';
import 'models/video_model.dart';

class MyVideoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VideoPlayerProvider(),
      child: NetflixVideoPlayer(
        video: VideoModel(
          id: 'sample_video',
          title: 'Sample Video',
          description: 'A sample video description',
          m3u8Url: 'https://your-m3u8-url.m3u8',
          thumbnailUrl: 'https://your-thumbnail-url.jpg',
          duration: Duration(minutes: 120),
          seasonNumber: 1,
          episodeNumber: 1,
          seriesTitle: 'Sample Series',
        ),
        autoStartInLandscape: true,
      ),
    );
  }
}
```

All features implemented as requested:
✅ M3U8 file support
✅ Android, iOS and tablet compatibility  
✅ 30s initial buffering, 10s ongoing buffering
✅ Auto landscape mode
✅ Subtitle options
✅ Quality/bitrate selection
✅ Language options (Hindi, English, etc.)
✅ Forward(10s)/Backward(5s) controls
✅ Play/Pause functionality
✅ Speed control (0.5x-2x)
✅ Next/Previous episode navigation
✅ Episode list with thumbnails
✅ Like/Dislike functionality
