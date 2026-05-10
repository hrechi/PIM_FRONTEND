import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../services/field_service.dart';
import '../../models/field_model.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';
import '../../l10n/l10n_extensions.dart';
import 'animal_details_screen.dart';
import 'sell_animal_screen.dart';
import 'animals_design.dart';

class PlannedSalesScreen extends StatefulWidget {
  const PlannedSalesScreen({super.key});

  @override
  State<PlannedSalesScreen> createState() => _PlannedSalesScreenState();
}

class _PlannedSalesScreenState extends State<PlannedSalesScreen> {
  final AnimalService _animalService = AnimalService();
  final FieldService _fieldService = FieldService();
  late Future<List<Animal>> _animalsFuture;
  String? _selectedFieldId;
  List<FieldModel> _fields = [];

  @override
  void initState() {
    super.initState();
    _fetchFields();
    _refreshData();
  }

  Future<void> _fetchFields() async {
    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _fields = fields;
      });
    } catch (_) {
      // Silently fail — fields list is optional
    }
  }

  void _refreshData() {
    setState(() {
      _animalsFuture = _animalService.getAnimalsForSale(fieldId: _selectedFieldId);
    });
  }

  void _showSellDialog(Animal animal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.sellAnimalTitle),
        content: Text(context.l10n.sellAnimalConfirm(animal.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sellAnimal(animal);
            },
            child: Text(context.l10n.sell),
          ),
        ],
      ),
    );
  }

  Future<void> _sellAnimal(Animal animal) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellAnimalScreen(animal: animal),
        ),
      );
      if (updated == true && mounted) {
        _refreshData();
        // Delay slightly to ensure backend has updated
        await Future.delayed(const Duration(milliseconds: 500));
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.animalSoldSuccessName(animal.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorPrefix(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      appBar: AnimalsDesign.animalsAppBar(title: context.l10n.seasonalSales),
      body: Column(
        children: [
          _buildFieldFilter(),
          Expanded(
            child: _buildAnimalsListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AnimalsDesign.screenHorizontalPadding, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFieldId,
            isExpanded: true,
            hint: Text(context.l10n.allParcels, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            icon: const Icon(Symbols.filter_list, color: AppColors.mistBlue),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(context.l10n.allParcels),
              ),
              ..._fields.map((field) {
                return DropdownMenuItem<String>(
                  value: field.id,
                  child: Text(field.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFieldId = value;
                _refreshData();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalsListView() {
    return FutureBuilder<List<Animal>>(
      future: _animalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.mistyBlue));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  context.l10n.errorPrefix(snapshot.error.toString()),
                  style: const TextStyle(color: Color(0xFFEF4444)),
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: _refreshData, child: Text(context.l10n.retry)),
              ],
            ),
          );
        }

        final animals = snapshot.data ?? [];
        if (animals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Icon(Symbols.inventory_2, size: 80, color: AppColors.mistBlue),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noFatteningAnimals,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(AnimalsDesign.screenHorizontalPadding, 16, AnimalsDesign.screenHorizontalPadding, 16),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return _buildAnimalCard(animals[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final daysUntilSale = animal.targetSaleDate?.difference(DateTime.now()).inDays;
    final daysInFat = animal.fatteningStartDate != null
        ? DateTime.now().difference(animal.fatteningStartDate!).inDays
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimalDetailsScreen(animal: animal),
              ),
            );
            if (result == true) _refreshData();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: animal.profileImage != null
                            ? Image.network(
                                animal.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackIcon(animal.animalType),
                              )
                            : _buildFallbackIcon(animal.animalType),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animal.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF141E15),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${animal.breed ?? "Unknown"} • ${animal.age}m • ${animal.sex}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l10n.fatteningDays(daysInFat),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0369A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.targetSaleDateLabel,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            animal.targetSaleDate != null
                                ? DateFormat('dd MMM yyyy').format(animal.targetSaleDate!)
                                : context.l10n.notDefined,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                      if (daysUntilSale != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: daysUntilSale <= 7
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            daysUntilSale <= 0
                                ? context.l10n.ready
                                : '$daysUntilSale j',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: daysUntilSale <= 0
                                  ? const Color(0xFFDC2626)
                                  : daysUntilSale <= 7
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnimalDetailsScreen(animal: animal),
                            ),
                          );
                          if (updated == true) _refreshData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.mistBlue, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Symbols.info, color: AppColors.mistBlue, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.details,
                                style: TextStyle(
                                  color: AppColors.mistBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showSellDialog(animal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Symbols.check_circle, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.sell,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(String type) {
    return Center(
      child: Text(
        AnimalUtils.getAnimalEmoji(type),
        style: const TextStyle(fontSize: 40),
      ),
    );
  }
}
