import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../utils/constants.dart';
import '../models/animal.dart';
import '../models/alert_item.dart';
import '../models/weather_info.dart';
import '../providers/weather_provider.dart';
import '../services/animal_service.dart';
import '../services/milk_production_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/metric_card.dart';
import '../widgets/alert_tile.dart';
import '../widgets/gradient_container.dart';
import '../widgets/security_alert_overlay.dart';
import 'soil/soil_measurements_list_screen.dart';
import 'animals/animal_list_screen.dart';
import 'animals/animal_dashboard_screen.dart';
import 'animals/add_animal_screen.dart';
import 'animals/milk_production_screen.dart';
import 'animals/milk_analytics_screen.dart';
import 'vaccines/vaccine_dashboard_screen.dart';
import 'profile_screen.dart';
import 'fields_management_screen.dart';
import 'mission_list_screen.dart';
import 'chat_assistant_screen.dart';
import 'add_staff_screen.dart';
import 'staff_list_screen.dart';
import 'security/incident_history_screen.dart';
import 'security/live_feed_screen.dart';
import 'security/daily_report_screen.dart';
import 'security/acoustic_monitor_screen.dart';
import 'weather_screen.dart';
import 'irrigation_scheduler_screen.dart';
import 'agricultural_news_screen.dart';
import 'package:frontend_pim/screens/parcel_list_screen.dart';
import 'plant_doctor_screen.dart';

/// Main home screen displaying the farm dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late WeatherInfo weatherInfo;
  late List<AlertItem> alerts;
  late List<Animal> animals;

  final AnimalService _animalService = AnimalService();
  final MilkProductionService _milkService = MilkProductionService();

  Map<String, dynamic>? _animalStats;
  Map<String, dynamic>? _milkStats;
  bool _isLoadingStats = true;

  // Socket.io client for siren
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _fetchDashboardStats();
    _initFcmListener();
    _initSocket();
  }

  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final results = await Future.wait([
        _animalService.getStatistics(),
        _milkService.getStatistics(),
      ]);
      if (mounted) {
        setState(() {
          _animalStats = results[0];
          _milkStats = results[1];
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  void _initSocket() {
    _socket = IO.io(
      'http://${AppConfig.serverHost}:${AppConfig.serverPort}',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
    _socket.onConnect((_) => debugPrint('[SOCKET] Connected to NestJS'));
    _socket.onDisconnect((_) => debugPrint('[SOCKET] Disconnected'));
  }

  void _triggerSiren() {
    _socket.emit('trigger_siren', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.volume_up, color: Colors.white),
            SizedBox(width: 10),
            Text('🚨 Siren triggered!'),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _initFcmListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final incidentId = data['incidentId'] ?? '';
      final type = data['type'] ?? 'intruder';
      final imageUrl = data['image_url'] ?? '';

      if (!mounted) return;
      SecurityAlertOverlay.show(
        context,
        incidentId: incidentId,
        type: type,
        imageUrl: imageUrl,
      );
    });
  }

  void _loadMockData() {
    weatherInfo = WeatherInfo.getMockData();
    alerts = AlertItem.getMockData();
    animals = Animal.getMockData();
  }

  @override
  Widget build(BuildContext context) {
    final attentionRequired = AlertItem.getAttentionRequired(alerts);
    final animalAlerts =
        _animalStats?['needingAttention'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.sageTint,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: Responsive.constrainedContent(
              context: context,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(child: _buildQuickAccessButtons()),
                  SliverToBoxAdapter(child: _buildWeatherSoilCard()),
                  if (_isLoadingStats)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(child: _buildAnimalStatsGrid()),
                    SliverToBoxAdapter(child: _buildMilkProductionBanner()),
                  ],
                  if (attentionRequired.isNotEmpty || animalAlerts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildAttentionRequiredSection(
                          attentionRequired, animalAlerts),
                    ),
                  SliverToBoxAdapter(child: _buildLivestockLocationSection()),
                  SliverToBoxAdapter(child: _buildLiveHealthMetrics()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ─────────────────────────────────────────────
  // DRAWER
  // Full inline drawer (Doc4 structure) + Milk/Vaccine items (Doc3)
  // ─────────────────────────────────────────────
  Widget _buildDrawer() {
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
                            color:
                                AppColorPalette.white.withValues(alpha: 0.9),
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
                              builder: (_) => const ParcelListScreen()));
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
                              builder: (_) => const PlantDoctorScreen()));
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
                              builder: (_) => const WeatherScreen()));
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
                              builder: (_) => AgriculturalNewsScreen()));
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
                              builder: (_) =>
                                  const IrrigationSchedulerScreen()));
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
                              builder: (_) => const StaffListScreen()));
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
                              builder: (_) => const AddStaffScreen()));
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
                              builder: (_) => const IncidentHistoryScreen()));
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
                              builder: (_) => const LiveFeedScreen()));
                    },
                  ),
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
                              builder: (_) => const AnimalListScreen()));
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
                              builder: (_) => const AddAnimalScreen()));
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
                              builder: (_) => const MilkProductionScreen()));
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
                              builder: (_) => const MilkAnalyticsScreen()));
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
                              builder: (_) => const VaccineDashboardScreen()));
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
                              builder: (_) => const ProfileScreen()));
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
                          color: AppColorPalette.softSlate),
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
        style: AppTextStyles.caption(color: AppColorPalette.softSlate)
            .copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
      title: Text(title,
          style:
              AppTextStyles.bodyLarge(color: AppColorPalette.charcoalGreen)),
      subtitle: Text(subtitle,
          style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate)),
      onTap: onTap,
    );
  }

  // ─────────────────────────────────────────────
  // HEADER BACKGROUND DECORATION (Doc3)
  // ─────────────────────────────────────────────
  Widget _buildHeaderBackground() {
    return Positioned(
      top: -100,
      left: -100,
      right: -100,
      height: 400,
      child: Opacity(
        opacity: 0.6,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.fieldFreshStart.withValues(alpha: 0.2),
                      AppColors.fieldFreshStart.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.mistyBlue.withValues(alpha: 0.2),
                      AppColors.mistyBlue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // Transparent AppBar (Doc3)
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      toolbarHeight: 80,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: AppColorPalette.charcoalGreen),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/agricole_icon2.gif',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fieldly',
                    style: AppTextStyles.h3()
                        .copyWith(color: AppColorPalette.charcoalGreen)),
                Text('Farm Overview',
                    style: AppTextStyles.bodySmall(
                        color: AppColorPalette.softSlate)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IncidentHistoryScreen(),
                  ),
                );
              },
            ),
            if (alerts.where((a) => !a.isRead).isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColorPalette.alertError,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${alerts.where((a) => !a.isRead).length}',
                    style: AppTextStyles.caption(color: AppColorPalette.white)
                        .copyWith(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              backgroundColor: AppColorPalette.mistyBlue,
              child: const Icon(Icons.person, color: AppColorPalette.white),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // QUICK ACCESS BUTTONS
  // ─────────────────────────────────────────────
  Widget _buildQuickAccessButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FieldsManagementScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.mistyBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.landscape),
              label: const Text('Fields'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MissionListScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.mistyBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.task),
              label: const Text('Missions'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatAssistantScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.mistyBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Assistant'),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WEATHER & SOIL CARD
  // Outer GestureDetector → WeatherScreen
  // Inner InkWell → SoilMeasurementsListScreen
  // ─────────────────────────────────────────────
  Widget _buildWeatherSoilCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WeatherScreen())),
      child: GradientContainer.fieldFresh(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: Responsive.verticalPadding(context),
        ),
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Conditions',
                        style: AppTextStyles.bodyMedium(
                            color: AppColorPalette.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weatherInfo.formattedTemperature,
                        style: AppTextStyles.displayLarge(
                                color: AppColorPalette.white)
                            .copyWith(fontSize: 56),
                      ),
                      Text(
                        weatherInfo.condition,
                        style:
                            AppTextStyles.bodyLarge(color: AppColorPalette.white)
                                .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorPalette.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(weatherInfo.weatherIcon,
                      style: const TextStyle(fontSize: 48)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const SoilMeasurementsListScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorPalette.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColorPalette.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.water_drop,
                        color: AppColorPalette.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soil Moisture',
                            style: AppTextStyles.bodySmall(
                                color:
                                    AppColorPalette.white.withOpacity(0.9)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                weatherInfo.formattedSoilMoisture,
                                style: AppTextStyles.h2(
                                        color: AppColorPalette.white)
                                    .copyWith(fontSize: 28),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: weatherInfo.isSoilMoistureHealthy
                                      ? AppColorPalette.success
                                      : AppColorPalette.warning,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  weatherInfo.soilMoistureStatus,
                                  style: AppTextStyles.caption(
                                          color: AppColorPalette.white)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: AppColorPalette.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ANIMAL STATS GRID (Doc3)
  // ─────────────────────────────────────────────
  Widget _buildAnimalStatsGrid() {
    if (_animalStats == null) return const SizedBox();

    final totalAnimals = _animalStats!['totalAnimals'] ?? 0;
    final healthAlerts = _animalStats!['healthAlerts'] ?? 0;
    final vaccinesDue = _animalStats!['vaccinesDue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Livestock Overview', style: AppTextStyles.h3()),
          ),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Total Animals',
                  '$totalAnimals',
                  'Across all types',
                  Symbols.pets,
                  const Color(0xFF10B981),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AnimalListScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardStatCard(
                  'Health Alerts',
                  '$healthAlerts',
                  'Needing attention',
                  Symbols.warning,
                  const Color(0xFFEF4444),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Vaccines Due',
                  '$vaccinesDue',
                  'Next 7 days',
                  Symbols.vaccines,
                  const Color(0xFF3B82F6),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const VaccineDashboardScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardStatCard(
                  'Monthly Spend',
                  '${_animalStats!['monthlySpend'] ?? 0} DT',
                  'Feed & Care',
                  Symbols.payments,
                  const Color(0xFFF59E0B),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MILK PRODUCTION BANNER (Doc3)
  // ─────────────────────────────────────────────
  Widget _buildMilkProductionBanner() {
    if (_animalStats == null) return const SizedBox();

    final double today = _toDouble(_animalStats!['todayMilk']);
    final double yesterday = _toDouble(_animalStats!['yesterdayMilk']);
    double trendPercent = 0;
    if (yesterday > 0) {
      trendPercent = ((today - yesterday) / yesterday) * 100;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MilkProductionScreen())),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.mistBlue,
                AppColors.mistBlue.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.mistBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Symbols.water_drop,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text("Today's Yield",
                          style: AppTextStyles.h4()
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                  if (yesterday > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            trendPercent >= 0
                                ? Symbols.trending_up
                                : Symbols.trending_down,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trendPercent.abs().toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${today.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 4),
                  const Text('Liters',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    'vs ${yesterday.toStringAsFixed(0)}L yesterday',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ATTENTION REQUIRED
  // Combined field alerts + animal alerts (Doc3)
  // ─────────────────────────────────────────────
  Widget _buildAttentionRequiredSection(
      List<AlertItem> attentionAlerts, List<dynamic> animalAlerts) {
    final totalCount = attentionAlerts.length + animalAlerts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.alertError.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColorPalette.alertError, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Attention Required', style: AppTextStyles.h3()),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorPalette.alertError,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount',
                  style: AppTextStyles.caption(color: AppColorPalette.white)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DashboardCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Field Alerts
              ...attentionAlerts.take(2).map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AlertTile.compact(alert: alert, onTap: () {}),
                    ),
                  ),
              // Animal Alerts
              ...animalAlerts.take(2).map((aRaw) {
                final animal = Animal.fromJson(aRaw);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAnimalAlertTile(animal),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalAlertTile(Animal animal) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AnimalListScreen())),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColorPalette.warning.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
              color: AppColorPalette.warning.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColorPalette.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Symbols.pets,
                  size: 18.0, color: AppColorPalette.warning),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${animal.name} needs attention',
                    style: AppTextStyles.bodySmall(
                            color: AppColorPalette.charcoalGreen)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Status: ${animal.healthStatus} • Score: ${animal.vitalityScore}%',
                    style: AppTextStyles.bodySmall(
                        color: AppColorPalette.softSlate),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColorPalette.softSlate),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIVESTOCK LOCATION
  // ─────────────────────────────────────────────
  Widget _buildLivestockLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorPalette.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on,
                        color: AppColorPalette.info, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Livestock Location', style: AppTextStyles.h3()),
                ],
              ),
              StatusChip.info(
                  label: '${animals.length} animals', icon: Icons.pets),
            ],
          ),
        ),
        DashboardCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColorPalette.lightGrey,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColorPalette.emeraldGreen.withOpacity(0.1),
                      AppColorPalette.mistyBlue.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map,
                              size: 48,
                              color: AppColorPalette.softSlate.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Interactive Map View',
                              style: AppTextStyles.bodyMedium(
                                  color: AppColorPalette.softSlate)),
                        ],
                      ),
                    ),
                    ...animals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final animal = entry.value;
                      return Positioned(
                        left: 50.0 + (index * 40.0),
                        top: 80.0 + (index % 2 == 0 ? 20.0 : 0.0),
                        child: _buildAnimalPin(animal),
                      );
                    }).toList(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.mistyBlue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fullscreen),
                      const SizedBox(width: 8),
                      Text('VIEW FULL MAP',
                          style: AppTextStyles.buttonMedium()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalPin(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: animal.isHealthy
            ? AppColorPalette.success
            : AppColorPalette.alertError,
        shape: BoxShape.circle,
        border: Border.all(color: AppColorPalette.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.pets, size: 16, color: AppColorPalette.white),
    );
  }

  // ─────────────────────────────────────────────
  // LIVE HEALTH METRICS
  // DASHBOARD button (Doc4) → AnimalDashboardScreen
  // ─────────────────────────────────────────────
  Widget _buildLiveHealthMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: Responsive.verticalPadding(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorPalette.healthGlow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.favorite,
                        color: AppColorPalette.warning, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Live Health Metrics', style: AppTextStyles.h3()),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnimalDashboardScreen()),
                ),
                child: Text(
                  'DASHBOARD',
                  style: AppTextStyles.buttonSmall(
                      color: AppColorPalette.mistyBlue),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: Responsive.value(
              context, mobile: 310.0, tablet: 330.0, desktop: 350.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context)),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return MetricCard(
                animal: animals[index],
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnimalListScreen())),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FLOATING ACTION BUTTON
  // Siren FAB stacked above Chatbot FAB
  // ─────────────────────────────────────────────
  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Chatbot mascot FAB ─────────────────
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (context) => const ChatAssistantScreen())),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.charcoalGreen.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/maskot_chatbot.png',
                width: 65,
                height: 85,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
