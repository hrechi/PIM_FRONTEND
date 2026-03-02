import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../models/field_model.dart';

/// Screen for picking a single location point on the map
class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final FieldModel? selectedField;

  const LocationPickerScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.selectedField,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController mapController = MapController();
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else if (widget.selectedField != null && widget.selectedField!.areaCoordinates.isNotEmpty) {
      // Set initial location to center of field
      final coords = widget.selectedField!.areaCoordinates;
      double avgLat = coords.map((c) => c[0]).reduce((a, b) => a + b) / coords.length;
      double avgLng = coords.map((c) => c[1]).reduce((a, b) => a + b) / coords.length;
      selectedLocation = LatLng(avgLat, avgLng);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      selectedLocation = point;
    });
  }

  void _confirm() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }
    Navigator.pop(
      context,
      {
        'latitude': selectedLocation!.latitude,
        'longitude': selectedLocation!.longitude,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = selectedLocation ?? const LatLng(35.8989, 10.1592); // Tunisia center

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          widget.selectedField != null 
            ? 'Select location in ${widget.selectedField!.name}'
            : 'Select Location',
          style: AppTextStyles.h3(),
        ),
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
              initialCenter: initialCenter,
              initialZoom: 13.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fieldly.app',
              ),
              // Show field boundary if field is selected
              if (widget.selectedField != null && widget.selectedField!.areaCoordinates.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.selectedField!.areaCoordinates
                          .map((coord) => LatLng(coord[0], coord[1]))
                          .toList(),
                      isFilled: true,
                      color: AppColorPalette.fieldFreshStart.withOpacity(0.3),
                      borderColor: AppColorPalette.fieldFreshStart,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Instructions at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorPalette.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: AppColorPalette.mistyBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap on the map to select measurement location',
                      style: AppTextStyles.bodyMedium(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel with coordinates and confirm button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorPalette.white,
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
                  if (selectedLocation != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColorPalette.mistyBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                          style: AppTextStyles.bodyMedium(),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: AppTextStyles.bodyMedium(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (selectedLocation == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'No location selected',
                        style: AppTextStyles.bodyMedium(
                          color: AppColorPalette.softSlate,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (selectedLocation != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => selectedLocation = null);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ),
                      if (selectedLocation != null) const SizedBox(width: 12),
                      Expanded(
                        flex: selectedLocation != null ? 2 : 1,
                        child: ElevatedButton.icon(
                          onPressed: _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorPalette.mistyBlue,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text(
                            'Confirm Location',
                            style: TextStyle(color: AppColorPalette.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
