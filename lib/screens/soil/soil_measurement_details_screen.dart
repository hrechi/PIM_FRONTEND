import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../models/soil_measurement.dart' as soil_models;
import '../../models/field_model.dart';
import '../../widgets/soil/status_badge.dart';
import '../../widgets/soil/soil_metric_card.dart';
import '../../services/field_service.dart';
import '../../services/soil_crop_analysis_service.dart';
import '../../services/parcel_crud_service.dart';
import '../../models/crop_suitability.dart';
import '../../models/parcel.dart';
import 'soil_measurement_form_screen.dart';
import 'soil_measurements_list_screen.dart';

/// Screen displaying detailed information about a soil measurement
/// Route: /soil/:id
class SoilMeasurementDetailsScreen extends StatefulWidget {
  final soil_models.SoilMeasurement measurement;

  const SoilMeasurementDetailsScreen({
    super.key,
    required this.measurement,
  });

  @override
  State<SoilMeasurementDetailsScreen> createState() =>
      _SoilMeasurementDetailsScreenState();
}

class _SoilMeasurementDetailsScreenState
    extends State<SoilMeasurementDetailsScreen> {
  late soil_models.SoilMeasurement measurement;
  FieldModel? _field;
  bool _isLoadingField = false;
  final FieldService _fieldService = FieldService();
  
  // Plant recommendation state (REPLACED WITH ML)
  // PlantRecommendations? _plantRecommendations;
  
  // Parcel selection state
  List<Parcel> _parcels = [];
  Parcel? _selectedParcel;
  bool _isLoadingParcels = false;
  final ParcelCrudService _parcelService = ParcelCrudService();
  
  // ML Crop analysis state (from parcels)
  bool _isLoadingCropAnalysis = false;
  CropAnalysisResult? _cropAnalysisResult;
  String? _cropAnalysisError;
  
  // ML Crop recommendations state
  bool _isLoadingMLRecommendations = false;
  MLCropRecommendations? _mlRecommendations;
  String? _mlRecommendationsError;
  
  /// Helper method to get nutrient value with fallback for different key formats
  /// Tries uppercase (N, P, K) first, then lowercase (nitrogen, phosphorus, potassium)
  double _getNutrientValue(String nutrientType) {
    final nutrients = measurement.nutrients;
    
    switch (nutrientType.toLowerCase()) {
      case 'n':
      case 'nitrogen':
        // Try uppercase first, then lowercase, then default to 0
        final value = (nutrients['N'] ?? nutrients['nitrogen'] ?? 0) as num?;
        return value?.toDouble() ?? 0.0;
      case 'p':
      case 'phosphorus':
        final value = (nutrients['P'] ?? nutrients['phosphorus'] ?? 0) as num?;
        return value?.toDouble() ?? 0.0;
      case 'k':
      case 'potassium':
        final value = (nutrients['K'] ?? nutrients['potassium'] ?? 0) as num?;
        return value?.toDouble() ?? 0.0;
      default:
        return 0.0;
    }
  }
  
  /// Load all parcels for selection
  Future<void> _loadParcels() async {
    setState(() => _isLoadingParcels = true);
    try {
      final parcels = await _parcelService.getParcels();
      if (mounted) {
        setState(() {
          _parcels = parcels;
          // Auto-select first parcel with crops if available
          if (parcels.isNotEmpty) {
            _selectedParcel = parcels.firstWhere(
              (p) => p.crops.isNotEmpty,
              orElse: () => parcels.first,
            );
          }
          _isLoadingParcels = false;
        });
        // Load crop analysis with selected parcel
        if (_selectedParcel != null) {
          _loadCropAnalysisAndRecommendations();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingParcels = false;
          _cropAnalysisError = 'Failed to load parcels: ${e.toString()}';
        });
      }
    }
  }
  
  /// Load field data if measurement is linked to a field
  Future<void> _loadField() async {
    setState(() => _isLoadingField = true);
    try {
      final fields = await _fieldService.getFields();
      final field = fields.firstWhere(
        (f) => f.id == measurement.fieldId,
        orElse: () => throw Exception('Field not found'),
      );
      if (mounted) {
        setState(() {
          _field = field;
          _isLoadingField = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingField = false);
      }
    }
  }

  /// Get display title for the measurement
  String get _displayTitle {
    if (measurement.fieldId != null && _field != null) {
      return _field!.name;
    }
    return 'Soil Measurement';
  }

  /// Navigate to edit screen
  Future<void> _editMeasurement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<SoilMeasurementsProvider>(),
          child: SoilMeasurementFormScreen(
            measurement: measurement,
          ),
        ),
      ),
    );

    // Reload if measurement was edited
    if (result == true && mounted) {
      // Get updated measurement from provider
      final provider = context.read<SoilMeasurementsProvider>();
      final updated = provider.measurements.firstWhere(
        (m) => m.id == measurement.id,
        orElse: () => measurement,
      );
      setState(() {
        measurement = updated;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Measurement updated'),
          backgroundColor: AppColorPalette.success,
        ),
      );
    }
  }
  /// Analyze soil health based on current measurement
  @override
  void initState() {
    super.initState();
    measurement = widget.measurement;
    // Load field data if measurement is linked to a field
    if (measurement.fieldId != null) {
      _loadField();
    }
    
    // Load parcels first, then analysis
    _loadParcels();
    _loadMLCropRecommendations();
  }

  /// Load ML-based crop recommendations
  Future<void> _loadMLCropRecommendations() async {
    setState(() {
      _isLoadingMLRecommendations = true;
      _mlRecommendationsError = null;
    });

    try {
      // Get soil measurement data using helper method that handles different key formats
      final nitrogen = _getNutrientValue('N');
      final phosphorus = _getNutrientValue('P');
      final potassium = _getNutrientValue('K');
      
      // Get ML recommendations
      final recommendations = await SoilCropAnalysisService.getMLCropRecommendations(
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        ph: measurement.ph,
        temperature: measurement.temperature,
        humidity: measurement.soilMoisture,
        rainfall: 200.0,
      );
      
      if (mounted) {
        setState(() {
          _mlRecommendations = recommendations;
          _isLoadingMLRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mlRecommendationsError = e.toString();
          _isLoadingMLRecommendations = false;
        });
      }
    }
  }

  /// Load ML-based crop analysis and generate filtered plant recommendations
  Future<void> _loadCropAnalysisAndRecommendations() async {
    // Don't load if no parcel is selected
    if (_selectedParcel == null) {
      return;
    }
    
    setState(() {
      _isLoadingCropAnalysis = true;
      _cropAnalysisError = null;
    });

    try {
      // Get soil measurement data using helper method that handles different key formats
      final nitrogen = _getNutrientValue('N');
      final phosphorus = _getNutrientValue('P');
      final potassium = _getNutrientValue('K');
      
      // Analyze crops using ML for the selected parcel
      final result = await SoilCropAnalysisService.analyzeCropsForSoilMeasurement(
        parcelId: _selectedParcel!.id, // Pass selected parcel ID
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        ph: measurement.ph,
        temperature: measurement.temperature,
        humidity: measurement.soilMoisture, // Using soil moisture as humidity proxy
        rainfall: 200, // Default rainfall value
      );
      
      if (mounted) {
        setState(() {
          _cropAnalysisResult = result;
          _isLoadingCropAnalysis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cropAnalysisError = e.toString();
          _isLoadingCropAnalysis = false;
        });
      }
    }
  }

  /// Delete measurement
  Future<void> _deleteMeasurement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: Text(
          'Are you sure you want to delete this measurement? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorPalette.alertError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SoilMeasurementsProvider>();
      final success = await provider.deleteMeasurement(measurement.id);
      
      if (success && mounted) {
        Navigator.pop(context, 'deleted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Measurement deleted successfully'),
            backgroundColor: AppColorPalette.success,
          ),
        );
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
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
          _isLoadingField ? 'Loading...' : _displayTitle,
          style: AppTextStyles.h3(),
        ),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editMeasurement,
            tooltip: 'Edit',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteMeasurement,
            color: AppColorPalette.alertError,
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Responsive.constrainedContent(
        context: context,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.cardPadding(context)),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card - Overall Status
            _buildHeaderCard(),

            const SizedBox(height: 16),

            // Status Badges Section
            _buildStatusBadges(),

            const SizedBox(height: 24),

            // Metrics Grid
            _buildMetricsGrid(),

            const SizedBox(height: 24),

            // Soil Health Analysis Section
            _buildSoilHealthAnalysisSection(),

            const SizedBox(height: 24),

            // ML Crop Analysis Section (from parcels)
            _buildMLCropAnalysisSection(),

            const SizedBox(height: 24),

            // Plant Recommendations Section (What you can grow)
            _buildPlantRecommendationsSection(),

            const SizedBox(height: 24),

            // Nutrients Section
            _buildNutrientsSection(),

            const SizedBox(height: 24),

            // Location Section
            _buildLocationSection(),

            const SizedBox(height: 24),

            // Metadata Section
            _buildMetadataSection(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    ));
  }

  /// Build soil health analysis section
  Widget _buildSoilHealthAnalysisSection() {
    // Get nutrients using helper method that handles different key formats
    final nitrogen = _getNutrientValue('N');
    final phosphorus = _getNutrientValue('P');
    final potassium = _getNutrientValue('K');

    // Analyze nutrient deficiencies
    final nitrogenStatus = nitrogen < 20 ? 'Low' : nitrogen < 40 ? 'Moderate' : 'Adequate';
    final phosphorusStatus = phosphorus < 15 ? 'Low' : phosphorus < 30 ? 'Moderate' : 'Adequate';
    final potassiumStatus = potassium < 20 ? 'Low' : potassium < 40 ? 'Moderate' : 'Adequate';
    
    final hasDeficiencies = nitrogenStatus == 'Low' || phosphorusStatus == 'Low' || potassiumStatus == 'Low';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: measurement.isHealthy
                      ? AppColorPalette.success.withValues(alpha: 0.1)
                      : AppColorPalette.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  measurement.isHealthy ? Icons.eco : Icons.report_problem,
                  size: 20,
                  color: measurement.isHealthy ? AppColorPalette.success : AppColorPalette.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Soil Health Analysis',
                  style: AppTextStyles.h4(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getHealthScoreColor(measurement.healthScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${measurement.healthScore.toStringAsFixed(0)}%',
                  style: AppTextStyles.bodyMedium(
                    color: _getHealthScoreColor(measurement.healthScore),
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Nutrient Status
          Text(
            'Nutrient Levels',
            style: AppTextStyles.bodyMedium().copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          _buildNutrientBar('Nitrogen (N)', nitrogen, nitrogenStatus, 60),
          const SizedBox(height: 8),
          _buildNutrientBar('Phosphorus (P)', phosphorus, phosphorusStatus, 50),
          const SizedBox(height: 8),
          _buildNutrientBar('Potassium (K)', potassium, potassiumStatus, 60),
          
          const SizedBox(height: 20),

          // Soil Issues
          if (!measurement.isHealthy || hasDeficiencies) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColorPalette.alertError.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorPalette.alertError.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: AppColorPalette.alertError,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Soil Health Issues',
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColorPalette.alertError,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._getSoilIssues().map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: AppColorPalette.alertError)),
                        Expanded(
                          child: Text(
                            issue,
                            style: AppTextStyles.bodySmall(),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build nutrient level bar
  Widget _buildNutrientBar(String name, double value, String status, double maxValue) {
    Color statusColor;
    if (status == 'Adequate') {
      statusColor = AppColorPalette.success;
    } else if (status == 'Moderate') {
      statusColor = AppColorPalette.warning;
    } else {
      statusColor = AppColorPalette.alertError;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTextStyles.bodySmall().copyWith(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall().copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  ' mg/kg',
                  style: AppTextStyles.caption(color: AppColorPalette.softSlate),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.caption(color: statusColor).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColorPalette.softSlate.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / maxValue).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Get list of soil issues
  List<String> _getSoilIssues() {
    final issues = <String>[];
    
    // pH issues
    if (measurement.ph < 5.5) {
      issues.add('Soil is too acidic (pH ${measurement.ph.toStringAsFixed(1)}). This can lock up nutrients and harm plant roots.');
    } else if (measurement.ph > 8.0) {
      issues.add('Soil is too alkaline (pH ${measurement.ph.toStringAsFixed(1)}). This can reduce nutrient availability.');
    }
    
    // Moisture issues
    if (measurement.soilMoisture < 20) {
      issues.add('Soil is too dry (${measurement.soilMoisture.toStringAsFixed(0)}% moisture). Plants will struggle to absorb nutrients.');
    } else if (measurement.soilMoisture > 80) {
      issues.add('Soil is waterlogged (${measurement.soilMoisture.toStringAsFixed(0)}% moisture). This can cause root rot.');
    }
    
    // Temperature issues
    if (measurement.temperature < 10) {
      issues.add('Soil temperature too cold (${measurement.temperature.toStringAsFixed(1)}°C). Plant growth will be severely stunted.');
    } else if (measurement.temperature > 35) {
      issues.add('Soil temperature too hot (${measurement.temperature.toStringAsFixed(1)}°C). Can damage plant roots and reduce growth.');
    }
    
    // Nutrient issues using helper method that handles different key formats
    final nitrogen = _getNutrientValue('N');
    final phosphorus = _getNutrientValue('P');
    final potassium = _getNutrientValue('K');
    
    if (nitrogen < 20) {
      issues.add('Low nitrogen (${nitrogen.toStringAsFixed(0)} mg/kg). Plants will have yellow leaves and poor growth.');
    }
    if (phosphorus < 15) {
      issues.add('Low phosphorus (${phosphorus.toStringAsFixed(0)} mg/kg). Root development and flowering will be poor.');
    }
    if (potassium < 20) {
      issues.add('Low potassium (${potassium.toStringAsFixed(0)} mg/kg). Plants will be weak and susceptible to disease.');
    }
    
    if (issues.isEmpty) {
      issues.add('No major issues detected. Soil is in good condition.');
    }
   
    return issues;
  }

  /// Get soil improvement recommendations
  /// Build ML crop analysis section (from farmer's parcels)
  Widget _buildMLCropAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: AppColorPalette.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Crops Analysis (ML-Based)',
                  style: AppTextStyles.h4(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Analysis of crops from your parcels based on these soil conditions',
            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
          ),
          const SizedBox(height: 16),
          
          // Parcel selector dropdown
          if (_parcels.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColorPalette.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorPalette.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: AppColorPalette.info),
                  const SizedBox(width: 8),
                  Text(
                    'Select Parcel:',
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColorPalette.charcoalGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedParcel?.id,
                        isExpanded: true,
                        hint: Text(
                          'Choose a parcel',
                          style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: AppColorPalette.info),
                        style: AppTextStyles.bodyMedium(),
                        items: _parcels.map((parcel) {
                          return DropdownMenuItem<String>(
                            value: parcel.id,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${parcel.location} (${parcel.crops.length} crops)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedParcel = _parcels.firstWhere((p) => p.id == newValue);
                            });
                            // Reload analysis with new parcel
                            _loadCropAnalysisAndRecommendations();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (_parcels.isNotEmpty)
            const SizedBox(height: 16),

          // Loading state
          if (_isLoadingCropAnalysis || _isLoadingParcels)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColorPalette.info),
                    const SizedBox(height: 12),
                    Text(
                      _isLoadingParcels ? 'Loading parcels...' : 'Analyzing your crops...',
                      style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
                    ),
                  ],
                ),
              ),
            )

          // Error state
          else if (_cropAnalysisError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorPalette.alertError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColorPalette.alertError),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to analyze crops: $_cropAnalysisError',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ),
                ],
              ),
            )
          
          // No parcels state
          else if (_parcels.isEmpty && !_isLoadingParcels)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorPalette.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColorPalette.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No parcels found. Create a parcel and add crops to see ML analysis.',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ),
                ],
              ),
            )

          // No crops state
          else if (_cropAnalysisResult != null && !_cropAnalysisResult!.hasCrops)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorPalette.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColorPalette.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No crops found in your parcels. Add crops to your parcels to see ML analysis.',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ),
                ],
              ),
            )

          // Results
          else if (_cropAnalysisResult != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crops you CAN plant
                if (_cropAnalysisResult!.cropsCanPlant.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColorPalette.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You CAN Plant (${_cropAnalysisResult!.cropsCanPlant.length})',
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColorPalette.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._cropAnalysisResult!.cropsCanPlant.map((crop) => _buildCropAnalysisCard(crop)),
                  const SizedBox(height: 16),
                ],

                // Crops that NEED improvement
                if (_cropAnalysisResult!.cropsNeedImprovement.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColorPalette.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Need Soil Improvement (${_cropAnalysisResult!.cropsNeedImprovement.length})',
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColorPalette.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._cropAnalysisResult!.cropsNeedImprovement.map((crop) => _buildCropAnalysisCard(crop)),
                  const SizedBox(height: 16),
                ],

                // Crops you CANNOT plant
                if (_cropAnalysisResult!.cropsCannotPlant.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.cancel, color: AppColorPalette.alertError, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You CANNOT Plant (${_cropAnalysisResult!.cropsCannotPlant.length})',
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColorPalette.alertError,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._cropAnalysisResult!.cropsCannotPlant.map((crop) => _buildCropAnalysisCard(crop)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// Build individual crop analysis card
  Widget _buildCropAnalysisCard(CropAnalysisItem crop) {
    Color decisionColor;
    
    switch (crop.decision) {
      case CropDecision.canPlant:
        decisionColor = AppColorPalette.success;
        break;
      case CropDecision.canPlantWithImprovement:
        decisionColor = AppColorPalette.warning;
        break;
      case CropDecision.cannotPlant:
        decisionColor = AppColorPalette.alertError;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: decisionColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: decisionColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop name and decision
          Row(
            children: [
              Icon(Icons.spa, color: decisionColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  crop.crop.toUpperCase(),
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.bold,
                    color: decisionColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: decisionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${crop.suitabilityScore.toStringAsFixed(0)}%',
                  style: AppTextStyles.caption(color: decisionColor).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // Recommendations
          if (crop.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...crop.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: decisionColor, fontSize: 12)),
                  Expanded(
                    child: Text(
                      rec,
                      style: AppTextStyles.caption().copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  /// Build header card with overall status
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: measurement.isHealthy
            ? AppColorPalette.successGradient
            : AppColorPalette.alertGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                measurement.isHealthy ? Icons.check_circle : Icons.warning,
                color: AppColorPalette.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.isHealthy
                          ? 'Healthy Soil'
                          : 'Requires Attention',
                      style: AppTextStyles.h3(
                        color: AppColorPalette.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Health Score: ${measurement.healthScore.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColorPalette.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: measurement.healthScore / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorPalette.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badges
  Widget _buildStatusBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Indicators',
          style: AppTextStyles.h4(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatusBadge.ph(status: measurement.phStatus),
            StatusBadge.moisture(status: measurement.moistureStatus),
            StatusBadge.health(isHealthy: measurement.isHealthy),
          ],
        ),
      ],
    );
  }

  /// Build metrics grid
  Widget _buildMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Measurements',
          style: AppTextStyles.h4(),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: Responsive.gridColumns(
            context,
            mobile: 1,
            tablet: 2,
            desktop: 2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: Responsive.value(
            context,
            mobile: 2.5,
            tablet: 1.8,
            desktop: 2.0,
          ),
          children: [
            SoilMetricCard.ph(
              value: measurement.ph,
              status: measurement.phStatus,
              compact: true,
            ),
            SoilMetricCard.moisture(
              value: measurement.soilMoisture,
              status: measurement.moistureStatus,
              compact: true,
            ),
            SoilMetricCard.sunlight(
              value: measurement.sunlight,
              compact: true,
            ),
            SoilMetricCard.temperature(
              value: measurement.temperature,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Build nutrients section
  Widget _buildNutrientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.grass,
                  size: 20,
                  color: AppColorPalette.success,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrients (N-P-K)',
                style: AppTextStyles.h4(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...measurement.nutrients.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getNutrientName(entry.key),
                    style: AppTextStyles.bodyMedium(),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorPalette.success,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build location section
  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppColorPalette.info,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Location',
                style: AppTextStyles.h4(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LocationRow(
            label: 'Latitude',
            value: measurement.latitude.toStringAsFixed(6),
          ),
          const SizedBox(height: 8),
          _LocationRow(
            label: 'Longitude',
            value: measurement.longitude.toStringAsFixed(6),
          ),
        ],
      ),
    );
  }

  /// Build metadata section
  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.softSlate.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColorPalette.softSlate,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Measurement Info',
                style: AppTextStyles.h4(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetadataRow(
            label: 'Date & Time',
            value: measurement.formattedDateTime,
          ),
        ],
      ),
    );
  }

  String _getNutrientName(String code) {
    switch (code) {
      case 'N':
        return 'Nitrogen';
      case 'P':
        return 'Phosphorus';
      case 'K':
        return 'Potassium';
      default:
        return code;
    }
  }

  /// Get color based on soil health score (0-100)
  Color _getHealthScoreColor(double score) {
    if (score >= 75) {
      return AppColorPalette.success;
    } else if (score >= 50) {
      return AppColorPalette.warning;
    } else {
      return AppColorPalette.alertError;
    }
  }

  /// Build ML-based plant recommendations section
  Widget _buildPlantRecommendationsSection() {
    // Loading state
    if (_isLoadingMLRecommendations) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.softSlate.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading ML recommendations...',
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.softSlate,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_mlRecommendationsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.alertError.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColorPalette.alertError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading recommendations: $_mlRecommendationsError',
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.alertError,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No ML recommendations
    if (_mlRecommendations == null) return const SizedBox.shrink();

    final topCrops = _mlRecommendations!.topRecommendations;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.agriculture,
                  size: 24,
                  color: AppColorPalette.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What You Can Grow Here',
                      style: AppTextStyles.h4(),
                    ),
                    Text(
                      'Based on ML analysis',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 14,
                      color: AppColorPalette.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.info,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recommended Crops (no title)
          if (topCrops.isNotEmpty) ...[
            ...topCrops.map((crop) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildMLCropRecommendationTile(crop),
            )),
            const SizedBox(height: 20),
          ],
          
          // Soil Improvement Section (MOST IMPORTANT)
          _buildSoilImprovementSection(),
          
          // Info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorPalette.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColorPalette.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColorPalette.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommendations are based on AI analysis of your current soil conditions.',
                    style: AppTextStyles.caption(
                      color: AppColorPalette.charcoalGreen,
                    ).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual ML crop recommendation tile
  Widget _buildMLCropRecommendationTile(RecommendedCrop crop) {
    final probability = crop.suitabilityScore; // 0-100
    final color = _getSuitabilityColor(probability);
    final emoji = _getCropEmoji(crop.crop);
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Crop emoji
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Crop info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.crop.toUpperCase(),
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.charcoalGreen,
                  ).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSuitabilityText(probability),
                  style: AppTextStyles.caption(
                    color: AppColorPalette.softSlate,
                  ),
                ),
              ],
            ),
          ),
          
          // Probability badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '${probability.toStringAsFixed(0)}%',
                  style: AppTextStyles.h4(
                    color: color,
                  ).copyWith(fontSize: 18),
                ),
                Text(
                  'Match',
                  style: AppTextStyles.caption(
                    color: color,
                  ).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get suitability color based on probability percentage
  Color _getSuitabilityColor(double probability) {
    if (probability >= 80) {
      return AppColorPalette.success;
    } else if (probability >= 60) {
      return AppColorPalette.info;
    } else if (probability >= 40) {
      return AppColorPalette.warning;
    } else {
      return AppColorPalette.alertError;
    }
  }

  /// Get suitability text based on probability percentage
  String _getSuitabilityText(double probability) {
    if (probability >= 80) {
      return 'Excellent match for your soil';
    } else if (probability >= 60) {
      return 'Good match for your soil';
    } else if (probability >= 40) {
      return 'Fair match - may need adjustments';
    } else {
      return 'Low match - challenging to grow';
    }
  }

  /// Get crop emoji based on crop name
  String _getCropEmoji(String cropName) {
    final crop = cropName.toLowerCase();
    
    // Common crops
    if (crop.contains('rice')) return '🌾';
    if (crop.contains('wheat')) return '🌾';
    if (crop.contains('maize') || crop.contains('corn')) return '🌽';
    if (crop.contains('potato')) return '🥔';
    if (crop.contains('tomato')) return '🍅';
    if (crop.contains('cucumber')) return '🥒';
    if (crop.contains('carrot')) return '🥕';
    if (crop.contains('lettuce') || crop.contains('cabbage')) return '🥬';
    if (crop.contains('onion')) return '🧅';
    if (crop.contains('garlic')) return '🧄';
    if (crop.contains('pepper') || crop.contains('chili')) return '🌶️';
    if (crop.contains('beans')) return '🫘';
    if (crop.contains('peas')) return '🫛';
    if (crop.contains('chickpea')) return '🫘';
    if (crop.contains('lentil')) return '🫘';
    
    // Fruits
    if (crop.contains('apple')) return '🍎';
    if (crop.contains('banana')) return '🍌';
    if (crop.contains('orange')) return '🍊';
    if (crop.contains('grape')) return '🍇';
    if (crop.contains('mango')) return '🥭';
    if (crop.contains('watermelon')) return '🍉';
    if (crop.contains('coconut')) return '🥥';
    if (crop.contains('papaya')) return '🍈';
    if (crop.contains('pomegranate')) return '🍎';
    if (crop.contains('muskmelon')) return '🍈';
    if (crop.contains('strawberry')) return '🍓';
    
    // Cash crops
    if (crop.contains('cotton')) return '🌱';
    if (crop.contains('jute')) return '🌿';
    if (crop.contains('coffee')) return '☕';
    if (crop.contains('sugarcane')) return '🎋';
    if (crop.contains('kidneybeans')) return '🫘';
    if (crop.contains('pigeonpeas')) return '🫘';
    if (crop.contains('mothbeans')) return '🫘';
    if (crop.contains('mungbean')) return '🫘';
    if (crop.contains('blackgram')) return '🫘';
    
    // Default
    return '🌱';
  }

  /// Build prominent soil improvement section
  Widget _buildSoilImprovementSection() {
    final measurement = widget.measurement;
    final improvements = <Map<String, dynamic>>[];
    
    // Analyze pH levels
    if (measurement.ph < 6.0) {
      improvements.add({
        'icon': Icons.science,
        'color': AppColorPalette.warning,
        'title': 'Soil is Too Acidic (pH ${measurement.ph.toStringAsFixed(1)})',
        'problem': 'Low pH reduces nutrient availability and can harm plant roots.',
        'steps': [
          'Apply agricultural lime (calcium carbonate) at 2-3 kg per 10 square meters',
          'Mix lime thoroughly into the top 15-20 cm of soil',
          'Wait 2-4 weeks before planting to allow pH to stabilize',
          'Retest soil pH after 30 days to verify improvement',
          'Target pH: 6.0-7.0 for most crops',
        ],
        'products': 'Use: Dolomitic lime (adds calcium + magnesium) or Calcitic lime (adds calcium only)',
      });
    } else if (measurement.ph > 7.5) {
      improvements.add({
        'icon': Icons.science,
        'color': AppColorPalette.warning,
        'title': 'Soil is Too Alkaline (pH ${measurement.ph.toStringAsFixed(1)})',
        'problem': 'High pH locks nutrients like iron, making them unavailable to plants.',
        'steps': [
          'Add elemental sulfur at 1-2 kg per 10 square meters',
          'Mix organic matter like compost or peat moss (5-10 cm layer)',
          'Apply acidic fertilizers like ammonium sulfate',
          'Water deeply after application to help sulfur work into soil',
          'Retest pH after 60 days (sulfur works slowly)',
        ],
        'products': 'Use: Elemental sulfur, aluminum sulfate, or iron sulfate',
      });
    }
    
    // Analyze moisture levels
    if (measurement.soilMoisture < 20) {
      improvements.add({
        'icon': Icons.water_drop,
        'color': AppColorPalette.info,
        'title': 'Soil is Too Dry (${measurement.soilMoisture.toStringAsFixed(0)}% moisture)',
        'problem': 'Insufficient moisture stresses plants and reduces nutrient uptake.',
        'steps': [
          'Install drip irrigation system for efficient watering',
          'Water deeply 2-3 times per week (aim for 25-35% moisture)',
          'Add organic mulch (5-8 cm thick) to retain moisture',
          'Mix compost into soil to improve water retention capacity',
          'Water early morning or evening to reduce evaporation',
        ],
        'products': 'Use: Drip irrigation kit, organic mulch (straw, wood chips, grass clippings)',
      });
    } else if (measurement.soilMoisture > 60) {
      improvements.add({
        'icon': Icons.water_drop,
        'color': AppColorPalette.alertError,
        'title': 'Soil is Too Wet (${measurement.soilMoisture.toStringAsFixed(0)}% moisture)',
        'problem': 'Waterlogged soil causes root rot and prevents oxygen from reaching roots.',
        'steps': [
          'Stop watering immediately until moisture drops below 50%',
          'Dig drainage channels or install drainage pipes',
          'Create raised beds (30-40 cm high) for better drainage',
          'Add coarse sand or perlite (20-30% by volume) to improve drainage',
          'Plant in mounds to keep roots above water level',
        ],
        'products': 'Use: Drainage pipes, coarse sand, perlite, or raised bed materials',
      });
    }
    
    // Analyze temperature
    if (measurement.temperature < 15) {
      improvements.add({
        'icon': Icons.thermostat,
        'color': AppColorPalette.info,
        'title': 'Soil Temperature is Low (${measurement.temperature.toStringAsFixed(1)}°C)',
        'problem': 'Cold soil slows seed germination and root growth.',
        'steps': [
          'Use black plastic mulch to warm soil faster (raises temp 3-5°C)',
          'Wait for warmer season before planting heat-loving crops',
          'Use row covers or low tunnels to trap heat',
          'Plant cool-season crops (lettuce, peas, carrots) that tolerate cold',
          'Remove mulch once soil reaches 18-20°C for planting',
        ],
        'products': 'Use: Black plastic mulch, row covers, or cold frames',
      });
    } else if (measurement.temperature > 35) {
      improvements.add({
        'icon': Icons.thermostat,
        'color': AppColorPalette.alertError,
        'title': 'Soil Temperature is High (${measurement.temperature.toStringAsFixed(1)}°C)',
        'problem': 'Hot soil damages roots and kills beneficial soil microbes.',
        'steps': [
          'Apply thick organic mulch (8-10 cm) to cool soil surface',
          'Use shade cloth (30-50% shade) over crops during hottest hours',
          'Water more frequently but with less volume to cool soil',
          'Plant during cooler season (autumn/winter)',
          'Choose heat-tolerant crop varieties',
        ],
        'products': 'Use: Organic mulch (straw, hay), shade cloth, or heat-resistant seeds',
      });
    }
    
    // Check nutrients using helper method that handles different key formats
    final nValue = _getNutrientValue('N');
    final pValue = _getNutrientValue('P');
    final kValue = _getNutrientValue('K');
    
    if (nValue < 30 || pValue < 20 || kValue < 30) {
      final deficient = <String>[];
      if (nValue < 30) deficient.add('Nitrogen (N: ${nValue.toStringAsFixed(1)} mg/kg)');
      if (pValue < 20) deficient.add('Phosphorus (P: ${pValue.toStringAsFixed(1)} mg/kg)');
      if (kValue < 30) deficient.add('Potassium (K: ${kValue.toStringAsFixed(1)} mg/kg)');
      
      improvements.add({
        'icon': Icons.grass,
        'color': AppColorPalette.success,
        'title': 'Nutrient Deficiency Detected',
        'problem': 'Low ${deficient.join(", ")}. Plants will have stunted growth and poor yields.',
        'steps': [
          'Apply NPK fertilizer based on deficiencies:',
          '  • Nitrogen (N): Use urea (46-0-0) or ammonium nitrate at 20-30 kg per hectare',
          '  • Phosphorus (P): Use superphosphate (0-20-0) at 30-40 kg per hectare',
          '  • Potassium (K): Use potash (0-0-60) at 20-30 kg per hectare',
          'Add organic compost (100-200 kg per 100 square meters)',
          'Split fertilizer application: 50% at planting, 50% after 4 weeks',
          'Water thoroughly after fertilizing to help nutrients reach roots',
          'Retest nutrients after 60 days to track improvement',
        ],
        'products': 'Use: NPK compound fertilizer, organic compost, or specific nutrient fertilizers',
      });
    }
    
    // If soil is good, show maintenance tips
    if (improvements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorPalette.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColorPalette.success.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorPalette.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColorPalette.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Excellent Soil Conditions!',
                    style: AppTextStyles.h4(
                      color: AppColorPalette.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your soil is in great shape. To maintain quality:',
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.charcoalGreen,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              'Continue regular watering to maintain 25-40% moisture',
              'Apply compost every 3-4 months to maintain nutrients',
              'Rotate crops each season to prevent nutrient depletion',
              'Test soil every 6 months to catch problems early',
              'Add mulch to maintain stable moisture and temperature',
            ].map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ ',
                    style: AppTextStyles.bodyMedium(
                      color: AppColorPalette.success,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.bodySmall(
                        color: AppColorPalette.charcoalGreen,
                      ).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      );
    }
    
    // Show improvement cards
    return Column(
      children: improvements.map((improvement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorPalette.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (improvement['color'] as Color).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (improvement['color'] as Color).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (improvement['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      improvement['icon'] as IconData,
                      color: improvement['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      improvement['title'] as String,
                      style: AppTextStyles.h4(
                        color: AppColorPalette.charcoalGreen,
                      ).copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 14),
              
              // Problem explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorPalette.alertError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppColorPalette.alertError,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        improvement['problem'] as String,
                        style: AppTextStyles.bodySmall(
                          color: AppColorPalette.charcoalGreen,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Solution steps
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.build_circle,
                          color: AppColorPalette.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to Fix This:',
                          style: AppTextStyles.bodyMedium(
                            color: AppColorPalette.charcoalGreen,
                          ).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(improvement['steps'] as List<String>).asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColorPalette.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: AppTextStyles.caption(
                                    color: AppColorPalette.success,
                                  ).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTextStyles.bodySmall(
                                  color: AppColorPalette.charcoalGreen,
                                ).copyWith(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Products recommendation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      color: AppColorPalette.info,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        improvement['products'] as String,
                        style: AppTextStyles.caption(
                          color: AppColorPalette.charcoalGreen,
                        ).copyWith(
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Location row widget
class _LocationRow extends StatelessWidget {
  final String label;
  final String value;

  const _LocationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            color: AppColorPalette.softSlate,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Metadata row widget
class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            color: AppColorPalette.softSlate,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
