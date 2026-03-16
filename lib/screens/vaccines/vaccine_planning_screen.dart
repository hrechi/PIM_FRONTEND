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
      content: Text(ok
          ? '✅ $count schedule(s) generated from farm country'
          : '❌ Error generating plan'),
      backgroundColor: ok ? const Color(0xFF1B3C35) : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vaccine Planning', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
            Text(widget.animalName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => VaccineHistoryScreen(animalId: widget.animalId, animalName: widget.animalName),
            )),
            tooltip: 'History',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF1B3C35),
          labelColor: const Color(0xFF1B3C35),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'MANDATORY'),
            Tab(text: 'RECOMMENDED'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B3C35),
        elevation: 6,
        onPressed: _generating ? null : _generatePlan,
        icon: _generating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: Text(_generating ? 'Generating...' : 'Generate schedule', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
      ),
      body: Consumer<VaccineProvider>(
        builder: (_, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B3C35)));
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

// ─── Schedule list ──────────────────────────────────────────────────────────
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
            const Icon(Icons.vaccines_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Press "Generate schedule" to start', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: schedules.length,
      itemBuilder: (_, i) => _ScheduleCard(schedule: schedules[i], animalId: animalId),
    );
  }
}

// ─── Schedule card ──────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final VaccineSchedule schedule;
  final String animalId;

  const _ScheduleCard({required this.schedule, required this.animalId});

  @override
  Widget build(BuildContext context) {
    final vaccine = schedule.vaccine;
    final daysLeft = schedule.daysUntil;
    final fmt = DateFormat('dd MMM yyyy', 'en_US');

    Color leftBorder;
    if (schedule.isMandatory) {
      if (schedule.isOverdue || (daysLeft <= 7)) {
        leftBorder = const Color(0xFFEF4444); // Urgent/Overdue Mandatory
      } else {
        leftBorder = const Color(0xFFF59E0B); // Future Mandatory
      }
    } else {
      leftBorder = const Color(0xFF1B3C35); // Recommended
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: leftBorder.withOpacity(0.2), width: 1.2),
        boxShadow: [BoxShadow(color: leftBorder.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: leftBorder, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [leftBorder.withOpacity(0.2), leftBorder.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.vaccines_rounded, color: leftBorder, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (vaccine?.code == 'OTHER' ? schedule.notes : vaccine?.nameEn) ?? schedule.notes ?? 'Vaccine',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                          if (vaccine?.nameEn != null)
                            Text(vaccine!.nameEn, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (schedule.isPending)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3C35).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF1B3C35)),
                          onPressed: () => _editDate(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      fmt.format(schedule.scheduledDate),
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (!schedule.isDone) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: schedule.isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: schedule.isOverdue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
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
                          schedule.isOverdue ? 'Overdue by ${-daysLeft} days' : daysLeft == 0 ? 'Scheduled for today' : 'Due in $daysLeft days',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
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
                        backgroundColor: const Color(0xFF1B3C35),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1B3C35)),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null && context.mounted) {
      final ok = await context.read<VaccineProvider>().updateScheduleDate(
        schedule.id, newDate, animalId
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '✅ Date updated' : '❌ Error'),
          backgroundColor: ok ? const Color(0xFF1B3C35) : Colors.red,
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

// ─── Mark done bottom sheet ─────────────────────────────────────────────────
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
    if (_vetCtrl.text.isEmpty) {
      return;
    }
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
        backgroundColor: ok ? const Color(0xFF1B3C35) : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Confirm administration', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(widget.schedule.vaccine?.nameFr ?? '', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            _field('Veterinarian name *', _vetCtrl, Icons.person_outline),
            const SizedBox(height: 16),
            _field('Dose administered (ml)', _doseCtrl, Icons.water_drop_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _field('Lot number (optional)', _lotCtrl, Icons.tag_rounded),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3C35), 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B3C35)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B3C35), width: 2),
        ),
      ),
    );
  }
}
