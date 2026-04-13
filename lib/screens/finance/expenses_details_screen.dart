import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_detail_model.dart';
import '../../services/finance_details_service.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';

class ExpensesDetailsScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;

  const ExpensesDetailsScreen({
    required this.fieldId,
    required this.fieldName,
    super.key,
  });

  @override
  State<ExpensesDetailsScreen> createState() => _ExpensesDetailsScreenState();
}

class _ExpensesDetailsScreenState extends State<ExpensesDetailsScreen> {
  late FinanceDetailsService _financeService;
  String _selectedPeriod = 'month';
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _currentPage = 0;
  final int _pageSize = 20;
  ExpensesResponse? _currentData;
  bool _isLoading = false;
  String? _error;

  final Map<String, String> _categoryLabels = {
    'all': 'Tous',
    'feed': 'Aliments',
    'vet': 'Vétérinaire',
    'meds': 'Médicaments',
    'equip': 'Équipement',
    'labor': 'Main-d\'œuvre',
    'other': 'Autres',
  };

  final Map<String, Color> _categoryColors = {
    'feed': const Color(0xFF8B4513),
    'vet': const Color(0xFFE74C3C),
    'meds': const Color(0xFF3498DB),
    'equip': const Color(0xFF2C3E50),
    'labor': const Color(0xFF27AE60),
    'other': const Color(0xFF95A5A6),
  };

  @override
  void initState() {
    super.initState();
    _financeService = FinanceDetailsService();
    _loadExpensesData();
  }

  Future<void> _loadExpensesData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _financeService.getExpensesDetails(
        fieldId: widget.fieldId,
        period: _selectedPeriod,
        skip: _currentPage * _pageSize,
        take: _pageSize,
      );

      setState(() {
        _currentData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  List<ExpenseDetail> _getFilteredData() {
    if (_currentData == null) return [];

    var filtered = _currentData!.data;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((expense) => expense.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.animalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (expense.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filtered;
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'feed':
        return '🌾';
      case 'vet':
        return '🩺';
      case 'meds':
        return '💊';
      case 'equip':
        return '🔧';
      case 'labor':
        return '👨‍🌾';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dépenses - ${widget.fieldName}'),
        backgroundColor: AppColors.mistyBlue,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Header with filters
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.mistyBlue, AppColors.mistyBlue.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selector
                Text(
                  'Période',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['month', 'quarter', 'year'].map((period) {
                      final labels = {'month': 'Mois', 'quarter': 'Trimestre', 'year': 'Année'};
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPeriod = period;
                              _currentPage = 0;
                            });
                            _loadExpensesData();
                          },
                          label: Text(labels[period] ?? period),
                          backgroundColor: Colors.white.withOpacity(0.15),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.mistyBlue : Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Category filter
                Text(
                  'Catégorie',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'feed', 'vet', 'meds', 'equip', 'labor', 'other'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                              _currentPage = 0;
                            });
                            _loadExpensesData();
                          },
                          label: Text(_categoryLabels[cat] ?? cat),
                          backgroundColor: Colors.white.withOpacity(0.15),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.mistyBlue : Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Search box
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher par animal, description...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadExpensesData,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _currentData == null || _currentData!.data.isEmpty
                        ? const Center(child: Text('Aucune dépense trouvée'))
                        : _buildExpensesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    final filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
      return const Center(child: Text('Aucun résultat trouvé'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredData.length + 1,
      itemBuilder: (context, index) {
        if (index == filteredData.length) {
          return _buildPagination();
        }

        final expense = filteredData[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildExpenseCard(ExpenseDetail expense) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final categoryColor = _categoryColors[expense.category] ?? Colors.grey;
    final categoryLabel = _categoryLabels[expense.category] ?? expense.category;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: categoryColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with animal name and amount
              Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _getCategoryIcon(expense.category),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.animalName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  categoryLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: categoryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${expense.amount.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFEF4444),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      'Date',
                      formatter.format(expense.date),
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              // Description/Notes if available
              if (expense.description != null && expense.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Description: ${expense.description}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mistyBlue),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (_currentData == null) return const SizedBox.shrink();

    final filteredData = _getFilteredData();
    final totalPages = (filteredData.length / _pageSize).ceil();
    final canGoPrevious = _currentPage > 0;
    final canGoNext = _currentPage < totalPages - 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: canGoPrevious
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadExpensesData();
                  }
                : null,
            child: const Text('← Précédent'),
          ),
          Text('Page ${_currentPage + 1} / $totalPages'),
          ElevatedButton(
            onPressed: canGoNext
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadExpensesData();
                  }
                : null,
            child: const Text('Suivant →'),
          ),
        ],
      ),
    );
  }
}
