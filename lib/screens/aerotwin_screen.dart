import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/aerotwin_model.dart';
import '../models/field_model.dart';
import '../services/aerotwin_service.dart';
import '../services/field_service.dart';

class AeroTwinScreen extends StatefulWidget {
  const AeroTwinScreen({Key? key}) : super(key: key);

  @override
  _AeroTwinScreenState createState() => _AeroTwinScreenState();
}

class _AeroTwinScreenState extends State<AeroTwinScreen> {
  final AeroTwinService _aeroTwinService = AeroTwinService();
  final FieldService _fieldService = FieldService();
  final MapController _mapController = MapController();

  List<FieldModel> _fields = [];
  String? _selectedFieldId;
  NDVIRecordModel? _currentNDVI;
  SimulationResult? _simulationResult;
  AeroTwinAlert? _alert;
  
  bool _isLoading = true;
  bool _isSimulating = false;

  // Sliders
  double _irrigation = 0; // -50 to 50
  double _temperature = 25; // 0 to 50
  double _nitrogen = 0.5; // 0 to 1

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _fields = fields;
        if (fields.isNotEmpty) {
          _selectedFieldId = fields.first.id;
        }
        _isLoading = false;
      });
      if (_selectedFieldId != null) {
        _fetchNDVIData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load fields: $e');
    }
  }

  Future<void> _fetchNDVIData() async {
    if (_selectedFieldId == null) return;
    setState(() => _isLoading = true);
    try {
      final ndvi = await _aeroTwinService.getNDVI(_selectedFieldId!);
      final alert = await _aeroTwinService.getAlerts(_selectedFieldId!);
      
      final field = _fields.firstWhere((f) => f.id == _selectedFieldId);
      final center = _getFieldCenter(field);
      
      // Use try-catch or check to avoid LateInitializationError if map isn't ready
      try {
        _mapController.move(center, 17.5);
      } catch (_) {
        // Map not ready yet, initialCenter in MapOptions will handle it
      }

      setState(() {
        _currentNDVI = ndvi;
        _alert = alert;
        _simulationResult = null; // Reset simulation
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load NDVI: $e');
    }
  }

  LatLng _getFieldCenter(FieldModel field) {
    if (field.areaCoordinates.isEmpty) return const LatLng(36.89, 10.18);
    double lat = 0, lng = 0;
    for (var c in field.areaCoordinates) {
      lat += c[0];
      lng += c[1];
    }
    return LatLng(lat / field.areaCoordinates.length, lng / field.areaCoordinates.length);
  }

  Future<void> _runSimulation() async {
    if (_selectedFieldId == null) return;
    setState(() => _isSimulating = true);
    try {
      final result = await _aeroTwinService.simulate(
        _selectedFieldId!,
        irrigationChange: _irrigation,
        temperature: _temperature,
        nitrogenLevel: _nitrogen,
      );
      setState(() {
        _simulationResult = result;
        _isSimulating = false;
      });
    } catch (e) {
      setState(() => _isSimulating = false);
      _showError('Simulation failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _getNDVIColor(double value) {
    if (value < 0.3) return Colors.red.withOpacity(0.6);
    if (value < 0.5) return Colors.yellow.withOpacity(0.6);
    return Colors.greenAccent.withOpacity(0.6);
  }

  List<List<double>> _getEffectiveGrid() {
    final baseGrid = _currentNDVI?.gridData ?? [];
    if (baseGrid.isEmpty) return [];

    List<List<double>> result = [];
    for (int r = 0; r < 10; r++) {
      List<double> row = [];
      for (int c = 0; c < 10; c++) {
        double baseVal = baseGrid[r][c];
        
        // Formula: newNDVI = baseNDVI + (irrigation * 0.001) + (nitrogen * 0.1) - (temperature > 35 ? 0.1 : 0)
        double newVal = baseVal 
          + (_irrigation * 0.001) 
          + (_nitrogen * 0.1) 
          - (_temperature > 35 ? 0.1 : 0);

        // Clamp between 0 and 1
        if (newVal < 0) newVal = 0;
        if (newVal > 1) newVal = 1;

        row.add(newVal);
      }
      result.add(row);
    }
    return result;
  }

  List<Polygon> _buildGridPolygons() {
    final grid = _getEffectiveGrid();
    if (grid.isEmpty || _selectedFieldId == null) return [];

    final field = _fields.firstWhere((f) => f.id == _selectedFieldId);
    final coords = field.areaCoordinates;
    if (coords.isEmpty) return [];

    double minLat = coords[0][0], maxLat = coords[0][0];
    double minLng = coords[0][1], maxLng = coords[0][1];
    for (var c in coords) {
      if (c[0] < minLat) minLat = c[0];
      if (c[0] > maxLat) maxLat = c[0];
      if (c[1] < minLng) minLng = c[1];
      if (c[1] > maxLng) maxLng = c[1];
    }

    double latStep = (maxLat - minLat) / 10;
    double lngStep = (maxLng - minLng) / 10;

    List<Polygon> polygons = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        double top = maxLat - (r * latStep);
        double bottom = maxLat - ((r + 1) * latStep);
        double left = minLng + (c * lngStep);
        double right = minLng + ((c + 1) * lngStep);

        polygons.add(Polygon(
          points: [
            LatLng(top, left),
            LatLng(top, right),
            LatLng(bottom, right),
            LatLng(bottom, left),
          ],
          color: _getNDVIColor(grid[r][c]),
          borderStrokeWidth: 0.5,
          borderColor: Colors.white24,
        ));
      }
    }
    return polygons;
  }

  bool _isModified() {
    return _irrigation != 0 || _nitrogen != 0.5 || _temperature != 25;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Aero-Twin MapView', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_fields.isNotEmpty)
            DropdownButton<String>(
              value: _selectedFieldId,
              dropdownColor: const Color(0xFF1E2128),
              underline: const SizedBox(),
              items: _fields.map((f) => DropdownMenuItem(
                value: f.id,
                child: Text(f.name, style: GoogleFonts.inter(color: Colors.white)),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedFieldId = val);
                _fetchNDVIData();
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
        : Stack(
            children: [
              _buildMap(),
              _buildOverlayUI(),
              if (_isModified()) _buildSimulatedBadge(),
            ],
          ),
    );
  }

  Widget _buildMap() {
    final field = _fields.firstWhere((f) => f.id == _selectedFieldId);
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _getFieldCenter(field),
        initialZoom: 17.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
          additionalOptions: const {'mapType': 'satellite'},
        ),
        PolygonLayer(
          polygons: _buildGridPolygons(),
        ),
      ],
    );
  }

  Widget _buildSimulatedBadge() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
        child: Row(
          children: [
            const Icon(Icons.science, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('SIMULATED STATE', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildIntelligencePanel(),
        const SizedBox(height: 16),
        _buildControlPanel(),
      ],
    );
  }

  Widget _buildIntelligencePanel() {
    final activeAlert = _simulationResult?.alert ?? _alert;
    if (activeAlert == null) return const SizedBox.shrink();

    final isSimulated = _simulationResult?.alert != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115).withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isSimulated ? Colors.orangeAccent : Colors.blueAccent).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSimulated ? Colors.orangeAccent : Colors.blueAccent).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSimulated ? Icons.analytics : Icons.auto_awesome, 
                  color: isSimulated ? Colors.orangeAccent : Colors.blueAccent, 
                  size: 24
                ),
                const SizedBox(width: 12),
                Text(
                  isSimulated ? 'SIMULATION INSIGHT' : 'FIELD INTELLIGENCE', 
                  style: GoogleFonts.outfit(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    letterSpacing: 1.2,
                  )
                ),
                const Spacer(),
                if (isSimulated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('PREDICTION', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              activeAlert.recommendation, 
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9), 
                fontSize: 14,
                height: 1.5,
              )
            ),
            if (activeAlert.issue != 'nominal' && activeAlert.issue != 'unknown') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Detected Issue: ${activeAlert.issue.replaceAll('_', ' ').toUpperCase()}',
                    style: GoogleFonts.inter(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2128),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _compactSlider('Irrigation', _irrigation, -50, 50, '%', 
                onChanged: (v) => setState(() => _irrigation = v),
                onChangedEnd: (_) => _runSimulation(),
              ),
              _compactSlider('Nitrogen', _nitrogen, 0, 1, '', 
                onChanged: (v) => setState(() => _nitrogen = v),
                onChangedEnd: (_) => _runSimulation(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _simpleSlider('Temperature', _temperature, 0, 50, '°C', 
            onChanged: (v) => setState(() => _temperature = v),
            onChangedEnd: (_) => _runSimulation(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isSimulating ? null : _runSimulation,
              child: _isSimulating 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Run Digital-Twin Simulation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _compactSlider(String label, double value, double min, double max, String unit, {
    required Function(double) onChanged,
    required Function(double) onChangedEnd,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
          Slider(
            value: value, 
            min: min, 
            max: max, 
            activeColor: Colors.blueAccent, 
            onChanged: onChanged,
            onChangeEnd: onChangedEnd,
          ),
          Text('${value.toStringAsFixed(0)}$unit', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _simpleSlider(String label, double value, double min, double max, String unit, {
    required Function(double) onChanged,
    required Function(double) onChangedEnd,
  }) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
        Expanded(
          child: Slider(
            value: value, 
            min: min, 
            max: max, 
            activeColor: Colors.blueAccent, 
            onChanged: onChanged,
            onChangeEnd: onChangedEnd,
          ),
        ),
        Text('${value.toStringAsFixed(1)}$unit', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
