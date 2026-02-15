import 'package:flutter/material.dart';
import '../models/field_model.dart';
import '../services/field_service.dart';
import '../utils/constants.dart';
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
    final cropController = TextEditingController();
    List<List<double>>? coordinates;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Field Name',
                    hintText: 'e.g., North Field',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cropController,
                  decoration: const InputDecoration(
                    labelText: 'Crop Type (optional)',
                    hintText: 'e.g., Wheat',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push<List<List<double>>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPickerScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() => coordinates = result);
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
                    child: Text(
                      'Field area marked (${coordinates!.length} points)',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Field name is required')),
                  );
                  return;
                }
                if (coordinates == null || coordinates!.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please mark the field area')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text,
                  'cropType': cropController.text.isEmpty
                      ? null
                      : cropController.text,
                  'coordinates': coordinates,
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
        result['cropType'],
        result['coordinates'],
      );
    }
  }

  Future<void> _createField(
    String name,
    String? cropType,
    List<List<double>> coordinates,
  ) async {
    try {
      await fieldService.createField(
        name: name,
        cropType: cropType,
        areaCoordinates: coordinates,
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
      appBar: AppBar(
        title: const Text('Manage Fields'),
        backgroundColor: AppColors.mistBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                      Icon(
                        Icons.landscape,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No fields yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first field to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: fields.length,
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.landscape,
                                  color: AppColors.mistBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        field.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (field.cropType != null)
                                        Text(
                                          'Crop: ${field.cropType}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (field.areaSize != null)
                              Text(
                                'Area: ${(field.areaSize! / 10000).toStringAsFixed(2)} hectares',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    // Edit field (optional)
                                  },
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.mistBlue),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteField(field.id),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewField,
        backgroundColor: AppColors.mistBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Field'),
      ),
    );
  }
}
