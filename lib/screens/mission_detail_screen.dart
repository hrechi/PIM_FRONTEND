import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';
import '../utils/constants.dart';

class MissionDetailScreen extends StatefulWidget {
  final MissionModel mission;

  const MissionDetailScreen({Key? key, required this.mission})
      : super(key: key);

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  late MissionService missionService;
  late MissionModel currentMission;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    missionService = MissionService();
    currentMission = widget.mission;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => isLoading = true);
    try {
      final updated = await missionService.updateMissionStatus(
        id: currentMission.id,
        status: newStatus,
      );
      setState(() => currentMission = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProgress(int value) async {
    setState(() => isLoading = true);
    try {
      final updated = await missionService.updateMissionProgress(
        id: currentMission.id,
        progress: value,
      );
      setState(() => currentMission = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editMission() async {
    final titleController = TextEditingController(text: currentMission.title);
    final descriptionController = TextEditingController(text: currentMission.description ?? '');
    final notesController = TextEditingController(text: currentMission.notes ?? '');
    
    String selectedType = currentMission.missionType;
    String selectedPriority = currentMission.priority;
    DateTime? selectedDueDate = currentMission.dueDate;
    int? estimatedDuration = currentMission.estimatedDuration;
    String? validationError;

    final result = await showDialog<Map<String, dynamic>>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Mission'),
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
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Mission Title *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Spring Planting',
                    helperText: 'Required - 3 to 255 characters',
                  ),
                  onChanged: (value) => setState(() => validationError = null),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Provide task details...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Mission Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['PLANTING', 'WATERING', 'FERTILIZING', 'PESTICIDE', 'HARVESTING', 'OTHER']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedType = value ?? currentMission.missionType),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT']
                      .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedPriority = value ?? currentMission.priority),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(selectedDueDate == null
                      ? 'Due Date (optional)'
                      : 'Due: ${selectedDueDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDueDate = date);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Estimated Duration (minutes)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 480',
                    helperText: 'Optional - must be positive if provided',
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: estimatedDuration?.toString() ?? ''),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    setState(() => estimatedDuration = parsed);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Additional notes...',
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
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  setState(() => validationError = 'Mission title is required');
                  return;
                }
                if (title.length < 3) {
                  setState(() => validationError = 'Mission title must be at least 3 characters');
                  return;
                }
                if (title.length > 255) {
                  setState(() => validationError = 'Mission title must not exceed 255 characters');
                  return;
                }
                if (estimatedDuration != null && estimatedDuration! <= 0) {
                  setState(() => validationError = 'Estimated duration must be a positive number');
                  return;
                }
                if (selectedDueDate != null) {
                  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  if (selectedDueDate!.isBefore(today)) {
                    setState(() => validationError = 'Due date cannot be in the past');
                    return;
                  }
                }
                
                Navigator.pop(context, {
                  'title': title,
                  'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                  'missionType': selectedType,
                  'priority': selectedPriority,
                  'dueDate': selectedDueDate,
                  'estimatedDuration': estimatedDuration,
                  'notes': notesController.text.isEmpty ? null : notesController.text,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mistBlue),
              child: const Text(
                'Update Mission',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _updateMissionDetails(result);
    }
  }

  Future<void> _updateMissionDetails(Map<String, dynamic> updates) async {
    setState(() => isLoading = true);
    try {
      final updated = await missionService.updateMission(
        id: currentMission.id,
        title: updates['title'],
        description: updates['description'],
        missionType: updates['missionType'],
        priority: updates['priority'],
        dueDate: updates['dueDate'],
        estimatedDuration: updates['estimatedDuration'],
        notes: updates['notes'],
      );
      setState(() => currentMission = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating mission: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteMission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mission?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_rounded,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${currentMission.title}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        await missionService.deleteMission(currentMission.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mission deleted successfully')),
          );
          Navigator.pop(context, true); // Signal that mission was deleted
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting mission: $e')),
          );
        }
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Details'),
        backgroundColor: AppColors.mistBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: isLoading ? null : _editMission,
            tooltip: 'Edit Mission',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: isLoading ? null : _deleteMission,
            tooltip: 'Delete Mission',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  currentMission.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentMission.status)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: 120,
                  child: Text(
                    currentMission.status,
                    style: TextStyle(
                      color: _getStatusColor(currentMission.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection('Description', currentMission.description ?? 'N/A'),
                _buildSection('Mission Type', currentMission.missionType),
                _buildSection('Priority', currentMission.priority),
                const SizedBox(height: 24),
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentMission.progress / 100,
                    minHeight: 8,
                    backgroundColor:
                        AppColors.sageGreen.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.mistBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: currentMission.progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: '${currentMission.progress}%',
                  onChanged: (value) =>
                      _updateProgress(value.toInt()),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                        .map(
                          (status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: currentMission.status == status
                                  ? null
                                  : () => _updateStatus(status),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    currentMission.status == status
                                        ? _getStatusColor(status)
                                        : Colors.grey[300],
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: currentMission.status == status
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (currentMission.dueDate != null) ...[
                  const SizedBox(height: 24),
                  _buildSection(
                    'Due Date',
                    currentMission.dueDate!
                        .toLocal()
                        .toString()
                        .split(' ')[0],
                  ),
                ],
                if (currentMission.notes != null &&
                    currentMission.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSection('Notes', currentMission.notes!),
                ],
              ],
            ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
