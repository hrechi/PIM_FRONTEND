import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parcel_provider.dart';
import '../models/parcel.dart';

class AddParcelScreen extends StatefulWidget {
  final Parcel? existingParcel;

  const AddParcelScreen({super.key, this.existingParcel});

  @override
  State<AddParcelScreen> createState() => _AddParcelScreenState();
}

class _AddParcelScreenState extends State<AddParcelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _locationController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _boundariesController = TextEditingController();
  final _soilPhController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _irrigationFrequencyController = TextEditingController();

  String _soilType = 'loam';
  String _waterSource = 'rain-fed';
  String _irrigationMethod = 'drip';
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
          SnackBar(
            content: Text(isEdit ? 'Parcel updated successfully!' : 'Parcel added successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2ECC71),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save parcel: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1A4731);
    const accentGreen = Color(0xFF2ECC71);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        title: Text(
          widget.existingParcel != null ? 'Edit Parcel' : 'New Parcel',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Header
          Container(height: 100, color: primaryGreen),
          
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormCard(
                    title: 'Location & Area',
                    icon: Icons.map_rounded,
                    children: [
                      _buildField(
                        controller: _locationController,
                        label: 'Location Name',
                        hint: 'e.g. North Ridge Section',
                        icon: Icons.location_on_rounded,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _areaSizeController,
                        label: 'Area Size (ha)',
                        hint: 'e.g. 2.5',
                        icon: Icons.square_foot_rounded,
                        isRequired: true,
                        isNumber: true,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _boundariesController,
                        label: 'Boundaries Description',
                        hint: 'e.g. Near the main road access',
                        icon: Icons.border_outer_rounded,
                        isMultiline: true,
                        isRequired: true,
                      ),
                    ],
                  ),
                  
                  _buildFormCard(
                    title: 'Soil Composition',
                    icon: Icons.grass_rounded,
                    children: [
                      _buildDropdown(
                        label: 'Soil Type',
                        value: _soilType,
                        items: ['clay', 'sandy', 'loam', 'other'],
                        icon: Icons.terrain_rounded,
                        onChanged: (val) => setState(() => _soilType = val!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _soilPhController,
                              label: 'Soil pH',
                              hint: 'e.g. 6.5',
                              icon: Icons.science_rounded,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _nitrogenController,
                              label: 'Nitrogen (N)',
                              hint: 'e.g. 40',
                              icon: Icons.opacity_rounded,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _phosphorusController,
                              label: 'Phosphorus (P)',
                              hint: 'e.g. 25',
                              icon: Icons.opacity_rounded,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _potassiumController,
                              label: 'Potassium (K)',
                              hint: 'e.g. 30',
                              icon: Icons.opacity_rounded,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  _buildFormCard(
                    title: 'Water & Irrigation',
                    icon: Icons.water_drop_rounded,
                    children: [
                      _buildDropdown(
                        label: 'Water Source',
                        value: _waterSource,
                        items: ['well', 'rain-fed', 'river', 'drip system'],
                        icon: Icons.waves_rounded,
                        onChanged: (val) => setState(() => _waterSource = val!),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Irrigation Method',
                        value: _irrigationMethod,
                        items: ['drip', 'sprinkler', 'flood'],
                        icon: Icons.shower_rounded,
                        onChanged: (val) => setState(() => _irrigationMethod = val!),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _irrigationFrequencyController,
                        label: 'Irrigation Frequency',
                        hint: 'e.g. Twice weekly',
                        icon: Icons.update_rounded,
                        isRequired: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: accentGreen)),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            widget.existingParcel != null ? 'Update Changes' : 'Create Parcel',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2ECC71), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A4731)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    bool isRequired = false,
    bool isMultiline = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : (isMultiline ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiline ? 3 : 1,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A4731)),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) return 'This field is required';
        if (isNumber && value != null && value.isNotEmpty && double.tryParse(value) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }
}
