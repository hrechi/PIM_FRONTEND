import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../models/animal.dart';
import '../models/alert_item.dart';
import '../models/weather_info.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/metric_card.dart';
import '../widgets/alert_tile.dart';
import '../widgets/gradient_container.dart';
import 'profile_screen.dart';
import 'fields_management_screen.dart';
import 'mission_list_screen.dart';

/// Main home screen displaying the farm dashboard
/// Provides overview of weather, soil, livestock health, and alerts
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data - will be replaced with API calls later
  late WeatherInfo weatherInfo;
  late List<AlertItem> alerts;
  late List<Animal> animals;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  /// Load mock data for demonstration
  void _loadMockData() {
    weatherInfo = WeatherInfo.getMockData();
    alerts = AlertItem.getMockData();
    animals = Animal.getMockData();
  }

  @override
  Widget build(BuildContext context) {
    // Get alerts that require attention
    final attentionRequired = AlertItem.getAttentionRequired(alerts);

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      body: SafeArea(
        child: Responsive.constrainedContent(
          context: context,
          child: CustomScrollView(
            slivers: [
            // A) Header Section
            _buildHeader(),

            // A1) Fields & Missions Quick Access
            SliverToBoxAdapter(
              child: _buildQuickAccessButtons(),
            ),

            // B) Weather & Soil Card
            SliverToBoxAdapter(
              child: _buildWeatherSoilCard(),
            ),

            // C) Attention Required Section
            if (attentionRequired.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildAttentionRequiredSection(attentionRequired),
              ),

            // D) Livestock Location Section
            SliverToBoxAdapter(
              child: _buildLivestockLocationSection(),
            ),

            // E) Live Health Metrics
            SliverToBoxAdapter(
              child: _buildLiveHealthMetrics(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    ),

    // F) Floating Action Button
    floatingActionButton: _buildFloatingActionButton(),
  );
}

  /// Build app header with title, notifications, and profile
  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColorPalette.wheatWarmClay,
      toolbarHeight: 80,
      title: Row(
        children: [
          // App Icon/Logo
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

          // Title
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
        // Notification Icon
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Navigate to notifications
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
                    style: AppTextStyles.caption(
                      color: AppColorPalette.white,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),

        // Profile Avatar
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              backgroundColor: AppColorPalette.mistyBlue,
              child: const Icon(
                Icons.person,
                color: AppColorPalette.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build quick access buttons for Fields & Missions
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FieldsManagementScreen(),
                  ),
                );
              },
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MissionListScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.mistyBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.task),
              label: const Text('Missions'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build weather and soil card with gradient background
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
              // Left side - Weather info
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

              // Right side - Weather icon
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
          
          // Soil Moisture Section - Tappable to navigate to Soil module
          InkWell(
            onTap: () {
              // TODO: Navigate to Soil Measurements module once created
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const SoilMeasurementsListScreen(),
              //   ),
              // );
            },
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
                  // Arrow icon to indicate navigation
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

  /// Build attention required section with alerts
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
              Text(
                'Attention Required',
                style: AppTextStyles.h3(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
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
                .take(3) // Show only first 3 alerts
                .map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AlertTile.compact(
                        alert: alert,
                        onTap: () {
                          // Navigate to alert details
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Build livestock location section with map placeholder
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
                  Text(
                    'Livestock Location',
                    style: AppTextStyles.h3(),
                  ),
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
              // Map Placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColorPalette.lightGrey,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  // Simulating a map with gradient
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
                    // Center text
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
                    // Animal location pins (mock positions)
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
              // Full Map Button
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to full map view
                  },
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

  /// Build animal location pin
  Widget _buildAnimalPin(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: animal.isHealthy
            ? AppColorPalette.success
            : AppColorPalette.alertError,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColorPalette.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.pets,
        size: 16,
        color: AppColorPalette.white,
      ),
    );
  }

  /// Build live health metrics horizontal scroll section
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
              Text(
                'Live Health Metrics',
                style: AppTextStyles.h3(),
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
                onTap: () {
                  // Navigate to animal details
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build floating action button with gradient
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColorPalette.successGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.success.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Open settings or scan
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.settings,
          size: 28,
        ),
      ),
    );
  }
}
