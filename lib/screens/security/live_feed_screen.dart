import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/constants.dart';

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
  static const _prefsKey = 'ai_engine_ip';

  bool _isConnected = false;
  bool _isPolling = false;
  Uint8List? _frameBytes;
  Timer? _timer;
  int _fps = 0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  String _lastError = '';
  String _customHost = '';

  /// Resolved host: custom override or default from AppConfig
  String get _host =>
      _customHost.isNotEmpty ? _customHost : AppConfig.serverHost;

  /// Single-frame JPEG endpoint served by Flask
  String get _snapshotUrl => 'http://$_host:5050/snapshot';

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedHost().then((_) => _startPolling());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedHost() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _customHost = saved);
    }
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
          _lastError = '';
        });
      } else if (response.statusCode == 503) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _lastError = 'HTTP 503 — Camera not ready (no frame yet)';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _lastError =
                'HTTP ${response.statusCode} — ${response.reasonPhrase}';
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _lastError = 'Timeout — server at $_host:5050 not responding';
        });
      }
    } on http.ClientException catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _lastError = 'Connection refused — ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _lastError = e.toString().length > 80
              ? '${e.toString().substring(0, 80)}…'
              : e.toString();
        });
      }
    }
  }

  // ── Settings dialog ────────────────────────────────────────

  Future<void> _showIpDialog() async {
    final controller = TextEditingController(text: _host);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'AI Engine IP',
          style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: TextStyle(color: AppColorPalette.charcoalGreen),
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.182',
                hintStyle: TextStyle(
                  color: AppColorPalette.softSlate.withValues(alpha: 0.5),
                ),
                labelText: 'IP Address',
                labelStyle: const TextStyle(
                  color: AppColorPalette.robotTechStart,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColorPalette.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColorPalette.robotTechStart,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Default: ${AppConfig.serverHost}',
              style: AppTextStyles.caption(color: AppColorPalette.softSlate),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorPalette.softSlate),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, AppConfig.serverHost),
            child: Text(
              'Reset',
              style: TextStyle(color: AppColorPalette.warning),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorPalette.robotTechStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final prefs = await SharedPreferences.getInstance();
      if (result == AppConfig.serverHost) {
        await prefs.remove(_prefsKey);
        setState(() => _customHost = '');
      } else {
        await prefs.setString(_prefsKey, result);
        setState(() => _customHost = result);
      }
      // Restart polling with the new IP
      _stopPolling();
      setState(() {
        _frameBytes = null;
        _isConnected = false;
        _lastError = '';
      });
      _startPolling();
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live/offline dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _isConnected
                    ? AppColorPalette.success
                    : AppColorPalette.alertError,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isConnected
                                ? AppColorPalette.success
                                : AppColorPalette.alertError)
                            .withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                'Live Security Feed',
                style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColorPalette.charcoalGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // FPS badge
          if (_isConnected)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorPalette.robotTechStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_fps fps',
                  style: const TextStyle(
                    color: AppColorPalette.robotTechStart,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Change AI IP',
            onPressed: _showIpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isConnected
                      ? AppColorPalette.robotTechStart.withValues(alpha: 0.3)
                      : AppColorPalette.alertError.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isConnected
                                ? AppColorPalette.robotTechStart
                                : AppColorPalette.alertError)
                            .withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: const Color(0xFF0D0D1A),
                  child: _buildFeedContent(),
                ),
              ),
            ),
          ),

          // ── Status Bar ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColorPalette.wheatWarmClay,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColorPalette.lightGrey),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorPalette.robotTechStart.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: AppColorPalette.robotTechStart,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIM Brain',
                        style: AppTextStyles.label(
                          color: AppColorPalette.charcoalGreen,
                        ),
                      ),
                      Text(
                        'Real-time AI monitoring',
                        style: AppTextStyles.caption(
                          color: AppColorPalette.softSlate,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? AppColorPalette.success.withValues(alpha: 0.1)
                        : AppColorPalette.alertError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isConnected
                          ? AppColorPalette.success.withValues(alpha: 0.3)
                          : AppColorPalette.alertError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? AppColorPalette.success
                              : AppColorPalette.alertError,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          color: _isConnected
                              ? AppColorPalette.success
                              : AppColorPalette.alertError,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
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
        gaplessPlayback: true,
      );
    }

    // No frame yet
    if (!_isConnected) {
      // Connection failed
      return Container(
        color: AppColorPalette.wheatWarmClay,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColorPalette.alertError.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.videocam_off_rounded,
                    size: 48,
                    color: AppColorPalette.alertError.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Camera Offline',
                  style: AppTextStyles.h3(color: AppColorPalette.alertError),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make sure the AI engine is running\non $_host:5050',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(
                    color: AppColorPalette.softSlate,
                  ),
                ),
                if (_lastError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorPalette.alertError.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColorPalette.alertError.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Text(
                      _lastError,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(
                        color: AppColorPalette.alertError,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _stopPolling();
                        setState(() => _frameBytes = null);
                        _startPolling();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorPalette.robotTechStart,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showIpDialog,
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Change IP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorPalette.softSlate,
                        side: BorderSide(color: AppColorPalette.mediumGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Waiting for first frame
    return Container(
      color: AppColorPalette.wheatWarmClay,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColorPalette.robotTechStart,
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting to camera…',
              style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
            ),
          ],
        ),
      ),
    );
  }
}
