import 'package:flutter/material.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_chip.dart';
import 'add_animal_screen.dart';
import 'animal_details_screen.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  final AnimalService _animalService = AnimalService();
  late Future<List<Animal>> _animalsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  String? _selectedType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _animalsFuture = _animalService.getAnimals(animalType: _selectedType);
      _statsFuture = _animalService.getStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Livestock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildSearchAndFilter(),
          Expanded(
            child: _buildAnimalList(isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAnimalScreen()),
          );
          if (result == true) _refreshData();
        },
        label: const Text('Add Animal'),
        icon: const Icon(Icons.add),
        backgroundColor: isDark ? AppColors.darkMistyBlue : AppColors.mistyBlue,
      ),
    );
  }

  Widget _buildStatsHeader() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final total = snapshot.data?['totalAnimals']?.toString() ?? '0';
        final health = snapshot.data?['healthPercentage']?.toString() ?? '100';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Total Animals',
                  value: total,
                  icon: Icons.pets,
                  color: AppColors.mistyBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Health Index',
                  value: '$health%',
                  icon: Icons.health_and_safety,
                  color: AppColors.fieldFreshStart,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by Name or Tag...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip(null, 'All'),
              ...AppConstants.animalTypes.map((type) => _buildFilterChip(type, type)),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFilterChip(String? type, String label) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedType = selected ? type : null;
            _refreshData();
          });
        },
        selectedColor: (isDark ? AppColors.darkMistyBlue : AppColors.mistyBlue).withValues(alpha: 0.2),
        checkmarkColor: isDark ? AppColors.darkMistyBlue : AppColors.mistyBlue,
        labelStyle: TextStyle(
          color: isSelected 
            ? (isDark ? AppColors.darkMistyBlue : AppColors.mistyBlue)
            : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAnimalList(bool isDark) {
    return FutureBuilder<List<Animal>>(
      future: _animalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final list = snapshot.data ?? [];
        final filteredList = list.where((a) {
          final query = _searchQuery.toLowerCase();
          return a.name.toLowerCase().contains(query) || 
                 (a.tagNumber?.toLowerCase().contains(query) ?? false);
        }).toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No animals found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final animal = filteredList[index];
            return _buildAnimalCard(animal, isDark);
          },
        );
      },
    );
  }

  Widget _buildAnimalCard(Animal animal, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnimalDetailsScreen(animal: animal)),
            );
            if (result == true) _refreshData();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getAnimalColor(animal.animalType).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getAnimalIcon(animal.animalType),
                    size: 40,
                    color: _getAnimalColor(animal.animalType),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            animal.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StatusChip(
                            label: animal.healthStatus,
                            color: _getHealthColor(animal.healthStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${animal.animalType} • ${animal.breed ?? "Common"}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.monitor_heart, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Vitality: ${animal.vitalityScore}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.label_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            animal.tagNumber ?? 'No Tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
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

  IconData _getAnimalIcon(String type) {
    switch (type) {
      case 'COW': return Icons.agriculture;
      case 'SHEEP': return Icons.cloud;
      case 'HORSE': return Icons.directions_run;
      case 'GOAT': return Icons.eco;
      case 'BIRD': return Icons.flutter_dash;
      default: return Icons.pets;
    }
  }

  Color _getAnimalColor(String type) {
    switch (type) {
      case 'COW': return AppColors.cowColor;
      case 'SHEEP': return AppColors.sheepColor;
      case 'HORSE': return AppColors.horseColor;
      case 'GOAT': return AppColors.goatColor;
      case 'BIRD': return AppColors.birdColor;
      default: return AppColors.otherColor;
    }
  }

  Color _getHealthColor(String status) {
    switch (status) {
      case 'OPTIMAL': return AppColors.healthOptimal;
      case 'WARNING': return AppColors.healthWarning;
      case 'CRITICAL': return AppColors.healthCritical;
      default: return Colors.grey;
    }
  }
}
