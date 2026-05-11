import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/animal.dart';
import '../../models/field_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/animal_service.dart';
import '../../services/expense_service.dart';
import '../../services/field_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AddExpenseScreen extends StatefulWidget {
  final FieldModel field;
  const AddExpenseScreen({super.key, required this.field});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'feed';
  String? _selectedAnimalId;
  Animal? _selectedAnimal;
  File? _receiptImage;
  bool _isLoading = false;
  bool _isLoadingAnimals = false;
  bool _isUploadingReceipt = false;
  String? _receiptUrl;
  String? _animalsError;
  List<Animal> _animals = [];
  String _currencySymbol = '\$'; // Default to USD

  final List<Map<String, dynamic>> _categories = [
    {'id': 'feed',  'label': 'Alimentation',  'icon': Symbols.grass},
    {'id': 'vet',   'label': 'Santé',         'icon': Symbols.medical_services},
    {'id': 'equip', 'label': 'Équipement',    'icon': Symbols.handyman},
    {'id': 'meds',  'label': 'Bâtiment',      'icon': Symbols.foundation},
    {'id': 'labor', 'label': "Main d'œuvre",  'icon': Symbols.groups},
    {'id': 'other', 'label': 'Autre',         'icon': Symbols.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
    _loadLastCategory();
    _loadUserCurrency();
  }

  Future<void> _loadLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCat = prefs.getString('last_expense_category');
    if (lastCat != null && mounted) {
      setState(() => _selectedCategory = lastCat);
    }
  }

  Future<void> _loadUserCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        final currencySymbol = userJson['currencySymbol'] as String?;
        if (currencySymbol != null && mounted) {
          setState(() => _currencySymbol = currencySymbol);
        }
      } catch (e) {
        // Keep default currency symbol
      }
    }
  }

  Future<void> _fetchAnimals() async {
    setState(() {
      _isLoadingAnimals = true;
      _animalsError = null;
    });
    try {
      final animals = await AnimalService().getAnimals(fieldId: widget.field.id);
      if (mounted) {
        setState(() {
          _animals = animals;
          _isLoadingAnimals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _animalsError = 'Erreur lors de la récupération des animaux';
          _isLoadingAnimals = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Symbols.camera_alt, color: AppColors.mistBlue),
              title: const Text('Prendre une photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Symbols.photo_library, color: AppColors.mistBlue),
              title: const Text('Choisir depuis la galerie',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _receiptImage = File(picked.path);
      _isUploadingReceipt = true;
    });

    try {
      final result = await ApiService.uploadFile(
        '/expenses/upload-receipt',
        picked.path,
        fieldName: 'file',
      );
      // Store the returned URL for submission
      _receiptUrl = result['receiptUrl'] as String?;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur upload: $e"), backgroundColor: Colors.red),
        );
        setState(() => _receiptImage = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingReceipt = false);
    }
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'fieldId': widget.field.id,
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'date': _selectedDate.toIso8601String(),
        'animalId': _selectedAnimalId,
        'notes': _notesController.text,
        'receiptUrl': _receiptUrl,
      };

      await ExpenseService.createExpense(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_expense_category', _selectedCategory);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dépense enregistrée !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      appBar: AppBar(
        backgroundColor: AppColors.wheatWarmClay,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.close, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter une dépense',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text(
              'Enregistrer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountSection(),
            const SizedBox(height: 32),
            _buildCategorySection(),
            const SizedBox(height: 32),
            _buildDateAndAnimalSection(),
            const SizedBox(height: 32),
            _buildNotesAndPhotoSection(),
            const SizedBox(height: 24),
            _buildIntelligentPrompts(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MONTANT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _currencySymbol,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Color(0xFFE2E8F0)),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATÉGORIE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat['id'] as String;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedCategory = cat['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.mistyBlue
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.mistyBlue
                        : const Color(0xFFF1F5F9),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateAndAnimalSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Symbols.calendar_month,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('d MMMM y').format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
              const Text(
                'ANIMAL (OPTIONNEL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showAnimalPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Symbols.pets,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAnimal?.name ?? 'Sélectionner...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedAnimal != null
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesAndPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTE & JUSTIFICATIF',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _notesController,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: 'Ex: Foin livraison semaine 12',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: _isUploadingReceipt ? null : _pickReceipt,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _receiptImage != null
                            ? Colors.transparent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: _isUploadingReceipt
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.mistBlue,
                              ),
                            )
                          : _receiptImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    _receiptImage!,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                  ),
                                )
                              : const Icon(
                                  Symbols.camera_alt,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _receiptImage != null
                              ? 'Reçu ajouté ✓'
                              : 'Ajouter une photo du reçu',
                          style: TextStyle(
                            color: _receiptImage != null
                                ? AppColors.mistBlue
                                : const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_receiptImage != null)
                          GestureDetector(
                            onTap: () => setState(() {
                              _receiptImage = null;
                              _receiptUrl = null;
                            }),
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntelligentPrompts() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final showSmallPrompt =
        amount > 500 && (_notesController.text.isEmpty && _receiptImage == null);
    final showAnimalPrompt =
        _selectedCategory == 'vet' && _selectedAnimalId == null;

    if (!showSmallPrompt && !showAnimalPrompt) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Column(
        children: [
          if (showSmallPrompt)
            _buildPromptItem(
              Symbols.lightbulb,
              'Dépense importante ! Pensez à ajouter une note ou une photo.',
            ),
          if (showSmallPrompt && showAnimalPrompt) const SizedBox(height: 12),
          if (showAnimalPrompt)
            _buildPromptItem(
              Symbols.pets,
              'Pour quel animal est cette dépense de santé ?',
              onTap: _showAnimalPicker,
            ),
        ],
      ),
    );
  }

  Widget _buildPromptItem(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onTap != null)
            const Icon(Symbols.chevron_right, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  void _showAnimalPicker() {
    if (_animalsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_animalsError!),
          action: SnackBarAction(label: 'Réessayer', onPressed: _fetchAnimals),
        ),
      );
      return;
    }
    if (_isLoadingAnimals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des animaux...')),
      );
      return;
    }
    if (_animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun animal trouvé pour ce champ')),
      );
      return;
    }

    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _animals.where((a) {
            return a.name.toLowerCase().contains(query.toLowerCase()) ||
                (a.tagNumber?.toLowerCase().contains(query.toLowerCase()) ??
                    false);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Text(
                        'Concernant quel animal ?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Symbols.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      decoration: const InputDecoration(
                        hintText: 'Chercher par nom ou Tag ID...',
                        border: InputBorder.none,
                        icon: Icon(Symbols.search),
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        query.isEmpty
                            ? 'Aucun animal trouvé'
                            : 'Aucun résultat pour "$query"',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedAnimalId = a.id;
                              _selectedAnimal = a;
                            });
                            Navigator.pop(context);
                          },
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.mistyBlue.withValues(alpha: 0.1),
                            child: Text(
                              a.name.isNotEmpty
                                  ? a.name[0].toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(color: AppColors.mistyBlue),
                            ),
                          ),
                          title: Text(
                            a.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(a.tagNumber ?? a.nodeId),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
