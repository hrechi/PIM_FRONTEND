import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalogue_provider.dart';
import '../models/animal.dart';

class AnimalSelectorScreen extends StatefulWidget {
  final List<Animal> selectedAnimals;

  const AnimalSelectorScreen({
    super.key,
    required this.selectedAnimals,
  });

  @override
  State<AnimalSelectorScreen> createState() => _AnimalSelectorScreenState();
}

class _AnimalSelectorScreenState extends State<AnimalSelectorScreen> {
  List<Animal> _filteredAnimals = [];
  List<String> _selectedIds = [];
  bool _isLoading = true;
  String? _error;

  // Cache de tous les animaux vus (toutes les pages de filtre confondues)
  // Permet de retrouver l'objet Animal complet même après un changement de filtre
  final Map<String, Animal> _allSeenAnimals = {};

  // Filter options
  String? _species;
  String? _sex;
  String? _fieldId;
  int? _minAgeMonths;
  int? _maxAgeMonths;
  double? _minWeight;
  double? _maxWeight;
  String? _vaccinationStatus;
  String? _reproductionStatus;
  String? _tagNumber;
  bool? _isFattening;

  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedAnimals.map((a) => a.id).toList();
    // Pré-remplir le cache avec les animaux déjà sélectionnés
    for (final a in widget.selectedAnimals) {
      _allSeenAnimals[a.id] = a;
    }
    _loadAnimals();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<CatalogueProvider>();
      final animals = await provider.previewFilter(
        species: _species,
        sex: _sex,
        fieldId: _fieldId,
        minAgeMonths: _minAgeMonths,
        maxAgeMonths: _maxAgeMonths,
        minWeight: _minWeight,
        maxWeight: _maxWeight,
        vaccinationStatus: _vaccinationStatus,
        reproductionStatus: _reproductionStatus,
        tagNumber: _tagNumber,
        isFattening: _isFattening,
      );

      if (animals != null) {
        // Ajouter tous les animaux retournés au cache global
        for (final a in animals) {
          _allSeenAnimals[a.id] = a;
        }
        setState(() {
          _filteredAnimals = animals;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Animals'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isNotEmpty ? _confirmSelection : null,
            child: Text(
              'Done (${_selectedIds.length})',
              style: TextStyle(
                color: _selectedIds.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildAnimalList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Species',
                value: _species,
                onTap: () => _showSpeciesFilter(),
              ),
              _buildFilterChip(
                label: 'Sex',
                value: _sex,
                onTap: () => _showSexFilter(),
              ),
              _buildFilterChip(
                label: 'Field',
                value: _fieldId,
                onTap: () => _showFieldFilter(),
              ),
              _buildFilterChip(
                label: 'Age Range',
                value: _getAgeRangeText(),
                onTap: () => _showAgeFilter(),
              ),
              _buildFilterChip(
                label: 'Weight Range',
                value: _getWeightRangeText(),
                onTap: () => _showWeightFilter(),
              ),
              _buildFilterChip(
                label: 'Vaccination',
                value: _vaccinationStatus == 'up_to_date'
                    ? 'Up to date'
                    : _vaccinationStatus == 'incomplete'
                        ? 'Incomplete'
                        : _vaccinationStatus,
                onTap: () => _showVaccinationFilter(),
              ),
              _buildFilterChip(
                label: 'Reproduction',
                value: _reproductionStatus == 'pregnant'
                    ? 'Pregnant'
                    : _reproductionStatus == 'not_pregnant'
                        ? 'Not pregnant'
                        : _reproductionStatus,
                onTap: () => _showReproductionFilter(),
              ),
              _buildFilterChip(
                label: 'Fattening',
                value: _isFattening == null ? null : (_isFattening! ? 'Yes' : 'No'),
                onTap: () => _showFatteningFilter(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagController,
            decoration: InputDecoration(
              hintText: 'Search by tag number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _tagController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _tagController.clear();
                        setState(() => _tagNumber = null);
                        _loadAnimals();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _tagNumber = value.isEmpty ? null : value);
              _loadAnimals();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return FilterChip(
      label: Text(
        hasValue ? '$label: $value' : label,
        style: TextStyle(
          color: hasValue ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      selected: hasValue,
      onSelected: (_) => onTap(),
      backgroundColor: hasValue ? Theme.of(context).primaryColor : null,
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildAnimalList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnimals,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredAnimals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No animals found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAnimals.length + 1, // +1 for Select All button
      itemBuilder: (context, index) {
        if (index == 0) {
          // Select All button
          final allSelected = _filteredAnimals.every((animal) => _selectedIds.contains(animal.id));
          final noneSelected = _filteredAnimals.every((animal) => !_selectedIds.contains(animal.id));

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: InkWell(
              onTap: () => _toggleSelectAll(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected ? true : (noneSelected ? false : null),
                      tristate: true,
                      onChanged: (_) => _toggleSelectAll(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        allSelected ? 'Deselect All' : 'Select All',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedIds.length}/${_filteredAnimals.length} selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final animal = _filteredAnimals[index - 1]; // -1 because index 0 is Select All
        final isSelected = _selectedIds.contains(animal.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _toggleSelection(animal.id),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(animal.id),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.tagNumber ?? 'No Tag',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (animal.animalType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${animal.animalType} ${animal.sex ?? ''}'.trim(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (animal.weight != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${animal.weight} kg',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (animal.profileImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        animal.profileImage!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleSelection(String animalId) {
    setState(() {
      if (_selectedIds.contains(animalId)) {
        _selectedIds.remove(animalId);
      } else {
        _selectedIds.add(animalId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final allSelected = _filteredAnimals.every((animal) => _selectedIds.contains(animal.id));
      if (allSelected) {
        // Deselect all
        _selectedIds.removeWhere((id) => _filteredAnimals.any((animal) => animal.id == id));
      } else {
        // Select all
        for (final animal in _filteredAnimals) {
          if (!_selectedIds.contains(animal.id)) {
            _selectedIds.add(animal.id);
          }
        }
      }
    });
  }

  void _confirmSelection() {
    // Construire la liste finale depuis le cache global (_allSeenAnimals)
    // et non depuis _filteredAnimals (qui ne contient que le filtre actuel).
    // Cela préserve les sélections faites avec des filtres précédents.
    final selectedAnimals = _selectedIds
        .map((id) => _allSeenAnimals[id])
        .whereType<Animal>()
        .toList();

    Navigator.pop(context, selectedAnimals);
  }

  void _clearFilters() {
    setState(() {
      _species = null;
      _sex = null;
      _fieldId = null;
      _minAgeMonths = null;
      _maxAgeMonths = null;
      _minWeight = null;
      _maxWeight = null;
      _vaccinationStatus = null;
      _reproductionStatus = null;
      _tagNumber = null;
      _isFattening = null;
      _tagController.clear();
    });
    _loadAnimals();
  }

  String? _getAgeRangeText() {
    if (_minAgeMonths == null && _maxAgeMonths == null) return null;
    if (_minAgeMonths != null && _maxAgeMonths != null) {
      return '${_minAgeMonths}m - ${_maxAgeMonths}m';
    }
    if (_minAgeMonths != null) return '${_minAgeMonths}m+';
    return 'Up to ${_maxAgeMonths}m';
  }

  String? _getWeightRangeText() {
    if (_minWeight == null && _maxWeight == null) return null;
    if (_minWeight != null && _maxWeight != null) {
      return '${_minWeight}kg - ${_maxWeight}kg';
    }
    if (_minWeight != null) return '${_minWeight}kg+';
    return 'Up to ${_maxWeight}kg';
  }

  void _showSpeciesFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Select Species',
        options: ['cow', 'sheep', 'horse', 'dog'],
        displayOptions: ['Cattle', 'Sheep', 'Horse', 'Dog'],
        selectedValue: _species,
        onSelected: (value) {
          setState(() => _species = value);
          _loadAnimals();
        },
      ),
    );
  }

  void _showSexFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Select Sex',
        options: ['male', 'female'],
        displayOptions: ['Male', 'Female'],
        selectedValue: _sex,
        onSelected: (value) {
          setState(() => _sex = value);
          _loadAnimals();
        },
      ),
    );
  }

  void _showFieldFilter() {
    // For now, show a simple text input for field selection
    // In a real app, this would load available fields from the API
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Select Field',
        options: ['Field 1', 'Field 2', 'Field 3'], // Placeholder - should load from API
        selectedValue: _fieldId,
        onSelected: (value) {
          setState(() => _fieldId = value);
          _loadAnimals();
        },
      ),
    );
  }

  void _showAgeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildRangeFilterBottomSheet(
        title: 'Age Range (Months)',
        minValue: _minAgeMonths,
        maxValue: _maxAgeMonths,
        minLimit: 0,
        maxLimit: 120,
        onChanged: (min, max) {
          setState(() {
            _minAgeMonths = min;
            _maxAgeMonths = max;
          });
          _loadAnimals();
        },
      ),
    );
  }

  void _showWeightFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildRangeFilterBottomSheet(
        title: 'Weight Range (kg)',
        minValue: _minWeight?.toInt(),
        maxValue: _maxWeight?.toInt(),
        minLimit: 0,
        maxLimit: 2000,
        onChanged: (min, max) {
          setState(() {
            _minWeight = min?.toDouble();
            _maxWeight = max?.toDouble();
          });
          _loadAnimals();
        },
      ),
    );
  }

  void _showVaccinationFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Vaccination Status',
        options: ['up_to_date', 'incomplete'],
        displayOptions: ['Up to date', 'Incomplete'],
        selectedValue: _vaccinationStatus,
        onSelected: (value) {
          setState(() => _vaccinationStatus = value);
          _loadAnimals();
        },
      ),
    );
  }

  void _showReproductionFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Reproduction Status',
        options: ['pregnant', 'not_pregnant'],
        displayOptions: ['Pregnant', 'Not pregnant'],
        selectedValue: _reproductionStatus,
        onSelected: (value) {
          setState(() => _reproductionStatus = value);
          _loadAnimals();
        },
      ),
    );
  }

  void _showFatteningFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Fattening',
        options: ['yes', 'no'],
        displayOptions: ['Yes', 'No'],
        selectedValue: _isFattening == null ? null : (_isFattening! ? 'yes' : 'no'),
        onSelected: (value) {
          setState(() {
            if (value == 'yes') {
              _isFattening = true;
            } else if (value == 'no') {
              _isFattening = false;
            } else {
              _isFattening = null;
            }
          });
          _loadAnimals();
        },
      ),
    );
  }

  Widget _buildFilterBottomSheet({
    required String title,
    required List<String> options,
    List<String>? displayOptions,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...options.asMap().entries.map((entry) {
            final value = entry.value;
            final label = displayOptions != null ? displayOptions[entry.key] : value;
            return ListTile(
              title: Text(label),
              trailing: selectedValue == value
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                onSelected(selectedValue == value ? null : value);
                Navigator.pop(context);
              },
            );
          }),
          ListTile(
            title: const Text('Clear Filter'),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRangeFilterBottomSheet({
    required String title,
    required int? minValue,
    required int? maxValue,
    required int minLimit,
    required int maxLimit,
    required Function(int?, int?) onChanged,
  }) {
    int? localMin = minValue;
    int? localMax = maxValue;

    return StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: localMin?.toString()),
                      onChanged: (value) => localMin = int.tryParse(value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: localMax?.toString()),
                      onChanged: (value) => localMax = int.tryParse(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onChanged(null, null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onChanged(localMin, localMax);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}