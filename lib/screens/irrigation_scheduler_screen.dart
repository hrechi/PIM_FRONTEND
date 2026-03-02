import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../models/irrigation_schedule.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';

/// Full-screen Smart Irrigation Scheduler.
/// Lets the user pick a field, then generates a 7-day AI-powered
/// irrigation plan with daily cards showing irrigate/skip, water
/// amount, best time, duration, and reasoning.
class IrrigationSchedulerScreen extends StatefulWidget {
  const IrrigationSchedulerScreen({super.key});

  @override
  State<IrrigationSchedulerScreen> createState() =>
      _IrrigationSchedulerScreenState();
}

class _IrrigationSchedulerScreenState extends State<IrrigationSchedulerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IrrigationProvider>().loadFields();
    });
  }

  // ── Palette ────────────────────────────────────────────────
  static const _headerStart = Color(0xFF2196F3); // blue
  static const _headerEnd = Color(0xFF00BCD4); // cyan
  static const _irrigateGreen = Color(0xFF4CAF50);
  static const _skipAmber = Color(0xFFFFA726);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      body: Consumer<IrrigationProvider>(
        builder: (context, ip, _) {
          return CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: _headerStart,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Irrigation Scheduler',
                  style: AppTextStyles.h3().copyWith(color: Colors.white),
                ),
              ),

              // ── Field selector ───────────────────────────
              SliverToBoxAdapter(child: _buildFieldSelector(ip)),

              // ── Body states ──────────────────────────────
              if (ip.isLoadingFields)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (ip.fields.isEmpty)
                SliverFillRemaining(child: _buildNoFields())
              else ...[
                // ── Generate button ────────────────────────
                SliverToBoxAdapter(child: _buildGenerateButton(ip)),

                // ── Loading / error / schedule ─────────────
                if (ip.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating your plan…',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  )
                else if (ip.error != null)
                  SliverToBoxAdapter(child: _buildError(ip.error!))
                else if (ip.schedule != null) ...[
                  SliverToBoxAdapter(
                      child: _buildWeeklyOverview(ip.schedule!)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) =>
                          _buildDayCard(ip.schedule!.schedule[i], i),
                      childCount: ip.schedule!.schedule.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ] else
                  SliverFillRemaining(child: _buildPlaceholder()),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FIELD SELECTOR
  // ─────────────────────────────────────────────────────────
  Widget _buildFieldSelector(IrrigationProvider ip) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_headerStart, _headerEnd]),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: ip.selectedFieldId,
            isExpanded: true,
            dropdownColor: _headerStart,
            icon: const Icon(Icons.expand_more, color: Colors.white),
            hint: Text('Select a field',
                style: AppTextStyles.bodyMedium()
                    .copyWith(color: Colors.white70)),
            items: ip.fields.map((f) {
              return DropdownMenuItem(
                value: f.id,
                child: Text(
                  '${f.name}${f.cropType != null ? " — ${f.cropType}" : ""}',
                  style: AppTextStyles.bodyMedium()
                      .copyWith(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) ip.selectField(id);
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // GENERATE BUTTON
  // ─────────────────────────────────────────────────────────
  Widget _buildGenerateButton(IrrigationProvider ip) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: ip.isLoading || ip.selectedFieldId == null
              ? null
              : () => ip.generateSchedule(ip.selectedFieldId!),
          style: ElevatedButton.styleFrom(
            backgroundColor: _headerStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.water_drop),
          label: Text(
            ip.schedule != null
                ? 'Regenerate Schedule'
                : 'Generate Irrigation Schedule',
            style: AppTextStyles.buttonLarge().copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // WEEKLY OVERVIEW CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildWeeklyOverview(IrrigationScheduleResponse schedule) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_headerStart, _headerEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _headerStart.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text('Weekly Overview',
                    style:
                        AppTextStyles.h4().copyWith(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),

            // Overview text
            Text(
              schedule.weeklyOverview,
              style: AppTextStyles.bodyMedium()
                  .copyWith(color: Colors.white.withOpacity(0.95)),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _overviewChip(Icons.opacity, '${schedule.totalWaterLiters.round()} L total'),
                const SizedBox(width: 12),
                _overviewChip(Icons.check_circle_outline,
                    '${schedule.irrigationDays} irrigate'),
                const SizedBox(width: 12),
                _overviewChip(Icons.pause_circle_outline,
                    '${schedule.restDays} rest'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTextStyles.caption().copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DAY CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildDayCard(DailyIrrigationPlan day, int index) {
    final irrigate = day.shouldIrrigate;
    final badgeColor = irrigate ? _irrigateGreen : _skipAmber;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: badgeColor.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(bottom: 16),
            leading: _dayLeadingIcon(irrigate),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: day label + badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day.dayLabel,
                        style: AppTextStyles.bodyLarge()
                            .copyWith(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        irrigate ? 'Irrigate' : 'Skip',
                        style: AppTextStyles.caption().copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Date
                Text(day.shortDate,
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColorPalette.softSlate)),
                const SizedBox(height: 4),
                // Weather summary — full width, wraps naturally
                Text(
                  day.weatherSummary,
                  style: AppTextStyles.bodySmall()
                      .copyWith(color: AppColorPalette.softSlate),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            // Expanded content
            children: [
              if (irrigate) ...[
                const Divider(),
                _detailRow(Icons.opacity, 'Water',
                    '${day.waterAmountLiters.round()} liters'),
                _detailRow(Icons.access_time, 'Best time',
                    day.bestTimeOfDay),
                _detailRow(Icons.timer_outlined, 'Duration',
                    '${day.durationMinutes} min'),
              ],
              const Divider(),
              _detailRow(Icons.lightbulb_outline, 'Reasoning',
                  day.reasoning),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayLeadingIcon(bool irrigate) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: (irrigate ? _irrigateGreen : _skipAmber).withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        irrigate ? Icons.water_drop : Icons.wb_sunny,
        color: irrigate ? _irrigateGreen : _skipAmber,
        size: 22,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColorPalette.softSlate),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label,
                style: AppTextStyles.caption()
                    .copyWith(color: AppColorPalette.softSlate)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodySmall()),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY / ERROR STATES
  // ─────────────────────────────────────────────────────────
  Widget _buildNoFields() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.landscape_outlined,
                size: 64, color: AppColorPalette.softSlate),
            const SizedBox(height: 16),
            Text('No fields found',
                style: AppTextStyles.h4()
                    .copyWith(color: AppColorPalette.charcoalGreen)),
            const SizedBox(height: 8),
            Text('Add a field first to generate an irrigation schedule.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium()
                    .copyWith(color: AppColorPalette.softSlate)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_outlined,
                size: 64, color: _headerStart.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Ready to plan',
                style: AppTextStyles.h4()
                    .copyWith(color: AppColorPalette.charcoalGreen)),
            const SizedBox(height: 8),
            Text(
              'Select a field and tap "Generate Irrigation Schedule" to get your AI-powered 7-day plan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium()
                  .copyWith(color: AppColorPalette.softSlate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error,
                  style: AppTextStyles.bodySmall()
                      .copyWith(color: Colors.red.shade700)),
            ),
          ],
        ),
      ),
    );
  }
}
