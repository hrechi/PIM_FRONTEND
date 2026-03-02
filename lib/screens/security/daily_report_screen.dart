import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/daily_report.dart';
import '../../services/api_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import 'report_detail_screen.dart'; // same security/ folder

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  late Future<List<DailyReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  Future<List<DailyReport>> _fetchReports() async {
    final response = await ApiService.get('/reports', withAuth: true);
    final List<dynamic> data = response as List;
    return data.map((json) => DailyReport.fromJson(json)).toList();
  }

  void _refresh() {
    setState(() {
      _reportsFuture = _fetchReports();
    });
  }

  // ── Threat level styling ──────────────────────────────────

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

  String _threatEmoji(String level) {
    switch (level) {
      case 'critical':
        return '🔴';
      case 'high':
        return '🟠';
      case 'medium':
        return '🟡';
      case 'low':
      default:
        return '🟢';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) return 'Today';
    if (diff.inHours < 48) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          'Daily Reports',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColorPalette.charcoalGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColorPalette.lightGrey),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<DailyReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColorPalette.alertError,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load reports', style: AppTextStyles.h4()),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: AppTextStyles.bodySmall(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorPalette.fieldFreshMid,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final reports = snapshot.data!;

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: AppColorPalette.softSlate.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: AppTextStyles.h3(color: AppColorPalette.softSlate),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Run the AI report engine to generate\nyour first daily security digest.',
                    style: AppTextStyles.bodySmall(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppColorPalette.fieldFreshMid,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── Latest report (hero card) ──
                _buildHeroCard(reports.first),
                const SizedBox(height: 24),

                // ── History header ──
                if (reports.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('Previous Reports', style: AppTextStyles.h4()),
                  ),
                  // ── History list ──
                  ...reports.skip(1).map((r) => _buildHistoryCard(r)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDetail(DailyReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
    );
  }

  // ── Hero Card (latest report) ─────────────────────────────

  Widget _buildHeroCard(DailyReport report) {
    final threatColor = _threatColor(report.averageThreatLevel);

    return GestureDetector(
      onTap: () => _openDetail(report),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColorPalette.charcoalGreen,
              AppColorPalette.charcoalGreen.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.charcoalGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Report',
                          style: AppTextStyles.h4(color: Colors.white),
                        ),
                        Text(
                          _formatDate(report.createdAt),
                          style: AppTextStyles.caption(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Threat badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: threatColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: threatColor, width: 1.5),
                    ),
                    child: Text(
                      '${_threatEmoji(report.averageThreatLevel)} ${report.averageThreatLevel.toUpperCase()}',
                      style: AppTextStyles.buttonSmall(color: threatColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // AI summary
              Text(
                report.summary,
                style: AppTextStyles.bodyMedium(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _buildHeroStat(
                    report.totalIncidents.toString(),
                    'Incidents',
                    Icons.warning_amber_rounded,
                  ),
                  _buildHeroStat(
                    report.criticalAlerts.toString(),
                    'Critical',
                    Icons.gpp_bad_rounded,
                  ),
                  _buildHeroStat(
                    '${report.peakActivityHour}:00',
                    'Peak Hour',
                    Icons.schedule_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to view full report',
                    style: AppTextStyles.caption(color: Colors.white60),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white60,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h3(color: Colors.white)),
          Text(label, style: AppTextStyles.caption(color: Colors.white60)),
        ],
      ),
    );
  }

  // ── History Card ──────────────────────────────────────────

  Widget _buildHistoryCard(DailyReport report) {
    final threatColor = _threatColor(report.averageThreatLevel);

    return GestureDetector(
      onTap: () => _openDetail(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + threat badge + chevron
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColorPalette.softSlate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(report.createdAt),
                    style: AppTextStyles.label(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: threatColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_threatEmoji(report.averageThreatLevel)} ${report.averageThreatLevel.toUpperCase()}',
                      style: AppTextStyles.caption(color: threatColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColorPalette.softSlate,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Summary (truncated)
              Text(
                report.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall(
                  color: AppColorPalette.charcoalGreen,
                ),
              ),

              const SizedBox(height: 12),

              // Stats chips row
              Row(
                children: [
                  _buildStatChip(
                    Icons.warning_amber_rounded,
                    '${report.totalIncidents} incidents',
                    AppColorPalette.charcoalGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.gpp_bad_rounded,
                    '${report.criticalAlerts} critical',
                    report.criticalAlerts > 0
                        ? AppColorPalette.alertError
                        : AppColorPalette.softSlate,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.schedule_rounded,
                    '${report.peakActivityHour}:00',
                    AppColorPalette.softSlate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption(color: color)),
        ],
      ),
    );
  }
}
