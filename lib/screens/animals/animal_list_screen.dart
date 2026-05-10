import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../main.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../services/field_service.dart';
import '../../models/field_model.dart';
import '../../l10n/l10n_extensions.dart';
import 'add_animal_screen.dart';
import 'animal_details_screen.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key, this.showFatteningOnly = false});
  final bool showFatteningOnly;
  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  final AnimalService _animalService = AnimalService();
  final FieldService _fieldService = FieldService();
  late Future<List<Animal>> _animalsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  late TabController _tabController;
  String? _selectedType;
  String? _selectedFieldId;
  bool _showFatteningOnly = false;
  List<FieldModel> _fields = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _showFatteningOnly = widget.showFatteningOnly;
    _fetchFields();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (mounted) _refreshData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _refreshData();
  }

  Future<void> _fetchFields() async {
    try {
      final fields = await _fieldService.getFields();
      if (mounted) setState(() => _fields = fields);
    } catch (_) {
      // Silently fail — fields list is optional
    }
  }

  void _refreshData() {
    setState(() {
      _animalsFuture = _animalService.getAnimals(
        animalType: _selectedType,
        fieldId: _selectedFieldId,
      );
      _statsFuture = _animalService.getStatistics(fieldId: _selectedFieldId);
    });
  }

  void _showCancelSaleDialog(Animal animal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelSaleConfirmTitle),
        content: Text(context.l10n.cancelSaleConfirmBody(animal.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSale(animal);
            },
            child: Text(context.l10n.yes),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSale(Animal animal) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await _animalService.cancelSale(animal.nodeId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.saleCancelled(animal.name)),
          backgroundColor: Colors.green,
        ));
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${context.l10n.error}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      drawer: const AppDrawer(),
      body: Container(
        color: AppColors.sageTint,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildFieldFilter(),
              _buildSearchSection(),
              _buildCategoryFilters(),
              _buildStatusTabs(),
              Expanded(child: _buildAnimalList()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.menu_rounded, color: Color(0xFF141E15), size: 24),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.mistBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Symbols.pets, color: AppColors.mistBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.livestock,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF141E15), letterSpacing: -0.5),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: IconButton(
              icon: const Icon(Symbols.notifications, color: Color(0xFF64748B)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: context.l10n.searchByNameOrId,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            prefixIcon: const Icon(Symbols.search, color: Color(0xFF94A3B8), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Symbols.close, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final l = context.l10n;
    final typeLabels = {
      'cow': l.cow,
      'horse': l.horse,
      'sheep': l.sheep,
      'dog': l.dog,
    };

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: AppConstants.animalTypes.length + 2,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isFatteningFilter = index == AppConstants.animalTypes.length + 1;
          final type = isAll ? null : !isFatteningFilter ? AppConstants.animalTypes[index - 1] : null;
          final label = isAll
              ? l.all
              : isFatteningFilter
                  ? l.plannedSales
                  : typeLabels[type] ?? (type![0].toUpperCase() + type.substring(1));
          final isSelected = isFatteningFilter ? _showFatteningOnly : _selectedType == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (isFatteningFilter) {
                    _showFatteningOnly = selected;
                  } else {
                    _selectedType = selected ? type : null;
                  }
                  _refreshData();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.mistBlue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.mistBlue : const Color(0xFFE2E8F0)),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: context.l10n.active),
          Tab(text: context.l10n.sold),
          Tab(text: context.l10n.deceased),
        ],
        labelColor: AppColors.mistBlue,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorColor: AppColors.mistBlue,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Widget _buildAnimalList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAnimalListByStatus('active'),
        _buildAnimalListByStatus('sold'),
        _buildAnimalListByStatus('deceased'),
      ],
    );
  }

  Widget _buildAnimalListByStatus(String status) {
    return FutureBuilder<List<Animal>>(
      future: _animalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('${context.l10n.error}: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFFEF4444)), textAlign: TextAlign.center),
                TextButton(onPressed: _refreshData, child: Text(context.l10n.retry)),
              ],
            ),
          );
        }

        final list = snapshot.data ?? [];
        final filteredList = list.where((a) {
          if (a.status.toLowerCase() != status.toLowerCase()) return false;
          final query = _searchQuery.toLowerCase();
          if (!a.name.toLowerCase().contains(query) && !a.nodeId.toLowerCase().contains(query)) return false;
          if (_selectedType != null && a.animalType.toUpperCase() != _selectedType!.toUpperCase()) return false;
          if (_showFatteningOnly && a.isFattening != true) return false;
          return true;
        }).toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(opacity: 0.2, child: Icon(Symbols.inventory_2, size: 80, color: AppColors.mistBlue)),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noAnimalsFound,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredList.length,
            itemBuilder: (context, index) => _buildAnimalCard(filteredList[index]),
          ),
        );
      },
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AnimalDetailsScreen(animal: animal)),
            );
            if (result == true) _refreshData();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCardImage(animal),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(animal.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF141E15)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          _buildHealthBadge(animal.vitalityScore),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${animal.breed ?? context.l10n.unknown} • ${animal.age}m',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(AnimalUtils.getAnimalIcon(animal.animalType), size: 16, color: const Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              const Icon(Symbols.event_repeat, size: 16, color: Color(0xFF94A3B8)),
                              if (animal.isFattening == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                                  child: Text(context.l10n.fattening,
                                      style: const TextStyle(color: Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                          if (animal.status.toLowerCase() == 'sold')
                            GestureDetector(
                              onTap: () => _showCancelSaleDialog(animal),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Symbols.close, color: Color(0xFFEF4444), size: 14),
                                    const SizedBox(width: 4),
                                    Text(context.l10n.cancelSale,
                                        style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Text(context.l10n.viewDetails,
                                    style: const TextStyle(color: AppColors.mistBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Symbols.chevron_right, color: AppColors.mistBlue, size: 16),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(Animal animal) {
    String? imageUrl;
    if (animal.profileImage != null && animal.profileImage!.isNotEmpty) {
      final p = animal.profileImage!;
      imageUrl = p.startsWith('http')
          ? p
          : 'http://${AppConfig.serverHost}:${AppConfig.serverPort}${p.startsWith('/') ? '' : '/'}$p';
    }
    return Container(
      width: 96, height: 96,
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: imageUrl != null
            ? Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(animal.animalType))
            : _buildFallbackIcon(animal.animalType),
      ),
    );
  }

  Widget _buildFallbackIcon(String type) {
    return Center(child: Icon(AnimalUtils.getAnimalIcon(type), size: 40, color: AppColors.mistBlue.withValues(alpha: 0.3)));
  }

  Widget _buildHealthBadge(int score) {
    Color bg = AppColors.mistBlue.withValues(alpha: 0.1);
    Color text = AppColors.mistBlue;
    if (score < 50) { bg = const Color(0xFFFEF2F2); text = const Color(0xFFEF4444); }
    else if (score < 80) { bg = const Color(0xFFFFFBEB); text = const Color(0xFFF59E0B); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text('${context.l10n.healthStatus}: $score',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
          );
          if (result == true) _refreshData();
        },
        label: Text(context.l10n.addLivestock,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        icon: const Icon(Icons.add, size: 28),
        backgroundColor: AppColors.mistBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildFieldFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFieldId,
            isExpanded: true,
            hint: Text(context.l10n.allFields, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            icon: const Icon(Symbols.filter_list, color: AppColors.mistBlue),
            items: [
              DropdownMenuItem<String>(value: null, child: Text(context.l10n.allFields)),
              ..._fields.map((field) => DropdownMenuItem<String>(value: field.id, child: Text(field.name))),
            ],
            onChanged: (value) {
              setState(() { _selectedFieldId = value; _refreshData(); });
            },
          ),
        ),
      ),
    );
  }
}
