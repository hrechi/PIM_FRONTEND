import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/parcel_provider.dart';
import '../models/aerotwin_model.dart';
import '../services/aerotwin_service.dart';

class AeroTwinScreen extends StatefulWidget {
  final String? fieldId;
  const AeroTwinScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  _AeroTwinScreenState createState() => _AeroTwinScreenState();
}

class _AeroTwinScreenState extends State<AeroTwinScreen> {
  final AeroTwinService _service = AeroTwinService();
  bool _isLoading = true;
  NDVIRecordModel? _ndviData;
  AeroTwinAlert? _alert;
  SimulationResult? _simulationResult;

  // Digital Twin Sliders
  double _irrigationChange = 0.0;
  double _temperature = 25.0;
  double _nitrogenLevel = 0.5;

  final MapController _mapController = MapController();
  // Assume a fixed center for demonstration purposes
  final LatLng _fieldCenter = const LatLng(36.8, 10.18); 
  final double _gridCellSize = 0.0005; // degree offset for each pixel mapping
  
  double? _selectedNDVI;
  String? _effectiveFieldId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoad();
    });
  }

  Future<void> _initializeAndLoad() async {
    if (widget.fieldId != null) {
       _effectiveFieldId = widget.fieldId;
    } else {
       final parcelProvider = Provider.of<ParcelProvider>(context, listen: false);
       if (parcelProvider.parcels.isEmpty) {
         await parcelProvider.fetchParcels();
       }
       if (parcelProvider.parcels.isNotEmpty) {
         _effectiveFieldId = parcelProvider.parcels.first.id;
       }
    }

    if (_effectiveFieldId == null) {
       if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No parcels found for Aero-Twin')));
       }
       return;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final ndvi = await _service.getNDVI(_effectiveFieldId!);
      final alert = await _service.getAlerts(_effectiveFieldId!);
      setState(() {
        _ndviData = ndvi;
        _alert = alert;
        _isLoading = false;
      });
    } catch (e) {
      if(mounted){
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _runSimulation() async {
     if (_effectiveFieldId == null) return;
     setState(() => _isLoading = true);
     try {
       final result = await _service.simulate(
         _effectiveFieldId!, 
         irrigationChange: _irrigationChange, 
         temperature: _temperature, 
         nitrogenLevel: _nitrogenLevel
       );
       if(mounted) {
         setState(() {
           _simulationResult = result;
           _isLoading = false;
         });
       }
     } catch(e) {
       if(mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulation failed: $e')));
       }
     }
  }

  Color _getColorForNDVI(double ndvi) {
    if (ndvi < 0.3) return Colors.red.withOpacity(0.6);
    if (ndvi < 0.5) return Colors.yellow.withOpacity(0.6);
    return Colors.greenAccent.withOpacity(0.6);
  }

  List<Polygon> _buildHeatmapPolygons() {
    List<List<double>> grid = _simulationResult?.predictedGrid ?? _ndviData?.gridData ?? [];
    if (grid.isEmpty) return [];

    List<Polygon> polygons = [];
    int rows = grid.length;
    int cols = grid[0].length;
    
    // Position the matrix centered on the field point
    double startLat = _fieldCenter.latitude + (rows / 2) * _gridCellSize;
    double startLng = _fieldCenter.longitude - (cols / 2) * _gridCellSize;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        double val = grid[i][j];
        
        double lat1 = startLat - (i * _gridCellSize);
        double lng1 = startLng + (j * _gridCellSize);
        double lat2 = lat1 - _gridCellSize;
        double lng2 = lng1 + _gridCellSize;

        polygons.add(Polygon(
          points: [
            LatLng(lat1, lng1),
            LatLng(lat1, lng2),
            LatLng(lat2, lng2),
            LatLng(lat2, lng1),
          ],
          color: _getColorForNDVI(val),
          isFilled: true,
          borderColor: Colors.black12,
          borderStrokeWidth: 1,
        ));
      }
    }
    return polygons;
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    List<List<double>> grid = _simulationResult?.predictedGrid ?? _ndviData?.gridData ?? [];
    if (grid.isEmpty) return;

    int rows = grid.length;
    int cols = grid[0].length;
    
    double startLat = _fieldCenter.latitude + (rows / 2) * _gridCellSize;
    double startLng = _fieldCenter.longitude - (cols / 2) * _gridCellSize;
    
    int rowId = ((startLat - point.latitude) / _gridCellSize).floor();
    int colId = ((point.longitude - startLng) / _gridCellSize).floor();

    if (rowId >= 0 && rowId < rows && colId >= 0 && colId < cols) {
      double val = grid[rowId][colId];
      setState(() {
         _selectedNDVI = val;
      });
    } else {
       setState(() {
         _selectedNDVI = null;
      });
    }
  }

  Widget _buildAlertPanel() {
    if (_alert == null) return const SizedBox.shrink();
    Color alertColor = _alert!.severity == 'high' 
        ? Colors.redAccent 
        : (_alert!.severity == 'medium' ? Colors.orangeAccent : Colors.greenAccent);
    IconData icon = _alert!.severity == 'high' 
        ? Icons.warning 
        : (_alert!.severity == 'medium' ? Icons.info_outline : Icons.check_circle_outline);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: alertColor),
              const SizedBox(width: 8),
              Expanded(child: Text('AI Insights - Groq Engine', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(_alert!.message, style: GoogleFonts.inter(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSimulationPanel() {
    return Container(
       padding: const EdgeInsets.all(20),
       decoration: const BoxDecoration(
         color: Color(0xFF1E2128),
         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisSize: MainAxisSize.min,
         children: [
           Text('Digital Twin Engine', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           _buildSlider('Irrigation Change (%)', _irrigationChange, -50, 50, (v) => setState(() => _irrigationChange = v)),
           _buildSlider('Temperature (°C)', _temperature, 0, 50, (v) => setState(() => _temperature = v)),
           _buildSlider('Nitrogen Level (0-1)', _nitrogenLevel, 0, 1, (v) => setState(() => _nitrogenLevel = v)),
           const SizedBox(height: 20),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF3B82F6), // Blue Accent
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               onPressed: _runSimulation,
               child: Text('Simulate Future Health', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
             ),
           ),
           if (_simulationResult != null)
             Container(
               margin: const EdgeInsets.only(top: 16.0),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
               child: Text(
                 '🔮 Predicted Avg NDVI: ${_simulationResult!.predictedAvgNDVI.toStringAsFixed(2)} | Risk Zones: ${_simulationResult!.riskZonesCount}',
                 style: GoogleFonts.inter(color: Colors.lightBlueAccent, fontWeight: FontWeight.w600),
               ),
             )
         ]
       ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(label, style: GoogleFonts.inter(color: Colors.white70)),
             Text(value.toStringAsFixed(1), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
           ],
         ),
         Slider(
           value: value,
           min: min,
           max: max,
           activeColor: const Color(0xFF3B82F6),
           inactiveColor: Colors.white24,
           onChanged: onChanged,
         ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Deep dark premium
      appBar: AppBar(
        title: Text('Aero-Twin Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_simulationResult != null)
             IconButton(
               icon: const Icon(Icons.refresh, color: Colors.white),
               onPressed: () {
                 setState(() {
                   _simulationResult = null;
                   _selectedNDVI = null;
                 });
               },
               tooltip: 'Reset Simulaton',
             )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
              children: [
                _buildAlertPanel(),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.white12, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _fieldCenter,
                              initialZoom: 16.0,
                              onTap: _onMapTap,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                              ),
                              PolygonLayer(
                                polygons: _buildHeatmapPolygons(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedNDVI != null)
                        Positioned(
                          top: 24,
                          right: 32,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getColorForNDVI(_selectedNDVI!), width: 2)
                            ),
                            child: Text(
                              'NDVI: ${_selectedNDVI!.toStringAsFixed(3)}',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 32,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                             color: Colors.black.withOpacity(0.7), 
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.white12)
                          ),
                          child: Row(
                            children: [
                               _legendItem(Colors.red.withOpacity(0.8), '< 0.3'),
                               const SizedBox(width: 12),
                               _legendItem(Colors.yellow.withOpacity(0.8), '0.3 - 0.5'),
                               const SizedBox(width: 12),
                               _legendItem(Colors.greenAccent.withOpacity(0.8), '> 0.5'),
                            ],
                          )
                        )
                      )
                    ],
                  ),
                ),
                _buildSimulationPanel(),
              ],
            ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
           width: 14, height: 14, 
           decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
