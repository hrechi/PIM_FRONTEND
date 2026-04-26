import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One persisted entry in the plant doctor history (one screenshot or video
/// captured + the AI report it produced).
class PlantDoctorRecord {
  PlantDoctorRecord({
    required this.id,
    required this.timestamp,
    required this.imagePath,
    required this.isVideo,
    required this.aiResult,
    this.videoPath,
    this.source,
  });

  /// Stable UUID-ish id (millisecond timestamp).
  final String id;
  final DateTime timestamp;

  /// Path to a JPEG used as the cover/thumbnail. For videos this is the frame
  /// that was actually fed to the YOLO model.
  final String imagePath;

  /// True when the capture is a video (frame sequence stored at [videoPath]).
  final bool isVideo;

  /// Path to the original `.zip` of JPEG frames produced by the robot capture
  /// screen. Only populated when [isVideo] is true.
  final String? videoPath;

  /// "camera" | "gallery" | "robot" — purely informational.
  final String? source;

  /// Full JSON map returned by the `/analyze` endpoint
  /// ({name, scientific_name, description, diagnosis, severity,
  /// treatment_steps, prevention, ...}).
  final Map<String, dynamic> aiResult;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
        'isVideo': isVideo,
        'videoPath': videoPath,
        'source': source,
        'aiResult': aiResult,
      };

  static PlantDoctorRecord fromJson(Map<String, dynamic> json) =>
      PlantDoctorRecord(
        id: json['id'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        imagePath: json['imagePath'] as String? ?? '',
        isVideo: json['isVideo'] as bool? ?? false,
        videoPath: json['videoPath'] as String?,
        source: json['source'] as String?,
        aiResult: Map<String, dynamic>.from(
          json['aiResult'] as Map? ?? const <String, dynamic>{},
        ),
      );
}

/// Persists plant doctor analyses on the device so the user can revisit the
/// result of every screenshot / video they took.
class PlantDoctorHistoryService {
  static const _prefsKey = 'plant_doctor_history_v1';
  static const _mediaSubdir = 'plant_doctor';

  /// Returns the records ordered newest-first.
  Future<List<PlantDoctorRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    final records = <PlantDoctorRecord>[];
    for (final entry in raw) {
      try {
        final decoded = json.decode(entry);
        if (decoded is Map<String, dynamic>) {
          records.add(PlantDoctorRecord.fromJson(decoded));
        }
      } catch (_) {
        // Ignore malformed entries silently.
      }
    }
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  Future<void> _writeAll(List<PlantDoctorRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = records.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList(_prefsKey, encoded);
  }

  /// Persists [imageBytes] (and optionally the original [videoSource] file)
  /// inside the app documents directory and stores a metadata record pointing
  /// at them.
  Future<PlantDoctorRecord> add({
    required Uint8List imageBytes,
    required Map<String, dynamic> aiResult,
    bool isVideo = false,
    File? videoSource,
    String? source,
    String imageExtension = 'jpg',
  }) async {
    final dir = await _ensureMediaDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final imageFile = File('${dir.path}/${id}_cover.$imageExtension');
    await imageFile.writeAsBytes(imageBytes, flush: true);

    String? videoPath;
    if (isVideo && videoSource != null && await videoSource.exists()) {
      final ext = videoSource.path.split('.').last.toLowerCase();
      final dest = File('${dir.path}/${id}_clip.$ext');
      await videoSource.copy(dest.path);
      videoPath = dest.path;
    }

    final record = PlantDoctorRecord(
      id: id,
      timestamp: DateTime.now(),
      imagePath: imageFile.path,
      isVideo: isVideo,
      videoPath: videoPath,
      source: source,
      aiResult: aiResult,
    );

    final all = await loadAll();
    all.insert(0, record);
    await _writeAll(all);
    return record;
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    final remaining = <PlantDoctorRecord>[];
    for (final r in all) {
      if (r.id == id) {
        await _safeDelete(r.imagePath);
        if (r.videoPath != null) await _safeDelete(r.videoPath!);
      } else {
        remaining.add(r);
      }
    }
    await _writeAll(remaining);
  }

  Future<void> clear() async {
    final all = await loadAll();
    for (final r in all) {
      await _safeDelete(r.imagePath);
      if (r.videoPath != null) await _safeDelete(r.videoPath!);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<Directory> _ensureMediaDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_mediaSubdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {/* ignore */}
  }
}
