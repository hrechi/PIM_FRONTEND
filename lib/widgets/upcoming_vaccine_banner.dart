import 'package:flutter/material.dart';
import '../models/vaccine_models.dart';

/// Orange/red banner displayed at the top of animal dashboard
/// showing urgent or overdue mandatory vaccines.
class UpcomingVaccineBanner extends StatelessWidget {
  final List<VaccineSchedule> schedules;
  final VoidCallback? onTap;

  const UpcomingVaccineBanner({
    super.key,
    required this.schedules,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = schedules.where((s) => s.isOverdue && s.isMandatory).toList();
    final urgent = schedules.where((s) => s.isUrgent && s.isMandatory).toList();
    final total = overdue.length + urgent.length;

    if (total == 0) return const SizedBox.shrink();

    final isRed = overdue.isNotEmpty;
    final gradStart = isRed ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final gradEnd   = isRed ? const Color(0xFFB91C1C) : const Color(0xFFD97706);

    String title;
    String subtitle;
    if (overdue.isNotEmpty && urgent.isNotEmpty) {
      title = '${overdue.length} en retard • ${urgent.length} urgent(s)';
      subtitle = 'Vaccination(s) obligatoire(s) nécessitent votre attention';
    } else if (overdue.isNotEmpty) {
      title = '${overdue.length} vaccination(s) en retard !';
      subtitle = overdue.first.vaccine?.nameFr ?? 'Vaccin obligatoire';
    } else {
      title = '${urgent.length} vaccination(s) dans 7 jours';
      subtitle = urgent.first.vaccine?.nameFr ?? 'Vaccin obligatoire';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [gradStart, gradEnd]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradStart.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRed ? Icons.warning_rounded : Icons.access_time_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
