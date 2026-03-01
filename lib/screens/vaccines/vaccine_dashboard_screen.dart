import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/vaccine_provider.dart';
import '../../models/vaccine_models.dart';
import '../../utils/constants.dart';
import '../../widgets/vaccine_status_chip.dart';
import '../../widgets/upcoming_vaccine_banner.dart';
import '../../services/animal_service.dart';
import '../../models/animal.dart';
import 'vaccine_planning_screen.dart';

class VaccineDashboardScreen extends StatefulWidget {
  const VaccineDashboardScreen({super.key});

  @override
  State<VaccineDashboardScreen> createState() => _VaccineDashboardScreenState();
}

class _VaccineDashboardScreenState extends State<VaccineDashboardScreen> {
  final _animalService = AnimalService();
  List<Animal> _animals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final animals = await _animalService.getAnimals();
      setState(() { _animals = animals; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppColors.fieldFreshStart.withValues(alpha: 0.08), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Dashboard Vaccinal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    Text('${_animals.length} animaux dans votre troupeau', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ]),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Stats row ──
              if (!_loading) _buildStatsRow(),

              const SizedBox(height: 16),

              // ── Animals list ──
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.mistBlue))
                    : _animals.isEmpty
                        ? const Center(child: Text('Aucun animal', style: TextStyle(color: Color(0xFF64748B))))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _animals.length,
                            itemBuilder: (_, i) => _AnimalVaccineRow(animal: _animals[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _animals.length;
    final vaccinated = _animals.where((a) => a.vaccination).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        _StatCard(label: 'Animaux', value: '$total', icon: Icons.pets_rounded, color: AppColors.mistBlue),
        const SizedBox(width: 12),
        _StatCard(label: 'Vaccinés', value: '$vaccinated', icon: Icons.vaccines_rounded, color: const Color(0xFF22C55E)),
        const SizedBox(width: 12),
        _StatCard(label: 'À vacciner', value: '${total - vaccinated}', icon: Icons.warning_rounded, color: const Color(0xFFF59E0B)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ]),
    ),
  );
}

class _AnimalVaccineRow extends StatelessWidget {
  final Animal animal;
  const _AnimalVaccineRow({required this.animal});

  IconData get _icon {
    switch (animal.animalType.toLowerCase()) {
      case 'cow': return Icons.set_meal_rounded;
      case 'sheep': return Icons.cloud_rounded;
      case 'horse': return Icons.directions_run_rounded;
      case 'dog': return Icons.pets_rounded;
      default: return Icons.cruelty_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => VaccinePlanningScreen(
          animalId: animal.id,
          animalName: animal.name,
          animalType: animal.animalType,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.mistBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: AppColors.mistBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(animal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
              Text('${animal.animalType.toUpperCase()} • ${animal.breed ?? ""}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: animal.vaccination ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              animal.vaccination ? '✅ Vacciné' : '⏰ À placer',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: animal.vaccination ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        ]),
      ),
    );
  }
}
