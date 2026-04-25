import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/agricultural_news_screen.dart';
import '../screens/harvest_analytics_screen.dart';
import '../screens/aerotwin_screen.dart';
import '../screens/crop_calendar_screen.dart';
import '../providers/auth_provider.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../screens/home_screen.dart';
import '../screens/farmer_home_screen_v2.dart';
import '../screens/animals/animal_list_screen.dart';
import '../screens/animals/add_animal_screen.dart';
import '../screens/animals/planned_sales_screen.dart';
import '../screens/animals/milk_production_screen.dart';
import '../screens/animals/milk_analytics_screen.dart';
import '../screens/vaccines/vaccine_dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/parcel_list_screen.dart';
import '../screens/plant_doctor_screen.dart';
import '../screens/staff_list_screen.dart';
import '../screens/add_staff_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/irrigation_scheduler_screen.dart';
import '../screens/live_feed_screen.dart';
import '../screens/soil/soil_measurements_list_screen.dart';
import '../screens/security/incident_history_screen.dart';
import '../screens/shorts_screen.dart';
import '../screens/community_feed_screen.dart';
import '../screens/finance/finance_dashboard_screen.dart';
import '../screens/catalogue_list_screen.dart';
import '../screens/signin_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role.toUpperCase() ?? 'OWNER';
    final isWorker = role == 'WORKER';

    if (isWorker) {
      return Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppColorPalette.fieldFreshGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/agricole_icon2.gif',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fieldly Worker',
                      style: AppTextStyles.h2(color: AppColorPalette.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Material operations',
                      style: AppTextStyles.bodySmall(
                        color: AppColorPalette.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerSection('Worker'),
                    _buildDrawerItem(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      subtitle: 'Worker Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmerHomeScreenV2(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      subtitle: 'My account',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.videogame_asset_rounded,
                      iconColor: AppColorPalette.robotTechStart,
                      title: 'Control Room',
                      subtitle: 'Control robot and monitor view',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/control_room');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: const Color(0xFF0A7E52),
                      title: 'Skill Certification',
                      subtitle: 'Micro-lessons and quizzes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/skill_certification');
                      },
                    ),
                    const Divider(height: 1),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      iconColor: AppColorPalette.alertError,
                      title: 'Sign Out',
                      subtitle: 'End worker session',
                      onTap: () async {
                        Navigator.pop(context);
                        await context.read<AuthProvider>().signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: AppColorPalette.fieldFreshGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/agricole_icon2.gif',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fieldly',
                          style: AppTextStyles.h2(color: AppColorPalette.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Farm System',
                          style: AppTextStyles.bodySmall(
                            color: AppColorPalette.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Home
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Main Dashboard',
                    onTap: () {
                      final role = context
                          .read<AuthProvider>()
                          .user
                          ?.role
                          .toUpperCase();
                      Navigator.pop(context);
                      // Navigate to the role-specific dashboard.
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => role == 'WORKER'
                              ? const FarmerHomeScreenV2()
                              : const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // Farm
                  _buildDrawerSection('Farm'),
                  _buildDrawerItem(
                    icon: Icons.grass,
                    title: 'My Parcels',
                    subtitle: 'View farm parcels',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParcelListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.science_rounded,
                    title: 'Soil Health',
                    subtitle: 'Measurements & Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SoilMeasurementsListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.medical_services,
                    iconColor: AppColorPalette.alertError,
                    title: 'AI Plant Doctor',
                    subtitle: 'Diagnose plant issues',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlantDoctorScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Harvest Analytics',
                    subtitle: 'Yield trends & insights',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HarvestAnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.map_rounded,
                    iconColor: Colors.deepPurpleAccent,
                    title: 'Aero-Twin NDVI',
                    subtitle: 'Digital Twin & NDVI Maps',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AeroTwinScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month_rounded,
                    iconColor: AppColorPalette.mistyBlue,
                    title: 'Crop Calendar',
                    subtitle: 'Planting & Harvest timeline',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CropCalendarScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.cloud,
                    iconColor: const Color(0xFF57A0D3),
                    title: 'Weather & Advice',
                    subtitle: 'Forecast & recommendations',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeatherScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF2196F3),
                    title: 'Irrigation Scheduler',
                    subtitle: 'Smart 7-day irrigation plan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IrrigationSchedulerScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.newspaper,
                    iconColor: Colors.orange,
                    title: 'Agricultural News',
                    subtitle: 'Latest farming updates',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgriculturalNewsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.play_circle_filled,
                    iconColor: const Color(0xFFFF6B6B),
                    title: 'Farm Reels',
                    subtitle: 'Agriculture video feed',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShortsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.forum_rounded,
                    iconColor: const Color(0xFF0E7A43),
                    title: 'Community Feed',
                    subtitle: 'Posts, votes, and discussions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityFeedScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // Animals
                  _buildDrawerSection('Animals'),
                  _buildDrawerItem(
                    icon: Icons.pets,
                    iconColor: const Color(0xFFFB923C),
                    title: 'Planned Sales',
                    subtitle: 'Animals in fattening',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlannedSalesScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // Finance
                  _buildDrawerSection('Finance'),
                  _buildDrawerItem(
                    icon: Icons.attach_money_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Finance Dashboard',
                    subtitle: 'Financial overview & reports',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FinanceDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(height: 1),

                  // Catalogue
                  _buildDrawerSection('Catalogue'),
                  _buildDrawerItem(
                    icon: Icons.library_books_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    title: 'Product Catalogue',
                    subtitle: 'Browse & manage products',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CatalogueListScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  _buildDrawerItem(
                    icon: Icons.vaccines_rounded,
                    title: 'Vaccination',
                    subtitle: 'Herd Health & Planning',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VaccineDashboardScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // Security
                  _buildDrawerSection('Security'),
                  _buildDrawerItem(
                    icon: Icons.shield_rounded,
                    title: 'Security Whitelist',
                    subtitle: 'View authorized staff',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_add_rounded,
                    title: 'Add Staff',
                    subtitle: 'Add to whitelist',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddStaffScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'Incident History',
                    subtitle: 'View security logs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncidentHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.videocam_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Live Feed',
                    subtitle: 'View live camera',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveFeedScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  _buildDrawerSection('Operations'),
                  _buildDrawerItem(
                    icon: Icons.videogame_asset_rounded,
                    iconColor: AppColorPalette.robotTechStart,
                    title: 'Control Room',
                    subtitle: 'Control robot and monitor view',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/control_room');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: const Color(0xFF0A7E52),
                    title: 'Skill Certification',
                    subtitle: 'Micro-lessons and quizzes',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/skill_certification');
                    },
                  ),

                  const Divider(height: 1),

                  // Account
                  _buildDrawerSection('Account'),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    subtitle: 'Manage account',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () => Navigator.pop(context),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Version 1.0.0',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption(
          color: AppColorPalette.softSlate,
        ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppColorPalette.fieldFreshStart;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge(color: AppColorPalette.charcoalGreen),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
      ),
      onTap: onTap,
    );
  }

  Widget _buildExpansionDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppColorPalette.fieldFreshStart;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge(color: AppColorPalette.charcoalGreen),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
        ),
        childrenPadding: const EdgeInsets.only(left: 64),
        children: children,
      ),
    );
  }

  Widget _buildDrawerSubItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18,
        color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(color: AppColorPalette.charcoalGreen),
      ),
      onTap: onTap,
    );
  }
}
