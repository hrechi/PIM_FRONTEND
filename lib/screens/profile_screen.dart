import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'edit_profile_screen.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'My Profile',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Sign Out',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to logout?',
                                style: GoogleFonts.inter(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(
                                    'Logout',
                                    style: GoogleFonts.inter(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await auth.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const SignInScreen(),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'Sign Out',
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Profile Picture
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.fieldFreshGradient,
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.wheatWarmClay,
                      backgroundImage: user.profilePicture != null
                          ? NetworkImage(
                              '${ApiService.mediaBaseUrl}${user.profilePicture}',
                            )
                          : null,
                      child: user.profilePicture == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mistyBlue,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Farm Name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.agriculture_rounded,
                        size: 16,
                        color: AppColors.mistyBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.farmName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.mistyBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Info Cards
                  _InfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: user.email ?? 'Not added yet',
                    isEmpty: user.email == null,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: user.phone ?? 'Not added yet',
                    isEmpty: user.phone == null,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Member Since',
                    value: _formatDate(user.createdAt),
                  ),

                  const SizedBox(height: 32),

                  // Edit Profile button
                  CustomButton(
                    text: 'Edit Profile',
                    gradient: AppColors.fieldFreshGradient,
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Delete Account button
                  CustomButton(
                    text: 'Delete Account',
                    isOutlined: true,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.error,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _showDeleteDialog(context, auth),
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showDeleteDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await auth.deleteAccount();
              if (success && context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isEmpty;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wheatWarmClay,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mistyBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.mistyBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isEmpty
                        ? AppColors.secondaryText.withValues(alpha: 0.5)
                        : AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
