import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../../providers/finance_provider.dart';
import '../../providers/field_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../expenses/add_expense_screen.dart';
import 'revenues_details_screen.dart';
import 'expenses_details_screen.dart';
import 'add_revenue_screen.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  String _selectedPeriod = 'month';
  String? _selectedFieldId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final fieldProvider = Provider.of<FieldProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    // Load fields if not loaded
    if (fieldProvider.fields.isEmpty && !fieldProvider.isLoading) {
      fieldProvider.loadFields().then((_) {
        if (fieldProvider.fields.isNotEmpty) {
          setState(() {
            _selectedFieldId = fieldProvider.fields.first.id;
          });
          _loadDashboard();
        }
      });
    } else if (fieldProvider.fields.isNotEmpty) {
      if (_selectedFieldId == null) {
        setState(() {
          _selectedFieldId = fieldProvider.fields.first.id;
        });
      }
      _loadDashboard();
    }
  }

  void _loadDashboard() {
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    if (_selectedFieldId != null) {
      financeProvider.loadDashboard(_selectedFieldId!, _selectedPeriod);
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadDashboard();
  }

  void _onFieldChanged(String? fieldId) {
    if (fieldId != null) {
      setState(() {
        _selectedFieldId = fieldId;
      });
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Financier'),
        backgroundColor: AppColors.mistyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer2<FieldProvider, FinanceProvider>(
        builder: (context, fieldProvider, financeProvider, child) {
          if (fieldProvider.fields.isEmpty) {
            return const Center(child: Text('Aucun champ trouvé'));
          }

          if (financeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (financeProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${financeProvider.error}'),
                  ElevatedButton(
                    onPressed: _loadDashboard,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final dashboard = financeProvider.dashboard;
          if (dashboard == null) {
            return const Center(child: Text('Aucune donnée disponible'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.mistyBlue, AppColors.mistyBlue.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue d\'ensemble',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<FieldProvider>(
                        builder: (context, fieldProvider, child) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedFieldId,
                              hint: const Text(
                                'Sélectionner un champ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              underline: const SizedBox(),
                              dropdownColor: AppColors.mistyBlue,
                              style: const TextStyle(color: Colors.white),
                              items: fieldProvider.fields.map((field) {
                                return DropdownMenuItem<String>(
                                  value: field.id,
                                  child: Text(
                                    field.name ?? 'Sans nom',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: _onFieldChanged,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPeriodSelector(),
                    ],
                  ),
                ),

                // Net Balance Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildNetBalance(dashboard),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue and Expenses Summary
                      Row(
                        children: [
                          Expanded(child: _buildRevenueCard(dashboard)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildExpensesCard(dashboard)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Expenses by Category
                      Text(
                        'Dépenses par catégorie',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildExpensesByCategory(dashboard),

                      const SizedBox(height: 24),

                      // Top Costly Animals
                      Text(
                        'Top 3 animaux coûteux',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTopCostlyAnimals(dashboard),

                      const SizedBox(height: 24),

                      // Recent Expenses
                      Text(
                        'Dernières dépenses',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentExpenses(dashboard),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedFieldId != null) {
            final fieldProvider = Provider.of<FieldProvider>(context, listen: false);
            final field = fieldProvider.fields.firstWhere((f) => f.id == _selectedFieldId);
            _showAddMenu(context, field);
          }
        },
        backgroundColor: AppColors.mistyBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMenu(BuildContext context, dynamic field) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.remove_circle_outline,
                      color: Colors.red.shade600),
                ),
                title: const Text('Ajouter une dépense',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Alimentation, santé, équipement...'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(field: field),
                    ),
                  ).then((_) => _loadDashboard());
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_circle_outline,
                      color: Colors.green.shade600),
                ),
                title: const Text('Ajouter un revenu',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Lait, cultures, services, subventions...'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRevenueScreen(field: field),
                    ),
                  ).then((_) => _loadDashboard());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodButton('month', 'Mois', Icons.calendar_today),
        _buildPeriodButton('quarter', 'Trimestre', Icons.date_range),
        _buildPeriodButton('year', 'Année', Icons.calendar_month),
      ],
    );
  }

  Widget _buildPeriodButton(String period, String label, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodChanged(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.mistyBlue : Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.mistyBlue : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetBalance(dashboard) {
    final isPositive = dashboard.netBalance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF059669).withOpacity(0.1)]
              : [const Color(0xFFEF4444).withOpacity(0.1), const Color(0xFFDC2626).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Symbols.trending_up : Symbols.trending_down,
                color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 28,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Solde Net',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${isPositive ? '+' : ''}${dashboard.netBalance.toStringAsFixed(2)} ${dashboard.currencySymbol}',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(dashboard) {
    return Consumer<FieldProvider>(
      builder: (context, fieldProvider, _) {
        final fieldName = fieldProvider.fields
            .firstWhere((f) => f.id == _selectedFieldId, orElse: () => fieldProvider.fields.first)
            .name;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF059669).withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Symbols.trending_up,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Revenus',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RevenuesDetailsScreen(
                            fieldId: _selectedFieldId!,
                            fieldName: fieldName ?? 'Champ',
                            field: fieldProvider.fields.firstWhere(
                              (f) => f.id == _selectedFieldId,
                              orElse: () => fieldProvider.fields.first,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text(
                            'Plus',
                            style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                           ),
                           SizedBox(width: 2),
                           Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF059669)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${dashboard.totalRevenue.toStringAsFixed(2)} ${dashboard.currencySymbol}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${dashboard.revenueByType.animalSales.count} animaux vendus',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesCard(dashboard) {
    return Consumer<FieldProvider>(
      builder: (context, fieldProvider, _) {
        final fieldName = fieldProvider.fields
            .firstWhere((f) => f.id == _selectedFieldId, orElse: () => fieldProvider.fields.first)
            .name;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFEF4444).withOpacity(0.1), const Color(0xFFDC2626).withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Symbols.trending_down,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Dépenses',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExpensesDetailsScreen(
                            fieldId: _selectedFieldId!,
                            fieldName: fieldName ?? 'Champ',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text(
                            'Plus',
                            style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                           ),
                           SizedBox(width: 2),
                           Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFDC2626)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${dashboard.totalExpenses.toStringAsFixed(2)} ${dashboard.currencySymbol}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${dashboard.expensesByCategory.length} catégories',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesByCategory(dashboard) {
    final categories = dashboard.expensesByCategory.entries.toList();
    categories.sort((a, b) {
      final aAmount = (a.value as dynamic).amount as double;
      final bAmount = (b.value as dynamic).amount as double;
      return bAmount.compareTo(aAmount);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final entry in categories) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExpenseBar(entry.key, entry.value, dashboard),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildExpenseBar(String category, expense, dashboard) {
    final percentage = expense.percentage / 100.0;
    final color = _getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryDisplayName(category),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            Text(
              '${expense.amount.toStringAsFixed(2)} ${dashboard.currencySymbol}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            '${expense.percentage}%',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'feed': Color(0xFF8B5CF6),
      'vet': Color(0xFFEF4444),
      'meds': Color(0xFF06B6D4),
      'equip': Color(0xFFF59E0B),
      'labor': Color(0xFF3B82F6),
      'other': Color(0xFF6B7280),
    };
    return colors[category] ?? const Color(0xFF9CA3AF);
  }

  Widget _buildTopCostlyAnimals(dashboard) {
    if (dashboard.topCostlyAnimals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.pets,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun animal trouvé',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final entry in dashboard.topCostlyAnimals.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.2),
                          const Color(0xFF1E40AF).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'ID: ${entry.value.animalId.substring(0, 8)}...',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.value.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                        dashboard.currencySymbol,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses(dashboard) {
    if (dashboard.recentExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.receipt,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune dépense',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final expense in dashboard.recentExpenses)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(expense.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Symbols.receipt,
                      color: _getCategoryColor(expense.category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryDisplayName(expense.category),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (expense.animalName != null)
                          Text(
                            'Pour ${expense.animalName}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${expense.amount.toStringAsFixed(2)} ${dashboard.currencySymbol}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _getCategoryColor(expense.category),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    const displayNames = {
      'feed': 'Alimentation',
      'vet': 'Vétérinaire',
      'meds': 'Médicaments',
      'equip': 'Équipement',
      'labor': 'Main d\'œuvre',
      'other': 'Autre',
    };
    return displayNames[category] ?? category;
  }
}