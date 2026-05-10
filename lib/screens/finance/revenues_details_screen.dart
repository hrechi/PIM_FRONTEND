import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/field_model.dart';
import '../../models/revenue_detail_model.dart';
import '../../services/finance_details_service.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';
import '../../l10n/l10n_extensions.dart';
import 'add_revenue_screen.dart';

class RevenuesDetailsScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;
  final FieldModel? field;

  const RevenuesDetailsScreen({
    required this.fieldId,
    required this.fieldName,
    this.field,
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
        _error = '${context.l10n.error}: $e';
        _isLoading = false;
      });
    }
  }

  List<RevenueDetail> _getFilteredData() {
    if (_currentData == null) return [];
    if (_searchQuery.isEmpty) return _currentData!.data;
    return _currentData!.data.where((r) {
      final q = _searchQuery.toLowerCase();
      return (r.animalName?.toLowerCase().contains(q) ?? false) ||
          (r.buyerName?.toLowerCase().contains(q) ?? false) ||
          r.type.toLowerCase().contains(q) ||
          (r.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _openAddRevenue() async {
    if (widget.field == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRevenueScreen(field: widget.field!),
      ),
    );
    if (result == true) _loadRevenuesData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.revenues} — ${widget.fieldName}'),
        backgroundColor: AppColors.mistyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: widget.field != null
          ? FloatingActionButton.extended(
              onPressed: _openAddRevenue,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              icon: const Icon(Symbols.add),
              label: Text(l10n.addRevenue),
            )
          : null,
      body: Column(
        children: [
          // Header filters
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.mistyBlue,
                  AppColors.mistyBlue.withValues(alpha: 0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.period,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['month', 'quarter', 'year'].map((p) {
                      final labels = {
                        'month': l10n.periodMonth,
                        'quarter': l10n.periodQuarter,
                        'year': l10n.periodYear,
                      };
                      final isSelected = _selectedPeriod == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedPeriod = p;
                              _currentPage = 0;
                            });
                            _loadRevenuesData();
                          },
                          label: Text(labels[p] ?? p),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          selectedColor: AppColors.mistyBlue,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.mistyBlue
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: l10n.revenueSearchHint,
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.white24),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
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
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : _currentData == null || _currentData!.data.isEmpty
                        ? Center(child: Text(l10n.noRevenuesFound))
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final filtered = _getFilteredData();
    if (filtered.isEmpty) {
      return Center(child: Text(context.l10n.noRevenuesFound));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: filtered.length + 1,
      itemBuilder: (ctx, i) {
        if (i == filtered.length) return _buildPagination();
        return _buildCard(filtered[i]);
      },
    );
  }

  Widget _buildCard(RevenueDetail revenue) {
    final formatter = DateFormat('dd/MM/yyyy');
    final isManual = revenue.source == RevenueSource.manual;

    final Color cardColor =
        isManual ? const Color(0xFF8B5CF6) : Colors.green.shade600;
    final IconData cardIcon =
        isManual ? _manualCategoryIcon(revenue.type) : Symbols.pets;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              cardColor.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isManual
                        ? Icon(cardIcon, size: 20, color: cardColor)
                        : Text(
                            AnimalUtils.getAnimalEmoji(revenue.type),
                            style: const TextStyle(fontSize: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isManual
                              ? _manualCategoryLabel(
                                  revenue.type, context)
                              : (revenue.animalName ?? '—'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isManual
                                ? context.l10n.revenueSourceManual
                                : context.l10n.revenueSourceAnimalSale,
                            style: TextStyle(
                              fontSize: 11,
                              color: cardColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${revenue.salePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _detailRow(
                        context.l10n.date,
                        formatter.format(revenue.saleDate),
                        Icons.calendar_today,
                        Colors.blue.shade600,
                      ),
                    ),
                    if (!isManual && revenue.buyerName != null)
                      Expanded(
                        child: _detailRow(
                          context.l10n.buyerName,
                          revenue.buyerName!,
                          Icons.person,
                          Colors.purple.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (revenue.description != null &&
                  revenue.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.note,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          revenue.description!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (_currentData == null) return const SizedBox.shrink();
    final totalPages = (_currentData!.total / _pageSize).ceil();
    final canPrev = _currentPage > 0;
    final canNext = _currentPage < totalPages - 1;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: canPrev
                ? () {
                    setState(() => _currentPage--);
                    _loadRevenuesData();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canPrev ? AppColors.mistyBlue : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text('← ${context.l10n.previous}'),
          ),
          Text('${_currentPage + 1} / $totalPages'),
          ElevatedButton(
            onPressed: canNext
                ? () {
                    setState(() => _currentPage++);
                    _loadRevenuesData();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canNext ? AppColors.mistyBlue : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text('${context.l10n.next} →'),
          ),
        ],
      ),
    );
  }

  IconData _manualCategoryIcon(String category) {
    switch (category) {
      case 'milk':
        return Symbols.water_drop;
      case 'crops':
        return Symbols.grass;
      case 'services':
        return Symbols.handyman;
      case 'subsidies':
        return Symbols.account_balance;
      default:
        return Symbols.attach_money;
    }
  }

  String _manualCategoryLabel(String category, BuildContext ctx) {
    switch (category) {
      case 'milk':
        return ctx.l10n.revenueCategoryMilk;
      case 'crops':
        return ctx.l10n.revenueCategoryCrops;
      case 'services':
        return ctx.l10n.revenueCategoryServices;
      case 'subsidies':
        return ctx.l10n.revenueCategorySubsidies;
      default:
        return ctx.l10n.other;
    }
  }
}
