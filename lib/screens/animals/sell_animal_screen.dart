import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n_extensions.dart';
import '../../theme/app_colors.dart';
import 'animals_design.dart';

class SellAnimalScreen extends StatefulWidget {
  final Animal animal;
  const SellAnimalScreen({super.key, required this.animal});

  @override
  State<SellAnimalScreen> createState() => _SellAnimalScreenState();
}

class _SellAnimalScreenState extends State<SellAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _buyerController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _saleDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    _buyerController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final salePrice = double.tryParse(_priceController.text.trim());
      final saleWeight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text.trim())
          : null;
      if (salePrice == null) {
        throw const FormatException('Invalid sale price');
      }
      if (_weightController.text.isNotEmpty && saleWeight == null) {
        throw const FormatException('Invalid sale weight');
      }
      final payload = <String, dynamic>{
        'salePrice': salePrice,
        'saleDate': _saleDate.toIso8601String(),
        if (_buyerController.text.isNotEmpty) 'buyerName': _buyerController.text,
        if (saleWeight != null) 'saleWeightKg': saleWeight,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
      };
      await AnimalService().sellAnimal(widget.animal.nodeId, payload);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.animalSoldSuccess)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      appBar: AnimalsDesign.animalsAppBar(title: '${l.sellAnimal} — ${widget.animal.name}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AnimalsDesign.screenHorizontalPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _priceController,
                label: l.salePrice,
                icon: Symbols.payments,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.isEmpty ? l.distanceRequired : null,
              ),
              const SizedBox(height: 16),
              // Date picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _saleDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _saleDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Symbols.calendar_today, color: AppColors.mistyBlue, size: AnimalsDesign.inlineIconSize),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.saleDate, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(
                              DateFormat('dd MMM yyyy').format(_saleDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(controller: _buyerController, label: l.buyerName, icon: Symbols.person),
              const SizedBox(height: 16),
              _buildField(
                controller: _weightController,
                label: l.saleWeightKg,
                icon: Symbols.scale,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildField(controller: _notesController, label: l.notes, icon: Symbols.notes, maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: AnimalsDesign.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: AnimalsDesign.primaryButtonStyle(),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: FieldlyColors.primary)
                      : Text(l.confirmSale,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.mistyBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
