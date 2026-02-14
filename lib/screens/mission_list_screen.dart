import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../models/field_model.dart';
import '../services/mission_service.dart';
import '../services/field_service.dart';
import '../theme/color_palette.dart';
import 'create_mission_screen.dart';
import 'mission_detail_screen.dart';

class MissionListScreen extends StatefulWidget {
  final String? fieldId;

  const MissionListScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  State<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends State<MissionListScreen> {
  late MissionService missionService;
  late FieldService fieldService;
  List<MissionModel> missions = [];
  List<FieldModel> fields = [];
  bool isLoading = false;
  String? selectedStatus;
  String? selectedPriority;

  @override
  void initState() {
    super.initState();
    missionService = MissionService();
    fieldService = FieldService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final loadedMissions =
          await missionService.getMissions(fieldId: widget.fieldId);
      final loadedFields = await fieldService.getFields();
      setState(() {
        missions = loadedMissions;
        fields = loadedFields;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<MissionModel> get filteredMissions {
    return missions.where((mission) {
      if (selectedStatus != null && mission.status != selectedStatus) {
        return false;
      }
      if (selectedPriority != null && mission.priority != selectedPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  String _getFieldName(String fieldId) {
    try {
      return fields.firstWhere((f) => f.id == fieldId).name;
    } catch (e) {
      return 'Unknown Field';
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
        title: const Text('Missions'),
        backgroundColor: AppColors.mistBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          hint: const Text('Filter by Status'),
                          isExpanded: true,
                          items: ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                              .map((status) =>
                                  DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedStatus = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedStatus != null)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => selectedStatus = null),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredMissions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No missions',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMissions.length,
                          itemBuilder: (context, index) {
                            final mission = filteredMissions[index];
                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MissionDetailScreen(mission: mission),
                                  ),
                                );
                                _loadData();
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  mission.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Field: ${_getFieldName(mission.fieldId)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      mission.status)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              mission.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(
                                                    mission.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: mission.progress / 100,
                                          minHeight: 6,
                                          backgroundColor:
                                              AppColors.sageGreen
                                                  .withOpacity(0.3),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.mistBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Progress: ${mission.progress.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateMissionScreen(fieldId: widget.fieldId),
            ),
          );
          _loadData();
        },
        backgroundColor: AppColors.mistBlue,
        icon: const Icon(Icons.add),
        label: const Text('New Mission'),
      ),
    );
  }
}
