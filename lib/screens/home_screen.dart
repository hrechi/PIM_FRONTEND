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
// 1. Make sure to import your new screen here
import 'plant_doctor_screen.dart';

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
      // --- DRAWER ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColorPalette.emeraldGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, color: AppColorPalette.emeraldGreen, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fieldly Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Farm Overview'),
              onTap: () => Navigator.pop(context),
            ),
            // FIX: Plant Doctor Navigation
            ListTile(
              leading: const Icon(Icons.medical_services, color: AppColorPalette.alertError),
              title: const Text(
                'AI Plant Doctor',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColorPalette.emeraldGreen),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlantDoctorScreen()),
                );
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Responsive.constrainedContent(
          context: context,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(child: _buildWeatherSoilCard()),
              if (attentionRequired.isNotEmpty)
                SliverToBoxAdapter(child: _buildAttentionRequiredSection(attentionRequired)),
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

  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      backgroundColor: AppColorPalette.wheatWarmClay,
      toolbarHeight: 80,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColorPalette.charcoalGreen),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      automaticallyImplyLeading: false,
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
                Text('Fieldly', style: AppTextStyles.h3().copyWith(color: AppColorPalette.charcoalGreen)),
                Text('Farm Overview', style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: const CircleAvatar(
              backgroundColor: AppColorPalette.mistyBlue,
              child: Icon(Icons.person, color: AppColorPalette.white),
            ),
          ),
        ),
      ],
    );
  }

  // --- ALL OTHER UI HELPER WIDGETS ---
  // (Assuming you have these defined as per your previous setup)
  Widget _buildWeatherSoilCard() { /* ... */ return Container(); }
  Widget _buildAttentionRequiredSection(List<AlertItem> alerts) { /* ... */ return Container(); }
  Widget _buildLivestockLocationSection() { /* ... */ return Container(); }
  Widget _buildLiveHealthMetrics() { /* ... */ return Container(); }
  Widget _buildFloatingActionButton() { /* ... */ return Container(); }
}