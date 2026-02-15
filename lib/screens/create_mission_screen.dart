import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../models/field_model.dart';
import '../services/mission_service.dart';
import '../services/field_service.dart';
import '../utils/constants.dart';

class CreateMissionScreen extends StatefulWidget {
  final String? fieldId;

  const CreateMissionScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  late MissionService missionService;
  late FieldService fieldService;
  
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  
  List<FieldModel> fields = [];
  String? selectedFieldId;
  String selectedType = 'OTHER';
  String selectedPriority = 'MEDIUM';
  DateTime? selectedDueDate;
  int? estimatedDuration;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    missionService = MissionService();
    fieldService = FieldService();
    selectedFieldId = widget.fieldId;
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final loadedFields = await fieldService.getFields();
      setState(() {
        fields = loadedFields;
        if (selectedFieldId == null && loadedFields.isNotEmpty) {
          selectedFieldId = loadedFields.first.id;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading fields: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => selectedDueDate = date);
    }
  }

  Future<void> _createMission() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission title is required')),
      );
      return;
    }
    if (selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a field')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await missionService.createMission(
        fieldId: selectedFieldId!,
        title: titleController.text,
        description:
            descriptionController.text.isEmpty ? null : descriptionController.text,
        missionType: selectedType,
        priority: selectedPriority,
        dueDate: selectedDueDate,
        estimatedDuration: estimatedDuration,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating mission: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Mission'),
        backgroundColor: AppColors.mistBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Mission Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedFieldId,
            decoration: const InputDecoration(
              labelText: 'Select Field',
              border: OutlineInputBorder(),
            ),
            items: fields
                .map((field) => DropdownMenuItem(
                      value: field.id,
                      child: Text(field.name),
                    ))
                .toList(),
            onChanged: (value) => setState(() => selectedFieldId = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Mission Title',
              border: OutlineInputBorder(),
              hintText: 'e.g., Spring Planting',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
              hintText: 'Provide task details...',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(
              labelText: 'Mission Type',
              border: OutlineInputBorder(),
            ),
            items: ['PLANTING', 'WATERING', 'FERTILIZING', 'PESTICIDE', 'HARVESTING', 'OTHER']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedType = value ?? 'OTHER'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedPriority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT']
                .map((priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedPriority = value ?? 'MEDIUM'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(selectedDueDate == null
                ? 'Due Date (optional)'
                : 'Due: ${selectedDueDate!.toLocal().toString().split(' ')[0]}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Estimated Duration (minutes)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 480',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) =>
                setState(() => estimatedDuration = int.tryParse(value)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Additional notes...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _createMission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mistBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Mission',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
