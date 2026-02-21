import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class PlantDoctorScreen extends StatefulWidget {
  const PlantDoctorScreen({super.key});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _aiResult;

  // ⚠️ IMPORTANT:
  // Android Emulator: 'http://10.0.2.2:8000/analyze'
  // iPhone Simulator: 'http://localhost:8000/analyze'
  // Real Device: Use your computer's IP, e.g., 'http://192.168.1.15:8000/analyze'
  final String _apiUrl = 'http://localhost:8000/analyze';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _aiResult = null; // Reset previous results
      });
    }
  }

  Future<void> _analyzePlant() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Prepare the request
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      // 2. Send to Python Backend
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 3. Parse the JSON result
        final data = json.decode(response.body);
        setState(() {
          _aiResult = data;
        });
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Failed to connect: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColorPalette.alertError),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: const Text('AI Plant Doctor 🌿', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColorPalette.emeraldGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. IMAGE UPLOAD AREA ---
            GestureDetector(
              onTap: () => _showImageSourceModal(),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColorPalette.emeraldGreen.withOpacity(0.5), width: 2),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 60, color: AppColorPalette.emeraldGreen.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text("Tap to upload plant photo", style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate)),
                  ],
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. ANALYZE BUTTON ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColorPalette.emeraldGreen))
            else
              ElevatedButton.icon(
                onPressed: _selectedImage != null ? _analyzePlant : null,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text("DIAGNOSE NOW", style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorPalette.emeraldGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Text(
                      _aiResult!['name'] ?? 'Unknown Plant',
                      style: AppTextStyles.h2().copyWith(color: AppColorPalette.charcoalGreen),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _aiResult!['scientific_name'] ?? 'Species Unknown',
                      style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate).copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    // Severity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(_aiResult!['severity']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "SEVERITY: ${(_aiResult!['severity'] ?? 'UNKNOWN').toString().toUpperCase()}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                  border: Border.all(color: AppColorPalette.success.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    if (_aiResult!['treatment_steps'] != null && _aiResult!['treatment_steps'] is List)
                      ...(_aiResult!['treatment_steps'] as List).map(
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
                      ).toList()
                    else
                      const Text("No specific steps provided. Consult an expert."),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // D. Prevention Tip
              _buildSectionTitle("🛡️ Prevention"),
              _buildInfoCard(
                content: _aiResult!['prevention'] ?? 'Keep monitoring regularly.',
                icon: Icons.shield,
                color: Colors.orange,
              ),
              const SizedBox(height: 40),
            ]
          ],
        ),
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
        return Colors.orange;            // Orange
      case 'low':
        return AppColorPalette.success;     // Green
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
        style: AppTextStyles.h3().copyWith(color: AppColorPalette.charcoalGreen),
      ),
    );
  }

  // 3. Generic Info Card
  Widget _buildInfoCard({required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColorPalette.emeraldGreen),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColorPalette.emeraldGreen),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}