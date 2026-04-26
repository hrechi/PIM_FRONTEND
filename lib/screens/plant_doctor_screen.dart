import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../services/plant_doctor_history_service.dart';
import '../services/robot_api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import 'plant_doctor/plant_doctor_history_screen.dart';
import 'plant_doctor/plant_doctor_result_screen.dart';
import 'robot/robot_capture_screen.dart';

class PlantDoctorScreen extends StatefulWidget {
  const PlantDoctorScreen({super.key});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _aiResult;

  // Robot capture state
  final RobotApiService _robotApi = RobotApiService();
  final PlantDoctorHistoryService _history = PlantDoctorHistoryService();
  bool _capturingFromRobot = false;
  bool _selectedIsVideo = false;
  File? _selectedVideoZip; // Original .zip of frames when capture is a video.
  String _selectedSource = 'gallery';
  String _imageFilename = 'plant.jpg';

  String get _apiUrl =>
      'http://${AppConfig.serverHost}:${AppConfig.plantDoctorPort}/analyze';

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _robotApi.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _selectedIsVideo = false;
        _selectedVideoZip = null;
        _selectedSource =
            source == ImageSource.camera ? 'camera' : 'gallery';
        _imageFilename = image.name;
        _aiResult = null;
      });
    }
  }

  Future<void> _captureFromRobot() async {
    if (_capturingFromRobot) return;
    setState(() => _capturingFromRobot = true);
    try {
      final robots = await _robotApi.listRobots();
      if (robots.isEmpty) {
        throw RobotApiException(
          'No robots are registered. Add one from the Robots screen first.',
        );
      }
      final robot = robots.first;
      if (!mounted) return;

      final result = await Navigator.of(context).push<RobotCaptureResult>(
        MaterialPageRoute(builder: (_) => RobotCaptureScreen(robot: robot)),
      );
      if (!mounted || result == null) return;

      Uint8List coverBytes;
      String coverName;
      if (result.isVideo) {
        // The capture screen returns a `.zip` of JPEG frames. Pull the
        // middle frame to send to the YOLO endpoint and use as the
        // thumbnail.
        coverBytes = await _extractCoverFrameFromZip(result.file);
        coverName = 'plant_video_cover.jpg';
      } else {
        coverBytes = await result.file.readAsBytes();
        coverName = 'plant_screenshot.jpg';
      }

      setState(() {
        _selectedImage = XFile(result.file.path);
        _imageBytes = coverBytes;
        _selectedIsVideo = result.isVideo;
        _selectedVideoZip = result.isVideo ? result.file : null;
        _selectedSource = 'robot';
        _imageFilename = coverName;
        _aiResult = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColorPalette.success,
          content: Text(result.isVideo
              ? 'Robot video captured. Tap "Diagnose Now" to analyze.'
              : 'Robot screenshot captured. Tap "Diagnose Now" to analyze.'),
        ),
      );
    } on RobotApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Robot capture failed: $e');
    } finally {
      if (mounted) setState(() => _capturingFromRobot = false);
    }
  }

  Future<Uint8List> _extractCoverFrameFromZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Accept any common image extension (be defensive about case + format).
    bool _isImage(String name) {
      final n = name.toLowerCase();
      return n.endsWith('.jpg') ||
          n.endsWith('.jpeg') ||
          n.endsWith('.png') ||
          n.endsWith('.webp') ||
          n.endsWith('.bmp');
    }

    final frames = archive
        .where((f) => f.isFile && _isImage(f.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (frames.isEmpty) {
      // Surface what was actually inside the zip so the user / logs can
      // see why no frames were found (e.g. only a manifest, wrong codec).
      final names = archive.where((f) => f.isFile).map((f) => f.name).toList();
      throw RobotApiException(
        'Recorded video contained no image frames. '
        'Zip contents: ${names.isEmpty ? '(empty)' : names.join(', ')}.',
      );
    }
    final mid = frames[frames.length ~/ 2];
    final data = mid.content;
    return data is Uint8List ? data : Uint8List.fromList(data as List<int>);
  }

  Future<void> _analyzePlant() async {
    if (_selectedImage == null || _imageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      // For robot videos we send the entire zip — the server picks a frame.
      // For everything else we send the (already extracted) image bytes.
      if (_selectedIsVideo && _selectedVideoZip != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _selectedVideoZip!.path,
          filename:
              'robot_recording_${DateTime.now().millisecondsSinceEpoch}.zip',
        ));
      } else {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: _imageFilename,
        ));
      }

      // Hard timeout so the UI never hangs if the server is unreachable.
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException(
            'Plant Doctor server did not respond within 90s. Is `python detect.py` running on $_apiUrl ?'),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map<String, dynamic>) {
          _showError('Unexpected response from Plant Doctor service.');
          return;
        }
        setState(() {
          _aiResult = data;
        });

        // Persist + open the dedicated result screen.
        try {
          final record = await _history.add(
            imageBytes: _imageBytes!,
            aiResult: data,
            isVideo: _selectedIsVideo,
            videoSource: _selectedVideoZip,
            source: _selectedSource,
          );
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlantDoctorResultScreen(
                  record: record,
                  onDelete: () async => _history.delete(record.id),
                ),
              ),
            );
          }
        } catch (e) {
          // Persistence failure should not break the diagnosis flow.
          debugPrint('Failed to save plant doctor history: $e');
        }
      } else {
        _showError(
            'Server Error ${response.statusCode}: ${response.body.isNotEmpty ? response.body : 'no body'}');
      }
    } on TimeoutException catch (e) {
      _showError(e.message ?? 'Request timed out.');
    } on SocketException catch (e) {
      _showError(
          'Cannot reach Plant Doctor server at $_apiUrl. Start it with `python detect.py` (Plant_Vision). Details: ${e.message}');
    } catch (e) {
      _showError('Failed to connect: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlantDoctorHistoryScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorPalette.alertError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'AI Plant Doctor 🌿',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColorPalette.emeraldGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive sizing: scale paddings, hero height and content width
          // so the screen looks right on small phones, big phones and tablets.
          final w = constraints.maxWidth;
          final h = MediaQuery.of(context).size.height;
          final isCompact = w < 380;
          final horizontalPad = w < 360 ? 12.0 : (w < 600 ? 16.0 : 24.0);
          // Make the photo hero fill the screen width and be tall enough
          // to read at a glance. Cap on big screens so it doesn't dominate.
          final heroHeight =
              math.min(h * 0.28, w * 0.6).clamp(180.0, 280.0).toDouble();
          final maxContentWidth = w < 800 ? double.infinity : 720.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPad, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 1. IMAGE UPLOAD AREA ---
                    GestureDetector(
                      onTap: () => _showImageSourceModal(),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: heroHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColorPalette.emeraldGreen
                                      .withOpacity(0.5),
                                  width: 2),
                              image: (_selectedImage != null &&
                                      _imageBytes != null)
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _selectedImage == null
                                ? Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: isCompact ? 44 : 60,
                                        color: AppColorPalette.emeraldGreen
                                            .withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          "Tap to upload plant photo",
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.bodyMedium(
                                            color: AppColorPalette.softSlate,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Camera • Gallery • Robot",
                                        style: AppTextStyles.bodySmall(
                                          color: AppColorPalette.softSlate,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          if (_selectedIsVideo)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Robot video',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 2. ANALYZE BUTTON ---
                    if (_isLoading)
                      const Center(
                child: CircularProgressIndicator(
                  color: AppColorPalette.emeraldGreen,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _selectedImage != null ? _analyzePlant : null,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(
                  "DIAGNOSE NOW",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorPalette.emeraldGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            // --- 3. PRO RESULTS DISPLAY ---
            if (_aiResult != null) ...[
              const SizedBox(height: 30),

              // A. Header with Name & Severity
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _aiResult!['name'] ?? 'Unknown Plant',
                      style: AppTextStyles.h2().copyWith(
                        color: AppColorPalette.charcoalGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _aiResult!['scientific_name'] ?? 'Species Unknown',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.softSlate,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    // Severity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(_aiResult!['severity']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "SEVERITY: ${(_aiResult!['severity'] ?? 'UNKNOWN').toString().toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // B. Diagnosis Card
              _buildSectionTitle("🔍 Diagnosis"),
              _buildInfoCard(
                content: _aiResult!['diagnosis'] ?? 'No diagnosis available.',
                icon: Icons.biotech,
                color: AppColorPalette.info,
              ),

              const SizedBox(height: 20),

              // C. Treatment Steps (List)
              _buildSectionTitle("💊 Treatment Plan"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColorPalette.success.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_aiResult!['treatment_steps'] != null &&
                        _aiResult!['treatment_steps'] is List)
                      ...(_aiResult!['treatment_steps'] as List)
                          .map(
                            (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: AppColorPalette.success, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step.toString(),
                                  style: AppTextStyles.bodyMedium(color: AppColorPalette.charcoalGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text(
                        "No specific steps provided. Consult an expert.",
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // D. Prevention Tip
              _buildSectionTitle("🛡️ Prevention"),
              _buildInfoCard(
                content:
                    _aiResult!['prevention'] ?? 'Keep monitoring regularly.',
                icon: Icons.shield,
                color: Colors.orange,
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER METHODS ---

  // 1. Get Severity Color
  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return AppColorPalette.alertError; // Red
      case 'medium':
        return Colors.orange; // Orange
      case 'low':
        return AppColorPalette.success; // Green
      default:
        return Colors.grey;
    }
  }

  // 2. Simple Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: AppTextStyles.h3().copyWith(
          color: AppColorPalette.charcoalGreen,
        ),
      ),
    );
  }

  // 3. Generic Info Card
  Widget _buildInfoCard({
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Modal to choose Camera vs Gallery
  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColorPalette.emeraldGreen,
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColorPalette.emeraldGreen,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: _capturingFromRobot
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColorPalette.emeraldGreen,
                      ),
                    )
                  : const Icon(
                      Icons.smart_toy,
                      color: AppColorPalette.emeraldGreen,
                    ),
              title: const Text('Robot Camera'),
              subtitle: const Text(
                  'Take a screenshot or record a short video from the field robot'),
              onTap: _capturingFromRobot
                  ? null
                  : () {
                      Navigator.pop(context);
                      _captureFromRobot();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
