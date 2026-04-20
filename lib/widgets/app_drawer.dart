import 'package:flutter/material.dart';
import 'package:frontend_pim/screens/animals/animal_dashboard_screen.dart';
import '../screens/agricultural_news_screen.dart';
import '../screens/harvest_analytics_screen.dart';
import '../screens/crop_calendar_screen.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../screens/home_screen.dart';
import '../screens/animals/animal_list_screen.dart';
import '../screens/animals/add_animal_screen.dart';
import '../screens/animals/milk_production_screen.dart';
import '../screens/animals/milk_analytics_screen.dart';
import '../screens/animals/planned_sales_screen.dart';
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
import '../screens/security/daily_report_screen.dart';
import '../screens/security/acoustic_monitor_screen.dart';import '../screens/security/daily_report_screen.dart';
import '../screens/security/acoustic_monitor_screen.dart';import '../screens/shorts_screen.dart';
import '../screens/community_feed_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../services/field_service.dart';
import '../screens/finance/finance_dashboard_screen.dart';
import '../screens/catalogue_list_screen.dart';
import '../screens/catalogue_wizard_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
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

                  const SizedBox(height: 8),

                  // ── Farm ──────────────────────────────
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
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Finance Dashboard',
                    subtitle: 'Financial overview',
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
                  _buildDrawerItem(
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'catalogues',
                    subtitle: 'catalogues',
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
                  _buildDrawerItem(
                    icon: Icons.science,
                    iconColor: AppColorPalette.fieldFreshStart,
                    title: 'Soil Measurements',
                    subtitle: 'Track soil health data',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SoilMeasurementsListScreen()));
                    },
                  ),

                  const Divider(height: 1),

                  // ── Security ──────────────────────────
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
                    iconColor: AppColorPalette.emeraldGreen,
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
                  // ── New from Doc6 ──
                  _buildDrawerItem(
                    icon: Icons.assessment_rounded,
                    iconColor: AppColorPalette.fieldFreshMid,
                    title: 'Daily Reports',
                    subtitle: 'AI security digest',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyReportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.graphic_eq_rounded,
                    iconColor: Colors.cyanAccent,
                    title: 'Acoustic Monitor',
                    subtitle: 'Sound threat detection',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AcousticMonitorScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // ── Animals ───────────────────────────
                  _buildDrawerSection('Animals'),
                  _buildDrawerItem(
                    icon: Icons.pets,
                    title: 'Animal List',
                    subtitle: 'View all animals',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnimalListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    iconColor: AppColorPalette.emeraldGreen,
                    title: 'Add Animal',
                    subtitle: 'Register new animal',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAnimalScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.sell,
                    title: 'Ventes saisonnières',
                    subtitle: 'Animaux en engraissement',
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
                  _buildDrawerItem(
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF57A0D3),
                    title: 'Milk Production',
                    subtitle: 'Track daily yield',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MilkProductionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Milk Analytics',
                    subtitle: 'Production insights',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MilkAnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.vaccines,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Vaccine Dashboard',
                    subtitle: 'Vaccination schedule',
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

                  // ── Account ───────────────────────────
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

  }