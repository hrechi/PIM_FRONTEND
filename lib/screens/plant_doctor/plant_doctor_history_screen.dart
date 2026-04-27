import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/plant_doctor_history_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import 'plant_doctor_result_screen.dart';

/// Lists every plant doctor analysis the user has run. Accessed from the
/// AppBar of [PlantDoctorScreen].
class PlantDoctorHistoryScreen extends StatefulWidget {
  const PlantDoctorHistoryScreen({super.key});

  @override
  State<PlantDoctorHistoryScreen> createState() =>
      _PlantDoctorHistoryScreenState();
}

class _PlantDoctorHistoryScreenState extends State<PlantDoctorHistoryScreen> {
  final PlantDoctorHistoryService _service = PlantDoctorHistoryService();
  late Future<List<PlantDoctorRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadAll();
  }

  void _reload() {
    setState(() => _future = _service.loadAll());
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
            'All saved plant doctor diagnoses will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorPalette.alertError,
            ),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.clear();
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: const Text(
          'Diagnosis History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColorPalette.emeraldGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: FutureBuilder<List<PlantDoctorRecord>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColorPalette.emeraldGreen,
              ),
            );
          }
          final items = snap.data ?? const <PlantDoctorRecord>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 80,
                      color: AppColorPalette.softSlate,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No diagnoses yet',
                      style: AppTextStyles.h3()
                          .copyWith(color: AppColorPalette.charcoalGreen),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture a plant photo or video from the Plant Doctor screen and it will be saved here.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(
                          color: AppColorPalette.softSlate),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _HistoryTile(
                record: items[i],
                onTap: () => _openDetail(items[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(PlantDoctorRecord record) async {
    final didDelete = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlantDoctorResultScreen(
          record: record,
          onDelete: () async => _service.delete(record.id),
        ),
      ),
    );
    if (didDelete == true) _reload();
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.onTap});

  final PlantDoctorRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ai = record.aiResult;
    final ts = record.timestamp.toLocal();
    final dateLabel =
        '${ts.year}-${_2(ts.month)}-${_2(ts.day)}  ${_2(ts.hour)}:${_2(ts.minute)}';
    final file = File(record.imagePath);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: file.existsSync()
                          ? Image.file(file, fit: BoxFit.cover)
                          : Container(
                              color: Colors.black12,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: AppColorPalette.softSlate,
                              ),
                            ),
                    ),
                    if (record.isVideo)
                      const Positioned(
                        right: 4,
                        bottom: 4,
                        child: Icon(
                          Icons.play_circle,
                          color: Colors.white,
                          size: 22,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ai['name']?.toString() ?? 'Unknown Plant',
                      style: AppTextStyles.h3().copyWith(
                        color: AppColorPalette.charcoalGreen,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ai['scientific_name']?.toString() ?? '',
                      style: AppTextStyles.bodySmall(
                              color: AppColorPalette.softSlate)
                          .copyWith(fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _severityColor(ai['severity']?.toString()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (ai['severity'] ?? 'UNKNOWN')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: AppTextStyles.bodySmall(
                                color: AppColorPalette.softSlate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColorPalette.softSlate),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return AppColorPalette.alertError;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppColorPalette.success;
      default:
        return Colors.grey;
    }
  }

  String _2(int n) => n.toString().padLeft(2, '0');
}
