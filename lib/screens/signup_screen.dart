import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'signin_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // false = email, true = phone
  bool _usePhone = false;

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      name: _nameController.text.trim(),
      farmName: _farmNameController.text.trim(),
      email: _usePhone ? null : _emailController.text.trim(),
      phone: _usePhone ? _phoneController.text.trim() : null,
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/agricole_icon2.gif',
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Center(
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Center(
                    child: Text(
                      'Join Fieldly to manage your farm',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Enter your full name',
                  label: 'Full Name',
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

                // Contact method toggle
                Text(
                  'Contact Method',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondaryText.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _usePhone = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_usePhone
                                  ? AppColors.mistyBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 18,
                                    color: !_usePhone
                                        ? Colors.white
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Email',
                                    style: GoogleFonts.inter(
                                      color: !_usePhone
                                          ? Colors.white
                                          : AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _usePhone = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _usePhone
                                  ? AppColors.mistyBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 18,
                                    color: _usePhone
                                        ? Colors.white
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Phone',
                                    style: GoogleFonts.inter(
                                      color: _usePhone
                                          ? Colors.white
                                          : AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Email or Phone field
                if (!_usePhone)
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.requiredEmail,
                  )
                else
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'Enter your phone number',
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.requiredPhone,
                  ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Create a password',
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                ),

                const SizedBox(height: 12),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage != null) {
                      return Padding(
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 8),

                // Sign Up button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: 'Create Account',
                      gradient: AppColors.fieldFreshGradient,
                      isLoading: auth.isLoading,
                      onPressed: _handleSignUp,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Sign In link
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.inter(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const SignInScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                            color: AppColors.mistyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
