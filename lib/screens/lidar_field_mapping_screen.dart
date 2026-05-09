import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/lidar_map_builder.dart';
import '../services/robot_api_service.dart';
import '../services/robot_service.dart';
import '../services/robot_voice_controller.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/robot/lidar_map_panel.dart';
import '../widgets/robot/lidar_radar_panel.dart';

/// Dedicated workflow for **field mapping**:
///
/// * **Capture tab** — drive (or auto-explore) the robot around a field,
///   watch the live occupancy grid build up, then either save the map to
///   the backend or extract a polygon perimeter and return it to the
///   caller.
/// * **Saved Maps tab** — browse every map snapshot persisted on the
///   backend for this robot, with thumbnail, label, date and a full-screen
///   preview on tap.
///
/// This screen owns its own [LidarMapBuilder] so the captured data is
/// independent of whatever the Control Room is doing.
class LidarFieldMappingScreen extends StatefulWidget {
  const LidarFieldMappingScreen({super.key});

  @override
  State<LidarFieldMappingScreen> createState() =>
      _LidarFieldMappingScreenState();
}

class _LidarFieldMappingScreenState extends State<LidarFieldMappingScreen>
    with SingleTickerProviderStateMixin {
  final RobotApiService _api = RobotApiService();
  RobotService? _robot;
  RobotDescriptor? _descriptor;
  StreamSubscription<RobotConnectionState>? _connSub;
  late final LidarMapBuilder _builder;
  late final TabController _tabs;

  String? _error;
  bool _busy = false;
  bool _saving = false;
  bool _showRadar = false;
  List<List<double>>? _perimeter;

  // Saved-maps tab state.
  Future<List<RobotMapMetadata>>? _savedMapsFuture;

  @override
  void initState() {
    super.initState();
    _builder = LidarMapBuilder();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _bootstrap();
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging && _tabs.index == 1) {
      _refreshSavedMaps();
    }
  }

  Future<void> _bootstrap() async {
    try {
      final robots = await _api.listRobots();
      if (robots.isEmpty) {
        setState(() => _error = 'No robots registered.');
        return;
      }
      final desc = robots.first;
      final svc = RobotService(
        robotIp: desc.ip,
        rosbridgePort: desc.rosbridgePort,
      );
      _connSub = svc.connectionState.listen((_) {
        if (mounted) setState(() {});
      });
      await svc.connect();
      if (!mounted) {
        await svc.dispose();
        return;
      }
      setState(() {
        _descriptor = desc;
        _robot = svc;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Connect failed: $e');
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _connSub?.cancel();
    _robot?.dispose();
    _api.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Capture actions
  // ---------------------------------------------------------------------------

  Future<void> _capturePerimeter() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final poly = _builder.extractPerimeter();
      if (!mounted) return;
      setState(() => _perimeter = poly);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            poly.isEmpty
                ? 'No perimeter detected yet. Drive around the field first.'
                : 'Captured perimeter: ${poly.length} vertices.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleExplore() async {
    final ctrl = RobotVoiceController.instance;
    if (ctrl.isExploring) {
      await ctrl.stopExplore();
    } else {
      await ctrl.startExplore();
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveMapToBackend() async {
    final desc = _descriptor;
    if (desc == null || _saving) return;
    if (_builder.updateCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drive around first to build a map.')),
      );
      return;
    }
    final label = await _promptForLabel();
    if (label == null) return; // user cancelled
    setState(() => _saving = true);
    try {
      final pixels = _builder.toGreyscalePixels();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        _builder.cols,
        _builder.rows,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final image = await completer.future;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('Failed to encode map PNG.');
      }
      final pngBytes = byteData.buffer.asUint8List();

      await _api.saveMap(
        robotId: desc.id,
        pngBytes: pngBytes,
        resolutionMeters: _builder.resolutionMeters,
        cols: _builder.cols,
        rows: _builder.rows,
        label: label.isEmpty ? null : label,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map saved to backend.')),
      );
      _refreshSavedMaps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _promptForLabel() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Label this map'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. North field – wheat plot',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmAndReturn() {
    if (_perimeter == null || _perimeter!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture a perimeter first.')),
      );
      return;
    }
    Navigator.of(context).pop(_perimeter);
  }

  // ---------------------------------------------------------------------------
  // Saved maps actions
  // ---------------------------------------------------------------------------

  void _refreshSavedMaps() {
    final desc = _descriptor;
    if (desc == null) return;
    setState(() {
      _savedMapsFuture = _api.listMaps(desc.id);
    });
  }

  Future<void> _openSavedMap(RobotMapMetadata meta) async {
    final desc = _descriptor;
    if (desc == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.of(ctx).size.width,
          child: FutureBuilder<Uint8List>(
            future: _api.fetchMapPng(robotId: desc.id, mapId: meta.id),
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load: ${snap.error}'),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      meta.label ?? meta.id,
                      style: AppTextStyles.h4(
                        color: AppColorPalette.charcoalGreen,
                      ),
                    ),
                  ),
                  Container(
                    color: AppColorPalette.charcoalGreen,
                    constraints: const BoxConstraints(maxHeight: 480),
                    child: InteractiveViewer(
                      maxScale: 6,
                      child: Image.memory(
                        snap.data!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${meta.cols}×${meta.rows} cells · '
                      '${meta.resolution.toStringAsFixed(2)} m/cell · '
                      '${DateFormat.yMMMd().add_Hm().format(meta.createdAt.toLocal())}',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Mapping'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.gps_fixed_rounded), text: 'Capture'),
            Tab(icon: Icon(Icons.collections_bookmark_rounded), text: 'Saved'),
          ],
        ),
        actions: [
          if (_perimeter != null && _perimeter!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Use this perimeter',
              onPressed: _confirmAndReturn,
            ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildCaptureTab(),
            _buildSavedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureTab() {
    final svc = _robot;
    if (svc == null) {
      return Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.alertError,
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final mapPanel = LidarMapPanel(
          scanStream: svc.scanStream,
          telemetryStream: svc.telemetryStream,
          builder: _builder,
          height: double.infinity,
        );

        final radarPanel = LidarRadarPanel(
          scanStream: svc.scanStream,
          lastScan: svc.lastScan,
        );

        // ---- Side-by-side on tablets/landscape -------------------------
        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInstructions(),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: mapPanel),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            radarPanel,
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildActionPanel(svc),
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

        // ---- Stacked layout for phones --------------------------------
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInstructions(),
              const SizedBox(height: 8),
              SizedBox(
                height: constraints.maxHeight * 0.55,
                child: mapPanel,
              ),
              const SizedBox(height: 8),
              _buildActionPanel(svc),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: _showRadar,
                onExpansionChanged: (v) => setState(() => _showRadar = v),
                title: Text(
                  'Show radar',
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.charcoalGreen,
                  ),
                ),
                children: [radarPanel],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Text(
      'Drive (or auto-explore) the robot around the field. When the live '
      'map shows a closed loop, tap "Capture perimeter" or "Save map".',
      style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
    );
  }

  Widget _buildActionPanel(RobotService svc) {
    final exploring = RobotVoiceController.instance.isExploring;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleExplore,
          style: ElevatedButton.styleFrom(
            backgroundColor: exploring
                ? AppColorPalette.warning
                : AppColorPalette.fieldFreshStart,
          ),
          icon: Icon(
            exploring ? Icons.stop_rounded : Icons.explore_rounded,
          ),
          label: Text(exploring ? 'Stop Explore' : 'Auto-Explore'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _capturePerimeter,
          icon: const Icon(Icons.crop_free_rounded),
          label: const Text('Capture perimeter'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveMapToBackend,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_rounded),
          label: const Text('Save map'),
        ),
        OutlinedButton.icon(
          onPressed: () => svc.stop(),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Stop robot'),
        ),
        if (_perimeter != null)
          Chip(
            avatar: const Icon(Icons.check_circle, size: 16),
            label: Text('${_perimeter!.length} vertices'),
            backgroundColor:
                AppColorPalette.success.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _buildSavedTab() {
    final desc = _descriptor;
    if (desc == null) {
      return Center(
        child: _error != null
            ? Text(
                _error!,
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.alertError,
                ),
              )
            : const CircularProgressIndicator(),
      );
    }

    _savedMapsFuture ??= _api.listMaps(desc.id);

    return RefreshIndicator(
      onRefresh: () async => _refreshSavedMaps(),
      child: FutureBuilder<List<RobotMapMetadata>>(
        future: _savedMapsFuture,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load maps: ${snap.error}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(
                      color: AppColorPalette.alertError,
                    ),
                  ),
                ),
              ],
            );
          }
          final items = snap.data ?? const <RobotMapMetadata>[];
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Icon(
                  Icons.map_outlined,
                  size: 56,
                  color: AppColorPalette.softSlate,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No maps saved yet.\nUse the Capture tab and tap "Save map".',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                ),
              ],
            );
          }
          return LayoutBuilder(
            builder: (_, c) {
              final crossAxisCount = c.maxWidth >= 900
                  ? 4
                  : c.maxWidth >= 600
                      ? 3
                      : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _SavedMapCard(
                  meta: items[i],
                  api: _api,
                  onTap: () => _openSavedMap(items[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedMapCard extends StatelessWidget {
  const _SavedMapCard({
    required this.meta,
    required this.api,
    required this.onTap,
  });

  final RobotMapMetadata meta;
  final RobotApiService api;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: AppColorPalette.charcoalGreen,
                child: FutureBuilder<Uint8List>(
                  future: api.fetchMapPng(
                    robotId: meta.robotId,
                    mapId: meta.id,
                  ),
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (snap.hasError || snap.data == null) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      );
                    }
                    return Image.memory(
                      snap.data!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label?.isNotEmpty == true ? meta.label! : meta.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(
                      color: AppColorPalette.charcoalGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.yMMMd()
                        .add_Hm()
                        .format(meta.createdAt.toLocal()),
                    style: AppTextStyles.caption(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
