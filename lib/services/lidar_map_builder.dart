import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'robot_service.dart';

/// Lightweight in-memory occupancy grid built from `/scan` + odom-derived
/// pose. Uses a Bayesian log-odds update so cells can be incrementally
/// reinforced (free OR occupied) as the robot moves.
///
/// The grid is robot-centred at start; (0,0) world coordinates correspond to
/// the cell at [_originRow], [_originCol]. The grid does not auto-grow — make
/// it large enough for the area you plan to map (default 30 m × 30 m at 5 cm
/// resolution = 600×600 cells = 360 KB of int8).
class LidarMapBuilder {
  LidarMapBuilder({
    this.resolutionMeters = 0.05,
    this.widthMeters = 30.0,
    this.heightMeters = 30.0,
    this.lOccupied = 0.85,
    this.lFree = -0.4,
    this.lClampMin = -4.0,
    this.lClampMax = 4.0,
  })  : cols = (widthMeters / resolutionMeters).round(),
        rows = (heightMeters / resolutionMeters).round() {
    _grid = Float32List(rows * cols);
    _originRow = rows ~/ 2;
    _originCol = cols ~/ 2;
  }

  final double resolutionMeters;
  final double widthMeters;
  final double heightMeters;
  final double lOccupied;
  final double lFree;
  final double lClampMin;
  final double lClampMax;
  final int rows;
  final int cols;

  late final Float32List _grid;
  late final int _originRow;
  late final int _originCol;

  // Latest robot pose in world frame (metres, radians yaw).
  double _poseX = 0;
  double _poseY = 0;
  double _poseYaw = 0;
  bool _hasPose = false;
  int _updateCount = 0;

  int get updateCount => _updateCount;
  Float32List get logOdds => _grid;

  /// Update the latest pose from telemetry (yaw is degrees in RobotTelemetry).
  void setPoseFromTelemetry(RobotTelemetry t) {
    // RobotTelemetry doesn't expose x/y; we integrate from linearSpeed and
    // headingDeg between successive ticks.
    final now = DateTime.now();
    if (_lastPoseAt != null) {
      final dt = now.difference(_lastPoseAt!).inMilliseconds / 1000.0;
      if (dt > 0 && dt < 0.5) {
        final yaw = t.headingDeg * math.pi / 180.0;
        _poseX += t.linearSpeed * math.cos(yaw) * dt;
        _poseY += t.linearSpeed * math.sin(yaw) * dt;
        _poseYaw = yaw;
      }
    }
    _lastPoseAt = now;
    _hasPose = true;
  }

  DateTime? _lastPoseAt;

  /// Set pose explicitly (e.g. from a Pose subscription).
  void setPose({required double x, required double y, required double yawRad}) {
    _poseX = x;
    _poseY = y;
    _poseYaw = yawRad;
    _hasPose = true;
  }

  double get poseX => _poseX;
  double get poseY => _poseY;
  double get poseYaw => _poseYaw;

  /// Integrate one scan into the grid.
  void integrateScan(RobotLaserScan scan) {
    if (!_hasPose) {
      _hasPose = true; // assume origin
    }
    final cosY = math.cos(_poseYaw);
    final sinY = math.sin(_poseYaw);
    final originCellX = _originCol + (_poseX / resolutionMeters).round();
    final originCellY = _originRow - (_poseY / resolutionMeters).round();

    for (var i = 0; i < scan.ranges.length; i++) {
      final r = scan.ranges[i];
      final maxR = math.min(r.isFinite ? r : scan.rangeMax, scan.rangeMax);
      if (maxR <= scan.rangeMin) continue;
      final beamAngle = scan.angleMin + i * scan.angleIncrement;
      // Convert beam to world-frame direction.
      final wx = cosY * math.cos(beamAngle) - sinY * math.sin(beamAngle);
      final wy = sinY * math.cos(beamAngle) + cosY * math.sin(beamAngle);
      final endX = _poseX + maxR * wx;
      final endY = _poseY + maxR * wy;
      final endCellX = _originCol + (endX / resolutionMeters).round();
      final endCellY = _originRow - (endY / resolutionMeters).round();
      _bresenhamFree(originCellX, originCellY, endCellX, endCellY);
      // Mark the endpoint as occupied only if the beam actually hit something
      // (range < rangeMax). NaN/Inf or max-range = free sweep, no hit.
      final hit = r.isFinite && r < scan.rangeMax;
      if (hit) {
        _bumpCell(endCellX, endCellY, lOccupied);
      }
    }
    _updateCount++;
  }

  void _bumpCell(int col, int row, double delta) {
    if (col < 0 || col >= cols || row < 0 || row >= rows) return;
    final idx = row * cols + col;
    final v = (_grid[idx] + delta).clamp(lClampMin, lClampMax);
    _grid[idx] = v;
  }

  /// Mark all cells along the beam (excluding endpoint) as free.
  void _bresenhamFree(int x0, int y0, int x1, int y1) {
    var x = x0;
    var y = y0;
    final dx = (x1 - x0).abs();
    final dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx + dy;
    var steps = 0;
    while (true) {
      if (x == x1 && y == y1) break;
      _bumpCell(x, y, lFree);
      if (++steps > 2000) break; // safety
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y += sy;
      }
    }
  }

  /// Render the current map as a greyscale ARGB byte buffer (ready for
  /// `decodeImageFromPixels`). Free=white, unknown=grey, occupied=black.
  Uint8List toGreyscalePixels() {
    final out = Uint8List(rows * cols * 4);
    for (var i = 0; i < _grid.length; i++) {
      final l = _grid[i];
      int v;
      if (l == 0) {
        v = 200; // unknown — light grey
      } else if (l > 0) {
        // occupied: 0..255 → black-ish
        final t = (l / lClampMax).clamp(0.0, 1.0);
        v = (255 * (1 - t)).round();
      } else {
        // free: white
        final t = (l / lClampMin).clamp(0.0, 1.0);
        v = (200 + 55 * t).round();
      }
      final o = i * 4;
      out[o] = v;
      out[o + 1] = v;
      out[o + 2] = v;
      out[o + 3] = 255;
    }
    return out;
  }

  /// Snapshot the grid for persistence (rows × cols int8 in -127..127).
  Uint8List toInt8Snapshot() {
    final out = Uint8List(rows * cols);
    for (var i = 0; i < _grid.length; i++) {
      final l = _grid[i];
      final v = (l / lClampMax * 127).clamp(-127.0, 127.0).round();
      out[i] = v & 0xFF;
    }
    return out;
  }

  /// Clear the grid back to "all unknown".
  void reset() {
    for (var i = 0; i < _grid.length; i++) {
      _grid[i] = 0;
    }
    _poseX = 0;
    _poseY = 0;
    _poseYaw = 0;
    _hasPose = false;
    _lastPoseAt = null;
    _updateCount = 0;
  }

  // ── Field perimeter extraction ─────────────────────────────────────────

  /// Returns a closed polygon (in metres, robot-frame origin) approximating
  /// the outer boundary of the connected free region containing the robot.
  /// Uses a coarse marching-squares-style contour walk on the binary
  /// occupied/free grid.
  List<List<double>> extractPerimeter({double simplifyMeters = 0.10}) {
    if (!_hasPose && _updateCount == 0) return const [];
    final occ = Uint8List(rows * cols);
    for (var i = 0; i < _grid.length; i++) {
      occ[i] = _grid[i] > 0.3 ? 1 : 0;
    }
    // Flood-fill the free region from the robot cell.
    final originCellX = _originCol + (_poseX / resolutionMeters).round();
    final originCellY = _originRow - (_poseY / resolutionMeters).round();
    if (originCellX < 0 ||
        originCellX >= cols ||
        originCellY < 0 ||
        originCellY >= rows) {
      return const [];
    }
    final visited = Uint8List(rows * cols);
    final stack = <int>[originCellY * cols + originCellX];
    while (stack.isNotEmpty) {
      final idx = stack.removeLast();
      if (visited[idx] == 1) continue;
      visited[idx] = 1;
      final r = idx ~/ cols;
      final c = idx % cols;
      const dx = [1, -1, 0, 0];
      const dy = [0, 0, 1, -1];
      for (var k = 0; k < 4; k++) {
        final nr = r + dy[k];
        final nc = c + dx[k];
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        final ni = nr * cols + nc;
        if (visited[ni] == 1) continue;
        if (occ[ni] == 1) continue;
        // Only spread through cells that have actually been observed.
        if (_grid[ni] == 0) continue;
        stack.add(ni);
      }
    }
    // Boundary cells: visited cells adjacent to non-visited / occupied.
    final boundary = <int>[];
    for (var r = 1; r < rows - 1; r++) {
      for (var c = 1; c < cols - 1; c++) {
        final i = r * cols + c;
        if (visited[i] == 0) continue;
        bool isEdge = false;
        for (var k = 0; k < 4; k++) {
          const dx = [1, -1, 0, 0];
          const dy = [0, 0, 1, -1];
          final ni = (r + dy[k]) * cols + (c + dx[k]);
          if (visited[ni] == 0) {
            isEdge = true;
            break;
          }
        }
        if (isEdge) boundary.add(i);
      }
    }
    if (boundary.isEmpty) return const [];
    // Convert to world coords + simple Douglas-Peucker-lite via stride.
    final stride = math.max(1, (simplifyMeters / resolutionMeters).round());
    final poly = <List<double>>[];
    for (var i = 0; i < boundary.length; i += stride) {
      final idx = boundary[i];
      final r = idx ~/ cols;
      final c = idx % cols;
      final x = (c - _originCol) * resolutionMeters;
      final y = (_originRow - r) * resolutionMeters;
      poly.add(<double>[x, y]);
    }
    return poly;
  }
}

// kDebugMode reference to avoid unused import warning if extended later.
// ignore: unused_element
const _kSilenceDebug = kDebugMode;
