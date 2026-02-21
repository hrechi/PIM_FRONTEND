import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parcel_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

import '../models/parcel.dart';

class AddParcelScreen extends StatefulWidget {
  final Parcel? existingParcel;

  const AddParcelScreen({super.key, this.existingParcel});

  @override
  State<AddParcelScreen> createState() => _AddParcelScreenState();
}

class _AddParcelScreenState extends State<AddParcelScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1: Parcel
  final _locationController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _boundariesController = TextEditingController();

  // 2: Soil
  String _soilType = 'loam';
  final _soilPhController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();

  // 4: Irrigation
  String _waterSource = 'rain-fed';
  String _irrigationMethod = 'drip';
  final _irrigationFrequencyController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingParcel != null) {
      final p = widget.existingParcel!;
      _locationController.text = p.location;
      _areaSizeController.text = p.areaSize.toString();
      _boundariesController.text = p.boundariesDescription;
      _soilType = ['clay', 'sandy', 'loam', 'other'].contains(p.soilType) ? p.soilType : 'other';
      if (p.soilPh != null) _soilPhController.text = p.soilPh.toString();
      if (p.nitrogenLevel != null) _nitrogenController.text = p.nitrogenLevel.toString();
      if (p.phosphorusLevel != null) _phosphorusController.text = p.phosphorusLevel.toString();
      if (p.potassiumLevel != null) _potassiumController.text = p.potassiumLevel.toString();
      _waterSource = ['well', 'rain-fed', 'river', 'drip system'].contains(p.waterSource) ? p.waterSource : 'rain-fed';
      _irrigationMethod = ['drip', 'sprinkler', 'flood'].contains(p.irrigationMethod) ? p.irrigationMethod : 'drip';
      _irrigationFrequencyController.text = p.irrigationFrequency;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _areaSizeController.dispose();
    _boundariesController.dispose();
    _soilPhController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _irrigationFrequencyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final parcelData = {
        'location': _locationController.text,
        'areaSize': double.parse(_areaSizeController.text),
        'boundariesDescription': _boundariesController.text,
        'soilType': _soilType,
        'soilPh': _soilPhController.text.isNotEmpty ? double.parse(_soilPhController.text) : null,
        'nitrogenLevel': _nitrogenController.text.isNotEmpty ? double.parse(_nitrogenController.text) : null,
        'phosphorusLevel': _phosphorusController.text.isNotEmpty ? double.parse(_phosphorusController.text) : null,
        'potassiumLevel': _potassiumController.text.isNotEmpty ? double.parse(_potassiumController.text) : null,
        'waterSource': _waterSource,
        'irrigationMethod': _irrigationMethod,
        'irrigationFrequency': _irrigationFrequencyController.text,
      };

      final isEdit = widget.existingParcel != null;
      if (isEdit) {
        await Provider.of<ParcelProvider>(context, listen: false).updateParcel(widget.existingParcel!.id, parcelData);
      } else {
        await Provider.of<ParcelProvider>(context, listen: false).addParcel(parcelData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Parcel updated successfully!' : 'Parcel added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save parcel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool isRequired = false, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : (isMultiline ? TextInputType.multiline : TextInputType.text),
        maxLines: isMultiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ' (Optional)'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 2),
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) return 'Please enter $label';
                if (isNumber && double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              }
            : (value) {
                if (value != null && value.isNotEmpty && isNumber && double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
      ),
    );
  }

  Widget _buildDropdown(String label, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: '$label *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 2),
          ),
        ),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existingParcel != null ? 'Edit Parcel' : 'Add New Parcel', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.emeraldGreen),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('1. Parcel Details'),
                    _buildTextField(_locationController, 'Location', isRequired: true),
                    _buildTextField(_areaSizeController, 'Area Size (ha/m²)', isNumber: true, isRequired: true),
                    _buildTextField(_boundariesController, 'Boundaries Description', isMultiline: true, isRequired: true),

                    _buildSectionTitle('2. Soil Information'),
                    _buildDropdown('Soil Type', _soilType, ['clay', 'sandy', 'loam', 'other'], (val) => setState(() => _soilType = val!)),
                    _buildTextField(_soilPhController, 'Soil pH', isNumber: true),
                    _buildTextField(_nitrogenController, 'Nitrogen Level', isNumber: true),
                    _buildTextField(_phosphorusController, 'Phosphorus Level', isNumber: true),
                    _buildTextField(_potassiumController, 'Potassium Level', isNumber: true),

                    _buildSectionTitle('3. Irrigation'),
                    _buildDropdown('Water Source', _waterSource, ['well', 'rain-fed', 'river', 'drip system'], (val) => setState(() => _waterSource = val!)),
                    _buildDropdown('Irrigation Method', _irrigationMethod, ['drip', 'sprinkler', 'flood'], (val) => setState(() => _irrigationMethod = val!)),
                    _buildTextField(_irrigationFrequencyController, 'Irrigation Frequency (e.g. 2 times/week)', isRequired: true),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(widget.existingParcel != null ? 'Update Parcel' : 'Save Parcel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
