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
import '../soil/screens/soil_measurements_list_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMockData();
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
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
                  Icon(Icons.water_drop, color: AppColorPalette.white, size: 32),
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
                .map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AlertTile.compact(alert: alert, onTap: () {}),
                    ))
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
                      Text('VIEW FULL MAP', style: AppTextStyles.buttonMedium()),
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatAssistantScreen()),
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
    );
  }
}