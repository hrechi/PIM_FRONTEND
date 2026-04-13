import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/revenue_detail_model.dart';
import '../../services/finance_details_service.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';

class RevenuesDetailsScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;

  const RevenuesDetailsScreen({
    required this.fieldId,
    required this.fieldName,
    super.key,
  });

  @override
  State<RevenuesDetailsScreen> createState() => _RevenuesDetailsScreenState();
}

class _RevenuesDetailsScreenState extends State<RevenuesDetailsScreen> {
  late FinanceDetailsService _financeService;
  String _selectedPeriod = 'month';
  String _searchQuery = '';
  int _currentPage = 0;
  final int _pageSize = 20;
  RevenuesResponse? _currentData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _financeService = FinanceDetailsService();
    _loadRevenuesData();
  }

  Future<void> _loadRevenuesData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _financeService.getRevenuesDetails(
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

  List<RevenueDetail> _getFilteredData() {
    if (_currentData == null) return [];

    if (_searchQuery.isEmpty) {
      return _currentData!.data;
    }

    return _currentData!.data.where((revenue) {
      return revenue.animalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (revenue.buyerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          revenue.type.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revenus - ${widget.fieldName}'),
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
                            _loadRevenuesData();
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
                // Search box
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher par animal, acheteur...',
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
                              onPressed: _loadRevenuesData,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _currentData == null || _currentData!.data.isEmpty
                        ? const Center(child: Text('Aucun revenu trouvé'))
                        : _buildRevenuesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenuesList() {
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

        final revenue = filteredData[index];
        return _buildRevenueCard(revenue);
      },
    );
  }

  Widget _buildRevenueCard(RevenueDetail revenue) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animal name and price
            Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        AnimalUtils.getAnimalEmoji(revenue.type),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              revenue.animalName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              revenue.type,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
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
                        '+${revenue.salePrice.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF10B981),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (revenue.saleWeightKg != null)
                        Text(
                          '${revenue.saleWeightKg!.toStringAsFixed(1)} kg',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    'Date',
                    formatter.format(revenue.saleDate),
                    Icons.calendar_today,
                  ),
                ),
                if (revenue.buyerName != null)
                  Expanded(
                    child: _buildDetailRow(
                      'Acheteur',
                      revenue.buyerName ?? '',
                      Icons.person,
                    ),
                  ),
              ],
            ),
          ],
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

    final totalPages = (_currentData!.total / _pageSize).ceil();
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
                    _loadRevenuesData();
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
                    _loadRevenuesData();
                  }
                : null,
            child: const Text('Suivant →'),
          ),
        ],
      ),
    );
  }
}
