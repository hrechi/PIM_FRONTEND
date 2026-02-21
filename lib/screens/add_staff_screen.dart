import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

/// Screen that lets the farmer add a staff member to the security whitelist.
/// Captures a name and a face photo, then uploads both as a multipart request.
class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Image selection ─────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Photo',
                style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColorPalette.fieldFreshStart.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColorPalette.fieldFreshStart,
                  ),
                ),
                title: Text('Take a Photo', style: AppTextStyles.bodyLarge()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColorPalette.fieldFreshStart.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColorPalette.fieldFreshStart,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTextStyles.bodyLarge(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a photo', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.uploadStaff(
        _nameController.text.trim(),
        _selectedImage!.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Staff member added to whitelist!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.of(context).pop(true); // return true = added successfully
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        backgroundColor: AppColorPalette.wheatWarmClay,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColorPalette.charcoalGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Staff',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // ── Photo Section ──────────────────────────────
                Text(
                  'Staff Photo',
                  style: AppTextStyles.h2(color: AppColorPalette.charcoalGreen),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take or select a clear face photo for recognition',
                  style: AppTextStyles.bodySmall(
                    color: AppColorPalette.softSlate,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── Image Preview ──────────────────────────────
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedImage != null
                            ? AppColorPalette.fieldFreshStart
                            : AppColorPalette.mediumGrey,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorPalette.charcoalGreen.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _selectedImage!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: 48,
                                color: AppColorPalette.softSlate.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to add photo',
                                style: AppTextStyles.bodySmall(
                                  color: AppColorPalette.softSlate,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                if (_selectedImage != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Change photo', style: GoogleFonts.inter()),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColorPalette.fieldFreshStart,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Name Field ─────────────────────────────────
                CustomTextField(
                  controller: _nameController,
                  hintText: 'e.g. Ahmed Ben Ali',
                  label: 'Staff Name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the staff name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // ── Submit Button ──────────────────────────────
                CustomButton(
                  text: 'Add to Whitelist',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  gradient: AppColors.fieldFreshGradient,
                  icon: Icons.shield_rounded,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
