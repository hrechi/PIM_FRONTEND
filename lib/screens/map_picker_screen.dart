import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

class MapPickerScreen extends StatefulWidget {
  final List<List<double>>? initialCoordinates;

  const MapPickerScreen({Key? key, this.initialCoordinates})
      : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();
  late List<LatLng> polygonPoints;
  double? areaSize;

  @override
  void initState() {
    super.initState();
    if (widget.initialCoordinates != null &&
        widget.initialCoordinates!.isNotEmpty) {
      polygonPoints = widget.initialCoordinates!
          .map((coord) => LatLng(coord[0], coord[1]))
          .toList();
      _calculateArea();
    } else {
      polygonPoints = [];
    }
  }

  void _calculateArea() {
    if (polygonPoints.length < 3) {
      setState(() => areaSize = null);
      return;
    }

    // Simple polygon area calculation (shoelace formula)
    double area = 0.0;
    for (int i = 0; i < polygonPoints.length; i++) {
      final p1 = polygonPoints[i];
      final p2 = polygonPoints[(i + 1) % polygonPoints.length];
      area += p1.latitude * p2.longitude - p2.latitude * p1.longitude;
    }
    area = (area.abs() / 2).toDouble();

    // Rough conversion to square meters (1 degree ≈ 111km)
    double areaInSqm = area * 111000 * 111000;

    setState(() => areaSize = areaInSqm);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      polygonPoints.add(point);
      _calculateArea();
    });
  }

  void _removeLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() {
        polygonPoints.removeLast();
        _calculateArea();
      });
    }
  }

  void _clearAll() {
    setState(() {
      polygonPoints.clear();
      areaSize = null;
    });
  }

  void _confirm() {
    if (polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark at least 3 points')),
      );
      return;
    }
    Navigator.pop(
      context,
      polygonPoints.map((p) => [p.latitude, p.longitude]).toList(),
    );
  }

  String _formatAreaSize() {
    if (areaSize == null) return 'Mark area';
    if (areaSize! < 1000000) {
      return '${(areaSize! / 10000).toStringAsFixed(2)} hectares';
    }
    return '${(areaSize!).toStringAsFixed(0)} m²';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Field Area'),
        backgroundColor: AppColors.mistBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: const LatLng(35.8989, 10.1592), // Tunisia center
              zoom: 8.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fieldly.app',
              ),
              if (polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      isFilled: true,
                      color:
                          AppColors.sageGreen.withOpacity(0.3),
                      borderColor: AppColors.mistBlue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: polygonPoints
                    .asMap()
                    .entries
                    .map(
                      (entry) => Marker(
                        point: entry.value,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onLongPress: () {
                            setState(() => polygonPoints.removeAt(entry.key));
                            _calculateArea();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.mistBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.wheat,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatAreaSize(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mistBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Points: ${polygonPoints.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _removeLastPoint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                              ),
                              icon: const Icon(Icons.undo,
                                  color: Colors.grey),
                              label: const Text('Undo',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _clearAll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[100],
                              ),
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              label: const Text('Clear',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirm,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mistBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Confirm Field Area',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
