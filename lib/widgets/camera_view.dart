import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

/// Renders a robot's MJPEG stream from `web_video_server`.
///
/// Falls back to an inline "Camera offline" placeholder if the stream
/// errors (Mjpeg passes errors via the `error` builder).
class CameraView extends StatelessWidget {
  const CameraView({
    super.key,
    required this.robotIp,
    required this.videoPort,
    required this.videoTopic,
    this.quality = 70,
    this.isLive = true,
  });

  final String robotIp;
  final int videoPort;
  final String videoTopic;
  final int quality;

  /// Set to `false` to pause the stream (e.g. when leaving the screen).
  final bool isLive;

  String get _streamUrl =>
      'http://$robotIp:$videoPort/stream'
      '?topic=$videoTopic&type=mjpeg&quality=$quality';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black,
          child: Mjpeg(
            stream: _streamUrl,
            isLive: isLive,
            fit: BoxFit.cover,
            error: (context, error, stack) => _OfflinePlaceholder(
              message: 'Camera offline',
              detail: error.toString(),
            ),
            loading: (context) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflinePlaceholder extends StatelessWidget {
  const _OfflinePlaceholder({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
