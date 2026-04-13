import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/daily_report.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

class ReportDetailScreen extends StatelessWidget {
  final DailyReport report;

  const ReportDetailScreen({super.key, required this.report});

  // ── Threat level helpers ────────────────────────────────

  Color _threatColor(String level) {
    switch (level) {
      case 'critical':
        return AppColorPalette.alertError;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
      default:
        return AppColorPalette.fieldFreshMid;
    }
  }

  IconData _threatIcon(String level) {
    switch (level) {
      case 'critical':
        return Icons.gpp_bad_rounded;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      case 'low':
      default:
        return Icons.verified_user_rounded;
    }
  }

  String _threatLabel(String level) {
    switch (level) {
      case 'critical':
        return 'Critical Threat Level';
      case 'high':
        return 'High Threat Level';
      case 'medium':
        return 'Medium Threat Level';
      case 'low':
      default:
        return 'Low Threat Level';
    }
  }

  String _threatDescription(String level) {
    switch (level) {
      case 'critical':
        return 'Immediate attention required. Multiple critical events detected.';
      case 'high':
        return 'Elevated risk. Consider reviewing security measures.';
      case 'medium':
        return 'Moderate activity. Routine monitoring recommended.';
      case 'low':
      default:
        return 'All clear. No significant threats detected.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _threatColor(report.averageThreatLevel);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(report.createdAt);
    final timeStr = DateFormat('hh:mm a').format(report.createdAt);

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          'Report Details',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColorPalette.charcoalGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColorPalette.lightGrey,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date & Time header ──
            _buildDateHeader(dateStr, timeStr),
            const SizedBox(height: 20),

            // ── Threat Level Banner ──
            _buildThreatBanner(tc),
            const SizedBox(height: 20),

            // ── Stats Grid ──
            _buildStatsGrid(tc),
            const SizedBox(height: 20),

            // ── AI Summary ──
            _buildSummaryCard(),
            const SizedBox(height: 20),

            // ── Breakdown ──
            _buildBreakdownCard(tc),
          ],
        ),
      ),
    );
  }

  // ── Date header ──────────────────────────────────────────

  Widget _buildDateHeader(String date, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorPalette.robotTechStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColorPalette.robotTechStart,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen)),
              const SizedBox(height: 2),
              Text(
                'Generated at $time',
                style: AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Threat Banner ────────────────────────────────────────

  Widget _buildThreatBanner(Color tc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_threatIcon(report.averageThreatLevel), color: tc, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _threatLabel(report.averageThreatLevel),
                  style: AppTextStyles.h4(color: tc),
                ),
                const SizedBox(height: 4),
                Text(
                  _threatDescription(report.averageThreatLevel),
                  style: AppTextStyles.bodySmall(color: AppColorPalette.charcoalGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ───────────────────────────────────────────

  Widget _buildStatsGrid(Color tc) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.warning_amber_rounded,
            value: report.totalIncidents.toString(),
            label: 'Total Incidents',
            color: AppColorPalette.charcoalGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.gpp_bad_rounded,
            value: report.criticalAlerts.toString(),
            label: 'Critical Alerts',
            color: report.criticalAlerts > 0
                ? AppColorPalette.alertError
                : AppColorPalette.fieldFreshMid,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.schedule_rounded,
            value: '${report.peakActivityHour}:00',
            label: 'Peak Hour',
            color: AppColorPalette.softSlate,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── AI Summary Card ──────────────────────────────────────

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.robotTechStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColorPalette.robotTechStart,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Summary',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            report.summary,
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.charcoalGreen.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown Card ───────────────────────────────────────

  Widget _buildBreakdownCard(Color tc) {
    final nonCritical = report.totalIncidents - report.criticalAlerts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColorPalette.charcoalGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Incident Breakdown',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Breakdown bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (report.criticalAlerts > 0)
                    Expanded(
                      flex: report.criticalAlerts,
                      child: Container(color: AppColorPalette.alertError),
                    ),
                  if (nonCritical > 0)
                    Expanded(
                      flex: nonCritical,
                      child: Container(color: AppColorPalette.robotTechStart),
                    ),
                  if (report.totalIncidents == 0)
                    Expanded(
                      child: Container(color: AppColorPalette.lightGrey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          _breakdownRow(
            'Critical Incidents',
            report.criticalAlerts.toString(),
            AppColorPalette.alertError,
          ),
          const SizedBox(height: 8),
          _breakdownRow(
            'Non-Critical Incidents',
            nonCritical.toString(),
            AppColorPalette.robotTechStart,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _breakdownRow(
            'Total',
            report.totalIncidents.toString(),
            AppColorPalette.charcoalGreen,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color, {bool bold = false}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: bold
                ? AppTextStyles.label(color: AppColorPalette.charcoalGreen)
                : AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
          ),
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.h4(color: AppColorPalette.charcoalGreen)
              : AppTextStyles.label(color: AppColorPalette.charcoalGreen),
        ),
      ],
    );
  }
}
