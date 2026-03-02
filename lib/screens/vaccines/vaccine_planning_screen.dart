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
          ? '✅ $count plannings générés depuis le pays de la ferme'
          : '❌ Erreur lors de la génération'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Planning Vaccinal', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
            Text(widget.animalName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => VaccineHistoryScreen(animalId: widget.animalId, animalName: widget.animalName),
            )),
            tooltip: 'Historique',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.mistBlue,
          labelColor: AppColors.mistBlue,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'OBLIGATOIRE'),
            Tab(text: 'RECOMMANDÉ'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mistBlue,
        onPressed: _generating ? null : _generatePlan,
        icon: _generating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(_generating ? 'Génération...' : 'Générer le planning'),
      ),
      body: Consumer<VaccineProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.mistBlue));
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _ScheduleList(
                schedules: prov.mandatorySchedules,
                animalId: widget.animalId,
                emptyMessage: 'Aucun vaccin obligatoire planifié',
              ),
              _ScheduleList(
                schedules: prov.recommendedSchedules,
                animalId: widget.animalId,
                emptyMessage: 'Aucun vaccin recommandé planifié',
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
            const Text('Appuyez sur "Générer le planning" pour démarrer', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
    final fmt = DateFormat('dd MMM yyyy', 'fr_FR');

    Color leftBorder;
    if (schedule.isOverdue) leftBorder = const Color(0xFFEF4444);
    else if (schedule.isUrgent) leftBorder = const Color(0xFFF59E0B);
    else leftBorder = AppColors.mistBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: leftBorder, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vaccine?.nameFr ?? 'Vaccin',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                ),
                VaccineStatusChip(status: schedule.status, small: true),
              ],
            ),
            if (vaccine?.nameEn != null)
              Text(vaccine!.nameEn, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                fmt.format(schedule.scheduledDate),
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              if (!schedule.isDone) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: schedule.isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    schedule.isOverdue ? 'Retard: ${-daysLeft}j' : daysLeft == 0 ? "Aujourd'hui" : 'Dans ${daysLeft}j',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: schedule.isOverdue ? const Color(0xFFDC2626) : AppColors.mistBlue,
                    ),
                  ),
                ),
              ],
            ]),
            if (schedule.isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mistBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Marquer comme effectué', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => _markDone(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
        content: Text(ok ? '✅ Vaccination enregistrée' : '❌ Erreur'),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marquer la vaccination', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text(widget.schedule.vaccine?.nameFr ?? '', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            _field('Nom du vétérinaire *', _vetCtrl, Icons.person_outline),
            const SizedBox(height: 12),
            _field('Dose administrée (ml)', _doseCtrl, Icons.water_drop_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('N° de lot (optionnel)', _lotCtrl, Icons.tag_rounded),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mistBlue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
        prefixIcon: Icon(icon, color: AppColors.mistBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mistBlue, width: 2),
        ),
      ),
    );
  }
}
