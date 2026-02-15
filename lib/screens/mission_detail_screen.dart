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
