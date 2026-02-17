import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/responsive.dart';
import '../models/soil_measurement.dart';
import '../models/ai_prediction.dart';
import '../data/soil_repository.dart';
import '../data/soil_api_service.dart';
import '../widgets/measurement_tile.dart';
import 'soil_measurement_form_screen.dart';
import 'soil_measurement_details_screen.dart';
import 'soil_analytics_screen.dart';
import 'soil_map_screen.dart';

/// Provider for managing Soil Measurements state
class SoilMeasurementsProvider extends ChangeNotifier {
  final SoilRepository _repository;
  
  List<SoilMeasurement> _measurements = [];
  bool _isLoading = false;
  String? _error;
  String _filterStatus = 'All';
  
  // Pagination
  int _currentPage = 1;
  int _limit = 20;
  bool _hasMore = true;
  PaginationMeta? _meta;
  
  // AI Predictions cache (measurementId -> AiPrediction)
  final Map<String, AiPrediction> _predictions = {};
  
  SoilMeasurementsProvider({SoilRepository? repository})
      : _repository = repository ?? SoilRepository();
  
  List<SoilMeasurement> get measurements => _measurements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  bool get hasMore => _hasMore;
  PaginationMeta? get meta => _meta;
  
  /// Get filtered measurements based on status
  List<SoilMeasurement> get filteredMeasurements {
    if (_filterStatus == 'All') return _measurements;
    if (_filterStatus == 'Healthy') {
      return _measurements.where((m) => m.isHealthy).toList();
    }
    return _measurements.where((m) => !m.isHealthy).toList();
  }
  
  /// Load measurements from API
  Future<void> loadMeasurements({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _currentPage = 1;
      _measurements = [];
      _hasMore = true;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _repository.getMeasurements(
        page: _currentPage,
        limit: _limit,
        sortBy: 'createdAt',
        order: 'DESC',
      );
      
      if (refresh) {
        _measurements = response.data;
      } else {
        _measurements.addAll(response.data);
      }
      
      _meta = response.meta;
      _hasMore = response.meta.hasNextPage;
      _currentPage++;
      
      _isLoading = false;
      notifyListeners();
    } on SoilApiException catch (e) {
      _error = e.userMessage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Create a new measurement
  Future<bool> createMeasurement({
    required double ph,
    required double soilMoisture,
    required double sunlight,
    required Map<String, dynamic> nutrients,
    required double temperature,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _repository.createMeasurement(
        ph: ph,
        soilMoisture: soilMoisture,
        sunlight: sunlight,
        nutrients: nutrients,
        temperature: temperature,
        latitude: latitude,
        longitude: longitude,
      );
      
      // Refresh the list
      await loadMeasurements(refresh: true);
      return true;
    } catch (e) {
      _error = e is SoilApiException ? e.userMessage : e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Update a measurement
  Future<bool> updateMeasurement({
    required String id,
    double? ph,
    double? soilMoisture,
    double? sunlight,
    Map<String, dynamic>? nutrients,
    double? temperature,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updated = await _repository.updateMeasurement(
        id: id,
        ph: ph,
        soilMoisture: soilMoisture,
        sunlight: sunlight,
        nutrients: nutrients,
        temperature: temperature,
        latitude: latitude,
        longitude: longitude,
      );
      
      // Update in local list
      final index = _measurements.indexWhere((m) => m.id == id);
      if (index != -1) {
        _measurements[index] = updated;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e is SoilApiException ? e.userMessage : e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Delete a measurement
  Future<bool> deleteMeasurement(String id) async {
    try {
      await _repository.deleteMeasurement(id);
      
      // Remove from local list
      _measurements.removeWhere((m) => m.id == id);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e is SoilApiException ? e.userMessage : e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Set filter status
  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Get prediction for a measurement (from cache)
  AiPrediction? getPrediction(String measurementId) {
    return _predictions[measurementId];
  }
  
  /// Store prediction in cache
  void storePrediction(String measurementId, AiPrediction prediction) {
    _predictions[measurementId] = prediction;
    notifyListeners();
  }
  
  /// Clear prediction cache for a measurement
  void clearPrediction(String measurementId) {
    _predictions.remove(measurementId);
    notifyListeners();
  }
}

/// Screen displaying list of all soil measurements
/// Route: /soil
class SoilMeasurementsListScreen extends StatefulWidget {
  const SoilMeasurementsListScreen({super.key});

  @override
  State<SoilMeasurementsListScreen> createState() =>
      _SoilMeasurementsListScreenState();
}

class _SoilMeasurementsListScreenState
    extends State<SoilMeasurementsListScreen> {
  late final SoilMeasurementsProvider _provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = SoilMeasurementsProvider();
    _provider.loadMeasurements();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (_provider.hasMore && !_provider.isLoading) {
        _provider.loadMeasurements();
      }
    }
  }

  /// Navigate to add measurement screen
  Future<void> _navigateToAddMeasurement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _provider,
          child: const SoilMeasurementFormScreen(),
        ),
      ),
    );

    // Reload if measurement was added
    if (result == true) {
      _provider.loadMeasurements(refresh: true);
    }
  }

  /// Navigate to details screen
  void _navigateToDetails(SoilMeasurement measurement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _provider,
          child: SoilMeasurementDetailsScreen(measurement: measurement),
        ),
      ),
    );
  }

  /// Delete measurement with confirmation
  Future<void> _deleteMeasurement(SoilMeasurement measurement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: Text('Are you sure you want to delete measurement ${measurement.id}?'),
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
      final success = await _provider.deleteMeasurement(measurement.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Measurement ${measurement.id} deleted'),
            backgroundColor: AppColorPalette.success,
          ),
        );
      } else if (mounted && _provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_provider.error!),
            backgroundColor: AppColorPalette.alertError,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () => _provider.clearError(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<SoilMeasurementsProvider>(
        builder: (context, provider, child) {
          final filtered = provider.filteredMeasurements;

          return Scaffold(
            backgroundColor: AppColorPalette.wheatWarmClay,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soil Measurements',
                    style: AppTextStyles.h3(),
                  ),
                  if (provider.meta != null)
                    Text(
                      '${provider.meta!.total} total measurements',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                ],
              ),
              actions: [
                // Analytics button
                IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoilAnalyticsScreen(),
                      ),
                    );
                  },
                  tooltip: 'View Analytics',
                ),
                // Map button
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SoilMapScreen(
                          measurements: provider.measurements,
                        ),
                      ),
                    );
                  },
                  tooltip: 'View Map',
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => provider.loadMeasurements(refresh: true),
              child: Responsive.constrainedContent(
                context: context,
                child: Column(
                  children: [
                    // Error banner
                    if (provider.error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColorPalette.alertError.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColorPalette.alertError,
                            width: 1,
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
                                provider.error!,
                                style: AppTextStyles.bodyMedium(
                                  color: AppColorPalette.alertError,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: provider.clearError,
                              color: AppColorPalette.alertError,
                            ),
                          ],
                        ),
                      ),

                    // Filter chips
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontalPadding(context),
                        vertical: 12,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              count: provider.measurements.length,
                              isSelected: provider.filterStatus == 'All',
                              onTap: () => provider.setFilterStatus('All'),
                            ),
                            SizedBox(width: Responsive.spacing(context)),
                            _FilterChip(
                              label: 'Healthy',
                              count: provider.measurements
                                  .where((m) => m.isHealthy)
                                  .length,
                              isSelected: provider.filterStatus == 'Healthy',
                              onTap: () => provider.setFilterStatus('Healthy'),
                              color: AppColorPalette.success,
                            ),
                            SizedBox(width: Responsive.spacing(context)),
                            _FilterChip(
                              label: 'Warning',
                              count: provider.measurements
                                  .where((m) => !m.isHealthy)
                                  .length,
                              isSelected: provider.filterStatus == 'Warning',
                              onTap: () => provider.setFilterStatus('Warning'),
                              color: AppColorPalette.alertError,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Measurements list
                    Expanded(
                      child: provider.isLoading && provider.measurements.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : filtered.isEmpty
                              ? _buildEmptyState(provider.filterStatus)
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    bottom: 80,
                                    left: Responsive.horizontalPadding(context),
                                    right: Responsive.horizontalPadding(context),
                                  ),
                                  itemCount: filtered.length + (provider.hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == filtered.length) {
                                      // Loading indicator for pagination
                                      return const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final measurement = filtered[index];
                                    return MeasurementTile(
                                      measurement: measurement,
                                      onTap: () => _navigateToDetails(measurement),
                                      onDelete: () => _deleteMeasurement(measurement),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _navigateToAddMeasurement,
              icon: const Icon(Icons.add),
              label: const Text('Add Measurement'),
              backgroundColor: AppColorPalette.mistyBlue,
            ),
          );
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(String filterStatus) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grass,
            size: 80,
            color: AppColorPalette.softSlate.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filterStatus == 'All'
                ? 'No measurements yet'
                : 'No $filterStatus measurements',
            style: AppTextStyles.h4(
              color: AppColorPalette.softSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filterStatus == 'All'
                ? 'Tap the button below to add your first measurement'
                : 'Try changing the filter',
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.softSlate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColorPalette.mistyBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColorPalette.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : AppColorPalette.softSlate.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall().copyWith(
                color: isSelected
                    ? AppColorPalette.white
                    : AppColorPalette.charcoalGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColorPalette.white.withOpacity(0.3)
                    : chipColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.caption().copyWith(
                  color: isSelected ? AppColorPalette.white : chipColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
