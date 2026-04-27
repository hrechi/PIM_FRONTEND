import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Lightweight network-MP4 player used in the soil-measurement details
/// screen. Loads the video lazily, shows a play/pause overlay, and falls
/// back to a friendly error placeholder when the URL is unreachable.
class SoilVideoPlayer extends StatefulWidget {
  const SoilVideoPlayer({
    super.key,
    required this.url,
    this.height = 250,
  });

  final String url;
  final double height;

  @override
  State<SoilVideoPlayer> createState() => _SoilVideoPlayerState();
}

class _SoilVideoPlayerState extends State<SoilVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _placeholder(
        icon: Icons.broken_image,
        message: 'Unable to load recording',
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(
        height: widget.height,
        color: AppColorPalette.softSlate.withOpacity(0.1),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: c.value.aspectRatio == 0
                ? 16 / 9
                : c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
          VideoProgressIndicator(c, allowScrubbing: true),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                c.value.isPlaying ? c.pause() : c.play();
              }),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: c.value.isPlaying
                    ? const SizedBox.shrink()
                    : Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({required IconData icon, required String message}) {
    return Container(
      height: widget.height,
      color: AppColorPalette.softSlate.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColorPalette.softSlate),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.caption(color: AppColorPalette.softSlate),
            ),
          ],
        ),
      ),
    );
  }
}
