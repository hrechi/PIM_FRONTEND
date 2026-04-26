import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/plant_doctor_history_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Read-only detail view for one [PlantDoctorRecord]. Shown both right after
/// a fresh capture is analyzed and when the user taps an entry in the
/// history.
class PlantDoctorResultScreen extends StatelessWidget {
  const PlantDoctorResultScreen({
    super.key,
    required this.record,
    this.onDelete,
  });

  final PlantDoctorRecord record;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final ai = record.aiResult;
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          ai['name']?.toString() ?? 'Diagnosis Result',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColorPalette.emeraldGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCover(),
            const SizedBox(height: 16),
            _buildMetaRow(),
            const SizedBox(height: 20),
            _buildHeader(ai),
            const SizedBox(height: 20),
            _sectionTitle('🔍 Diagnosis'),
            _infoCard(
              ai['diagnosis']?.toString() ?? 'No diagnosis available.',
              icon: Icons.biotech,
              color: AppColorPalette.info,
            ),
            const SizedBox(height: 20),
            _sectionTitle('💊 Treatment Plan'),
            _treatmentCard(ai['treatment_steps']),
            const SizedBox(height: 20),
            _sectionTitle('🛡️ Prevention'),
            _infoCard(
              ai['prevention']?.toString() ?? 'Keep monitoring regularly.',
              icon: Icons.shield,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            _sectionTitle('🪴 Description'),
            _infoCard(
              ai['description']?.toString() ?? 'No description available.',
              icon: Icons.local_florist,
              color: AppColorPalette.success,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Sections -----------------------------------------------------------

  Widget _buildCover() {
    final file = File(record.imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    color: Colors.black12,
                    child: const Icon(Icons.image_not_supported, size: 60),
                  ),
          ),
          if (record.isVideo)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Robot video',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final ts = record.timestamp.toLocal();
    final formatted =
        '${ts.year}-${_2(ts.month)}-${_2(ts.day)}  ${_2(ts.hour)}:${_2(ts.minute)}';
    final src = record.source;
    return Row(
      children: [
        const Icon(Icons.schedule, size: 16, color: AppColorPalette.softSlate),
        const SizedBox(width: 6),
        Text(
          formatted,
          style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
        ),
        const Spacer(),
        if (src != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColorPalette.emeraldGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              src.toUpperCase(),
              style: const TextStyle(
                color: AppColorPalette.emeraldGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> ai) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            ai['name']?.toString() ?? 'Unknown Plant',
            style: AppTextStyles.h2()
                .copyWith(color: AppColorPalette.charcoalGreen),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            ai['scientific_name']?.toString() ?? 'Species Unknown',
            style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate)
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _severityColor(ai['severity']?.toString()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SEVERITY: ${(ai['severity'] ?? 'UNKNOWN').toString().toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
        child: Text(
          title,
          style: AppTextStyles.h3()
              .copyWith(color: AppColorPalette.charcoalGreen),
        ),
      );

  Widget _infoCard(
    String content, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style:
                  AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _treatmentCard(dynamic steps) {
    final list = (steps is List) ? steps : const <dynamic>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColorPalette.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: list.isEmpty
            ? const [
                Text('No specific steps provided. Consult an expert.'),
              ]
            : list
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColorPalette.success, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.toString(),
                            style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.charcoalGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  // --- Helpers ------------------------------------------------------------

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

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete diagnosis?'),
        content: const Text(
            'This will remove the saved capture and AI report from your history.'),
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
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok == true && onDelete != null) {
      await onDelete!();
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }
}
