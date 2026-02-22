import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/security_incident.dart';
import '../services/api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  List<SecurityIncident> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '/security/incidents',
        withAuth: true,
      );
      final List<dynamic> data = response as List;
      setState(() {
        _incidents = data
            .map((json) => SecurityIncident.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load incidents: $e')));
      }
    }
  }

  IconData _getIconForType(String type) {
    return type == 'intruder' ? Icons.person : Icons.pets;
  }

  Color _getColorForType(String type) {
    return type == 'intruder'
        ? AppColorPalette.alertError
        : AppColorPalette.warning;
  }

  Future<void> _createTestIncident(String type) async {
    try {
      // Get a test image from gallery or camera
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final file = File(image.path);

      // Create multipart request
      final uri = Uri.parse('${ApiService.baseUrl}/security/incidents');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] =
          'Bearer ${await ApiService.getAccessToken()}';
      request.fields['type'] = type;
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$type incident created!')));
        _loadIncidents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create incident')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showTestOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Test Incident',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _createTestIncident('intruder');
              },
              icon: const Icon(Icons.person),
              label: const Text('Test: Intruder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.alertError,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _createTestIncident('animal');
              },
              icon: const Icon(Icons.pets),
              label: const Text('Test: Animal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.warning,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
        backgroundColor: AppColorPalette.emeraldGreen,
        foregroundColor: AppColorPalette.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadIncidents,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _incidents.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppColorPalette.softSlate.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No incidents recorded',
                      style: AppTextStyles.bodyLarge().copyWith(
                        color: AppColorPalette.softSlate.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _incidents.length,
                itemBuilder: (context, index) {
                  final incident = _incidents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Incident Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              '${ApiService.mediaBaseUrl}${incident.imagePath}',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColorPalette.lightGrey,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColorPalette.softSlate,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Incident Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getIconForType(incident.type),
                                      color: _getColorForType(incident.type),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      incident.type == 'intruder'
                                          ? 'Intruder Detected'
                                          : 'Animal Detected',
                                      style: AppTextStyles.h4().copyWith(
                                        color: _getColorForType(incident.type),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(incident.timestamp),
                                  style: AppTextStyles.bodySmall().copyWith(
                                    color: AppColorPalette.softSlate
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${incident.timestamp.hour.toString().padLeft(2, '0')}:${incident.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: AppTextStyles.bodySmall().copyWith(
                                    color: AppColorPalette.charcoalGreen
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTestOptions,
        tooltip: 'Create Test Incident',
        child: const Icon(Icons.add),
      ),
    );
  }
}
