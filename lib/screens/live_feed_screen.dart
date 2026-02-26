import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/text_styles.dart';
import '../utils/constants.dart';

/// Displays the live camera feed from the Python AI engine.
///
/// Uses a polling approach: fetches a single JPEG snapshot from Flask every
/// 200 ms and displays it with [Image.memory]. This works reliably on mobile
/// because Flutter's [Image.network] cannot decode multipart/x-mixed-replace
/// MJPEG streams.
class LiveFeedScreen extends StatefulWidget {
  const LiveFeedScreen({super.key});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  static const _pollInterval = Duration(milliseconds: 200);

  bool _isConnected = false;
  bool _isPolling = false;
  Uint8List? _frameBytes;
  Timer? _timer;
  int _fps = 0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  /// Single-frame JPEG endpoint served by Flask
  String get _snapshotUrl =>
      'http://${AppConfig.serverHost}:5050/snapshot';

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Polling ────────────────────────────────────────────────

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _timer = Timer.periodic(_pollInterval, (_) => _fetchFrame());
  }

  void _stopPolling() {
    _isPolling = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchFrame() async {
    try {
      final response = await http
          .get(Uri.parse(_snapshotUrl))
          .timeout(const Duration(seconds: 2));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Update FPS counter
        _frameCount++;
        final now = DateTime.now();
        if (now.difference(_lastFpsUpdate).inMilliseconds >= 1000) {
          _fps = _frameCount;
          _frameCount = 0;
          _lastFpsUpdate = now;
        }

        setState(() {
          _frameBytes = response.bodyBytes;
          _isConnected = true;
        });
      } else {
        // Server up but camera not ready (503)
        if (mounted) setState(() => _isConnected = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            // Live/offline dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.greenAccent : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isConnected ? Colors.greenAccent : Colors.red)
                        .withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            Text(
              'Live Security Feed',
              style: AppTextStyles.h3(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // FPS badge
          if (_isConnected)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_fps fps',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry',
            onPressed: () {
              _stopPolling();
              setState(() {
                _frameBytes = null;
                _isConnected = false;
              });
              _startPolling();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Live Feed ──────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isConnected
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isConnected ? Colors.greenAccent : Colors.red)
                        .withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildFeedContent(),
              ),
            ),
          ),

          // ── Info Bar ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.greenAccent.withValues(alpha: 0.8),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PIM Brain • Real-time AI monitoring active',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isConnected ? 'LIVE' : 'OFFLINE',
                    style: TextStyle(
                      color: _isConnected ? Colors.greenAccent : Colors.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the camera frame area: spinner → frame → offline message
  Widget _buildFeedContent() {
    // We have a frame — show it
    if (_frameBytes != null) {
      return Image.memory(
        _frameBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true, // no flicker between frames
      );
    }

    // No frame yet
    if (!_isConnected) {
      // Connection failed
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.red.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Offline',
              style: AppTextStyles.h3(color: Colors.red.shade300),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the AI engine is running\non ${AppConfig.serverHost}:5050',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _stopPolling();
                setState(() => _frameBytes = null);
                _startPolling();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.greenAccent,
                side: const BorderSide(color: Colors.greenAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Waiting for first frame
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 16),
          Text(
            'Connecting to camera…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
