import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/vaccine_provider.dart';
import '../../models/vaccine_models.dart';
import '../../utils/constants.dart';
import '../../widgets/vaccine_status_chip.dart';
import 'vaccine_history_screen.dart';

class VaccinePlanningScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final String animalType;

  const VaccinePlanningScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    required this.animalType,
  });

  @override
  State<VaccinePlanningScreen> createState() => _VaccinePlanningScreenState();
}

class _VaccinePlanningScreenState extends State<VaccinePlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaccineProvider>().loadForAnimal(widget.animalId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    setState(() => _generating = true);
    final ok = await context.read<VaccineProvider>().generatePlan(widget.animalId);
    setState(() => _generating = false);
    if (!mounted) return;
    final count = context.read<VaccineProvider>().generatedCount;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '✅ $count plan(s) generated' : '❌ Generation error'),
      backgroundColor: ok ? AppColors.mistBlue : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vaccine Planning',
              style: TextStyle(color: Color(0xFF141E15), fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.animalName,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => VaccineHistoryScreen(animalId: widget.animalId, animalName: widget.animalName),
              )),
              tooltip: 'Historique',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.mistBlue,
              indicatorWeight: 3,
              labelColor: AppColors.mistBlue,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'MANDATORY'),
                Tab(text: 'RECOMMENDED'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mistBlue,
        elevation: 4,
        onPressed: _generating ? null : _generatePlan,
        icon: _generating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: Text(
          _generating ? 'Generating...' : 'Generate planning',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
        ),
      ),
      body: Consumer<VaccineProvider>(
        builder: (_, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.mistBlue));
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _ScheduleList(
                schedules: prov.mandatorySchedules,
                animalId: widget.animalId,
                emptyMessage: 'No mandatory vaccines scheduled',
              ),
              _ScheduleList(
                schedules: prov.recommendedSchedules,
                animalId: widget.animalId,
                emptyMessage: 'No recommended vaccines scheduled',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Schedule list ────────────────────────────────────────────────────────────
class _ScheduleList extends StatelessWidget {
  final List<VaccineSchedule> schedules;
  final String animalId;
  final String emptyMessage;

  const _ScheduleList({required this.schedules, required this.animalId, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16)],
              ),
              child: const Icon(Icons.vaccines_outlined, size: 48, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 20),
            Text(emptyMessage, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap "Generate planning"', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: schedules.length,
      itemBuilder: (_, i) => _ScheduleCard(schedule: schedules[i], animalId: animalId),
    );
  }
}

// ─── Schedule card ────────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final VaccineSchedule schedule;
  final String animalId;

  const _ScheduleCard({required this.schedule, required this.animalId});

  @override
  Widget build(BuildContext context) {
    final vaccine = schedule.vaccine;
    final daysLeft = schedule.daysUntil;
    final fmt = DateFormat('dd MMM yyyy', 'en_US');

    Color accentColor;
    if (schedule.isMandatory) {
      accentColor = (schedule.isOverdue || daysLeft <= 7)
          ? const Color(0xFFEF4444)
          : const Color(0xFFF59E0B);
    } else {
      accentColor = AppColors.mistBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.vaccines_rounded, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (vaccine?.code == 'OTHER' ? schedule.notes : vaccine?.nameEn) ?? schedule.notes ?? 'Vaccin',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF141E15)),
                          ),
                          if (vaccine?.nameFr != null && vaccine?.nameFr != vaccine?.nameEn)
                            Text(
                              vaccine!.nameEn,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                    if (schedule.isPending)
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: IconButton(
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () => _editDate(context),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          tooltip: 'Edit date',
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    VaccineStatusChip(status: schedule.status, small: true),
                    const Spacer(),
                    Icon(Icons.calendar_today_rounded, size: 12, color: const Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      fmt.format(schedule.scheduledDate),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                if (!schedule.isDone) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: schedule.isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: schedule.isOverdue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          schedule.isOverdue ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                          size: 14,
                          color: schedule.isOverdue ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          schedule.isOverdue
                              ? 'Overdue by ${-daysLeft} day(s)'
                              : daysLeft == 0
                                  ? 'Due today'
                                  : 'In $daysLeft day(s)',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: schedule.isOverdue ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (schedule.isPending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mistBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Confirm administration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      onPressed: () => _markDone(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editDate(BuildContext context) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: schedule.scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.mistBlue),
        ),
        child: child!,
      ),
    );
    if (newDate != null && context.mounted) {
      final ok = await context.read<VaccineProvider>().updateScheduleDate(schedule.id, newDate, animalId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '✅ Date updated' : '❌ Error'),
          backgroundColor: ok ? AppColors.mistBlue : Colors.red,
        ));
      }
    }
  }

  void _markDone(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkDoneSheet(schedule: schedule, animalId: animalId),
    );
  }
}

// ─── Mark done sheet ──────────────────────────────────────────────────────────
class _MarkDoneSheet extends StatefulWidget {
  final VaccineSchedule schedule;
  final String animalId;
  const _MarkDoneSheet({required this.schedule, required this.animalId});

  @override
  State<_MarkDoneSheet> createState() => _MarkDoneSheetState();
}

class _MarkDoneSheetState extends State<_MarkDoneSheet> {
  final _vetCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '1');
  final _lotCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _vetCtrl.dispose(); _doseCtrl.dispose(); _lotCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vetCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final ok = await context.read<VaccineProvider>().markDone(
      widget.schedule.id, widget.animalId,
      administeredBy: _vetCtrl.text.trim(),
      doseGiven: double.tryParse(_doseCtrl.text) ?? 1,
      lotNumber: _lotCtrl.text.trim().isEmpty ? null : _lotCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Vaccination recorded' : '❌ Error'),
        backgroundColor: ok ? AppColors.mistBlue : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      widget.schedule.vaccine?.nameEn ?? '',
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _field('Veterinarian name *', _vetCtrl, Icons.person_outline),
            const SizedBox(height: 16),
            _field('Administered dose (ml)', _doseCtrl, Icons.water_drop_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _field('Lot number (optional)', _lotCtrl, Icons.tag_rounded),
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
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.mistBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.mistBlue, width: 2),
      ),
    ),
  );
}
