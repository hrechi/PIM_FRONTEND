import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../models/soil_measurement.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';
import 'location_picker_screen.dart';
import 'soil_measurements_list_screen.dart';

/// Screen for adding or editing soil measurements
/// Route: /soil/add or /soil/edit/:id
class SoilMeasurementFormScreen extends StatefulWidget {
  final SoilMeasurement? measurement; // null for add, populated for edit

  const SoilMeasurementFormScreen({
    super.key,
    this.measurement,
  });

  @override
  State<SoilMeasurementFormScreen> createState() =>
      _SoilMeasurementFormScreenState();
}

class _SoilMeasurementFormScreenState extends State<SoilMeasurementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phController = TextEditingController();
  final _moistureController = TextEditingController();
  final _sunlightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _selectedFieldId;
  List<FieldModel> _fields = [];
  bool _isLoadingFields = false;
  bool isEditing = false;
  bool isSaving = false;

  final FieldService _fieldService = FieldService();

  @override
  void initState() {
    super.initState();
    isEditing = widget.measurement != null;

    if (isEditing) {
      _populateFields(widget.measurement!);
    }
    
    _loadFields();
  }

  /// Load available fields from backend
  Future<void> _loadFields() async {
    setState(() {
      _isLoadingFields = true;
    });

    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _fields = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFields = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load fields: $e')),
        );
      }
    }
  }

  /// Populate form fields in edit mode
  void _populateFields(SoilMeasurement measurement) {
    _phController.text = measurement.ph.toString();
    _moistureController.text = measurement.soilMoisture.toString();
    _sunlightController.text = measurement.sunlight.toString();
    _temperatureController.text = measurement.temperature.toString();
    _latitude = measurement.latitude;
    _longitude = measurement.longitude;
    _selectedFieldId = measurement.fieldId;
    _nitrogenController.text = (measurement.nutrients['nitrogen'] ?? 0).toString();
    _phosphorusController.text = (measurement.nutrients['phosphorus'] ?? 0).toString();
    _potassiumController.text = (measurement.nutrients['potassium'] ?? 0).toString();
  }

  @override
  void dispose() {
    _phController.dispose();
    _moistureController.dispose();
    _sunlightController.dispose();
    _temperatureController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  /// Open map to pick location
  Future<void> _pickLocation() async {
    // Get selected field model if fieldId is set
    FieldModel? fieldModel;
    if (_selectedFieldId != null) {
      try {
        fieldModel = _fields.firstWhere((f) => f.id == _selectedFieldId);
      } catch (e) {
        // Field not found in list
      }
    }

    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          selectedField: fieldModel,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  /// Save measurement
  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: AppColorPalette.alertError,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final provider = context.read<SoilMeasurementsProvider>();
      bool success;

      final nutrients = {
        'nitrogen': double.parse(_nitrogenController.text),
        'phosphorus': double.parse(_phosphorusController.text),
        'potassium': double.parse(_potassiumController.text),
      };

      if (isEditing) {
        // Update existing measurement
        success = await provider.updateMeasurement(
          id: widget.measurement!.id,
          ph: double.parse(_phController.text),
          soilMoisture: double.parse(_moistureController.text),
          sunlight: double.parse(_sunlightController.text),
          nutrients: nutrients,
          temperature: double.parse(_temperatureController.text),
          latitude: _latitude!,
          longitude: _longitude!,
          fieldId: _selectedFieldId,
        );
      } else {
        // Create new measurement
        success = await provider.createMeasurement(
          ph: double.parse(_phController.text),
          soilMoisture: double.parse(_moistureController.text),
          sunlight: double.parse(_sunlightController.text),
          nutrients: nutrients,
          temperature: double.parse(_temperatureController.text),
          latitude: _latitude!,
          longitude: _longitude!,
          fieldId: _selectedFieldId,
        );
      }

      setState(() => isSaving = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Measurement updated successfully'
                    : 'Measurement saved successfully',
              ),
              backgroundColor: AppColorPalette.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          // Show error from provider
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to save measurement'),
              backgroundColor: AppColorPalette.alertError,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColorPalette.alertError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Measurement' : 'Add Measurement',
          style: AppTextStyles.h3(),
        ),
      ),
      body: Responsive.constrainedContent(
        context: context,
        maxWidth: 800,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(Responsive.cardPadding(context)),
            children: [
            // Header description
            Text(
              'Enter soil measurement data',
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.softSlate,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),

            // pH Section
            _SectionHeader(
              icon: Icons.science,
              title: 'pH Level',
              color: AppColorPalette.mistyBlue,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 14, desktop: 16)),
            _FormField(
              controller: _phController,
              label: 'pH Value',
              hint: 'Enter pH (0-14)',
              icon: Icons.science,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pH value';
                }
                final ph = double.tryParse(value);
                if (ph == null) {
                  return 'Please enter a valid number';
                }
                if (ph < 0 || ph > 14) {
                  return 'pH must be between 0 and 14';
                }
                return null;
              },
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),

            // Moisture Section
            _SectionHeader(
              icon: Icons.water_drop,
              title: 'Soil Moisture',
              color: AppColorPalette.info,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _moistureController,
              label: 'Moisture Percentage',
              hint: 'Enter moisture % (0-100)',
              icon: Icons.water_drop,
              suffix: '%',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter moisture percentage';
                }
                final moisture = double.tryParse(value);
                if (moisture == null) {
                  return 'Please enter a valid number';
                }
                if (moisture < 0 || moisture > 100) {
                  return 'Moisture must be between 0 and 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Sunlight Section
            _SectionHeader(
              icon: Icons.wb_sunny,
              title: 'Sunlight',
              color: AppColorPalette.warning,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _sunlightController,
              label: 'Sunlight Level',
              hint: 'Enter sunlight in lux',
              icon: Icons.wb_sunny,
              suffix: 'lux',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter sunlight level';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Temperature Section
            _SectionHeader(
              icon: Icons.thermostat,
              title: 'Temperature',
              color: AppColorPalette.alertError,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _temperatureController,
              label: 'Temperature',
              hint: 'Enter temperature',
              icon: Icons.thermostat,
              suffix: '°C',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter temperature';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Nutrients Section
            _SectionHeader(
              icon: Icons.grass,
              title: 'Nutrients (N-P-K)',
              color: AppColorPalette.success,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _nitrogenController,
                    label: 'Nitrogen',
                    hint: 'N',
                    suffix: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    controller: _phosphorusController,
                    label: 'Phosphorus',
                    hint: 'P',
                    suffix: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    controller: _potassiumController,
                    label: 'Potassium',
                    hint: 'K',
                    suffix: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Field Selection Section
            _SectionHeader(
              icon: Icons.landscape,
              title: 'Select Field',
              color: AppColorPalette.mistyBlue,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColorPalette.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorPalette.softSlate.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _isLoadingFields
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedFieldId,
                        hint: Text(
                          'Select a field (optional)',
                          style: AppTextStyles.bodyMedium(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: AppColorPalette.mistyBlue,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No field selected'),
                          ),
                          ..._fields.map((field) {
                            return DropdownMenuItem<String>(
                              value: field.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.landscape,
                                    size: 20,
                                    color: AppColorPalette.fieldFreshStart,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(field.name),
                                  ),
                                  if (field.areaSize != null)
                                    Text(
                                      '(${(field.areaSize! / 10000).toStringAsFixed(2)} ha)',
                                      style: AppTextStyles.caption(
                                        color: AppColorPalette.softSlate,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFieldId = value;
                          });
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Location Section
            _SectionHeader(
              icon: Icons.location_on,
              title: 'Location',
              color: AppColorPalette.sageTint,
            ),
            const SizedBox(height: 12),
            
            // Map picker button
            Container(
              decoration: BoxDecoration(
                color: AppColorPalette.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _latitude == null 
                      ? AppColorPalette.alertError.withOpacity(0.5)
                      : AppColorPalette.success.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickLocation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColorPalette.mistyBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.map,
                            color: AppColorPalette.mistyBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _latitude == null 
                                    ? 'Select Location from Map'
                                    : 'Location Selected',
                                style: AppTextStyles.bodyLarge().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_latitude != null && _longitude != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColorPalette.softSlate,
                                    ),
                                  ),
                                ),
                              if (_latitude == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Tap to open map and pick location',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColorPalette.softSlate,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          _latitude == null ? Icons.chevron_right : Icons.check_circle,
                          color: _latitude == null 
                              ? AppColorPalette.softSlate
                              : AppColorPalette.success,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: isSaving ? null : _saveMeasurement,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColorPalette.mistyBlue,
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColorPalette.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditing ? 'Update Measurement' : 'Save Measurement',
                      style: AppTextStyles.buttonLarge(),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ));
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.h4(),
        ),
      ],
    );
  }
}

/// Form field widget
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixText: suffix,
      ),
      validator: validator,
    );
  }
}
