import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/parcel_provider.dart';
import '../models/parcel.dart';
import '../models/soil_measurement.dart';
import '../models/field_model.dart';
import '../services/field_service.dart';
import '../services/soil_repository.dart';

class AddParcelScreen extends StatefulWidget {
  final Parcel? existingParcel;

  const AddParcelScreen({super.key, this.existingParcel});

  @override
  State<AddParcelScreen> createState() => _AddParcelScreenState();
}

class _AddParcelScreenState extends State<AddParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final FieldService _fieldService = FieldService();
  final SoilRepository _soilRepository = SoilRepository();

  // Map and soil measurement data
  MapController? _mapController;
  List<SoilMeasurement> _allSoilMeasurements = [];
  SoilMeasurement? _selectedSoilMeasurement;
  bool _isLoadingMeasurements = false;

  // Camera position for map
  late LatLng _mapCenter;
  final double _mapZoom = 13;

  // Field selection
  String? _selectedFieldId;
  List<FieldModel> _fields = [];
  bool _isLoadingFields = false;

  // Manual entries
  late TextEditingController _irrigationFrequencyController;
  String _waterSource = 'rain-fed';
  String _irrigationMethod = 'drip';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _irrigationFrequencyController = TextEditingController();
    
    // Set default map center
    _mapCenter = const LatLng(11.8, 79.7); // Default to India
    
    _loadFields();
    _loadSoilMeasurements();

    if (widget.existingParcel != null) {
      final p = widget.existingParcel!;
      _waterSource = ['well', 'rain-fed', 'river', 'drip system'].contains(p.waterSource) ? p.waterSource : 'rain-fed';
      _irrigationMethod = ['drip', 'sprinkler', 'flood'].contains(p.irrigationMethod) ? p.irrigationMethod : 'drip';
      _irrigationFrequencyController.text = p.irrigationFrequency;
    }
  }

  Future<void> _loadSoilMeasurements() async {
    setState(() => _isLoadingMeasurements = true);
    try {
      final response = await _soilRepository.getMeasurements(limit: 100);
      setState(() {
        // Filter out soil measurements that are already assigned to parcels (have parcelId)
        _allSoilMeasurements = response.data.where((m) => m.parcelId == null).toList();
        _isLoadingMeasurements = false;
        
        // Center map on first measurement if available
        if (_allSoilMeasurements.isNotEmpty) {
          final first = _allSoilMeasurements.first;
          _mapCenter = LatLng(first.latitude, first.longitude);
        }
      });
    } catch (e) {
      setState(() => _isLoadingMeasurements = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load soil measurements: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadFields() async {
    setState(() => _isLoadingFields = true);
    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _fields = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() => _isLoadingFields = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load fields: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _selectField(String? fieldId) {
    setState(() => _selectedFieldId = fieldId);
    
    if (fieldId != null) {
      try {
        final selectedField = _fields.firstWhere((f) => f.id == fieldId);
        if (selectedField.areaCoordinates.isNotEmpty) {
          // Calculate center of field
          double avgLat = selectedField.areaCoordinates.map((c) => c[0]).reduce((a, b) => a + b) / selectedField.areaCoordinates.length;
          double avgLng = selectedField.areaCoordinates.map((c) => c[1]).reduce((a, b) => a + b) / selectedField.areaCoordinates.length;
          
          setState(() {
            _mapCenter = LatLng(avgLat, avgLng);
          });
          
          // Animate map to field center
          Future.delayed(const Duration(milliseconds: 300), () {
            _mapController?.move(_mapCenter, 15);
          });
        }
      } catch (e) {
        // Field not found
      }
    }
  }

  void _selectSoilMeasurement(SoilMeasurement measurement) {
    setState(() {
      _selectedSoilMeasurement = measurement;
      _mapCenter = LatLng(measurement.latitude, measurement.longitude);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Soil data loaded: pH ${measurement.ph.toStringAsFixed(1)}, Moisture ${measurement.soilMoisture.toStringAsFixed(0)}%'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Marker> _buildMapMarkers() {
    return _allSoilMeasurements.map((measurement) {
      final isSelected = _selectedSoilMeasurement?.id == measurement.id;
      return Marker(
        point: LatLng(measurement.latitude, measurement.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _selectSoilMeasurement(measurement),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF2ECC71) : Colors.blue,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Center(
              child: Icon(
                isSelected ? Icons.check : Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Polygon> _buildFieldPolygon() {
    if (_selectedFieldId == null) return [];
    
    try {
      final selectedField = _fields.firstWhere((f) => f.id == _selectedFieldId);
      if (selectedField.areaCoordinates.isEmpty) return [];
      
      final polygonPoints = selectedField.areaCoordinates
          .map((coord) => LatLng(coord[0], coord[1]))
          .toList();
      
      return [
        Polygon(
          points: polygonPoints,
          color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
          borderColor: const Color(0xFF2ECC71),
          borderStrokeWidth: 2,
          isFilled: true,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _irrigationFrequencyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSoilMeasurement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a soil measurement on the map first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final soilData = _selectedSoilMeasurement!;
      final nValue = (soilData.nutrients['N'] ?? soilData.nutrients['nitrogen'] ?? 0) as num;
      final pValue = (soilData.nutrients['P'] ?? soilData.nutrients['phosphorus'] ?? 0) as num;
      final kValue = (soilData.nutrients['K'] ?? soilData.nutrients['potassium'] ?? 0) as num;
      
      // Get the selected field name
      final fieldName = _selectedFieldId != null 
        ? _fields.firstWhere((f) => f.id == _selectedFieldId, orElse: () => FieldModel(
            id: '', userId: '', name: 'Unknown Field', areaCoordinates: [], 
            createdAt: DateTime.now(), updatedAt: DateTime.now())).name
        : 'Unmapped Location';
      
      final parcelData = {
        'location': fieldName,
        'areaSize': 1.0,
        'boundariesDescription': 'From soil measurement',
        'soilType': soilData.soilType ?? 'unknown',
        'soilPh': soilData.ph,
        'nitrogenLevel': nValue.toDouble(),
        'phosphorusLevel': pValue.toDouble(),
        'potassiumLevel': kValue.toDouble(),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMobile = screenSize.height < screenSize.width; // Landscape detection

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        title: Text(
          widget.existingParcel != null ? 'Edit Parcel' : 'Select Soil Measurement',
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
          Column(
            children: [
              // Map View (responsive)
              Expanded(
                flex: isSmallScreen ? 1 : (isMobile ? 2 : 3),
                child: _isLoadingMeasurements
                    ? const Center(
                        child: CircularProgressIndicator(color: accentGreen),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: _mapZoom,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'frontend_pim',
                          ),
                          PolygonLayer(
                            polygons: _buildFieldPolygon(),
                          ),
                          MarkerLayer(
                            markers: _buildMapMarkers(),
                          ),
                        ],
                      ),
              ),

              // Form Section (responsive) - show more prominently on mobile when soil is selected
              Expanded(
                flex: isSmallScreen ? (_selectedSoilMeasurement != null ? 2 : 1) : (isMobile ? 1 : 2),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Field Selector Card
                        _buildResponsiveCard(
                          title: 'Field Selection',
                          icon: Icons.landscape,
                          isSmallScreen: isSmallScreen,
                          children: [
                            if (_isLoadingFields)
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(color: accentGreen),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _selectedFieldId,
                                hint: const Text('Select field (optional)'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('No field selected')),
                                  ..._fields.map((f) => DropdownMenuItem(
                                    value: f.id,
                                    child: Text(f.name),
                                  )),
                                ],
                                onChanged: _selectField,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.landscape, color: accentGreen),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 8 : 12),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 8 : 12),

                        // Selected Soil Data Display
                        if (_selectedSoilMeasurement != null)
                          _buildResponsiveCard(
                            title: 'Selected Soil Data',
                            icon: Icons.grass_rounded,
                            isSmallScreen: isSmallScreen,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: accentGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accentGreen, width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✅ Soil Data Loaded',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF27AE60), fontSize: 14),
                                    ),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    Wrap(
                                      spacing: isSmallScreen ? 8 : 12,
                                      runSpacing: isSmallScreen ? 6 : 8,
                                      children: [
                                        _buildSoilInfoChip('pH', _selectedSoilMeasurement!.ph.toStringAsFixed(1), isSmallScreen),
                                        _buildSoilInfoChip('Moisture', '${_selectedSoilMeasurement!.soilMoisture.toStringAsFixed(0)}%', isSmallScreen),
                                        _buildSoilInfoChip('Temp', '${_selectedSoilMeasurement!.temperature.toStringAsFixed(0)}°C', isSmallScreen),
                                        _buildSoilInfoChip('Type', _selectedSoilMeasurement!.soilType ?? 'Unknown', isSmallScreen),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        if (_selectedSoilMeasurement != null) SizedBox(height: isSmallScreen ? 8 : 12),

                        // Water & Irrigation Section
                        _buildResponsiveCard(
                          title: 'Water & Irrigation',
                          icon: Icons.water_drop_rounded,
                          isSmallScreen: isSmallScreen,
                          children: [
                            _buildResponsiveField(
                              label: 'Water Source',
                              value: _waterSource,
                              items: ['well', 'rain-fed', 'river', 'drip system'],
                              icon: Icons.waves_rounded,
                              onChanged: (val) => setState(() => _waterSource = val!),
                              isSmallScreen: isSmallScreen,
                              isDropdown: true,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            _buildResponsiveField(
                              label: 'Irrigation Method',
                              value: _irrigationMethod,
                              items: ['drip', 'sprinkler', 'flood'],
                              icon: Icons.shower_rounded,
                              onChanged: (val) => setState(() => _irrigationMethod = val!),
                              isSmallScreen: isSmallScreen,
                              isDropdown: true,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            _buildResponsiveField(
                              label: 'Irrigation Frequency',
                              hint: 'e.g. Twice weekly',
                              icon: Icons.update_rounded,
                              controller: _irrigationFrequencyController,
                              isSmallScreen: isSmallScreen,
                              isRequired: true,
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 60 : 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: accentGreen),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 48 : 56,
          child: ElevatedButton(
            onPressed: _isSubmitting || _selectedSoilMeasurement == null ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4731),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _selectedSoilMeasurement == null ? 'Select Soil on Map' : 'Create Parcel',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2ECC71), size: isSmallScreen ? 20 : 24),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A4731)),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSoilInfoChip(String label, String value, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2ECC71), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A4731))),
        ],
      ),
    );
  }

  Widget _buildResponsiveField({
    required String label,
    String? hint,
    required IconData icon,
    TextEditingController? controller,
    String? value,
    List<String>? items,
    bool isDropdown = false,
    ValueChanged<String?>? onChanged,
    bool isSmallScreen = false,
    bool isRequired = false,
  }) {
    if (isDropdown && items != null) {
      return DropdownButtonFormField<String>(
        value: value,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: isSmallScreen ? 18 : 20),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: isSmallScreen ? 18 : 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 8 : 12),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: isSmallScreen ? 12 : 13),
        ),
      );
    } else {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: isSmallScreen ? 18 : 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 8 : 12),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: isSmallScreen ? 12 : 13),
        ),
        validator: (val) {
          if (isRequired && (val == null || val.isEmpty)) return 'This field is required';
          return null;
        },
      );
    }
  }
}
