import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

/// Plain data describing a robot the backend knows about.
class RobotDescriptor {
  const RobotDescriptor({
    required this.id,
    required this.name,
    required this.ip,
    required this.rosbridgePort,
    required this.videoPort,
    required this.videoTopic,
  });

  final String id;
  final String name;
  final String ip;
  final int rosbridgePort;
  final int videoPort;
  final String videoTopic;

  factory RobotDescriptor.fromJson(Map<String, dynamic> json) {
    return RobotDescriptor(
      id: json['id'] as String,
      name: json['name'] as String,
      ip: json['ip'] as String,
      rosbridgePort: (json['rosbridgePort'] as num).toInt(),
      videoPort: (json['videoPort'] as num).toInt(),
      videoTopic: json['videoTopic'] as String,
    );
  }
}

/// Symbolic command names mirrored on the NestJS DTO.
enum RobotCommand { forward, backward, left, right, stop }

extension RobotCommandName on RobotCommand {
  String get wireName => name; // matches the DTO's lowercase enum values
}

/// Talks to the NestJS backend for robot registry + audit logging.
///
/// Reuses the existing [ApiService] for base URL + JWT retrieval so we don't
/// duplicate auth handling. The shared `accessToken` lives in
/// `SharedPreferences` (see [ApiService.getAccessToken]); migrating it to
/// `flutter_secure_storage` is a project-wide concern handled separately.
class RobotApiService {
  RobotApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final token = await ApiService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// `GET /api/robots` — returns the registered robots.
  Future<List<RobotDescriptor>> listRobots() async {
    final uri = Uri.parse('${ApiService.baseUrl}/robots');
    final res = await _client.get(uri, headers: await _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RobotApiException(
        'GET /robots failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw RobotApiException(
        'GET /robots returned unexpected payload: ${res.body}',
      );
    }
    return decoded
        .cast<Map<String, dynamic>>()
        .map(RobotDescriptor.fromJson)
        .toList(growable: false);
  }

  /// `POST /api/telemetry/command` — fire-and-forget audit log entry.
  ///
  /// Errors are logged but never thrown back to the caller, so a flaky
  /// backend never blocks the operator from driving the robot.
  void logCommand({
    required String robotId,
    required RobotCommand command,
    required double linear,
    required double angular,
  }) {
    unawaited(_postCommand(robotId, command, linear, angular));
  }

  Future<void> _postCommand(
    String robotId,
    RobotCommand command,
    double linear,
    double angular,
  ) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/telemetry/command');
      final body = json.encode({
        'robotId': robotId,
        'command': command.wireName,
        'linear': linear,
        'angular': angular,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      final res = await _client
          .post(uri, headers: await _headers(), body: body)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode >= 400) {
        debugPrint(
          '[RobotApiService] telemetry POST ${res.statusCode}: ${res.body}',
        );
      }
    } catch (e) {
      // Fire-and-forget; we never want telemetry failures to surface in UI.
      debugPrint('[RobotApiService] telemetry POST error: $e');
    }
  }

  void dispose() {
    _client.close();
  }

  /// Grab a single JPEG frame from the robot's `web_video_server` and write
  /// it to a temp file. Returns the local [File] so the caller can hand it
  /// to the existing soil-image upload pipeline.
  ///
  /// Tries `/snapshot?topic=...` first; if that fails (some web_video_server
  /// versions / topics return "connection closed before full header"),
  /// falls back to opening the MJPEG `/stream?topic=...` and extracting the
  /// first complete JPEG frame from the multipart body.
  Future<File> captureSnapshot(RobotDescriptor robot) async {
    final encodedTopic = Uri.encodeQueryComponent(robot.videoTopic);
    final base = 'http://${robot.ip}:${robot.videoPort}';
    final snapshotUri = Uri.parse('$base/snapshot?topic=$encodedTopic');
    // Use the same stream URL the Control Room's CameraView uses --
    // some web_video_server builds will close the connection if the
    // `type=mjpeg` query param is missing.
    final streamUri = streamUriFor(robot);

    Uint8List? jpegBytes;
    Object? snapshotError;

    // 1) Try /snapshot
    try {
      final res = await _client
          .get(snapshotUri)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        jpegBytes = res.bodyBytes;
      } else {
        snapshotError =
            'snapshot HTTP ${res.statusCode} (${res.bodyBytes.length} bytes)';
      }
    } catch (e) {
      snapshotError = e;
    }

    // 2) Fallback: pull one frame from the MJPEG stream.
    if (jpegBytes == null) {
      debugPrint(
        '[RobotApiService] /snapshot failed ($snapshotError); '
        'falling back to /stream',
      );
      try {
        jpegBytes = await _grabFrameFromMjpegStream(streamUri);
      } catch (e) {
        throw RobotApiException(
          'Capture failed. snapshot=$snapshotError; stream=$e',
        );
      }
    }

    final dir = await getTemporaryDirectory();
    final filename =
        'robot_${robot.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(jpegBytes, flush: true);
    return file;
  }

  /// Read raw bytes off `/stream` until we find one full JPEG (SOI..EOI),
  /// then close the connection. Works for any MJPEG multipart response —
  /// we don't bother parsing the multipart boundaries, we just look for the
  /// JPEG markers `0xFFD8 ... 0xFFD9` directly.
  Future<Uint8List> _grabFrameFromMjpegStream(Uri streamUri) async {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await httpClient.getUrl(streamUri);
      // web_video_server is happier when we look like a browser asking
      // for an MJPEG multipart stream. Without these headers some
      // builds close the socket immediately after the response line.
      req.headers.set(HttpHeaders.acceptHeader,
          'multipart/x-mixed-replace, image/jpeg, */*');
      req.headers.set(HttpHeaders.userAgentHeader,
          'Mozilla/5.0 FieldlyRobotClient/1.0');
      req.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
      final resp = await req.close().timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        throw RobotApiException(
          'Stream HTTP ${resp.statusCode} at $streamUri',
        );
      }

      final List<int> buffer = <int>[];
      const maxBytes = 8 * 1024 * 1024; // 8 MiB safety cap
      int soiIndex = -1;
      int searchFrom = 0;

      final completer = Completer<Uint8List>();
      late StreamSubscription<List<int>> sub;

      sub = resp.timeout(const Duration(seconds: 10)).listen(
        (chunk) {
          if (completer.isCompleted) return;
          buffer.addAll(chunk);
          if (buffer.length > maxBytes) {
            completer.completeError(
              RobotApiException(
                'Stream exceeded $maxBytes bytes without a frame',
              ),
            );
            sub.cancel();
            return;
          }

          // Find SOI (0xFFD8) once.
          if (soiIndex < 0) {
            final found = _indexOfPair(buffer, 0xFF, 0xD8, fromIndex: 0);
            if (found == null) return;
            soiIndex = found;
            searchFrom = soiIndex + 2;
          }

          // Find EOI (0xFFD9) after SOI.
          // Resume search from one byte before the new data to catch
          // markers split across chunks.
          final from = (searchFrom - 1).clamp(soiIndex + 2, buffer.length);
          final eoi = _indexOfPair(buffer, 0xFF, 0xD9, fromIndex: from);
          searchFrom = buffer.length;
          if (eoi == null) return;

          final frame = Uint8List.fromList(
            buffer.sublist(soiIndex, eoi + 2),
          );
          completer.complete(frame);
          sub.cancel();
        },
        onError: (Object e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(
              RobotApiException(
                'Stream ended after ${buffer.length} bytes '
                '(soi=$soiIndex) before a JPEG frame was found',
              ),
            );
          }
        },
        cancelOnError: true,
      );

      return await completer.future;
    } finally {
      httpClient.close(force: true);
    }
  }

  static int? _indexOfPair(
    List<int> bytes,
    int b0,
    int b1, {
    int fromIndex = 0,
  }) {
    final end = bytes.length - 1;
    for (var i = fromIndex < 0 ? 0 : fromIndex; i < end; i++) {
      if (bytes[i] == b0 && bytes[i + 1] == b1) return i;
    }
    return null;
  }

  /// Build the MJPEG live-stream URL for a given robot. Mirrors the
  /// query string used by the Control Room's `CameraView` widget so
  /// `web_video_server` returns a multipart/x-mixed-replace stream that
  /// `flutter_mjpeg` (and our raw recorder) can decode.
  Uri streamUriFor(RobotDescriptor robot, {int quality = 70}) {
    final encodedTopic = Uri.encodeQueryComponent(robot.videoTopic);
    return Uri.parse(
      'http://${robot.ip}:${robot.videoPort}/stream'
      '?topic=$encodedTopic&type=mjpeg&quality=$quality',
    );
  }

  /// Open a continuous MJPEG recording session against the robot. Each
  /// fully-decoded JPEG frame is delivered through [onFrame] together with
  /// the millisecond offset since recording started. The returned handle
  /// lets the UI stop the recording and produce a `.zip` file containing
  /// every captured frame plus a `manifest.json` with the timeline. The
  /// backend turns that zip into an MP4 with ffmpeg.
  RobotRecordingSession startRecording(
    RobotDescriptor robot, {
    void Function(int frameIndex, Uint8List jpeg)? onFrame,
    int maxFrames = 600, // ~60s at 10 fps safety cap
    Duration? maxDuration,
  }) {
    final session = RobotRecordingSession._(
      robot: robot,
      streamUri: streamUriFor(robot),
      onFrame: onFrame,
      maxFrames: maxFrames,
      maxDuration: maxDuration,
    );
    session._start();
    return session;
  }
}

/// Active MJPEG recording session. Call [stopAndZip] to finalize the
/// recording and obtain a local `.zip` file ready for upload.
class RobotRecordingSession {
  RobotRecordingSession._({
    required this.robot,
    required this.streamUri,
    this.onFrame,
    required this.maxFrames,
    this.maxDuration,
  });

  final RobotDescriptor robot;
  final Uri streamUri;
  final void Function(int frameIndex, Uint8List jpeg)? onFrame;
  final int maxFrames;
  final Duration? maxDuration;

  final List<Uint8List> _frames = <Uint8List>[];
  final List<int> _timestampsMs = <int>[];
  final Stopwatch _watch = Stopwatch();

  HttpClient? _httpClient;
  StreamSubscription<List<int>>? _sub;
  Completer<void>? _doneCompleter;
  Object? _error;
  bool _stopped = false;

  /// How many frames captured so far.
  int get frameCount => _frames.length;

  /// Elapsed milliseconds since the session started.
  int get elapsedMs => _watch.elapsedMilliseconds;

  /// True once the underlying MJPEG stream has been torn down.
  bool get isStopped => _stopped;

  void _start() {
    _watch.start();
    _doneCompleter = Completer<void>();
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    unawaited(_run());
  }

  Future<void> _run() async {
    final List<int> buffer = <int>[];
    int searchFrom = 0;
    int soiIndex = -1;
    try {
      final req = await _httpClient!.getUrl(streamUri);
      // Match the Control Room's CameraView headers so web_video_server
      // doesn't tear down the connection before sending any frames.
      req.headers.set(HttpHeaders.acceptHeader,
          'multipart/x-mixed-replace, image/jpeg, */*');
      req.headers.set(HttpHeaders.userAgentHeader,
          'Mozilla/5.0 FieldlyRobotClient/1.0');
      req.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
      final resp = await req.close().timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        throw RobotApiException(
          'Stream HTTP ${resp.statusCode} at $streamUri',
        );
      }
      _sub = resp.listen(
        (chunk) {
          if (_stopped) return;
          buffer.addAll(chunk);
          // Continuously extract JPEGs.
          while (true) {
            if (soiIndex < 0) {
              final found = RobotApiService._indexOfPair(
                buffer,
                0xFF,
                0xD8,
                fromIndex: 0,
              );
              if (found == null) {
                if (buffer.length > 4 * 1024 * 1024) {
                  // Avoid unbounded growth before we ever sync.
                  buffer.removeRange(0, buffer.length - 4096);
                }
                return;
              }
              soiIndex = found;
              searchFrom = soiIndex + 2;
            }
            final from = (searchFrom - 1).clamp(soiIndex + 2, buffer.length);
            final eoi = RobotApiService._indexOfPair(
              buffer,
              0xFF,
              0xD9,
              fromIndex: from,
            );
            if (eoi == null) {
              searchFrom = buffer.length;
              return;
            }
            final frame = Uint8List.fromList(
              buffer.sublist(soiIndex, eoi + 2),
            );
            final ts = _watch.elapsedMilliseconds;
            _frames.add(frame);
            _timestampsMs.add(ts);
            try {
              onFrame?.call(_frames.length - 1, frame);
            } catch (_) {}
            // Drop consumed bytes from the buffer.
            buffer.removeRange(0, eoi + 2);
            soiIndex = -1;
            searchFrom = 0;
            if (_frames.length >= maxFrames) {
              _stopInternal();
              return;
            }
            if (maxDuration != null &&
                _watch.elapsedMilliseconds >= maxDuration!.inMilliseconds) {
              _stopInternal();
              return;
            }
          }
        },
        onError: (Object e) {
          _error ??= e;
          _stopInternal();
        },
        onDone: () {
          _stopInternal();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _error = e;
      _stopInternal();
    }
  }

  void _stopInternal() {
    if (_stopped) return;
    _stopped = true;
    _watch.stop();
    try {
      _sub?.cancel();
    } catch (_) {}
    try {
      _httpClient?.close(force: true);
    } catch (_) {}
    if (!(_doneCompleter?.isCompleted ?? true)) {
      _doneCompleter!.complete();
    }
  }

  /// Stop capturing and write all collected frames into a `.zip` file in
  /// the OS temp directory. Returns the resulting [File] (with a
  /// `manifest.json` inside containing per-frame timestamps).
  ///
  /// Throws if no frames were captured.
  Future<File> stopAndZip() async {
    _stopInternal();
    // Give any in-flight onData a moment to flush.
    await _doneCompleter?.future
        .timeout(const Duration(seconds: 2), onTimeout: () {});

    if (_frames.isEmpty) {
      throw RobotApiException(
        'No frames were captured from the robot stream'
        '${_error != null ? ' (error: $_error)' : ''}.',
      );
    }

    final archive = Archive();
    for (var i = 0; i < _frames.length; i++) {
      final name = 'frame_${i.toString().padLeft(5, '0')}.jpg';
      final bytes = _frames[i];
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    final manifest = <String, dynamic>{
      'robotId': robot.id,
      'frameCount': _frames.length,
      'durationMs': _timestampsMs.isEmpty ? 0 : _timestampsMs.last,
      'timestampsMs': _timestampsMs,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    final manifestBytes = utf8.encode(json.encode(manifest));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw RobotApiException('Failed to encode recording zip');
    }

    final dir = await getTemporaryDirectory();
    final filename =
        'robot_${robot.id}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }

  /// Abort the recording without producing a file.
  Future<void> cancel() async {
    _stopInternal();
    _frames.clear();
    _timestampsMs.clear();
  }
}

class RobotApiException implements Exception {
  RobotApiException(this.message);
  final String message;
  @override
  String toString() => 'RobotApiException: $message';
}
