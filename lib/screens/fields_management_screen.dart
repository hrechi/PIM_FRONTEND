import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/field_model.dart';
import '../services/field_service.dart';
import '../utils/constants.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import 'map_picker_screen.dart';

class FieldsManagementScreen extends StatefulWidget {
  const FieldsManagementScreen({Key? key}) : super(key: key);

  @override
  State<FieldsManagementScreen> createState() => _FieldsManagementScreenState();
}

class _FieldsManagementScreenState extends State<FieldsManagementScreen> {
  late FieldService fieldService;
  List<FieldModel> fields = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fieldService = FieldService();
    _loadFields();
  }

  String? _getFieldValidationError(String name, List<List<double>>? coordinates) {
    if (name.trim().isEmpty) return 'Field name is required';
    if (name.trim().length < 2) return 'Field name must be at least 2 characters';
    if (name.trim().length > 100) return 'Field name must not exceed 100 characters';
    if (coordinates == null || coordinates.isEmpty) return 'Field area must be marked on the map';
    if (coordinates.length < 3) return 'Field area requires at least 3 points (triangle)';
    return null;
  }

  Future<void> _loadFields() async {
    setState(() => isLoading = true);
    try {
      final loadedFields = await fieldService.getFields();
      setState(() => fields = loadedFields);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading fields: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addNewField() async {
    final nameController = TextEditingController();
    List<List<double>>? coordinates;
    double? areaSize;
    String? validationError;

    final result = await showDialog<Map<String, dynamic>>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        validationError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name *',
                    hintText: 'e.g., North Field',
                    helperText: 'Name must be 2-100 characters',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => validationError = null),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final mapResult = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPickerScreen(),
                      ),
                    );
                    if (mapResult != null) {
                      setState(() {
                        coordinates = mapResult['coordinates'] as List<List<double>>;
                        areaSize = mapResult['areaSize'] as double?;
                      });
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Mark Field Area on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mistBlue,
                  ),
                ),
                if (coordinates != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        Text(
                          'Field area marked (${coordinates!.length} points)',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (areaSize != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              areaSize! < 1000000
                                  ? 'Area: ${(areaSize! / 10000).toStringAsFixed(2)} hectares'
                                  : 'Area: ${(areaSize!).toStringAsFixed(0)} m²',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final error = _getFieldValidationError(nameController.text, coordinates);
                if (error != null) {
                  setState(() => validationError = error);
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'coordinates': coordinates,
                  'areaSize': areaSize,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mistBlue),
              child: const Text(
                'Create Field',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _createField(
        result['name'],
        result['coordinates'],
        result['areaSize'],
      );
    }
  }

  Future<void> _createField(
    String name,
    List<List<double>> coordinates,
    double? areaSize,
  ) async {
    try {
      await fieldService.createField(
        name: name,
        areaCoordinates: coordinates,
        areaSize: areaSize,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field created successfully')),
      );
      _loadFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating field: $e')),
      );
    }
  }

  Future<void> _editField(FieldModel field) async {
    final nameController = TextEditingController(text: field.name);
    List<List<double>>? coordinates = field.areaCoordinates;
    double? areaSize = field.areaSize;
    String? validationError;

    final result = await showDialog<Map<String, dynamic>>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        validationError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name *',
                    hintText: 'e.g., North Field',
                    helperText: 'Name must be 2-100 characters',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => validationError = null),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final mapResult = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapPickerScreen(
                          initialCoordinates: coordinates,
                        ),
                      ),
                    );
                    if (mapResult != null) {
                      setState(() {
                        coordinates = mapResult['coordinates'] as List<List<double>>;
                        areaSize = mapResult['areaSize'] as double?;
                      });
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Update Field Area on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mistBlue,
                  ),
                ),
                if (coordinates != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        Text(
                          'Field area (${coordinates!.length} points)',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (areaSize != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              areaSize! < 1000000
                                  ? 'Area: ${(areaSize! / 10000).toStringAsFixed(2)} hectares'
                                  : 'Area: ${(areaSize!).toStringAsFixed(0)} m²',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final error = _getFieldValidationError(nameController.text, coordinates);
                if (error != null) {
                  setState(() => validationError = error);
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'coordinates': coordinates,
                  'areaSize': areaSize,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mistBlue),
              child: const Text(
                'Update Field',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _updateField(
        field.id,
        result['name'],
        result['coordinates'],
        result['areaSize'],
      );
    }
  }

  Future<void> _updateField(
    String id,
    String name,
    List<List<double>> coordinates,
    double? areaSize,
  ) async {
    try {
      await fieldService.updateField(
        id: id,
        name: name,
        areaCoordinates: coordinates,
        areaSize: areaSize,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field updated successfully')),
      );
      _loadFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating field: $e')),
      );
    }
  }

  Future<void> _deleteField(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: const Text('Are you sure you want to delete this field?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await fieldService.deleteField(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field deleted successfully')),
        );
        _loadFields();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting field: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text('Manage Fields',
            style: AppTextStyles.h3().copyWith(color: Colors.white)),
        backgroundColor: AppColors.mistBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.landscape_outlined,
                          size: 72, color: Colors.grey[350]),
                      const SizedBox(height: 16),
                      Text('No fields yet',
                          style: AppTextStyles.h4()
                              .copyWith(color: AppColorPalette.charcoalGreen)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first field',
                          style: AppTextStyles.bodyMedium()
                              .copyWith(color: AppColorPalette.softSlate)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: fields.length,
                  itemBuilder: (context, index) =>
                      _buildFieldCard(fields[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewField,
        backgroundColor: AppColors.mistBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Field',
            style:
                AppTextStyles.buttonLarge().copyWith(color: Colors.white)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FIELD CARD WITH MAP PREVIEW
  // ─────────────────────────────────────────────────────────
  Widget _buildFieldCard(FieldModel field) {
    final coords = field.areaCoordinates;
    final hasCoords = coords.isNotEmpty;

    // Compute centroid for map center
    LatLng center = const LatLng(36.8, 10.18);
    List<LatLng> polygon = [];
    if (hasCoords) {
      double latSum = 0, lngSum = 0;
      for (final c in coords) {
        latSum += c[0];
        lngSum += c[1];
        polygon.add(LatLng(c[0], c[1]));
      }
      center = LatLng(latSum / coords.length, lngSum / coords.length);
    }

    final areaText = field.areaSize != null
        ? '${(field.areaSize! / 10000).toStringAsFixed(2)} ha'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Map preview ───────────────────────────────
          SizedBox(
            height: 160,
            width: double.infinity,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fieldly.app',
                  ),
                  if (polygon.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: polygon,
                          color: AppColors.mistBlue.withOpacity(0.25),
                          borderColor: AppColors.mistBlue,
                          borderStrokeWidth: 2.5,
                          isFilled: true,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Info + actions ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.mistBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.landscape,
                      color: AppColors.mistBlue, size: 24),
                ),
                const SizedBox(width: 12),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.name,
                          style: AppTextStyles.bodyLarge()
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _metaChip(Icons.crop_square, areaText),
                          if (field.cropType != null) ...[
                            const SizedBox(width: 8),
                            _metaChip(Icons.grass, field.cropType!),
                          ],
                          const SizedBox(width: 8),
                          _metaChip(Icons.place_outlined,
                              '${coords.length} pts'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                _actionButton(
                  icon: Icons.edit_outlined,
                  color: AppColors.mistBlue,
                  tooltip: 'Edit',
                  onTap: () => _editField(field),
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Icons.delete_outline,
                  color: Colors.red.shade400,
                  tooltip: 'Delete',
                  onTap: () => _deleteField(field.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColorPalette.softSlate),
        const SizedBox(width: 3),
        Text(text,
            style: AppTextStyles.caption()
                .copyWith(color: AppColorPalette.softSlate)),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
