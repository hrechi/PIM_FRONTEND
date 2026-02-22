import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../models/soil_measurement.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';
import '../../services/soil_repository.dart';
import '../../widgets/soil/status_badge.dart';
import 'soil_measurement_details_screen.dart';

/// Screen displaying soil measurements on a map
/// Route: /soil/map
/// 
/// Usage:
/// ```dart
/// // Navigate to map without field boundary
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => SoilMapScreen(
///       measurements: measurements,
///     ),
///   ),
/// );
/// 
/// // Navigate to map with field boundary
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => SoilMapScreen(
///       measurements: measurements,
///       fieldId: 'field-id-here',
///     ),
///   ),
/// );
/// ```
class SoilMapScreen extends StatefulWidget {
  final List<SoilMeasurement> measurements;
  final String? fieldId;

  const SoilMapScreen({
    super.key,
    required this.measurements,
    this.fieldId,
  });

  @override
  State<SoilMapScreen> createState() => _SoilMapScreenState();
}

class _SoilMapScreenState extends State<SoilMapScreen> {
  final MapController _mapController = MapController();
  final FieldService _fieldService = FieldService();
  final SoilRepository _soilRepository = SoilRepository();
  
  SoilMeasurement? selectedMeasurement;
  FieldModel? _selectedField;
  List<SoilMeasurement> _loadedMeasurements = [];
  List<FieldModel> _availableFields = [];
  bool _isLoadingField = false;
  bool _isLoadingMeasurements = false;
  bool _isLoadingFields = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
    _loadAvailableFields();
    if (widget.fieldId != null) {
      _loadFieldData();
    }
  }

  /// Load all available fields
  Future<void> _loadAvailableFields() async {
    setState(() {
      _isLoadingFields = true;
    });

    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _availableFields = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFields = false;
      });
    }
  }

  @override
  void didUpdateWidget(SoilMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload field data if fieldId changed or widget updated
    if (widget.fieldId != null && widget.fieldId != oldWidget.fieldId) {
      _loadFieldData();
      _loadMeasurements();
    }
  }

  /// Load measurements from API
  Future<void> _loadMeasurements() async {
    setState(() {
      _isLoadingMeasurements = true;
    });

    try {
      final response = await _soilRepository.getMeasurements(
        page: 1,
        limit: 1000, // Get all measurements
        sortBy: 'createdAt',
        order: 'DESC',
      );
      
      setState(() {
        _loadedMeasurements = response.data;
        _isLoadingMeasurements = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load measurements: $e';
        _isLoadingMeasurements = false;
      });
    }
  }

  /// Get measurements to display (filtered by field if selected)
  List<SoilMeasurement> get _displayedMeasurements {
    List<SoilMeasurement> measurements;
    
    // Use loaded measurements or passed measurements
    if (_loadedMeasurements.isNotEmpty) {
      measurements = _loadedMeasurements;
    } else {
      measurements = widget.measurements;
    }
    
    // Filter by selected field if one is selected
    if (_selectedField != null) {
      return measurements.where((m) => m.fieldId == _selectedField!.id).toList();
    }
    
    return measurements;
  }

  /// Load field data from backend
  Future<void> _loadFieldData() async {
    if (widget.fieldId == null) {
      setState(() {
        _selectedField = null;
        _isLoadingField = false;
      });
      return;
    }

    setState(() {
      _isLoadingField = true;
      _errorMessage = null;
    });

    try {
      final field = await _fieldService.getFieldById(widget.fieldId!);
      setState(() {
        _selectedField = field;
        _isLoadingField = false;
      });

      // Zoom to fit field polygon
      if (field.areaCoordinates.isNotEmpty) {
        _fitBoundsToPolygon(field.areaCoordinates);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Field not found or has been deleted';
        _isLoadingField = false;
        _selectedField = null;
      });
      
      // If field was deleted, show message and go back after delay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This field has been deleted'),
            backgroundColor: AppColorPalette.alertError,
          ),
        );
        // Go back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  /// Zoom map to fit polygon bounds
  void _fitBoundsToPolygon(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return;

    double minLat = coordinates[0][0];
    double maxLat = coordinates[0][0];
    double minLng = coordinates[0][1];
    double maxLng = coordinates[0][1];

    for (var coord in coordinates) {
      if (coord[0] < minLat) minLat = coord[0];
      if (coord[0] > maxLat) maxLat = coord[0];
      if (coord[1] < minLng) minLng = coord[1];
      if (coord[1] > maxLng) maxLng = coord[1];
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Delay to ensure map is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });
  }

  /// Show field selector dialog
  Future<void> _showFieldSelector() async {
    try {
      final fields = await _fieldService.getFields();
      
      if (!mounted) return;
      
      if (fields.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fields available. Create a field first.')),
        );
        return;
      }

      final selectedField = await showDialog<FieldModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Field'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return ListTile(
                  leading: const Icon(Icons.landscape),
                  title: Text(field.name),
                  subtitle: Text(
                    '${field.areaSize?.toStringAsFixed(2) ?? "N/A"} m²',
                  ),
                  onTap: () => Navigator.pop(context, field),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedField != null) {
        setState(() {
          _selectedField = selectedField;
        });
        _fitBoundsToPolygon(selectedField.areaCoordinates);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fields: $e')),
      );
    }
  }

  /// Show measurement details in bottom sheet
  void _showMeasurementDetails(SoilMeasurement measurement) {
    setState(() {
      selectedMeasurement = measurement;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MeasurementBottomSheet(
        measurement: measurement,
        onViewDetails: () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SoilMeasurementDetailsScreen(
                measurement: measurement,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedField != null 
                  ? 'Field: ${_selectedField!.name}'
                  : 'Soil Map',
              style: AppTextStyles.h3(),
            ),
            Text(
              _selectedField != null
                  ? '${_selectedField!.areaSize?.toStringAsFixed(2) ?? "N/A"} m² • ${_displayedMeasurements.length} measurements'
                  : '${_displayedMeasurements.length} measurements',
              style: AppTextStyles.caption(
                color: AppColorPalette.softSlate,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button (when field is selected)
          if (_selectedField != null || widget.fieldId != null)
            IconButton(
              icon: _isLoadingField 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoadingField ? null : () {
                _loadFieldData();
                _loadMeasurements();
              },
              tooltip: 'Refresh Field',
            ),
          // Field selector button
          if (_selectedField == null && widget.fieldId == null)
            IconButton(
              icon: const Icon(Icons.add_location),
              onPressed: () => _showFieldSelector(),
              tooltip: 'Select Field',
            ),
          // Legend button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegend(),
            tooltip: 'Legend',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Responsive.constrainedContent(
        context: context,
        child: Column(
          children: [
            // Field selector dropdown (only if not coming from field management)
            if (widget.fieldId == null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.charcoalGreen.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.landscape,
                      color: AppColorPalette.mistyBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedField?.id,
                          hint: Text(
                            _isLoadingFields 
                              ? 'Loading fields...' 
                              : 'Select a field to view measurements',
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
                              child: Text('All Fields'),
                            ),
                            ..._availableFields.map((field) {
                              return DropdownMenuItem<String>(
                                value: field.id,
                                child: Text(field.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (fieldId) async {
                            if (fieldId == null) {
                              setState(() {
                                _selectedField = null;
                              });
                            } else {
                              final selected = _availableFields.firstWhere((f) => f.id == fieldId);
                              setState(() {
                                _selectedField = selected;
                              });
                              if (selected.areaCoordinates.isNotEmpty) {
                                _fitBoundsToPolygon(selected.areaCoordinates);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Map view
            Expanded(
              child: Stack(
                children: [
                  _buildMapView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build map view with measurement markers
  Widget _buildMapView() {
    // Default center: Tunisia
    LatLng defaultCenter = const LatLng(35.8989, 10.1592);
    
    // If we have a field, center on its first coordinate
    if (_selectedField != null && _selectedField!.areaCoordinates.isNotEmpty) {
      final firstCoord = _selectedField!.areaCoordinates[0];
      defaultCenter = LatLng(firstCoord[0], firstCoord[1]);
    }
    // If we have measurements, center on the first one
    else if (_displayedMeasurements.isNotEmpty) {
      final firstMeasurement = _displayedMeasurements[0];
      defaultCenter = LatLng(firstMeasurement.latitude, firstMeasurement.longitude);
    }

    return Stack(
      children: [
        // Flutter Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: defaultCenter,
            initialZoom: 13.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fieldly.app',
            ),
            
            // All field polygons layer (show all fields automatically)
            if (_availableFields.isNotEmpty)
              PolygonLayer(
                polygons: _availableFields
                    .where((field) => field.areaCoordinates.isNotEmpty)
                    .map((field) {
                  // Highlight the selected field
                  final isSelected = _selectedField?.id == field.id;
                  return Polygon(
                    points: field.areaCoordinates
                        .map((coord) => LatLng(coord[0], coord[1]))
                        .toList(),
                    isFilled: true,
                    color: isSelected
                        ? AppColorPalette.fieldFreshStart.withOpacity(0.3)
                        : AppColorPalette.mistyBlue.withOpacity(0.15),
                    borderColor: isSelected
                        ? AppColorPalette.fieldFreshStart
                        : AppColorPalette.mistyBlue,
                    borderStrokeWidth: isSelected ? 2.5 : 1.5,
                  );
                }).toList(),
              ),
            
            // Soil measurement markers
            if (_displayedMeasurements.isNotEmpty)
              MarkerLayer(
                markers: _displayedMeasurements.map((measurement) {
                  return Marker(
                    point: LatLng(measurement.latitude, measurement.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showMeasurementDetails(measurement),
                      child: _MapMarkerWidget(
                        measurement: measurement,
                        isSelected: selectedMeasurement?.id == measurement.id,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
        
        // Loading indicator
        if (_isLoadingField || _isLoadingMeasurements)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        // Error message
        if (_errorMessage != null)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorPalette.alertError,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Show map legend
  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(
              color: AppColorPalette.success,
              label: 'Healthy soil conditions',
            ),
            const SizedBox(height: 12),
            _LegendItem(
              color: AppColorPalette.warning,
              label: 'Moderate issues detected',
            ),
            const SizedBox(height: 12),
            _LegendItem(
              color: AppColorPalette.alertError,
              label: 'Critical issues detected',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Map marker widget
class _MapMarkerWidget extends StatelessWidget {
  final SoilMeasurement measurement;
  final bool isSelected;

  const _MapMarkerWidget({
    required this.measurement,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = measurement.isHealthy
        ? AppColorPalette.success
        : measurement.healthScore > 50
            ? AppColorPalette.warning
            : AppColorPalette.alertError;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 50 : 40,
      height: isSelected ? 50 : 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse animation when selected
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          // Main marker
          Container(
            width: isSelected ? 36 : 28,
            height: isSelected ? 36 : 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColorPalette.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              size: isSelected ? 20 : 16,
              color: AppColorPalette.white,
            ),
          ),
          // ID label
          if (isSelected)
            Positioned(
              bottom: -20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColorPalette.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.charcoalGreen.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  measurement.shortLocation,
                  style: AppTextStyles.caption().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet for measurement details
class _MeasurementBottomSheet extends StatelessWidget {
  final SoilMeasurement measurement;
  final VoidCallback onViewDetails;

  const _MeasurementBottomSheet({
    required this.measurement,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.locationName,
                      style: AppTextStyles.h3(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      measurement.formattedDateTime,
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.health(
                isHealthy: measurement.isHealthy,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick metrics
          Row(
            children: [
              Expanded(
                child: _QuickMetric(
                  icon: Icons.science,
                  label: 'pH',
                  value: measurement.ph.toStringAsFixed(1),
                  color: measurement.phStatusEnum == PhStatus.neutral
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickMetric(
                  icon: Icons.water_drop,
                  label: 'Moisture',
                  value: '${measurement.soilMoisture.toStringAsFixed(0)}%',
                  color: measurement.moistureStatusEnum == MoistureStatus.optimal
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickMetric(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: '${measurement.temperature.toStringAsFixed(0)}°C',
                  color: AppColorPalette.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge.ph(
                status: measurement.phStatus,
                compact: true,
              ),
              StatusBadge.moisture(
                status: measurement.moistureStatus,
                compact: true,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // View details button
          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColorPalette.mistyBlue,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye),
                const SizedBox(width: 8),
                Text(
                  'View Full Details',
                  style: AppTextStyles.buttonMedium(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick metric widget for bottom sheet
class _QuickMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColorPalette.white,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(),
          ),
        ),
      ],
    );
  }
}
