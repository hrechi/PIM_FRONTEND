import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../models/security_incident.dart';
import '../../services/api_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import 'incident_detail_screen.dart'; // same security/ folder

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
    switch (type) {
      case 'intruder':
        return Icons.person_off_rounded;
      case 'acoustic_engine':
        return Icons.directions_car_rounded;
      case 'acoustic_glass':
        return Icons.broken_image_rounded;
      case 'acoustic_loud':
        return Icons.volume_up_rounded;
      case 'acoustic_anomaly':
        return Icons.graphic_eq_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'intruder':
        return AppColorPalette.alertError;
      case 'acoustic_engine':
        return const Color(0xFFE65100);
      case 'acoustic_glass':
        return const Color(0xFF1565C0);
      case 'acoustic_loud':
        return const Color(0xFF6A1B9A);
      case 'acoustic_anomaly':
        return const Color(0xFF00ACC1);
      default:
        return AppColorPalette.warning;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'intruder':
        return 'Intruder Detected';
      case 'acoustic_engine':
        return 'Suspicious Engine';
      case 'acoustic_glass':
        return 'Glass Break / Impact';
      case 'acoustic_loud':
        return 'Loud Anomaly';
      case 'acoustic_anomaly':
        return 'Acoustic Threat';
      default:
        return 'Animal Detected';
    }
  }

  bool _isAcousticType(String type) => type.startsWith('acoustic');

  String _getSubtitleForType(String type) {
    switch (type) {
      case 'intruder':
        return 'Unrecognized face on property';
      case 'acoustic_engine':
        return 'Motor/vehicle sound near perimeter';
      case 'acoustic_glass':
        return 'High-freq impact — possible forced entry';
      case 'acoustic_loud':
        return 'Unusual loud sound detected';
      case 'acoustic_anomaly':
        return 'Sound anomaly by acoustic sensor';
      default:
        return 'Wildlife in restricted zone';
    }
  }

  Future<void> _createTestIncident(String type) async {
    try {
      // Get a test image from gallery or camera
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final file = File(image.path);

      // Get current location
      Position? position;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint('📍 Location service enabled: $serviceEnabled');

        if (!serviceEnabled) {
          debugPrint('📍 Location services are OFF — skipping GPS');
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          debugPrint('📍 Permission status: $permission');

          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            debugPrint('📍 After request, permission: $permission');
          }

          if (permission == LocationPermission.deniedForever) {
            debugPrint(
              '📍 Permission DENIED FOREVER — user must enable in Settings',
            );
          } else if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            debugPrint('📍 Getting current position...');
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 10));
            debugPrint(
              '📍 Got position: lat=${position.latitude}, lng=${position.longitude}',
            );
          }
        }
      } catch (e) {
        debugPrint('📍 Location error: $e');
      }

      // Create multipart request
      final uri = Uri.parse('${ApiService.baseUrl}/security/incidents');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] =
          'Bearer ${await ApiService.getAccessToken()}';
      request.fields['type'] = type;
      if (position != null) {
        request.fields['latitude'] = position.latitude.toString();
        request.fields['longitude'] = position.longitude.toString();
        debugPrint(
          '📤 Sending lat=${position.latitude}, lng=${position.longitude}',
        );
      } else {
        debugPrint('📤 No position available — sending WITHOUT lat/lng');
      }
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('📥 Response ${response.statusCode}: $responseBody');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$type incident created!')));
        _loadIncidents();
      } else {
        debugPrint('❌ Failed: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create incident: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteIncident(String id, int index) async {
    try {
      await ApiService.delete('/security/incidents/$id', withAuth: true);
      setState(() {
        _incidents.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Incident deleted'),
            backgroundColor: AppColorPalette.emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Restore the item if delete failed
      _loadIncidents();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColorPalette.mediumGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Test Incident',
              style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
            ),
            const SizedBox(height: 20),
            _testButton(
              'intruder',
              Icons.person_off_rounded,
              AppColorPalette.alertError,
              'Intruder',
            ),
            const SizedBox(height: 10),
            _testButton(
              'animal',
              Icons.pets_rounded,
              AppColorPalette.warning,
              'Animal',
            ),
          ],
        ),
      ),
    );
  }

  Widget _testButton(String type, IconData icon, Color color, String label) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _createTestIncident(type);
        },
        icon: Icon(icon),
        label: Text('Test: $label'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Incident History',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColorPalette.charcoalGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_incidents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorPalette.softSlate.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColorPalette.softSlate,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_incidents.length}',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColorPalette.fieldFreshMid,
        onRefresh: _loadIncidents,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColorPalette.fieldFreshMid,
                ),
              )
            : _incidents.isEmpty
            ? _buildEmptyState()
            : _buildIncidentList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTestOptions,
        backgroundColor: AppColorPalette.charcoalGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColorPalette.success.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 48,
              color: AppColorPalette.success.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Clear',
            style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
          ),
          const SizedBox(height: 8),
          Text(
            'No incidents recorded yet.',
            style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _incidents.length,
      itemBuilder: (context, index) {
        final incident = _incidents[index];
        return Dismissible(
          key: Key(incident.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(),
          onDismissed: (_) => _deleteIncident(incident.id, index),
          background: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColorPalette.alertError,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(
              Icons.delete_forever,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: _isAcousticType(incident.type)
              ? _buildAcousticCard(incident)
              : _buildGlassCard(incident),
        );
      },
    );
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Incident'),
        content: const Text('Are you sure you want to delete this incident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorPalette.softSlate),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorPalette.alertError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Glass Card (Intruder / Animal) ────────────────────────

  Widget _buildGlassCard(SecurityIncident incident) {
    final color = _getColorForType(incident.type);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(incidentId: incident.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColorPalette.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'incident-image-${incident.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${ApiService.mediaBaseUrl}${incident.imagePath}',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForType(incident.type),
                      color: color.withOpacity(0.5),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForType(incident.type),
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getLabelForType(incident.type),
                          style: AppTextStyles.label(
                            color: AppColorPalette.charcoalGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getSubtitleForType(incident.type),
                    style: AppTextStyles.caption(
                      color: AppColorPalette.softSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColorPalette.softSlate,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(incident.timestamp),
                        style: AppTextStyles.overline(
                          color: AppColorPalette.softSlate,
                        ),
                      ),
                      if (incident.latitude != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColorPalette.fieldFreshMid,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'GPS',
                          style: AppTextStyles.overline(
                            color: AppColorPalette.fieldFreshMid,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColorPalette.mediumGrey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Acoustic Card (Robot Tech gradient border + waveform) ──

  Widget _buildAcousticCard(SecurityIncident incident) {
    final color = _getColorForType(incident.type);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(incidentId: incident.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColorPalette.robotTechGradient,
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.robotTechStart.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Mini waveform thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(72, 72),
                        painter: _MiniWaveformPainter(color: color),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorPalette.healthGlow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AUDIO',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForType(incident.type),
                            color: color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getLabelForType(incident.type),
                            style: AppTextStyles.label(
                              color: AppColorPalette.charcoalGreen,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColorPalette.robotTechGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACOUSTIC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getSubtitleForType(incident.type),
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColorPalette.softSlate,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(incident.timestamp),
                          style: AppTextStyles.overline(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColorPalette.mediumGrey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Waveform Painter (static decorative for card thumbnails) ──

class _MiniWaveformPainter extends CustomPainter {
  final Color color;
  _MiniWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final midY = size.height / 2;
    const barCount = 20;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final amplitude = 0.15 + rng.nextDouble() * 0.7;
      final barHeight = amplitude * (size.height * 0.4);
      final x = i * barWidth + barWidth / 2;

      final paint = Paint()
        ..color = color.withOpacity(0.5 + amplitude * 0.5)
        ..strokeWidth = barWidth * 0.45
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, midY - barHeight),
        Offset(x, midY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
