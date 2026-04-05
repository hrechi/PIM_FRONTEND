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
import '../../services/soil_repository.dart';
import '../../services/parcel_crud_service.dart';
import '../../services/soil_crop_compatibility_service.dart';
import '../../services/weather_service.dart';
import '../../models/parcel.dart';
import '../../models/weather_info.dart';
import '../../config/api_config.dart';
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
  bool _isLoadingMeasurement = false;
  final FieldService _fieldService = FieldService();
  final SoilRepository _soilRepository = SoilRepository();
  final ParcelCrudService _parcelService = ParcelCrudService();
  final WeatherService _weatherService = WeatherService();

  // FEATURE 1: Parcel Crops Compatibility
  Parcel? _parcel;
  List<String> _parcelCropNames = [];
  List<CropCompatibilityResult> _cropCompatibilityResults = [];
  bool _isLoadingCropCompatibility = false;
  String? _cropCompatibilityError;

  // FEATURE 2: Soil Corrections for Crops
  List<SoilCorrectionAction> _soilCorrections = [];
  bool _isLoadingSoilCorrections = false;
  String? _soilCorrectionsError;

  // FEATURE 3: Seasonal Soil Care Plans
  Map<String, SeasonalSoilPlan> _seasonalPlans = {};
  bool _isLoadingSeasonalPlans = false;
  String? _seasonalPlansError;
  late String _currentSeason;
  WeatherForecastResponse? _fieldWeather;

  String _normalizeText(String value) {
    return value.trim().toLowerCase();
  }

  String _seasonByMonthAndLatitude(int month, double latitude) {
    final isNorthernHemisphere = latitude >= 0;

    if (isNorthernHemisphere) {
      if (month >= 3 && month <= 5) return 'Spring';
      if (month >= 6 && month <= 8) return 'Summer';
      if (month >= 9 && month <= 11) return 'Autumn';
      return 'Winter';
    }

    // Southern hemisphere season inversion.
    if (month >= 3 && month <= 5) return 'Autumn';
    if (month >= 6 && month <= 8) return 'Winter';
    if (month >= 9 && month <= 11) return 'Spring';
    return 'Summer';
  }

  Future<void> _resolveSeasonFromWeather() async {
    if (measurement.fieldId == null) {
      _currentSeason = _getCurrentSeason();
      return;
    }

    try {
      final forecast = await _weatherService.getWeatherForField(measurement.fieldId!);
      final weatherMonth = forecast.daily.isNotEmpty
          ? forecast.daily.first.date.month
          : DateTime.now().month;
      final latitude = forecast.latitude ?? measurement.latitude;
      final resolvedSeason = _seasonByMonthAndLatitude(weatherMonth, latitude);

      if (!mounted) return;

      setState(() {
        _fieldWeather = forecast;
        _currentSeason = resolvedSeason;
      });
    } catch (_) {
      _currentSeason = _getCurrentSeason();
    }
  }

  Future<void> _initializeSeasonAndCropAnalysis() async {
    await _resolveSeasonFromWeather();
    await _loadParcel();
  }
  
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

  /// Load parcel linked to this soil measurement
  Future<void> _loadParcel() async {
    try {
      Parcel? resolvedParcel;
      List<String> cropNames = [];

      if (measurement.parcelId != null) {
        resolvedParcel = await _parcelService.getParcelById(measurement.parcelId!);
        cropNames = resolvedParcel.crops
            .map((c) => c.cropName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
      } else if (measurement.fieldId != null) {
        final parcels = await _parcelService.getParcels();
        List<Parcel> fieldParcels = parcels
            .where((p) => p.fieldId == measurement.fieldId)
            .toList();

        // Backward-compatibility fallback for older parcels without fieldId:
        // match parcel location against field name (e.g., "gabes").
        if (fieldParcels.isEmpty) {
          try {
            final fields = await _fieldService.getFields();
            final field = fields.firstWhere((f) => f.id == measurement.fieldId);
            final normalizedFieldName = _normalizeText(field.name);

            fieldParcels = parcels.where((p) {
              final normalizedLocation = _normalizeText(p.location);
              return normalizedLocation == normalizedFieldName ||
                  normalizedLocation.contains(normalizedFieldName) ||
                  normalizedFieldName.contains(normalizedLocation);
            }).toList();
          } catch (_) {
            // Ignore fallback lookup errors and keep empty candidate list.
          }
        }

        if (fieldParcels.isNotEmpty) {
          resolvedParcel = fieldParcels.first;

          final seen = <String>{};
          for (final parcel in fieldParcels) {
            for (final crop in parcel.crops) {
              final cropName = crop.cropName.trim();
              final key = cropName.toLowerCase();
              if (cropName.isNotEmpty && seen.add(key)) {
                cropNames.add(cropName);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _parcel = resolvedParcel;
          _parcelCropNames = cropNames;
        });

        if (cropNames.isNotEmpty) {
          // Load crop compatibility after crop names are available (will trigger corrections)
          await _loadCropCompatibility();
          await _loadSeasonalPlans();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cropCompatibilityError = 'Failed to load parcel data: ${e.toString()}';
        });
      }
    }
  }

  /// Check which crops from parcel can be planted in current soil
  Future<void> _loadCropCompatibility() async {
    if (_parcelCropNames.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingCropCompatibility = true;
      _cropCompatibilityError = null;
    });

    try {
      final nitrogen = _getNutrientValue('N');
      final phosphorus = _getNutrientValue('P');
      final potassium = _getNutrientValue('K');

      final results = await SoilCropCompatibilityService.checkCropsCompatibility(
        cropNames: _parcelCropNames,
        ph: measurement.ph,
        moisture: measurement.soilMoisture,
        temperature: measurement.temperature,
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        season: _currentSeason,
      );

      if (mounted) {
        setState(() {
          _cropCompatibilityResults = results;
          _isLoadingCropCompatibility = false;
        });
      }
      
      // After crop compatibility is loaded, load soil corrections for failed crops
      await _loadSoilCorrections();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cropCompatibilityError = 'Failed to check crop compatibility: ${e.toString()}';
          _isLoadingCropCompatibility = false;
        });
      }
    }
  }

  /// Load soil corrections for crops that cannot be planted
  Future<void> _loadSoilCorrections() async {
    if (_parcelCropNames.isEmpty || _cropCompatibilityResults.isEmpty) {
      return;
    }

    final failedCrops = _cropCompatibilityResults
        .where((r) => !r.canPlant)
        .map((r) => r.cropName)
        .toList();

    if (failedCrops.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingSoilCorrections = true;
      _soilCorrectionsError = null;
    });

    try {
      final nitrogen = _getNutrientValue('N');
      final phosphorus = _getNutrientValue('P');
      final potassium = _getNutrientValue('K');

      final corrections = await SoilCropCompatibilityService.getSoilCorrections(
        failedCropNames: failedCrops,
        ph: measurement.ph,
        moisture: measurement.soilMoisture,
        temperature: measurement.temperature,
        soilType: measurement.soilType ?? 'Unknown',
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        season: _currentSeason,
      );

      if (mounted) {
        setState(() {
          _soilCorrections = corrections;
          _isLoadingSoilCorrections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _soilCorrectionsError = 'Failed to load soil corrections: ${e.toString()}';
          _isLoadingSoilCorrections = false;
        });
      }
    }
  }

  /// Load seasonal soil care plans
  Future<void> _loadSeasonalPlans() async {
    if (_parcelCropNames.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingSeasonalPlans = true;
      _seasonalPlansError = null;
    });

    try {
      final nitrogen = _getNutrientValue('N');
      final phosphorus = _getNutrientValue('P');
      final potassium = _getNutrientValue('K');

      // Get plans for all seasons
      final seasons = ['Spring', 'Summer', 'Autumn', 'Winter'];
      final plans = <String, SeasonalSoilPlan>{};

      for (final season in seasons) {
        try {
          final plan = await SoilCropCompatibilityService.getSeasonalPlan(
            season: season,
            ph: measurement.ph,
            moisture: measurement.soilMoisture,
            temperature: measurement.temperature,
            soilType: measurement.soilType ?? 'Unknown',
            nitrogen: nitrogen,
            phosphorus: phosphorus,
            potassium: potassium,
            cropNames: _parcelCropNames,
            weatherData: {
              if (_fieldWeather != null) 'weatherCondition': _fieldWeather!.current.condition,
              if (_fieldWeather != null) 'weatherTemperature': _fieldWeather!.current.temperature,
              if (_fieldWeather != null) 'weatherHumidity': _fieldWeather!.current.humidity,
              if (_fieldWeather != null) 'weatherUvIndex': _fieldWeather!.current.uvIndex,
              if (_fieldWeather?.timezone != null) 'timezone': _fieldWeather!.timezone,
              if (_fieldWeather?.latitude != null) 'latitude': _fieldWeather!.latitude,
              if (_fieldWeather?.longitude != null) 'longitude': _fieldWeather!.longitude,
            },
          );
          plans[season] = plan;
        } catch (e) {
          print('Failed to load $season plan: $e');
        }
      }

      if (mounted) {
        setState(() {
          _seasonalPlans = plans;
          _isLoadingSeasonalPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _seasonalPlansError = 'Failed to load seasonal plans: ${e.toString()}';
          _isLoadingSeasonalPlans = false;
        });
      }
    }
  }

  /// Determine current season based on device date (Tunisia climate zones)
  String _getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;

    // Tunisia climate: Spring Mar–May, Summer Jun–Aug, Autumn Sep–Nov, Winter Dec–Feb
    if (month >= 3 && month <= 5) {
      return 'Spring';
    } else if (month >= 6 && month <= 8) {
      return 'Summer';
    } else if (month >= 9 && month <= 11) {
      return 'Autumn';
    } else {
      return 'Winter';
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
  /// Reload measurement from API to get latest data
  Future<void> _reloadMeasurement() async {
    setState(() => _isLoadingMeasurement = true);
    try {
      final freshMeasurement = await _soilRepository.getMeasurementById(measurement.id);
      if (mounted) {
        setState(() {
          measurement = freshMeasurement;
          _isLoadingMeasurement = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMeasurement = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    measurement = widget.measurement;
    _currentSeason = _getCurrentSeason();
    // Reload measurement to get fresh data with soil type
    _reloadMeasurement();
    // Load field data if measurement is linked to a field
    if (measurement.fieldId != null) {
      _loadField();
    }
    // Load weather-based season first, then crop compatibility and seasonal plans.
    _initializeSeasonAndCropAnalysis();
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

            // Soil Photo Section (if available)
            if (measurement.imagePath != null) ...[
              _buildSoilPhotoSection(),
              const SizedBox(height: 24),
            ],

            // Metrics Grid
            _buildMetricsGrid(),

            const SizedBox(height: 24),

            // Soil Health Analysis Section
            _buildSoilHealthAnalysisSection(),

            const SizedBox(height: 24),

            // FEATURE 1: Parcel Crops Compatibility
            _buildParcelCropsCompatibilitySection(),

            const SizedBox(height: 24),

            // FEATURE 2: Soil Corrections for Crops
            _buildSoilCorrectionsSection(),

            const SizedBox(height: 24),

            // FEATURE 3: Seasonal Soil Care Plan
            _buildSeasonalSoilCareSection(),

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

  /// FEATURE 1: Build Parcel Crops Compatibility section
  Widget _buildParcelCropsCompatibilitySection() {
    if (_parcel == null && _parcelCropNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.softSlate.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.link_off, color: AppColorPalette.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No parcel crops found for this soil measurement field. Add crops in parcel/crops to analyze compatibility.',
                style: AppTextStyles.bodySmall(),
              ),
            ),
          ],
        ),
      );
    }

    if (_parcelCropNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.softSlate.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColorPalette.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No crops registered in parcel/crops for this field yet.',
                style: AppTextStyles.bodySmall(),
              ),
            ),
          ],
        ),
      );
    }

    // Show loading state
    if (_isLoadingCropCompatibility) {
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
                'Analyzing crop compatibility...',
                style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_cropCompatibilityError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.alertError.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColorPalette.alertError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cropCompatibilityError!,
                style: AppTextStyles.bodySmall(),
              ),
            ),
          ],
        ),
      );
    }

    if (_cropCompatibilityResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final canPlant = _cropCompatibilityResults.where((r) => r.canPlant).toList();
    final cannotPlant = _cropCompatibilityResults.where((r) => !r.canPlant).toList();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 20,
                  color: AppColorPalette.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🌱 Your Parcel Crops Compatibility',
                  style: AppTextStyles.h4(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Crops that CAN plant
          if (canPlant.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: AppColorPalette.success),
                const SizedBox(width: 8),
                Text(
                  'Can Plant (${canPlant.length})',
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.success,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...canPlant.map((result) => _buildCropCompatibilityCard(result, isCompatible: true)),
            const SizedBox(height: 16),
          ],
          // Crops that CANNOT plant
          if (cannotPlant.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.cancel, size: 18, color: AppColorPalette.alertError),
                const SizedBox(width: 8),
                Text(
                  'Cannot Plant (${cannotPlant.length})',
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.alertError,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...cannotPlant.map((result) => _buildCropCompatibilityCard(result, isCompatible: false)),
          ],
        ],
      ),
    );
  }

  /// Build individual crop compatibility card
  Widget _buildCropCompatibilityCard(CropCompatibilityResult result, {required bool isCompatible}) {
    final color = isCompatible ? AppColorPalette.success : AppColorPalette.alertError;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompatible ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.cropName.toUpperCase(),
                  style: AppTextStyles.bodyMedium(
                    color: color,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  result.reason,
                  style: AppTextStyles.caption(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FEATURE 2: Build Soil Corrections section
  Widget _buildSoilCorrectionsSection() {
    if (_soilCorrections.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoadingSoilCorrections) {
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
                'Loading soil correction recommendations...',
                style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
              ),
            ],
          ),
        ),
      );
    }

    if (_soilCorrectionsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.alertError.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColorPalette.alertError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _soilCorrectionsError!,
                style: AppTextStyles.bodySmall(),
              ),
            ),
          ],
        ),
      );
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.build,
                  size: 20,
                  color: AppColorPalette.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔧 Soil Corrections for Your Crops',
                  style: AppTextStyles.h4(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._soilCorrections.map((correction) => _buildCorrectionCard(correction)),
        ],
      ),
    );
  }

  /// Build individual soil correction card
  Widget _buildCorrectionCard(SoilCorrectionAction correction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorPalette.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorPalette.info.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Priority ${correction.priority}',
                  style: AppTextStyles.caption(
                    color: AppColorPalette.info,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correction.title,
                  style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.charcoalGreen,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            correction.description,
            style: AppTextStyles.caption(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorPalette.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps:',
                  style: AppTextStyles.bodySmall(
                    color: AppColorPalette.charcoalGreen,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...correction.steps.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: AppTextStyles.caption(
                          color: AppColorPalette.success,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.caption(),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps: ${correction.affectedCrops}',
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// FEATURE 3: Build Seasonal Soil Care Plan section
  Widget _buildSeasonalSoilCareSection() {
    if (_seasonalPlans.isEmpty || !_seasonalPlans.containsKey(_currentSeason)) {
      return const SizedBox.shrink();
    }

    final currentPlan = _seasonalPlans[_currentSeason]!;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorPalette.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: AppColorPalette.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 Seasonal Soil Care Plan',
                      style: AppTextStyles.h4(),
                    ),
                    Text(
                      'Current Season: ${_getSeasonEmoji(_currentSeason)} $_currentSeason',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                    if (_fieldWeather != null)
                      Text(
                        'Weather context: ${_fieldWeather!.current.condition}, ${_fieldWeather!.current.temperature.toStringAsFixed(1)}°C (UV ${_fieldWeather!.current.uvIndex})',
                        style: AppTextStyles.caption(
                          color: AppColorPalette.softSlate,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSeasonalPlanCard(currentPlan),
        ],
      ),
    );
  }

  /// Get emoji for season
  String _getSeasonEmoji(String season) {
    switch (season) {
      case 'Spring':
        return '🌸';
      case 'Summer':
        return '☀️';
      case 'Autumn':
        return '🍂';
      case 'Winter':
        return '❄️';
      default:
        return '📅';
    }
  }

  /// Build seasonal plan card
  Widget _buildSeasonalPlanCard(SeasonalSoilPlan plan) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorPalette.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorPalette.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to do this season:',
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.charcoalGreen,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...plan.tasks.map((task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✓ ', style: TextStyle(color: AppColorPalette.success)),
                Expanded(
                  child: Text(
                    task,
                    style: AppTextStyles.bodySmall(),
                  ),
                ),
              ],
            ),
          )),
          if (plan.canPlantNow.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Can plant now:',
              style: AppTextStyles.bodySmall(
                color: AppColorPalette.success,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              plan.canPlantNow.join(', '),
              style: AppTextStyles.caption(),
            ),
          ],
          if (plan.riskyThisSeason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Risky this season:',
              style: AppTextStyles.bodySmall(
                color: AppColorPalette.alertError,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              plan.riskyThisSeason.join(', '),
              style: AppTextStyles.caption(),
            ),
          ],
          if (plan.warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColorPalette.alertError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColorPalette.alertError.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: AppColorPalette.alertError,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.warning!,
                      style: AppTextStyles.caption(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (plan.amendmentWindow != null) ...[
            const SizedBox(height: 12),
            Text(
              'Best amendment window: ${plan.amendmentWindow}',
              style: AppTextStyles.caption(
                color: AppColorPalette.info,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
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

  /// Build soil photo section
  Widget _buildSoilPhotoSection() {
    final imageUrl = measurement.imagePath != null
        ? ApiConfig.baseUrl.replaceFirst('/api', '') + '/' + measurement.imagePath!
        : null;

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
                  color: AppColorPalette.charcoalGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: 20,
                  color: AppColorPalette.charcoalGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soil Photo',
                      style: AppTextStyles.h4(),
                    ),
                    if (measurement.soilType != null)
                      Text(
                        'AI detected: ${measurement.soilType}',
                        style: AppTextStyles.caption(
                          color: AppColorPalette.success,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: AppColorPalette.softSlate.withOpacity(0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColorPalette.softSlate,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unable to load image',
                            style: AppTextStyles.caption(
                              color: AppColorPalette.softSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    color: AppColorPalette.softSlate.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (measurement.detectionConfidence != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: measurement.detectionConfidence! >= 0.7
                      ? AppColorPalette.success
                      : AppColorPalette.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Confidence: ${(measurement.detectionConfidence! * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall(
                    color: measurement.detectionConfidence! >= 0.7
                        ? AppColorPalette.success
                        : AppColorPalette.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
            if (measurement.soilType != null)
              SoilMetricCard.soilType(
                soilType: measurement.soilType,
                confidence: measurement.detectionConfidence,
                compact: true,
              ),
          ],
        ),
        // AI Detected Soil Type Text Display
        if (measurement.soilType != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorPalette.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorPalette.success.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppColorPalette.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI Detected: ',
                            style: AppTextStyles.bodyMedium(
                              color: AppColorPalette.softSlate,
                            ),
                          ),
                          Text(
                            measurement.soilType!,
                            style: AppTextStyles.h4().copyWith(
                              color: AppColorPalette.success,
                            ),
                          ),
                          Text(
                            ' Soil',
                            style: AppTextStyles.bodyMedium(
                              color: AppColorPalette.softSlate,
                            ),
                          ),
                        ],
                      ),
                      if (measurement.detectionConfidence != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(measurement.detectionConfidence! * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.caption(
                            color: measurement.detectionConfidence! >= 0.7
                                ? AppColorPalette.success
                                : AppColorPalette.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
