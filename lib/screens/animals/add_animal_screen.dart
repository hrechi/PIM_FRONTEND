import 'package:flutter/material.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnimalService _animalService = AnimalService();
  
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _tagController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = AppConstants.animalTypes.first;
  String _selectedSex = AppConstants.sexOptions.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final animalData = {
        'name': _nameController.text,
        'animalType': _selectedType,
        'breed': _breedController.text,
        'age': int.parse(_ageController.text),
        'sex': _selectedSex,
        'tagNumber': _tagController.text,
        'notes': _notesController.text,
      };

      await _animalService.createAnimal(animalData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Animal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Animal Registry',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the details of your new livestock to start tracking.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              
              CustomTextField(
                controller: _nameController,
                labelText: 'Animal Name',
                hintText: 'e.g. Bessie',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildDropdown(
                label: 'Animal Type',
                value: _selectedType,
                items: AppConstants.animalTypes,
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _breedController,
                labelText: 'Breed',
                hintText: 'e.g. Holstein',
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      labelText: 'Age (Months)',
                      hintText: 'e.g. 24',
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Sex',
                      value: _selectedSex,
                      items: AppConstants.sexOptions,
                      onChanged: (val) => setState(() => _selectedSex = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _tagController,
                labelText: 'Tag Number',
                hintText: 'e.g. RF-452',
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes',
                hintText: 'Any special observations...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              CustomButton(
                text: 'Register Animal',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withAlpha(51)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
