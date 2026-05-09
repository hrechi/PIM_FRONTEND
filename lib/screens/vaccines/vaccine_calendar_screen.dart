import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/vaccine_provider.dart';
import '../../models/vaccine_models.dart';
import '../../utils/constants.dart';

class VaccineCalendarScreen extends StatefulWidget {
  const VaccineCalendarScreen({super.key});

  @override
  State<VaccineCalendarScreen> createState() => _VaccineCalendarScreenState();
}

class _VaccineCalendarScreenState extends State<VaccineCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaccineProvider>().loadGlobalSchedules();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  List<VaccineSchedule> _getEventsForDay(DateTime day, List<VaccineSchedule> allSchedules) {
    return allSchedules.where((s) => _isSameDay(s.scheduledDate, day)).toList();
  }

  // Returns all days visible in the calendar grid (leading/trailing + current month)
  List<DateTime?> _buildCalendarDays() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = (firstOfMonth.weekday % 7); // Sun first

    final List<DateTime?> days = [];
    // Leading nulls for previous month layout
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    // Current month days
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    // Trailing to fill last row
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  void _onMonthChanged(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      // Auto-select the same day in the new month if possible, else the 1st
      int day = _selectedDay.day;
      final lastDayOfNewMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
      if (day > lastDayOfNewMonth) day = lastDayOfNewMonth;
      _selectedDay = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use context.watch to make the whole UI react to provider data changes
    final allSchedules = context.watch<VaccineProvider>().allSchedules;
    
    final monthLabel = DateFormat('MMMM yyyy', 'en_US').format(_focusedMonth);
    final dayLabel = DateFormat('EEEE d MMMM', 'en_US').format(_selectedDay);
    final events = _getEventsForDay(_selectedDay, allSchedules);
    final calDays = _buildCalendarDays();

    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mistBlue,
        elevation: 6,
        onPressed: () {},
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(monthLabel),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarGrid(calDays, allSchedules),
                    const SizedBox(height: 20),
                    _buildDaySummary(dayLabel, events),
                    const SizedBox(height: 12),
                    if (events.isEmpty)
                      _buildEmpty()
                    else
                      ...events.map((s) => _VaccineEventCard(schedule: s, contextDay: _selectedDay)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String monthLabel) {
    return Container(
      color: AppColors.sageTint,
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF475569)),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Vaccine Calendar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF141E15)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 24, color: Color(0xFF475569)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.mistBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _onMonthChanged(-1),
                  child: Icon(Icons.chevron_left_rounded, color: AppColors.mistBlue, size: 26),
                ),
                Text(
                  monthLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.mistBlue),
                ),
                GestureDetector(
                  onTap: () => _onMonthChanged(1),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.mistBlue, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  Widget _buildCalendarGrid(List<DateTime?> days, List<VaccineSchedule> allSchedules) {
    return Column(
      children: [
        Row(
          children: _weekdayLabels.map((label) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
              ),
            ),
          )).toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.9,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            if (day == null) return const SizedBox.shrink();
            return _buildDayCell(day, allSchedules);
          },
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, List<VaccineSchedule> allSchedules) {
    final isSelected = _isSameDay(day, _selectedDay);
    final isToday = _isToday(day);
    final isCurrentMonth = day.month == _focusedMonth.month;
    final events = _getEventsForDay(day, allSchedules);
    final hasUrgent = events.any((e) => e.isMandatory && (e.isOverdue || e.isUrgent));
    final hasEvents = events.isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedDay = day;
        if (day.month != _focusedMonth.month) {
          _focusedMonth = DateTime(day.year, day.month);
        }
      }),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mistBlue : (isToday ? AppColors.mistBlue.withValues(alpha: 0.12) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.mistBlue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : (isCurrentMonth ? (isToday ? AppColors.mistBlue : const Color(0xFF334155)) : const Color(0xFFCBD5E1)),
              ),
            ),
            if (hasEvents) ...[
              const SizedBox(height: 2),
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : (hasUrgent ? const Color(0xFFEF4444) : AppColors.mistBlue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary(String dayLabel, List<VaccineSchedule> events) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dayLabel,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF141E15)),
        ),
        Text(
          '${events.length} task${events.length > 1 ? 's' : ''}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mistBlue),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.event_available_rounded, size: 42, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 16),
            const Text('No vaccines scheduled', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _VaccineEventCard extends StatefulWidget {
  final VaccineSchedule schedule;
  final DateTime contextDay;
  const _VaccineEventCard({required this.schedule, required this.contextDay});

  @override
  State<_VaccineEventCard> createState() => _VaccineEventCardState();
}

class _VaccineEventCardState extends State<_VaccineEventCard> {
  bool _saving = false;

  void _markDone() {
    final _vetCtrl  = TextEditingController();
    final _doseCtrl = TextEditingController(text: '1');
    final _lotCtrl  = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.mistBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.check_circle_rounded, color: AppColors.mistBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Confirm administration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF141E15))),
                        Text(
                          widget.schedule.vaccine?.nameEn ?? widget.schedule.vaccine?.nameFr ?? '',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _vetCtrl,
                  decoration: InputDecoration(
                    labelText: 'Veterinarian name *',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.mistBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mistBlue, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _doseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Dose (ml)',
                    prefixIcon: const Icon(Icons.water_drop_outlined, color: AppColors.mistBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mistBlue, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lotCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lot number (optional)',
                    prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.mistBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mistBlue, width: 2)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mistBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saving ? null : () async {
                      if (_vetCtrl.text.trim().isEmpty) return;
                      setS(() => _saving = true);
                      final ok = await context.read<VaccineProvider>().markDone(
                        widget.schedule.id,
                        widget.schedule.animalId,
                        administeredBy: _vetCtrl.text.trim(),
                        doseGiven: double.tryParse(_doseCtrl.text) ?? 1,
                        lotNumber: _lotCtrl.text.trim().isEmpty ? null : _lotCtrl.text.trim(),
                      );
                      setS(() => _saving = false);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? '✅ Vaccination recorded' : '❌ Error'),
                          backgroundColor: ok ? AppColors.mistBlue : Colors.red,
                        ));
                      }
                    },
                    child: _saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: widget.schedule.scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.mistBlue)),
        child: child!,
      ),
    );
    if (newDate != null && mounted) {
      final ok = await context.read<VaccineProvider>().updateScheduleDate(
        widget.schedule.id, newDate, widget.schedule.animalId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '✅ Date updated' : '❌ Error'),
          backgroundColor: ok ? AppColors.mistBlue : Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaccine = widget.schedule.vaccine;
    final name = (vaccine?.code == 'OTHER' ? widget.schedule.notes : vaccine?.nameFr) ?? 'Vaccin';
    final isDone = widget.schedule.status == 'DONE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? Colors.white.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: isDone ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.mistBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.pets_rounded, color: AppColors.mistBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fix #2 — affiche le nom de l'animal au lieu de l'UUID
                    Expanded(
                      child: Text(
                        (widget.schedule.animal as Map?)?['name']?.toString() ?? 'Animal',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF141E15)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(schedule: widget.schedule, viewDate: widget.contextDay),
                  ],
                ),
                Text(name, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                if (!isDone) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Fix #1 — bouton Done branché
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mistBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _saving ? null : _markDone,
                          child: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Fix #1 — bouton Edit branché
                      GestureDetector(
                        onTap: _editDate,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VaccineSchedule schedule;
  final DateTime viewDate;
  const _StatusBadge({required this.schedule, required this.viewDate});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg, fg;

    if (schedule.status == 'DONE') {
      label = 'COMPLETED'; bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A);
    } else if (schedule.isOverdue) {
      label = 'OVERDUE'; bg = const Color(0xFFFEF2F2); fg = const Color(0xFFEF4444);
    } else {
      label = 'SCHEDULED'; bg = const Color(0xFFEFF6FF); fg = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
