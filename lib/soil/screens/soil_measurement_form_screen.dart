import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/responsive.dart';
import '../models/soil_measurement.dart';

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();

  bool isEditing = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.measurement != null;

    if (isEditing) {
      _populateFields(widget.measurement!);
    }
  }

  /// Populate form fields in edit mode
  void _populateFields(SoilMeasurement measurement) {
    _phController.text = measurement.ph.toString();
    _moistureController.text = measurement.soilMoisture.toString();
    _sunlightController.text = measurement.sunlight.toString();
    _temperatureController.text = measurement.temperature.toString();
    _latitudeController.text = measurement.latitude.toString();
    _longitudeController.text = measurement.longitude.toString();
    _nitrogenController.text = (measurement.nutrients['N'] ?? 0).toString();
    _phosphorusController.text = (measurement.nutrients['P'] ?? 0).toString();
    _potassiumController.text = (measurement.nutrients['K'] ?? 0).toString();
  }

  @override
  void dispose() {
    _phController.dispose();
    _moistureController.dispose();
    _sunlightController.dispose();
    _temperatureController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  /// Save measurement
  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSaving = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // In production, save to backend
    final newMeasurement = SoilMeasurement(
      idMesure: isEditing
          ? widget.measurement!.idMesure
          : 'SM-${DateTime.now().millisecondsSinceEpoch}',
      ph: double.parse(_phController.text),
      soilMoisture: double.parse(_moistureController.text),
      sunlight: double.parse(_sunlightController.text),
      nutrients: {
        'N': double.parse(_nitrogenController.text),
        'P': double.parse(_phosphorusController.text),
        'K': double.parse(_potassiumController.text),
      },
      temperature: double.parse(_temperatureController.text),
      latitude: double.parse(_latitudeController.text),
      longitude: double.parse(_longitudeController.text),
      createdAt: isEditing ? widget.measurement!.createdAt : DateTime.now(),
    );

    setState(() => isSaving = false);

    if (mounted) {
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

      Navigator.pop(context, true); // Return true to indicate success
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

            // Location Section
            _SectionHeader(
              icon: Icons.location_on,
              title: 'Location',
              color: AppColorPalette.sageTint,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _latitudeController,
              label: 'Latitude',
              hint: 'Enter latitude',
              icon: Icons.location_on,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter latitude';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _longitudeController,
              label: 'Longitude',
              hint: 'Enter longitude',
              icon: Icons.location_on,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter longitude';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
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
