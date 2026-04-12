import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/aerotwin_model.dart';
import '../models/field_model.dart';
import '../services/aerotwin_service.dart';
import '../services/field_service.dart';

class AeroTwinScreen extends StatefulWidget {
  final String? fieldId;
  const AeroTwinScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  _AeroTwinScreenState createState() => _AeroTwinScreenState();
}

class _AeroTwinScreenState extends State<AeroTwinScreen> {
  final AeroTwinService _service = AeroTwinService();
  final FieldService _fieldService = FieldService();
  final MapController _mapController = MapController();
  
  bool _isInitialLoading = true;
  bool _isSimulating = false;
  
  List<FieldModel> _fields = [];
  FieldModel? _selectedField;
  
  NDVIRecordModel? _ndviData;
  AeroTwinAlert? _alert;
  SimulationResult? _simulationResult;

  // Digital Twin Sliders
  double _irrigationChange = 0.0;
  double _temperature = 25.0;
  double _nitrogenLevel = 0.5;

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
        if (widget.fieldId != null) {
          _selectedField = _fields.firstWhere((f) => f.id == widget.fieldId, orElse: () => _fields.first);
        } else if (_fields.isNotEmpty) {
          _selectedField = _fields.first;
        }
      });
      if (_selectedField != null) {
        _loadData();
      } else {
        setState(() => _isInitialLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadData() async {
    if (_selectedField == null) return;
    setState(() => _isInitialLoading = true);
    try {
      final ndvi = await _service.getNDVI(_selectedField!.id);
      final alert = await _service.getAlerts(_selectedField!.id);
      setState(() {
        _ndviData = ndvi;
        _alert = alert;
        _simulationResult = null; 
        _isInitialLoading = false;
      });
      _centerMapOnField();
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _centerMapOnField() {
    if (_selectedField == null || _selectedField!.areaCoordinates.isEmpty) return;
    
    final coords = _selectedField!.areaCoordinates;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    
    for (var point in coords) {
      if (point.length < 2) continue;
      if (point[0] < minLat) minLat = point[0];
      if (point[0] > maxLat) maxLat = point[0];
      if (point[1] < minLng) minLng = point[1];
      if (point[1] > maxLng) maxLng = point[1];
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 16.0);
  }

  List<Polygon> _buildGridPolygons() {
    final grid = _simulationResult?.predictedGrid ?? _ndviData?.gridData ?? [];
    if (grid.isEmpty || _selectedField == null || _selectedField!.areaCoordinates.isEmpty) return [];

    final coords = _selectedField!.areaCoordinates;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var p in coords) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLng) minLng = p[1];
      if (p[1] > maxLng) maxLng = p[1];
    }

    final latStep = (maxLat - minLat) / 10;
    final lngStep = (maxLng - minLng) / 10;
    final List<Polygon> polygons = [];

    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            final val = grid[i][j] ?? 0.0;
            final cellMinLat = maxLat - ((i + 1) * latStep);
            final cellMaxLat = maxLat - (i * latStep);
            final cellMinLng = minLng + (j * lngStep);
            final cellMaxLng = minLng + ((j + 1) * lngStep);

            polygons.add(Polygon(
                points: [
                    LatLng(cellMaxLat, cellMinLng),
                    LatLng(cellMaxLat, cellMaxLng),
                    LatLng(cellMinLat, cellMaxLng),
                    LatLng(cellMinLat, cellMinLng),
                ],
                color: _getColorForNDVI(val).withOpacity(0.6),
                isFilled: true,
                borderColor: Colors.white10,
                borderStrokeWidth: 1.0,
            ));
        }
    }
    return polygons;
  }

  Future<void> _runSimulation() async {
    if (_selectedField == null) return;
    setState(() => _isSimulating = true);
    try {
      final result = await _service.simulate(
        _selectedField!.id,
        irrigationChange: _irrigationChange,
        temperature: _temperature,
        nitrogenLevel: _nitrogenLevel,
      );
      if (mounted) {
        setState(() {
          _simulationResult = result;
          _isSimulating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  Color _getColorForNDVI(double ndvi) {
    if (ndvi < 0.3) return Colors.red;
    if (ndvi < 0.5) return Colors.yellow;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Aero-Twin System', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildFieldSelector(),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : Column(
              children: [
                _buildAlertPanel(),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMap(),
                      if (_simulationResult != null) _buildSimulatedBadge(),
                      _buildLegend(),
                    ],
                  ),
                ),
                _buildSimulationPanel(),
              ],
            ),
    );
  }

  Widget _buildFieldSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: _selectedField?.id,
        dropdownColor: const Color(0xFF1E2128),
        underline: const SizedBox(),
        items: _fields.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (id) {
          if (id != null) {
            setState(() => _selectedField = _fields.firstWhere((f) => f.id == id));
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(36.8, 10.1),
            initialZoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            ),
            PolygonLayer(
              polygons: _buildGridPolygons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatedBadge() {
    return Positioned(
      top: 32,
      left: 32,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('SIMULATED: ${_simulationResult!.predictedAvgNDVI.toStringAsFixed(3)}', 
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white), onPressed: () => setState(() => _simulationResult = null)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      right: 32,
      bottom: 32,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1E2128).withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _legendItem(Colors.red, 'Stress'),
            const SizedBox(height: 8),
            _legendItem(Colors.yellow, 'Warning'),
            const SizedBox(height: 8),
            _legendItem(Colors.greenAccent, 'Healthy'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Widget _buildAlertPanel() {
    if (_alert == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E2128), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Color(0xFF3B82F6), size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(_alert!.recommendation, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSimulationPanel() {
    return Container(
       padding: const EdgeInsets.all(24),
       decoration: const BoxDecoration(color: Color(0xFF1E2128), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           _buildSlider('Irrigation', _irrigationChange, -50, 50, '%', (v) => setState(() => _irrigationChange = v)),
           _buildSlider('Temperature', _temperature, 0, 50, '°C', (v) => setState(() => _temperature = v)),
           _buildSlider('Nitrogen', _nitrogenLevel, 0, 1, '', (v) => setState(() => _nitrogenLevel = v)),
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             height: 52,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
               onPressed: _isSimulating ? null : _runSimulation,
               child: _isSimulating ? const CircularProgressIndicator(color: Colors.white) : const Text('Run Digital Simulation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             ),
           ),
         ],
       ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, String unit, Function(double) onChanged) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Expanded(child: Slider(value: value, min: min, max: max, activeColor: const Color(0xFF3B82F6), onChanged: onChanged)),
      SizedBox(width: 50, child: Text('${value.toStringAsFixed(1)}$unit', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
    ]);
  }
}
