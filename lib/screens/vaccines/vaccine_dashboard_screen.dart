import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';
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

  // --- Search & Tabs ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _activeTabIndex = 0; // 0: All, 1: Vaccinated, 2: Pending

  // --- Filter State ---
  String? _filterType;
  String? _filterSex;
  String? _filterStatus;

  List<Animal> get _filteredAnimals {
    return _animals.where((a) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final name = a.name.toLowerCase();
        final tag = a.nodeId.toLowerCase();
        if (!name.contains(_searchQuery) && !tag.contains(_searchQuery)) return false;
      }

      // 2. Status Tab
      if (_activeTabIndex == 1 && !a.vaccination) return false;
      if (_activeTabIndex == 2 && a.vaccination) return false;

      // 3. Species & Gender Filters
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
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _selectAll() => setState(() => _selectedAnimalIds.addAll(_filteredAnimals.map((a) => a.id)));
  void _clearAll() => setState(() => _selectedAnimalIds.clear());
  bool get _allSelected => _filteredAnimals.isNotEmpty && _filteredAnimals.every((a) => _selectedAnimalIds.contains(a.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      drawer: const AppDrawer(),
      floatingActionButton: _selectedAnimalIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkMarkDone,
              elevation: 6,
              backgroundColor: AppColors.mistBlue,
              icon: const Icon(Icons.vaccines_rounded, color: Colors.white),
              label: Text(
                'Vaccinate ${_selectedAnimalIds.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search & Header ──
            if (!_loading) _buildModernHeader(),

            // ── Status Tabs ──
            if (!_loading && !_selectionMode) _buildStatusTabs(),

            const SizedBox(height: 12),

            // ── Section title ──
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Row(
                  children: [
                    Text(
                      _selectionMode ? 'MULTIPLE SELECTION' : 'QUICK FILTERS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF141E15).withValues(alpha: 0.4),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (!_selectionMode)
                      _buildStatsMiniCount(),
                  ],
                ),
              ),

            // ── Filters ──
            if (!_loading) _buildFilters(),

            // ── Animals list ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.mistBlue))
                  : _filteredAnimals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_rounded, size: 56, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text('No matching animals', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
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

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildCircleIconButton(Icons.menu_rounded, onPressed: () => Scaffold.of(context).openDrawer()),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Health & Vaccines',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                ),
              ),
              _buildCircleIconButton(
                _selectionMode ? Icons.close_rounded : Icons.checklist_rtl_rounded,
                active: _selectionMode,
                onPressed: () => setState(() {
                  _selectionMode = !_selectionMode;
                  if (!_selectionMode) _selectedAnimalIds.clear();
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // --- Search Bar ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search animals by name or tag...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mistBlue, size: 20),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFFCBD5E1)),
                      onPressed: () => _searchController.clear(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 18),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccineCalendarScreen())),
                    ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, {VoidCallback? onPressed, bool active = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? AppColors.mistBlue : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: active ? Colors.white : const Color(0xFF64748B), size: 22),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'All', Icons.grid_view_rounded),
            _buildTabItem(1, 'Vaccinated', Icons.check_circle_rounded),
            _buildTabItem(2, 'Pending', Icons.pending_actions_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isActive ? AppColors.mistBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsMiniCount() {
    final vaccinated = _animals.where((a) => a.vaccination).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$vaccinated/${_animals.length} Proteced',
        style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFilters() {
    final types = ['cow', 'horse', 'sheep', 'dog'];
    final typeLabels = {'cow': 'Cows', 'horse': 'Horses', 'sheep': 'Sheep', 'dog': 'Dogs'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterChip('All Species', _filterType == null, () => setState(() => _filterType = null), icon: Icons.grid_view_rounded),
              const SizedBox(width: 10),
              ...types.map((t) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildFilterChip(typeLabels[t]!, _filterType == t, () => setState(() => _filterType = _filterType == t ? null : t), icon: AnimalUtils.getAnimalIcon(t)),
              )),
              const VerticalDivider(width: 20, indent: 10, endIndent: 10, color: Color(0xFFE2E8F0)),
              _buildFilterChip('Male', _filterSex == 'male', () => setState(() => _filterSex = _filterSex == 'male' ? null : 'male'), icon: Icons.male_rounded),
              const SizedBox(width: 10),
              _buildFilterChip('Female', _filterSex == 'female', () => setState(() => _filterSex = _filterSex == 'female' ? null : 'female'), icon: Icons.female_rounded),
            ],
          ),
        ),
        if (_selectionMode) ...[
          const SizedBox(height: 16),
          _buildSelectionStatusCard(),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSelectionStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.mistBlue, AppColors.mistBlue.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.mistBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _allSelected ? 'ALL SELECTED' : '${_selectedAnimalIds.length} SELECTED',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                Text(
                  'Marking as vaccinated in bulk',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _allSelected ? _clearAll : _selectAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _allSelected ? 'Deselect' : 'Select All',
                  style: TextStyle(color: AppColors.mistBlue, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, VoidCallback onTap, {IconData? icon, Color? activeColor}) {
    final color = activeColor ?? AppColors.mistBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : const Color(0xFFCBD5E1).withValues(alpha: 0.3), width: 1),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isActive ? Colors.white : color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF64748B), 
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, 
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat card ───────────────────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.8)),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.3)),
        ],
      ),
    ),
  );
}

// ─── Animal vaccine row ─────────────────────────────────────────────────────
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
    return AnimalUtils.getAnimalIcon(animal.animalType);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onSelect(),
      onTap: selectionMode
          ? onSelect
          : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => VaccinePlanningScreen(
                  animalId: animal.id,
                  animalName: animal.name,
                  animalType: animal.animalType,
                ),
              )),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mistBlue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: AppColors.mistBlue, width: 2)
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.mistBlue.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          if (selectionMode) ...[
            Container(
              margin: const EdgeInsets.only(right: 14),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mistBlue : Colors.transparent,
                border: Border.all(color: isSelected ? AppColors.mistBlue : const Color(0xFFCBD5E1), width: 2),
                shape: BoxShape.circle,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mistBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_icon, color: AppColors.mistBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF141E15), letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        animal.animalType.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        animal.breed ?? 'Unknown breed',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                      animal.vaccination ? 'UP TO DATE' : 'CARE REQ.',
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
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
          ],
        ]),
      ),
    );
  }
}

// ─── Bulk mark done sheet ────────────────────────────────────────────────────
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
      final res = await context.read<VaccineProvider>().loadVaccines();
      setState(() { 
        _availableVaccines = res.map((v) => {'code': v.code, 'nameEn': v.nameEn ?? v.nameFr}).toList(); 
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
      if (ok) { widget.onDone(); Navigator.pop(context); }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Bulk vaccination recorded' : '❌ Error'),
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
                  child: Icon(Icons.vaccines_rounded, color: AppColors.mistBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bulk vaccination', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF141E15))),
                    Text('${widget.animalIds.length} animals selected', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _loadingVaccines
                ? const Center(child: CircularProgressIndicator(color: AppColors.mistBlue))
                : DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Select a vaccine', Icons.vaccines_rounded),
                    items: _availableVaccines.map<DropdownMenuItem<String>>((v) => DropdownMenuItem(
                      value: v['code'],
                      child: Text(v['nameEn'] ?? v['code'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedVaccineCode = v),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
            const SizedBox(height: 16),
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
                    : const Text('Confirm vaccination', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.mistBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.mistBlue, width: 2)),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: _inputDecoration(label, icon),
  );
}
