import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'edit_profile_screen.dart';
import 'signin_screen.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showTimeoutError = false;

  @override
  void initState() {
    super.initState();
    // If user is not loaded after 5 seconds, show timeout error
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.user == null &&
            auth.errorMessage == null &&
            !_showTimeoutError) {
          setState(() {
            _showTimeoutError = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          final isWorker = user?.role.toUpperCase() == 'WORKER';

          if (user == null) {
            // Check if there's an error
            if (auth.errorMessage != null || _showTimeoutError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showTimeoutError
                            ? 'Connection Timeout'
                            : 'Session Expired',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        auth.errorMessage ??
                            'Could not load profile. Please sign in again.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        child: Text(
                          'Go to Sign In',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Still loading
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
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
                          Builder(
                            builder: (context) => IconButton(
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu_rounded),
                              style: IconButton.styleFrom(
                                foregroundColor: AppColors.primaryText,
                              ),
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

                  // Account type / farm context
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWorker ? Icons.badge_outlined : Icons.agriculture_rounded,
                        size: 16,
                        color: AppColors.mistyBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isWorker ? 'Worker account' : user.farmName,
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
                  if (isWorker && (user.username?.isNotEmpty ?? false)) ...[
                    _InfoCard(
                      icon: Icons.alternate_email,
                      title: 'Username',
                      value: user.username!,
                    ),
                    const SizedBox(height: 12),
                  ],
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

                  if (!isWorker) ...[
                    // Delete Account button
                    CustomButton(
                      text: 'Delete Account',
                      isOutlined: true,
                      backgroundColor: AppColors.error,
                      textColor: AppColors.error,
                      icon: Icons.delete_outline_rounded,
                      onPressed: () => _showDeleteDialog(context, auth),
                    ),
                  ],

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
