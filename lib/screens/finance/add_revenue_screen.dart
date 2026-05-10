/// ============================================================
/// ADD REVENUE SCREEN — Formulaire d'ajout de revenu manuel
/// ============================================================
///
/// Cet écran permet à l'agriculteur d'enregistrer un revenu
/// qui ne provient pas d'une vente d'animal (ex: lait, cultures,
/// services rendus, subventions reçues).
///
/// Champs du formulaire :
///   • Montant    → Valeur numérique avec symbole de devise
///   • Catégorie  → Sélection visuelle parmi 5 catégories colorées
///   • Date       → DatePicker (par défaut : aujourd'hui)
///   • Description → Texte libre optionnel (max 200 caractères)
///
/// Catégories disponibles :
///   💧 Lait (milk)          → Vente de lait à la coopérative
///   🌿 Cultures (crops)     → Vente de blé, orge, légumes…
///   🔧 Services (services)  → Prestations (labour, transport…)
///   🏛️ Subventions          → Aides APIA, CRDA, PAC…
///   ➕ Autre (other)        → Revenus non catégorisés
///
/// Après soumission :
///   → POST /revenues (RevenueService)
///   → Retour à RevenuesDetailsScreen avec refresh automatique
///
/// Accessible depuis :
///   • FinanceDashboardScreen (FAB → menu → "Ajouter un revenu")
///   • RevenuesDetailsScreen (FAB "Ajouter un revenu")
/// ============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/field_model.dart';
import '../../services/revenue_service.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n_extensions.dart';

class AddRevenueScreen extends StatefulWidget {
  final FieldModel field;
  const AddRevenueScreen({super.key, required this.field});

  @override
  State<AddRevenueScreen> createState() => _AddRevenueScreenState();
}

class _AddRevenueScreenState extends State<AddRevenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'milk';
  bool _isLoading = false;
  String _currencySymbol = 'DT';

  // Categories with icons and l10n keys
  late List<Map<String, dynamic>> _categories;

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categories = [
      {
        'id': 'milk',
        'label': context.l10n.revenueCategoryMilk,
        'icon': Symbols.water_drop,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'crops',
        'label': context.l10n.revenueCategoryCrops,
        'icon': Symbols.grass,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'services',
        'label': context.l10n.revenueCategoryServices,
        'icon': Symbols.handyman,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'subsidies',
        'label': context.l10n.revenueCategorySubsidies,
        'icon': Symbols.account_balance,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'other',
        'label': context.l10n.other,
        'icon': Symbols.more_horiz,
        'color': const Color(0xFF6B7280),
      },
    ];
  }

  Future<void> _loadUserCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        final sym = userJson['currencySymbol'] as String?;
        if (sym != null && mounted) setState(() => _currencySymbol = sym);
      } catch (_) {}
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await RevenueService.createRevenue({
        'fieldId': widget.field.id,
        'amount': double.parse(_amountController.text.replaceAll(',', '.')),
        'category': _selectedCategory,
        'date': _selectedDate.toIso8601String(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.revenueAddedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.last,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addRevenue),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Symbols.landscape,
                        color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.field.name ?? context.l10n.selectField,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              Text(
                context.l10n.amount,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Symbols.attach_money),
                  suffixText: _currencySymbol,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return context.l10n.amountRequired;
                  }
                  final val = double.tryParse(v.replaceAll(',', '.'));
                  if (val == null || val <= 0) {
                    return context.l10n.enterValidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              Text(
                context.l10n.category,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  final color = cat['color'] as Color;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date
              Text(
                context.l10n.date,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Symbols.calendar_today,
                          size: 20, color: Color(0xFF6B7280)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                context.l10n.revenueDescription,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: context.l10n.revenueDescriptionHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(selectedCat['icon'] as IconData, size: 20),
                  label: Text(
                    _isLoading
                        ? context.l10n.loading
                        : context.l10n.addRevenue,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
