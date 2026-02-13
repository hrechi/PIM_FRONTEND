import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isUploadingPicture = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _farmNameController.text = user.farmName;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final auth = context.read<AuthProvider>();
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingPicture = true);
    await auth.uploadProfilePicture(picked.path);
    if (!mounted) return;
    setState(() => _isUploadingPicture = false);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    final success = await auth.updateProfile(
      name: _nameController.text.trim() != user.name
          ? _nameController.text.trim()
          : null,
      farmName: _farmNameController.text.trim() != user.farmName
          ? _farmNameController.text.trim()
          : null,
      email: _emailController.text.trim() != (user.email ?? '')
          ? _emailController.text.trim()
          : null,
      phone: _phoneController.text.trim() != (user.phone ?? '')
          ? _phoneController.text.trim()
          : null,
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.inter()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Profile picture editor
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.fieldFreshGradient,
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.wheatWarmClay,
                          backgroundImage: user.profilePicture != null
                              ? NetworkImage(
                                  '${ApiService.baseUrl.replaceAll('/api', '')}${user.profilePicture}')
                              : null,
                          child: _isUploadingPicture
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2.5)
                              : (user.profilePicture == null
                                  ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mistyBlue,
                                      ),
                                    )
                                  : null),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPicture ? null : _pickAndUploadImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.mistyBlue,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Name
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Enter your name',
                    label: 'Name',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) => Validators.required(v, 'Name'),
                  ),
                  const SizedBox(height: 16),

                  // Farm Name
                  CustomTextField(
                    controller: _farmNameController,
                    hintText: 'Enter your farm name',
                    label: 'Farm Name',
                    prefixIcon: Icons.agriculture_rounded,
                    validator: (v) => Validators.required(v, 'Farm name'),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    hintText: user.email != null
                        ? 'Update your email'
                        : 'Add your email',
                    label: user.email != null ? 'Email' : 'Add Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  CustomTextField(
                    controller: _phoneController,
                    hintText: user.phone != null
                        ? 'Update your phone'
                        : 'Add your phone number',
                    label: user.phone != null ? 'Phone' : 'Add Phone',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 16),

                  // New Password (optional)
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Leave blank to keep current',
                    label: 'New Password (optional)',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // optional
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Error message
                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Save button
                  CustomButton(
                    text: 'Save Changes',
                    gradient: AppColors.emeraldGradient,
                    isLoading: auth.isLoading,
                    onPressed: _handleSave,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
