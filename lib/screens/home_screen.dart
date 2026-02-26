import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../utils/constants.dart';
import '../models/animal.dart';
import '../models/alert_item.dart';
import '../models/weather_info.dart';
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
import 'profile_screen.dart';
import 'fields_management_screen.dart';
import 'mission_list_screen.dart';
import 'chat_assistant_screen.dart';
import 'add_staff_screen.dart';
import 'staff_list_screen.dart';
import 'incident_history_screen.dart';
import 'live_feed_screen.dart';
import 'package:frontend_pim/screens/parcel_list_screen.dart';
import 'plant_doctor_screen.dart';
import '../widgets/app_drawer.dart';

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

  // Socket.io client for siren
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _initFcmListener();
    _initSocket();
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
    // Listen for foreground push notifications
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

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Responsive.constrainedContent(
          context: context,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(child: _buildQuickAccessButtons()),
              SliverToBoxAdapter(child: _buildWeatherSoilCard()),
              if (attentionRequired.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildAttentionRequiredSection(attentionRequired),
                ),
              SliverToBoxAdapter(child: _buildLivestockLocationSection()),
              SliverToBoxAdapter(child: _buildLiveHealthMetrics()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ─────────────────────────────────────────────
<<<<<<< HEAD
=======
  // DRAWER
  // ─────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Expanded(
              child: ListView(
                children: [
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

  // ─────────────────────────────────────────────
>>>>>>> AmelSecurity
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColorPalette.wheatWarmClay,
      toolbarHeight: 80,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: AppColorPalette.charcoalGreen,
          ),
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
                Text(
                  'Fieldly',
                  style: AppTextStyles.h3().copyWith(
                    color: AppColorPalette.charcoalGreen,
                  ),
                ),
                Text(
                  'Farm Overview',
                  style: AppTextStyles.bodySmall(
                    color: AppColorPalette.softSlate,
                  ),
                ),
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
              onPressed: () {},
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
                    style: AppTextStyles.caption(
                      color: AppColorPalette.white,
                    ).copyWith(fontSize: 10),
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
                  builder: (context) => const FieldsManagementScreen(),
                ),
              ),
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
                  builder: (context) => const MissionListScreen(),
                ),
              ),
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
                  builder: (context) => const ChatAssistantScreen(),
                ),
              ),
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
  // ─────────────────────────────────────────────
  Widget _buildWeatherSoilCard() {
    return GradientContainer.fieldFresh(
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
                        color: AppColorPalette.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherInfo.formattedTemperature,
                      style: AppTextStyles.displayLarge(
                        color: AppColorPalette.white,
                      ).copyWith(fontSize: 56),
                    ),
                    Text(
                      weatherInfo.condition,
                      style: AppTextStyles.bodyLarge(
                        color: AppColorPalette.white,
                      ).copyWith(fontWeight: FontWeight.w500),
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
                child: Text(
                  weatherInfo.weatherIcon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SoilMeasurementsListScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorPalette.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorPalette.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop,
                    color: AppColorPalette.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soil Moisture',
                          style: AppTextStyles.bodySmall(
                            color: AppColorPalette.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              weatherInfo.formattedSoilMoisture,
                              style: AppTextStyles.h2(
                                color: AppColorPalette.white,
                              ).copyWith(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: weatherInfo.isSoilMoistureHealthy
                                    ? AppColorPalette.success
                                    : AppColorPalette.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                weatherInfo.soilMoistureStatus,
                                style: AppTextStyles.caption(
                                  color: AppColorPalette.white,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColorPalette.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ATTENTION REQUIRED
  // ─────────────────────────────────────────────
  Widget _buildAttentionRequiredSection(List<AlertItem> attentionAlerts) {
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
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColorPalette.alertError,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text('Attention Required', style: AppTextStyles.h3()),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorPalette.alertError,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attentionAlerts.length}',
                  style: AppTextStyles.caption(
                    color: AppColorPalette.white,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DashboardCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: attentionAlerts
                .take(3)
                .map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AlertTile.compact(alert: alert, onTap: () {}),
                  ),
                )
                .toList(),
          ),
        ),
      ],
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
                    child: const Icon(
                      Icons.location_on,
                      color: AppColorPalette.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Livestock Location', style: AppTextStyles.h3()),
                ],
              ),
              StatusChip.info(
                label: '${animals.length} animals',
                icon: Icons.pets,
              ),
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
                          Icon(
                            Icons.map,
                            size: 48,
                            color: AppColorPalette.softSlate.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Interactive Map View',
                            style: AppTextStyles.bodyMedium(
                              color: AppColorPalette.softSlate,
                            ),
                          ),
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
                      Text(
                        'VIEW FULL MAP',
                        style: AppTextStyles.buttonMedium(),
                      ),
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
                    child: Icon(
                      Icons.favorite,
                      color: AppColorPalette.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Live Health Metrics', style: AppTextStyles.h3()),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnimalDashboardScreen(),
                  ),
                ),
                child: Text(
                  'DASHBOARD',
                  style: AppTextStyles.buttonSmall(
                    color: AppColorPalette.mistyBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: Responsive.value(
            context,
            mobile: 310.0,
            tablet: 330.0,
            desktop: 350.0,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return MetricCard(
                animal: animals[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnimalListScreen(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FLOATING ACTION BUTTON
  // ─────────────────────────────────────────────
  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Siren FAB ──────────────────────────────────────────
        FloatingActionButton(
          heroTag: 'siren',
          onPressed: _triggerSiren,
          backgroundColor: Colors.red.shade700,
          child: const Icon(Icons.volume_up, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // ── Chat FAB ───────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatAssistantScreen(),
            ),
          ),
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
}
