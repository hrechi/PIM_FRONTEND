import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../models/soil_measurement.dart';
import '../../models/field_model.dart';
import '../../widgets/soil/status_badge.dart';
import '../../widgets/soil/soil_metric_card.dart';
import '../../models/ai_prediction.dart';
import '../../widgets/soil/ai_prediction_card.dart';
import '../../widgets/soil/ai_advice_card.dart';
import '../../services/soil_api_service.dart';
import '../../services/field_service.dart';
import '../../services/plant_recommendation_service.dart';
import '../../services/parcel_crud_service.dart';
import '../../models/crop_suitability.dart';
import '../../providers/parcel_provider.dart';
import 'soil_measurement_form_screen.dart';
import 'soil_measurements_list_screen.dart';

/// Screen displaying detailed information about a soil measurement
/// Route: /soil/:id
class SoilMeasurementDetailsScreen extends StatefulWidget {
  final SoilMeasurement measurement;

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
  late SoilMeasurement measurement;
  bool _loadingPrediction = false;
  AiPrediction? _prediction;
  String? _predictionError;
  PlantRecommendations? _plantRecommendations;
  FieldModel? _field;
  bool _isLoadingField = false;
  final SoilApiService _apiService = SoilApiService();
  final FieldService _fieldService = FieldService();
  final ParcelCrudService _parcelService = ParcelCrudService();
  
  // Crop analysis state
  bool _loadingCropAnalysis = false;
  AnalyzeExistingCropsResponse? _cropAnalysis;
  String? _cropAnalysisError;
  String? _selectedParcelId;
  
  @override
  void initState() {
    super.initState();
    measurement = widget.measurement;
    // Load field data if measurement is linked to a field
    if (measurement.fieldId != null) {
      _loadField();
    }
    // Check if prediction already exists in cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SoilMeasurementsProvider>();
      final cachedPrediction = provider.getPrediction(measurement.id);
      if (cachedPrediction != null) {
        setState(() {
          _prediction = cachedPrediction;
          _generatePlantRecommendations();
        });
      }
    });
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
  Future<void> _loadPrediction() async {
    setState(() {
      _loadingPrediction = true;
      _predictionError = null;
    });

    try {
      final prediction = await _apiService.getPrediction(measurement.id);
      if (mounted) {
        // Store in provider cache
        final provider = context.read<SoilMeasurementsProvider>();
        provider.storePrediction(measurement.id, prediction);
        
        setState(() {
          _prediction = prediction;
          _loadingPrediction = false;
          _generatePlantRecommendations();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictionError = e.toString();
          _loadingPrediction = false;
        });
      }
    }
  }
  
  /// Generate plant recommendations based on soil conditions
  void _generatePlantRecommendations() {
    _plantRecommendations = PlantRecommendationService.getRecommendations(
      ph: measurement.ph,
      soilMoisture: measurement.soilMoisture,
      temperature: measurement.temperature,
      sunlight: measurement.sunlight,
    );
  }

  /// Load crop analysis for a parcel
  Future<void> _loadCropAnalysis(String parcelId) async {
    setState(() {
      _loadingCropAnalysis = true;
      _cropAnalysisError = null;
      _selectedParcelId = parcelId;
    });

    try {
      final analysis = await _parcelService.analyzeExistingCrops(parcelId);
      if (mounted) {
        setState(() {
          _cropAnalysis = analysis;
          _loadingCropAnalysis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cropAnalysisError = e.toString();
          _loadingCropAnalysis = false;
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
              // AI Prediction Section
               _buildAiSection(),

            const SizedBox(height: 24),

            // Crop Suitability Analysis Section
            _buildCropAnalysisSection(),

            const SizedBox(height: 24),
            
            // Plant Recommendations Section (only if soil is not extreme)
            if (_prediction != null && _plantRecommendations != null)
              _plantRecommendations!.isExtreme
                  ? _buildExtremeSoilWarning()
                  : _buildPlantRecommendationsSection(),
              
            if (_prediction != null && _plantRecommendations != null)
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
Widget _buildAiSection() {
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
        // Section title with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.psychology,
                size: 20,
                color: AppColorPalette.charcoalGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI Analysis',
              style: AppTextStyles.h4(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Prediction card or loading/error state
        if (_loadingPrediction)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: AppColorPalette.charcoalGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Analyzing soil conditions...',
                    style: AppTextStyles.bodyMedium(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_predictionError != null)
          Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 36,
                color: AppColorPalette.alertError,
              ),
              const SizedBox(height: 12),
              Text(
                'Service Unavailable',
                style: AppTextStyles.bodyLarge(),
              ),
              const SizedBox(height: 6),
              Text(
                'AI service not responding. Check if the AI service is running.',
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadPrediction,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColorPalette.charcoalGreen,
                  side: BorderSide(color: AppColorPalette.charcoalGreen),
                ),
              ),
            ],
          )
        else if (_prediction != null)
          Column(
            children: [
              // Prediction card
              AiPredictionCard(
                prediction: _prediction!,
                onRefresh: _loadPrediction,
              ),
              const SizedBox(height: 16),
              // Advice card
              AiAdviceCard(prediction: _prediction!),
            ],
          )
        else
          // Initial state - show button to get prediction
          Column(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 40,
                color: AppColorPalette.charcoalGreen,
              ),
              const SizedBox(height: 12),
              Text(
                'Get Wilting Risk Prediction',
                style: AppTextStyles.bodyLarge(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Use machine learning to predict wilting risk',
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPrediction,
                icon: const Icon(Icons.psychology, size: 20),
                label: const Text('Analyze with AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorPalette.charcoalGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

  /// Build crop suitability analysis section
  Widget _buildCropAnalysisSection() {
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
          // Section title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.eco,
                  size: 20,
                  color: AppColorPalette.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Crop Suitability Analysis',
                  style: AppTextStyles.h4(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Analyze existing crops or get recommendations based on this soil measurement',
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ),
          ),
          const SizedBox(height: 16),

          // Parcel selector
          Consumer<ParcelProvider>(
            builder: (context, parcelProvider, _) {
              final parcels = parcelProvider.parcels;
              
              if (parcels.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorPalette.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColorPalette.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No parcels found. Create a parcel first to analyze crops.',
                          style: AppTextStyles.bodySmall(
                            color: AppColorPalette.charcoalGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parcel dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedParcelId,
                    decoration: InputDecoration(
                      labelText: 'Select Parcel',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: parcels.map((parcel) {
                      return DropdownMenuItem<String>(
                        value: parcel.id,
                        child: Text(parcel.location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _loadCropAnalysis(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Results
                  if (_loadingCropAnalysis)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: AppColorPalette.success,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Analyzing crops...',
                              style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.softSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_cropAnalysisError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColorPalette.alertError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColorPalette.alertError,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Analysis Failed',
                            style: AppTextStyles.bodyMedium(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cropAnalysisError!,
                            style: AppTextStyles.caption(
                              color: AppColorPalette.softSlate,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else if (_cropAnalysis != null)
                    _buildCropAnalysisResults(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build crop analysis results
  Widget _buildCropAnalysisResults() {
    if (_cropAnalysis == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Soil health score and wilting risk
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorPalette.success.withValues(alpha: 0.1),
                AppColorPalette.info.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColorPalette.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soil Health Score',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_cropAnalysis!.soilHealthScore.toStringAsFixed(0)}%',
                      style: AppTextStyles.h3(
                        color: AppColorPalette.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorPalette.softSlate.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wilting Risk',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cropAnalysis!.wiltingRisk,
                      style: AppTextStyles.bodyLarge(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Crops analysis
        if (_cropAnalysis!.cropsAnalysis.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorPalette.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColorPalette.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No crops planted on this parcel yet.',
                    style: AppTextStyles.bodySmall(
                      color: AppColorPalette.charcoalGreen,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crops Analysis (${_cropAnalysis!.cropsAnalysis.length})',
                style: AppTextStyles.h4(),
              ),
              const SizedBox(height: 12),
              ..._cropAnalysis!.cropsAnalysis.map((crop) {
                return _buildCropCard(crop);
              }).toList(),
            ],
          ),
      ],
    );
  }

  /// Build individual crop analysis card
  Widget _buildCropCard(CropAnalysisItem crop) {
    Color decisionColor;
    IconData decisionIcon;
    
    switch (crop.decision) {
      case CropDecision.canPlant:
        decisionColor = AppColorPalette.success;
        decisionIcon = Icons.check_circle;
        break;
      case CropDecision.canPlantWithImprovement:
        decisionColor = AppColorPalette.warning;
        decisionIcon = Icons.warning;
        break;
      case CropDecision.cannotPlant:
        decisionColor = AppColorPalette.alertError;
        decisionIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: decisionColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop name and decision
          Row(
            children: [
              Icon(
                Icons.spa,
                color: AppColorPalette.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  crop.crop.toUpperCase(),
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: decisionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      decisionIcon,
                      size: 14,
                      color: decisionColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      crop.decision.displayName,
                      style: AppTextStyles.caption(
                        color: decisionColor,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Suitability score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suitability Score',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${crop.suitabilityScore.toStringAsFixed(0)}',
                          style: AppTextStyles.h3(color: decisionColor),
                        ),
                        Text(
                          '/100',
                          style: AppTextStyles.bodyMedium(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: crop.regionAllowed
                      ? AppColorPalette.success.withValues(alpha: 0.1)
                      : AppColorPalette.alertError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      crop.regionAllowed ? Icons.location_on : Icons.location_off,
                      size: 16,
                      color: crop.regionAllowed
                          ? AppColorPalette.success
                          : AppColorPalette.alertError,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      crop.regionAllowed ? 'Region Allowed' : 'Not Allowed',
                      style: AppTextStyles.caption(
                        color: crop.regionAllowed
                            ? AppColorPalette.success
                            : AppColorPalette.alertError,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Recommendations
          if (crop.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Recommendations:',
              style: AppTextStyles.bodySmall().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...crop.recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: AppTextStyles.bodySmall(
                        color: decisionColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: AppTextStyles.bodySmall(
                          color: AppColorPalette.charcoalGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
  
  /// Build extreme soil warning section
  Widget _buildExtremeSoilWarning() {
    if (_plantRecommendations == null || !_plantRecommendations!.isExtreme) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.alertError.withValues(alpha: 0.3),
          width: 2,
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
                  color: AppColorPalette.alertError.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.dangerous,
                  size: 28,
                  color: AppColorPalette.alertError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Soil Not Suitable for Planting',
                  style: AppTextStyles.h4(
                    color: AppColorPalette.alertError,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Warning message
          Container(
            padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppColorPalette.alertError,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No plants, vegetables, fruits, herbs, or trees can be grown in these extreme conditions.',
                        style: AppTextStyles.bodyMedium(
                          color: AppColorPalette.charcoalGreen,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Critical issues
          Text(
            'Critical Issues:',
            style: AppTextStyles.h4(
              color: AppColorPalette.charcoalGreen,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColorPalette.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColorPalette.softSlate.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _plantRecommendations!.extremeMessage!
                  .split('\n\n')
                  .map((issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.alertError,
                              ).copyWith(fontSize: 16),
                            ),
                            Expanded(
                              child: Text(
                                issue,
                                style: AppTextStyles.bodyMedium(
                                  color: AppColorPalette.charcoalGreen,
                                ).copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action required section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColorPalette.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColorPalette.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_circle,
                      size: 20,
                      color: AppColorPalette.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Required Actions:',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.charcoalGreen,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._getExtremeConditionActions().map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${action['number']}. ',
                            style: AppTextStyles.bodyMedium(
                              color: AppColorPalette.charcoalGreen,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Expanded(
                            child: Text(
                              action['text'] as String,
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
          ),
          
          const SizedBox(height: 16),
          
          // Expert consultation notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorPalette.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.contact_support,
                  size: 18,
                  color: AppColorPalette.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consider consulting an agricultural expert or soil specialist to remediate these extreme conditions before attempting to plant.',
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
  
  /// Get actions needed for extreme conditions
  List<Map<String, dynamic>> _getExtremeConditionActions() {
    if (_plantRecommendations == null) return [];
    
    final actions = <Map<String, dynamic>>[];
    int actionNumber = 1;
    
    final measurement = widget.measurement;
    
    // pH corrections
    if (measurement.ph < 4.0) {
      actions.add({
        'number': actionNumber++,
        'text': 'Add large amounts of agricultural lime to raise pH. May require multiple applications over several months.',
      });
    } else if (measurement.ph > 9.5) {
      actions.add({
        'number': actionNumber++,
        'text': 'Add elemental sulfur or acidic organic matter to lower pH. Professional soil amendment may be necessary.',
      });
    }
    
    // Moisture corrections
    if (measurement.soilMoisture < 5) {
      actions.add({
        'number': actionNumber++,
        'text': 'Install irrigation system and water deeply multiple times. Add organic matter to improve water retention.',
      });
    } else if (measurement.soilMoisture > 95) {
      actions.add({
        'number': actionNumber++,
        'text': 'Install drainage system immediately. Consider raised beds. Do not water until moisture drops below 60%.',
      });
    }
    
    // Temperature management
    if (measurement.temperature < 5) {
      actions.add({
        'number': actionNumber++,
        'text': 'Wait for warmer season. Consider greenhouse or cold frame protection for season extension.',
      });
    } else if (measurement.temperature > 45) {
      actions.add({
        'number': actionNumber++,
        'text': 'Provide heavy mulching and shade structures. Increase irrigation to cool soil. Plant during cooler season.',
      });
    }
    
    actions.add({
      'number': actionNumber++,
      'text': 'Retest soil after implementing corrections to verify conditions have improved to safe levels.',
    });
    
    return actions;
  }
  
  /// Build plant recommendations section
  Widget _buildPlantRecommendationsSection() {
    if (_plantRecommendations == null) return const SizedBox.shrink();
    
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.park,
                  size: 20,
                  color: AppColorPalette.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'What You Can Grow Here',
                  style: AppTextStyles.h4(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Soil type description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorPalette.wheatWarmClay.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _plantRecommendations!.soilType,
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.charcoalGreen,
              ).copyWith(height: 1.4),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Vegetables
          if (_plantRecommendations!.vegetables.isNotEmpty) ...[
            _buildPlantCategoryHeader('Vegetables', Icons.spa, '🥬'),
            const SizedBox(height: 12),
            ..._plantRecommendations!.vegetables.take(3).map(
              (plant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlantRecommendationTile(plant),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Fruits
          if (_plantRecommendations!.fruits.isNotEmpty) ...[
            _buildPlantCategoryHeader('Fruits', Icons.apple, '🍓'),
            const SizedBox(height: 12),
            ..._plantRecommendations!.fruits.take(3).map(
              (plant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlantRecommendationTile(plant),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Trees
          if (_plantRecommendations!.trees.isNotEmpty) ...[
            _buildPlantCategoryHeader('Fruit Trees', Icons.forest, '🌳'),
            const SizedBox(height: 12),
            ..._plantRecommendations!.trees.take(3).map(
              (plant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlantRecommendationTile(plant),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Herbs
          if (_plantRecommendations!.herbs.isNotEmpty) ...[
            _buildPlantCategoryHeader('Herbs', Icons.grass, '🌿'),
            const SizedBox(height: 12),
            ..._plantRecommendations!.herbs.take(3).map(
              (plant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlantRecommendationTile(plant),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
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
                    'These recommendations are based on current soil conditions. For best results, test soil and adjust as needed.',
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
  
  /// Build plant category header
  Widget _buildPlantCategoryHeader(String title, IconData icon, String emoji) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h4(
            color: AppColorPalette.charcoalGreen,
          ),
        ),
      ],
    );
  }
  
  /// Build individual plant recommendation tile
  Widget _buildPlantRecommendationTile(PlantRecommendation plant) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(plant.suitabilityColor).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and suitability
          Row(
            children: [
              Text(
                plant.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plant.name,
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.charcoalGreen,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(plant.suitabilityColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 12,
                      color: Color(plant.suitabilityColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plant.suitabilityLevel,
                      style: AppTextStyles.caption(
                        color: Color(plant.suitabilityColor),
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Why suitable
          Text(
            'Why it\'s suitable:',
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ...plant.reasons.take(2).map((reason) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: AppTextStyles.caption(
                    color: AppColorPalette.success,
                  ),
                ),
                Expanded(
                  child: Text(
                    reason,
                    style: AppTextStyles.caption(
                      color: AppColorPalette.charcoalGreen,
                    ).copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 8),
          
          // Growing tip
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorPalette.wheatWarmClay.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: AppColorPalette.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plant.tips,
                    style: AppTextStyles.caption(
                      color: AppColorPalette.charcoalGreen,
                    ).copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
