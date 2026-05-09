import 'package:flutter/material.dart';
import '../../models/animal.dart';
import '../../models/milk_production.dart';
import '../../services/animal_service.dart';
import '../../services/milk_production_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/l10n_extensions.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../utils/animal_utils.dart';
import 'package:intl/intl.dart';
import 'milk_record_success_screen.dart';

class MilkProductionScreen extends StatefulWidget {
  const MilkProductionScreen({super.key});

  @override
  State<MilkProductionScreen> createState() => _MilkProductionScreenState();
}

class _MilkProductionScreenState extends State<MilkProductionScreen> {
  final MilkProductionService _milkService = MilkProductionService();
  final AnimalService _animalService = AnimalService();

  List<MilkProduction> _records = [];
  Map<String, dynamic> _stats = {};
  List<Animal> _cows = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _milkService.getRecords(),
        _milkService.getStatistics(),
        _animalService.getAnimals(animalType: 'cow'),
      ]);
      setState(() {
        _records = results[0] as List<MilkProduction>;
        _stats = results[1] as Map<String, dynamic>;
        _cows = results[2] as List<Animal>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showEntryDialog({MilkProduction? existingRecord}) {
    final l = context.l10n;
    if (_cows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noAnimalsFound)),
      );
      return;
    }

    Animal? selectedCow = existingRecord != null
        ? _cows.firstWhere((c) => c.id == existingRecord.animalId, orElse: () => _cows.first)
        : _cows.first;

    final morningController = TextEditingController(text: existingRecord?.morningL.toString() ?? '');
    final eveningController = TextEditingController(text: existingRecord?.eveningL.toString() ?? '');
    final notesController = TextEditingController(text: existingRecord?.notes ?? '');
    DateTime selectedDate = existingRecord?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existingRecord == null ? l.newMilkRecord : l.editMilkRecord,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    Row(
                      children: [
                        if (existingRecord != null)
                          IconButton(
                            onPressed: () => _confirmDelete(existingRecord, fromBottomSheet: true),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Cow selector
                Text(l.selectCow, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                InkWell(
                  onTap: existingRecord != null ? null : () async {
                    final Animal? picked = await showDialog<Animal>(
                      context: context,
                      builder: (context) {
                        String dialogSearch = '';
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            final filteredCows = _cows.where((c) =>
                              c.name.toLowerCase().contains(dialogSearch.toLowerCase()) ||
                              c.nodeId.toLowerCase().contains(dialogSearch.toLowerCase())
                            ).toList();
                            return AlertDialog(
                              title: Text(l.selectCow),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                        hintText: l.searchByNameOrId,
                                        prefixIcon: const Icon(Icons.search),
                                      ),
                                      onChanged: (v) => setDialogState(() => dialogSearch = v),
                                    ),
                                    const SizedBox(height: 16),
                                    Flexible(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: filteredCows.length,
                                        itemBuilder: (context, index) {
                                          final cow = filteredCows[index];
                                          return ListTile(
                                            leading: Icon(AnimalUtils.getAnimalIcon('cow'), color: AppColors.mistBlue),
                                            title: Text(cow.name),
                                            subtitle: Text('ID: ${cow.nodeId}'),
                                            onTap: () => Navigator.pop(context, cow),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                    if (picked != null) setModalState(() => selectedCow = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedCow?.name ?? l.selectCow),
                        if (existingRecord == null) const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date selector
                Text(l.saleDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setModalState(() => selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Morning / Evening volumes
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.morningL, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: morningController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.eveningL, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: eveningController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                Text(l.notes, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedCow == null) return;
                      final data = {
                        'animalId': selectedCow!.id,
                        'date': selectedDate.toIso8601String(),
                        'morningL': double.tryParse(morningController.text) ?? 0,
                        'eveningL': double.tryParse(eveningController.text) ?? 0,
                        'notes': notesController.text,
                      };
                      try {
                        MilkProduction result;
                        if (existingRecord == null) {
                          result = await _milkService.createRecord(data);
                        } else {
                          result = await _milkService.updateRecord(existingRecord.id, data);
                        }
                        if (mounted) Navigator.pop(context);
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MilkRecordSuccessScreen(record: result, isUpdate: existingRecord != null),
                          ));
                        }
                        _loadData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${context.l10n.error}: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mistBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      existingRecord == null ? l.saveRecord : l.updateRecord,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(MilkProduction record, {bool fromBottomSheet = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteRecord),
        content: Text(context.l10n.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (fromBottomSheet) Navigator.of(this.context).pop();
              try {
                await _milkService.deleteRecord(record.id);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('${context.l10n.error}: $e')),
                  );
                }
              }
            },
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(l),
                      const SizedBox(height: 32),
                      _buildStatsGrid(l),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.productionHistory,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          TextButton.icon(
                            onPressed: () => _showEntryDialog(),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(l.addEntry),
                            style: TextButton.styleFrom(foregroundColor: AppColors.mistBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: l.searchByNameOrId,
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () => _searchController.clear())
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildHistoryList(l),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(dynamic l) {
    return Row(
      children: [
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF64748B), size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(l.milkProduction,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF141E15))),
      ],
    );
  }

  Widget _buildStatsGrid(dynamic l) {
    final totalVol = _toDouble(_stats['totalLiters']);
    final herd = _stats['herdDetails'] as List?;
    final herdCount = herd?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l.totalYield,
            '${totalVol.toStringAsFixed(1)}L',
            l.allTime,
            Symbols.water_drop,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            l.topProducer,
            herdCount > 0 ? herd![0]['name'] : 'N/A',
            herdCount > 0 ? '${_toDouble(herd![0]['totalL'])}L' : '--',
            Symbols.star,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistoryList(dynamic l) {
    final filteredRecords = _records.where((record) {
      final name = record.animal?.name.toLowerCase() ?? '';
      final tag = record.animal?.nodeId.toLowerCase() ?? '';
      return name.contains(_searchQuery) || tag.contains(_searchQuery);
    }).toList();

    if (filteredRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            const Icon(Symbols.history, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? l.noRecordsYet : '${l.noData}: "$_searchQuery"',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return InkWell(
          onTap: () => _showEntryDialog(existingRecord: record),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.mistBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Symbols.water_drop, color: AppColors.mistBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.animal?.name ?? l.unknown,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text(DateFormat('MMM dd, yyyy').format(record.date),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${record.totalL}L',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mistBlue, fontSize: 16)),
                    Text('M:${record.morningL} E:${record.eveningL}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmDelete(record),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
