import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../utils/constants.dart';
import '../../services/animal_service.dart';
import '../../models/animal.dart';
import 'vaccine_planning_screen.dart';
import '../../widgets/app_drawer.dart';
import 'vaccine_calendar_screen.dart';



class VaccineDashboardScreen extends StatefulWidget {
  const VaccineDashboardScreen({super.key});

  @override
  State<VaccineDashboardScreen> createState() => _VaccineDashboardScreenState();
}

class _VaccineDashboardScreenState extends State<VaccineDashboardScreen> {
  final _animalService = AnimalService();
  List<Animal> _animals = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<String> _selectedAnimalIds = {};

  // ── Filters ──
  String? _filterType;   // cow, horse, sheep, dog
  String? _filterSex;    // male, female
  String? _filterStatus; // vaccinated, unvaccinated

  List<Animal> get _filteredAnimals {
    return _animals.where((a) {
      if (_filterType != null && a.animalType.toLowerCase() != _filterType) return false;
      if (_filterSex != null && a.sex.toLowerCase() != _filterSex) return false;
      if (_filterStatus == 'vaccinated' && !a.vaccination) return false;
      if (_filterStatus == 'unvaccinated' && a.vaccination) return false;
      return true;
    }).toList();
  }

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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedAnimalIds.contains(id)) {
        _selectedAnimalIds.remove(id);
        if (_selectedAnimalIds.isEmpty) _selectionMode = false;
      } else {
        _selectedAnimalIds.add(id);
        _selectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedAnimalIds.addAll(_filteredAnimals.map((a) => a.id));
    });
  }

  void _clearAll() {
    setState(() {
      _selectedAnimalIds.clear();
    });
  }

  bool get _allSelected => _filteredAnimals.isNotEmpty &&
      _filteredAnimals.every((a) => _selectedAnimalIds.contains(a.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      drawer: const AppDrawer(),
      floatingActionButton: _selectedAnimalIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkMarkDone,
              elevation: 6,
              backgroundColor: const Color(0xFF1B3C35),
              icon: const Icon(Icons.vaccines_rounded, color: Colors.white),
              label: Text('Vaccinate ${_selectedAnimalIds.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [const Color(0xFF1B3C35).withValues(alpha: 0.05), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Vaccination', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B3C35), letterSpacing: -1.0)),
                      Text('${_animals.length} animals total', style: const TextStyle(color: Color(0xFF4A6741), fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B3C35)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccineCalendarScreen())),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(
                      _selectionMode ? Icons.fact_check_rounded : Icons.fact_check_outlined, 
                      color: _selectionMode ? const Color(0xFFD4AF37) : const Color(0xFF1B3C35)
                    ),
                    onPressed: () => setState(() => _selectionMode = !_selectionMode),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(10),
                    ),
                    tooltip: 'Bulk actions',
                  ),
                  if (_selectionMode) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      onPressed: () => setState(() { _selectionMode = false; _selectedAnimalIds.clear(); }),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ]),
              ),

              const SizedBox(height: 20),

              // ── Stats row ──
              if (!_loading && !_selectionMode) _buildStatsRow(),

              if (!_loading) Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF1B3C35)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectionMode ? 'MULTIPLE SELECTION' : 'YOUR HERD', 
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        color: const Color(0xFF1B3C35), 
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (!_selectionMode)
                      GestureDetector(
                        onTap: () => setState(() => _selectionMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B3C35).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.checklist_rounded, size: 14, color: Color(0xFF1B3C35)),
                              const SizedBox(width: 4),
                              const Text('Bulk actions', 
                                style: TextStyle(color: Color(0xFF1B3C35), fontSize: 11, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Filters ──
              if (!_loading)
                _buildFilters(),

              // ── Animals list ──
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.mistBlue))
                    : _filteredAnimals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_alt_off_rounded, size: 48, color: const Color(0xFF1B3C35).withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                const Text('No animals match this filter', style: TextStyle(color: Color(0xFF4A6741), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredAnimals.length,
                            itemBuilder: (_, i) {
                              final animal = _filteredAnimals[i];
                              return _AnimalVaccineRow(
                                animal: animal,
                                isSelected: _selectedAnimalIds.contains(animal.id),
                                selectionMode: _selectionMode,
                                onSelect: () => _toggleSelection(animal.id),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkMarkDone() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BulkMarkDoneSheet(
        animalIds: _selectedAnimalIds.toList(),
        onDone: () {
          setState(() {
            _selectedAnimalIds.clear();
            _selectionMode = false;
          });
          _loadAnimals();
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _animals.length;
    final vaccinated = _animals.where((a) => a.vaccination).length;
    final toVaccinate = total - vaccinated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        _StatCard(label: 'Total', value: total.toString(), icon: Icons.pets_rounded, color: const Color(0xFF1B3C35)),
        const SizedBox(width: 12),
        _StatCard(label: 'Up to date', value: vaccinated.toString(), icon: Icons.check_circle_rounded, color: const Color(0xFF16A34A)),
        const SizedBox(width: 12),
        _StatCard(label: 'To schedule', value: toVaccinate.toString(), icon: Icons.schedule_rounded, color: const Color(0xFFF59E0B)),
      ]),
    );
  }

  Widget _buildFilters() {
    final types = ['cow', 'horse', 'sheep', 'dog'];
    final typeLabels = {'cow': '🐄 Cow', 'horse': '🐎 Horse', 'sheep': '🐑 Sheep', 'dog': '🐶 Dog'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animal type filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterChip('All', _filterType == null, () => setState(() => _filterType = null)),
              const SizedBox(width: 8),
              ...types.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(typeLabels[t]!, _filterType == t, () => setState(() => _filterType = _filterType == t ? null : t)),
              )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Sex + Status filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterChip('♂ Male', _filterSex == 'male', () => setState(() => _filterSex = _filterSex == 'male' ? null : 'male'), icon: Icons.male_rounded),
              const SizedBox(width: 8),
              _buildFilterChip('♀ Female', _filterSex == 'female', () => setState(() => _filterSex = _filterSex == 'female' ? null : 'female'), icon: Icons.female_rounded),
              const SizedBox(width: 16),
              _buildFilterChip('✅ Vaccinated', _filterStatus == 'vaccinated', () => setState(() => _filterStatus = _filterStatus == 'vaccinated' ? null : 'vaccinated'), activeColor: const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _buildFilterChip('⚠️ Unvaccinated', _filterStatus == 'unvaccinated', () => setState(() => _filterStatus = _filterStatus == 'unvaccinated' ? null : 'unvaccinated'), activeColor: const Color(0xFFEF4444)),
            ],
          ),
        ),
        // Select All / None bar (only in selection mode)
        if (_selectionMode) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3C35).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1B3C35).withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(
                    _allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: const Color(0xFF1B3C35),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _allSelected
                        ? '${_filteredAnimals.length} selected'
                        : '${_selectedAnimalIds.length}/${_filteredAnimals.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B3C35), fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _allSelected ? _clearAll : _selectAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3C35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _allSelected ? 'Deselect all' : 'Select all',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isActive,
    VoidCallback onTap, {
    IconData? icon,
    Color? activeColor,
  }) {
    final color = activeColor ?? const Color(0xFF1B3C35);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : const Color(0xFF1B3C35).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: isActive ? [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isActive ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.8)),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4A6741))),
        ],
      ),
    ),
  );
}

class _AnimalVaccineRow extends StatelessWidget {
  final Animal animal;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onSelect;

  const _AnimalVaccineRow({
    required this.animal,
    required this.isSelected,
    required this.selectionMode,
    required this.onSelect,
  });

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
      onLongPress: () => onSelect(),
      onTap: selectionMode ? onSelect : () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => VaccinePlanningScreen(
          animalId: animal.id,
          animalName: animal.name,
          animalType: animal.animalType,
        ),
      )),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3C35).withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: isSelected 
              ? Border.all(color: const Color(0xFFD4AF37), width: 2) 
              : Border.all(color: const Color(0xFF1B3C35).withValues(alpha: 0.05), width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF1B3C35).withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.03), 
              blurRadius: 15, 
              offset: const Offset(0, 6)
            ),
          ],
        ),
        child: Row(children: [
          if (selectionMode) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 16, color: Colors.white) 
                  : null,
            ),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1B3C35).withValues(alpha: 0.15), const Color(0xFF1B3C35).withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_icon, color: const Color(0xFF1B3C35), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal.name, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1B3C35), letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3C35).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(animal.animalType.toUpperCase(), 
                        style: const TextStyle(color: Color(0xFF1B3C35), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 6),
                    Text(animal.breed ?? 'Unknown breed', 
                      style: TextStyle(color: const Color(0xFF1B3C35).withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          if (!selectionMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: animal.vaccination ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: animal.vaccination ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    animal.vaccination ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    size: 14,
                    color: animal.vaccination ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    animal.vaccination ? 'UP TO DATE' : 'IMPORTANT',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900,
                      color: animal.vaccination ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: const Color(0xFF1B3C35).withValues(alpha: 0.3)),
          ],
        ]),
      ),
    );
  }
}

class _BulkMarkDoneSheet extends StatefulWidget {
  final List<String> animalIds;
  final VoidCallback onDone;
  const _BulkMarkDoneSheet({required this.animalIds, required this.onDone});

  @override
  State<_BulkMarkDoneSheet> createState() => _BulkMarkDoneSheetState();
}

class _BulkMarkDoneSheetState extends State<_BulkMarkDoneSheet> {
  final _vetCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '1');
  final _lotCtrl = TextEditingController();
  String? _selectedVaccineCode;
  List<dynamic> _availableVaccines = [];
  bool _loadingVaccines = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadVaccines();
  }

  Future<void> _loadVaccines() async {
    try {
      final res = await context.read<VaccineProvider>().loadVaccines(); // I need to add this method or use existing
      setState(() {
        _availableVaccines = res;
        _loadingVaccines = false;
      });
    } catch (_) {
      setState(() => _loadingVaccines = false);
    }
  }

  @override
  void dispose() {
    _vetCtrl.dispose(); _doseCtrl.dispose(); _lotCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vetCtrl.text.isEmpty || _selectedVaccineCode == null) return;
    setState(() => _saving = true);
    
    final ok = await context.read<VaccineProvider>().bulkMarkDone(
      animalIds: widget.animalIds,
      vaccineCode: _selectedVaccineCode!,
      administeredBy: _vetCtrl.text.trim(),
      administeredAt: DateTime.now(),
      doseGiven: double.tryParse(_doseCtrl.text) ?? 1,
      lotNumber: _lotCtrl.text.trim().isEmpty ? null : _lotCtrl.text.trim(),
    );

    setState(() => _saving = false);
    if (mounted) {
      if (ok) {
        widget.onDone();
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Bulk vaccination successful' : '❌ Error saving records'),
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
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Bulk Vaccination', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text('${widget.animalIds.length} animals selected', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            
            _loadingVaccines 
              ? const Center(child: CircularProgressIndicator(color: AppColors.mistBlue))
              : DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Select vaccine', Icons.vaccines_rounded),
                  items: _availableVaccines.map<DropdownMenuItem<String>>((v) => DropdownMenuItem(
                    value: v['code'],
                    child: Text(v['nameFr'] ?? v['code'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedVaccineCode = v),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                
            const SizedBox(height: 16),
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
                  backgroundColor: AppColors.mistBlue, 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Confirm vaccination', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.mistBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
    );
  }
}
