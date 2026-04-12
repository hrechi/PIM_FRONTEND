import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:material_symbols_icons/symbols.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../utils/constants.dart';
import '../utils/farm_mood_calculator.dart';
import '../utils/plant_message_generator.dart';
import '../models/animal.dart';
import '../models/alert_item.dart';
import '../models/soil_intelligence.dart';
import '../models/weather_info.dart';
import '../models/parcel.dart';

import '../providers/parcel_provider.dart';
import '../providers/weather_provider.dart';
import '../services/animal_service.dart';
import '../services/local_notification_service.dart';
import '../services/soil_repository.dart';
import '../services/soil_intelligence_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/security_alert_overlay.dart';
import '../widgets/unified_farm_status_card.dart';
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
import 'soil/soil_alert_notifications_screen.dart';
import 'weather_screen.dart';
import 'irrigation_scheduler_screen.dart';
import 'agricultural_news_screen.dart';
import 'harvest_analytics_screen.dart';
import 'crop_calendar_screen.dart';
import 'package:frontend_pim/screens/parcel_list_screen.dart';
import 'plant_doctor_screen.dart';
import 'shorts_screen.dart';
import 'community_feed_screen.dart';
import 'farm_quiz_screen.dart';
 
/// Main home screen displaying the farm dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late WeatherInfo? weatherInfo;
  late List<AlertItem> alerts;
  late List<Animal> animals;

  final AnimalService _animalService = AnimalService();
  final SoilRepository _soilRepository = SoilRepository();
  final SoilIntelligenceService _soilIntelligenceService = SoilIntelligenceService();
  Timer? _soilAlertPollTimer;
  final Set<String> _notifiedSoilAlertIds = <String>{};
  bool _soilAlertsPrimed = false;

  Map<String, dynamic>? _animalStats;
  bool _isLoadingStats = true;
  
  // Soil and crop data
  double? _soilPh;
  int _totalCrops = 0;
  bool _isLoadingSoilCrop = true;
  
  // Farm mood data
  FarmMoodData? _farmMoodData;
  String? _plantMessage;
  
  // Parcel management
  Parcel? _selectedParcel;
  String? _selectedFieldName;
  
  // Background images from assets
  late int _selectedBackgroundIndex;
  final List<BackgroundSlide> _backgroundSlides = [
    BackgroundSlide(
      imageAsset: 'assets/images/welcome_1.jpg',
      fallbackColor: const Color(0xFF2D5016),
    ),
    BackgroundSlide(
      imageAsset: 'assets/images/welcome_2.jpg',
      fallbackColor: const Color(0xFF3A6B35),
    ),
    BackgroundSlide(
      imageAsset: 'assets/images/welcome_3.jpg',
      fallbackColor: const Color(0xFF4A7C45),
    ),
  ];

  // Socket.io client for siren
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _selectedBackgroundIndex = 0; // Default to first background
    weatherInfo = null;
    alerts = [];
    animals = [];
    
    _initSocket();
    _initFcmListener();
    _soilAlertPollTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _refreshSoilAlertsForBell(),
    );
    
    // Listen to parcel provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parcelProvider = context.read<ParcelProvider>();
      parcelProvider.addListener(_onParcelProviderChanged);
      
      // Load initial data
      _syncWeatherWithAdviceField();
      _loadParcels();
      _fetchDashboardStats();
      _fetchAnimals();
      _fetchSoilAndCropData();
    });
  }
  
  void _onParcelProviderChanged() {
    final parcelProvider = context.read<ParcelProvider>();
    final parcels = parcelProvider.parcels;
    
    debugPrint('🔄 Parcel provider changed: ${parcels.length} parcels available');
    
    // Defer state updates to after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // If selected parcel was deleted, clear it or select the first one
      if (_selectedParcel != null && !parcels.any((p) => p.id == _selectedParcel!.id)) {
        debugPrint('⚠️ Selected parcel was deleted: ${_selectedParcel!.id}');
        setState(() {
          _selectedParcel = parcels.isNotEmpty ? parcels.first : null;
        });
        // Reload data for the new selected parcel
        if (_selectedParcel != null) {
          debugPrint('📍 Auto-selected new parcel: ${_selectedParcel!.id}');
          _fetchAnimalsForField(_selectedParcel!.id);
          _fetchSoilAndCropData();
          _refreshSoilAlertsForBell();
        } else {
          // All parcels deleted, clear data
          debugPrint('🗑️ All parcels deleted, clearing data');
          setState(() {
            _soilPh = null;
            _totalCrops = 0;
            weatherInfo = null;
            animals = [];
            alerts = [];
          });
        }
      } else if (_selectedParcel == null && parcels.isNotEmpty) {
        // If no parcel was selected but parcels are now available, select the first one
        debugPrint('📍 No parcel selected, auto-selecting first parcel');
        setState(() {
          _selectedParcel = parcels.first;
        });
        _fetchAnimalsForField(_selectedParcel!.id);
        _fetchSoilAndCropData();
        _refreshSoilAlertsForBell();
      }
      
      debugPrint('Parcel provider changed, selected: ${_selectedParcel?.location}');
    });
  }

  @override
  void dispose() {
    _soilAlertPollTimer?.cancel();
    _socket.disconnect();
    _socket.dispose();
    
    // Remove listener when disposing
    try {
      final parcelProvider = context.read<ParcelProvider>();
      parcelProvider.removeListener(_onParcelProviderChanged);
    } catch (e) {
      debugPrint('Error removing parcel listener: $e');
    }
    
    super.dispose();
  }

  Future<void> _loadParcels() async {
    try {
      final parcelProvider = context.read<ParcelProvider>();
      await parcelProvider.fetchParcels();
      if (mounted && parcelProvider.parcels.isNotEmpty) {
        setState(() {
          _selectedParcel = parcelProvider.parcels.first;
        });
        // Fetch animals and soil/crop data for the selected parcel
        await _fetchAnimalsForField(_selectedParcel!.id);
        await _fetchSoilAndCropData();
      }

      if (mounted) {
        await _refreshSoilAlertsForBell();
      }
    } catch (e) {
      debugPrint('Error loading parcels: $e');
    }
  }

  Future<void> _refreshSoilAlertsForBell() async {
    try {
      final parcelProvider = context.read<ParcelProvider>();
      final parcels = parcelProvider.parcels;

      if (parcels.isEmpty) {
        if (!mounted) return;
        setState(() {
          alerts = [];
        });
        return;
      }

      final allByParcel = await Future.wait(
        parcels.map((parcel) async {
          try {
            return await _soilIntelligenceService.getActiveAlerts(parcel.id);
          } catch (_) {
            return <SoilWeatherAlert>[];
          }
        }),
      );

      final soilAlerts = allByParcel.expand((items) => items).toList();
      final deduped = <String, SoilWeatherAlert>{
        for (final alert in soilAlerts) alert.id: alert,
      }.values.toList();

      deduped.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));

      final mapped = deduped
          .map(
            (alert) => AlertItem(
              id: alert.id,
              title: 'Soil Alert: ${alert.type.replaceAll('_', ' ')}',
              description: alert.message,
              severity: _mapAlertSeverity(alert.severity),
              type: AlertType.environment,
              timestamp: alert.triggeredAt,
              relatedEntityId: alert.id,
              isRead: alert.isRead,
              isResolved: false,
            ),
          )
          .toList();

      await _notifyNewSoilAlertsLocally(deduped);

      if (!mounted) return;
      setState(() {
        alerts = mapped;
      });
    } catch (e) {
      debugPrint('Error refreshing soil alerts for bell: $e');
    }
  }

  Future<void> _notifyNewSoilAlertsLocally(List<SoilWeatherAlert> alertsList) async {
    if (!_soilAlertsPrimed) {
      _soilAlertsPrimed = true;

      final unread = alertsList.where((alert) => !alert.isRead).toList();
      if (unread.isNotEmpty) {
        final top = unread.first;
        await LocalNotificationService.showSoilAlertNotification(
          alertId: top.id,
          parcelId: top.parcelId,
          severity: top.severity,
          alertType: top.type,
          message: unread.length > 1
              ? '${top.message} (+${unread.length - 1} more active alerts)'
              : top.message,
        );
      }

      _notifiedSoilAlertIds.addAll(alertsList.map((alert) => alert.id));
      return;
    }

    if (alertsList.isEmpty) {
      return;
    }

    final newUnreadAlerts = alertsList.where((alert) {
      return !alert.isRead && !_notifiedSoilAlertIds.contains(alert.id);
    });

    for (final alert in newUnreadAlerts) {
      _notifiedSoilAlertIds.add(alert.id);
      await LocalNotificationService.showSoilAlertNotification(
        alertId: alert.id,
        parcelId: alert.parcelId,
        severity: alert.severity,
        alertType: alert.type,
        message: alert.message,
      );
    }
  }

  AlertSeverity _mapAlertSeverity(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return AlertSeverity.critical;
      case 'MEDIUM':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
  
  Future<void> _syncWeatherWithAdviceField() async {
    if (!mounted) return;

    try {
      final weatherProvider = context.read<WeatherProvider>();

      if (weatherProvider.fields.isEmpty) {
        await weatherProvider.loadFields();
      }

      final selectedFieldId = weatherProvider.selectedFieldId;
      if (selectedFieldId != null) {
        await weatherProvider.fetchWeather(selectedFieldId);
      }

      if (mounted) {
        setState(() {
          weatherInfo = weatherProvider.forecast?.current;
          _selectedFieldName = weatherProvider.selectedField?.name;
        });
      }
    } catch (e) {
      debugPrint('Error syncing weather with advice field: $e');
    }
  }
  
  Future<void> _fetchAnimals() async {
    try {
      final animalList = await _animalService.getAnimals();
      if (mounted) {
        setState(() {
          animals = animalList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching animals: $e');
    }
  }
  
  Future<void> _fetchAnimalsForField(String fieldId) async {
    try {
      final animalList = await _animalService.getAnimals(fieldId: fieldId);
      if (mounted) {
        setState(() {
          animals = animalList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching animals for field: $e');
    }
  }

  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final animalStats = await _animalService.getStatistics();
      if (mounted) {
        setState(() {
          _animalStats = animalStats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchSoilAndCropData() async {
    final weatherProvider = context.read<WeatherProvider>();
    final selectedFieldId = weatherProvider.selectedFieldId;
    final selectedField = weatherProvider.selectedField;

    if (selectedFieldId == null || selectedField == null) {
      if (mounted) {
        setState(() {
          _soilPh = null;
          _totalCrops = 0;
          _isLoadingSoilCrop = false;
        });
      }
      debugPrint('⚠️ No field selected, clearing soil/crop data');
      return;
    }
    
    debugPrint('🔄 Fetching soil and crop data for field: $selectedFieldId');
    setState(() => _isLoadingSoilCrop = true);
    try {
      final parcelProvider = context.read<ParcelProvider>();
      final parcels = parcelProvider.parcels;

      final namedParcels = parcels
          .where((p) => p.location.trim().toLowerCase() == selectedField.name.trim().toLowerCase())
          .toList();
      final fieldParcels = parcels.where((p) => p.fieldId == selectedFieldId).toList();

      final parcelsForField = namedParcels.isNotEmpty
          ? namedParcels
          : (fieldParcels.isNotEmpty ? fieldParcels : <Parcel>[]);

      final totalCropsForField = parcelsForField.fold<int>(0, (sum, p) => sum + p.crops.length);

      final measurementsResponse = await _soilRepository.getMeasurements(
        page: 1,
        limit: 100,
        sortBy: 'createdAt',
        order: 'DESC',
      );
        final matchingMeasurements =
          measurementsResponse.data.where((m) => m.fieldId == selectedFieldId).toList();
        final soilMeasurement =
          matchingMeasurements.isNotEmpty ? matchingMeasurements.first : null;

      debugPrint('✅ Data fetched: soilPh=${soilMeasurement?.ph}, crops count=$totalCropsForField');
      
      if (mounted) {
        // Calculate soil health score and wilting risk from measurement
        final calculatedData = _calculateSoilMetrics(soilMeasurement);
        
        // Calculate farm mood
        final farmScore = calculateFarmScore(
          soilHealthScore: calculatedData['healthScore'] as int,
          wiltingRisk: calculatedData['wiltingRisk'] as String,
        );
        final moodData = getMoodData(farmScore);
        
        // Generate plant message based on mood
        final plantMessage = generatePlantMessage(moodData.mood);
        
        setState(() {
          _soilPh = soilMeasurement?.ph;
          _totalCrops = totalCropsForField;
          _farmMoodData = moodData;
          _plantMessage = plantMessage;
          _isLoadingSoilCrop = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching soil and crop data: $e');
      if (mounted) {
        setState(() => _isLoadingSoilCrop = false);
      }
    }
  }
  
  /// Calculate soil health score (0-100) and wilting risk from soil measurement
  /// Score is based on pH, moisture, and nutrient levels
  Map<String, dynamic> _calculateSoilMetrics(dynamic soilMeasurement) {
    if (soilMeasurement == null) {
      return {'healthScore': 50, 'wiltingRisk': 'moderate'};
    }

    // Extract values
    final ph = (soilMeasurement.ph as num?)?.toDouble() ?? 6.5;
    final moisture = (soilMeasurement.soilMoisture as num?)?.toDouble() ?? 50.0;
    final temp = (soilMeasurement.temperature as num?)?.toDouble() ?? 20.0;
    
    // Extract nutrients (handles both Map and JSON)
    int nitrogen = 0;
    int phosphorus = 0;
    int potassium = 0;
    
    final nutrients = soilMeasurement.nutrients;
    if (nutrients is Map) {
      nitrogen = (nutrients['nitrogen'] as num?)?.toInt() ?? 0;
      phosphorus = (nutrients['phosphorus'] as num?)?.toInt() ?? 0;
      potassium = (nutrients['potassium'] as num?)?.toInt() ?? 0;
    }
    
    // Calculate pH score (ideal range 6.0-7.5)
    int phScore = 50;
    if (ph >= 6.0 && ph <= 7.5) {
      phScore = 100;
    } else if (ph >= 5.5 && ph <= 8.0) {
      phScore = 75;
    } else if (ph >= 5.0 && ph <= 8.5) {
      phScore = 50;
    } else {
      phScore = 25;
    }
    
    // Calculate moisture score (ideal range 30-80%)
    int moistureScore = 50;
    if (moisture >= 30 && moisture <= 80) {
      moistureScore = 100;
    } else if (moisture >= 20 && moisture <= 90) {
      moistureScore = 75;
    } else if (moisture >= 10 && moisture <= 95) {
      moistureScore = 50;
    } else {
      moistureScore = 25;
    }
    
    // Determine wilting risk based on moisture
    String wiltingRisk = 'moderate';
    if (moisture < 20) {
      wiltingRisk = 'high'; // Dry soil, high wilting risk
    } else if (moisture >= 20 && moisture <= 70) {
      wiltingRisk = 'low'; // Good moisture, low risk
    } else {
      wiltingRisk = 'moderate'; // Too wet may cause root problems
    }
    
    // Calculate nutrient score (ideally N>=20, P>=15, K>=20)
    int nutrientScore = 50;
    final avgNutrient = (nitrogen + phosphorus + potassium) / 3;
    if (avgNutrient >= 20) {
      nutrientScore = 100;
    } else if (avgNutrient >= 15) {
      nutrientScore = 75;
    } else if (avgNutrient >= 10) {
      nutrientScore = 50;
    } else {
      nutrientScore = 25;
    }
    
    // Calculate overall health score (weighted average)
    final healthScore = ((phScore * 0.25) +
            (moistureScore * 0.35) +
            (nutrientScore * 0.25) +
            ((temp >= 15 && temp <= 30 ? 100 : 50) * 0.15))
        .toInt();
    
    debugPrint('📊 Soil Metrics: pH=$ph (score=$phScore), Moisture=$moisture% (score=$moistureScore), Nutrients=$avgNutrient (score=$nutrientScore), Health=$healthScore, Wilting=$wiltingRisk');
    
    return {
      'healthScore': healthScore.clamp(0, 100),
      'wiltingRisk': wiltingRisk,
    };
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



  void _initFcmListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final screen = (data['screen'] ?? '').toString().toUpperCase();
      final type = (data['type'] ?? 'intruder').toString();

      if (screen == 'SOIL_ALERTS' || type.toUpperCase() == 'SOIL_WEATHER_ALERT') {
        _refreshSoilAlertsForBell();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message']?.toString() ?? 'New soil alert received',
              ),
              backgroundColor: AppColorPalette.alertError,
            ),
          );
        }
        return;
      }

      final incidentId = data['incidentId'] ?? '';
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(child: _buildParcelSelectorButton()),
                SliverToBoxAdapter(child: _buildUnifiedFarmStatus()),
                SliverToBoxAdapter(child: _buildQuickAccessButtons()),
                SliverToBoxAdapter(child: _buildWeatherSoilCard()),
                SliverToBoxAdapter(child: _buildFarmReelsCard()),
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
                  SliverToBoxAdapter(child: _buildLiveHealthMetrics()),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ─────────────────────────────────────────────
  // DRAWER
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
                  _buildDrawerItem(
                    icon: Icons.quiz_rounded,
                    iconColor: Colors.deepPurple,
                    title: 'Farm Quiz',
                    subtitle: 'Learn & earn badges',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmQuizScreen(parcelId: _selectedParcel?.id),
                        ),
                      );
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

  // ─────────────────────────────────────────────
  // HEADER BACKGROUND DECORATION with Asset Images
  // ─────────────────────────────────────────────
  Widget _buildHeaderBackground() {
    return Positioned.fill(
      child: Container(
        color: AppColorPalette.fieldFreshStart,
        child: Stack(
          children: [
            // Background image from assets
            _buildAssetBackgroundImage(_backgroundSlides[_selectedBackgroundIndex]),
            
            // Dark gradient overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build background image from asset with fallback color
  Widget _buildAssetBackgroundImage(BackgroundSlide slide) {
    return Image.asset(
      slide.imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          Container(
            color: slide.fallbackColor,
            width: double.infinity,
            height: double.infinity,
          ),
    );
  }



  // ─────────────────────────────────────────────
  // HEADER
  // Transparent AppBar + notification bell → Soil Alert Notification Center
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
              color: AppColorPalette.white),
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
                Text('Hi, Good Morning',
                    style: AppTextStyles.h3()
                        .copyWith(color: AppColorPalette.white)),
                if (_selectedFieldName != null)
                  Text(_selectedFieldName!,
                      style: AppTextStyles.bodySmall(
                          color: AppColorPalette.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColorPalette.white),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SoilAlertNotificationsScreen(),
                  ),
                );
                _refreshSoilAlertsForBell();
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
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              backgroundColor: AppColorPalette.white.withValues(alpha: 0.3),
              child: const Icon(Icons.person, color: AppColorPalette.white),
            ),
          ),
        ),
      ],
    );
  }

  // Parcel selector button and bottom sheet
  Widget _buildParcelSelectorButton() {
    final responsivePadding = Responsive.horizontalPadding(context);
    final responsiveVertical = Responsive.verticalPadding(context);
    final isSmall = Responsive.isMobile(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsivePadding,
        vertical: responsiveVertical * 0.5,
      ),
      child: GestureDetector(
        onTap: _showParcelSelector,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: isSmall ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColorPalette.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppColorPalette.fieldFreshStart,
                size: isSmall ? 16 : 18,
              ),
              SizedBox(width: isSmall ? 6 : 8),
              if (_selectedFieldName != null)
                Flexible(
                  child: Text(
                    _selectedFieldName!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(
                      color: AppColorPalette.charcoalGreen,
                    ).copyWith(
                      fontSize: isSmall ? 12 : 14,
                    ),
                  ),
                ),
              SizedBox(width: isSmall ? 6 : 8),
              Icon(
                Icons.swap_horiz_rounded,
                color: AppColorPalette.fieldFreshStart,
                size: isSmall ? 16 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParcelSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          final fields = weatherProvider.fields;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select Field',
                    style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
                  ),
                ),
                if (fields.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No fields available',
                        style: AppTextStyles.bodyMedium(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: fields.length,
                      itemBuilder: (context, index) {
                        final field = fields[index];
                        final isSelected = weatherProvider.selectedFieldId == field.id;
                        return GestureDetector(
                          onTap: () async {
                            await weatherProvider.selectField(field.id);
                            if (!mounted) return;
                            setState(() => _selectedFieldName = field.name);
                            Navigator.pop(context);
                            // Fetch field-specific data after selecting field.
                            _fetchAnimalsForField(field.id);
                            _fetchSoilAndCropData();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColorPalette.fieldFreshStart.withValues(alpha: 0.1) : Colors.grey.shade100,
                              border: isSelected
                                  ? Border.all(color: AppColorPalette.fieldFreshStart, width: 2)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.grass, color: AppColorPalette.fieldFreshStart),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        field.name,
                                        style: AppTextStyles.bodyLarge(color: AppColorPalette.charcoalGreen),
                                      ),
                                      Text(
                                        field.areaSize != null ? '${field.areaSize} ha' : 'Area not set',
                                        style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppColorPalette.fieldFreshStart),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FARM MOOD CARD
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // UNIFIED FARM STATUS CARD
  // Displays real-time data from database:
  // - Soil health score (from soil measurements)
  // - Wilting risk (from soil moisture readings)
  // - Farm mood emoji & label
  // - Plant message (dynamic based on farm conditions)
  // ─────────────────────────────────────────────
  Widget _buildUnifiedFarmStatus() {
    // Show loading skeleton while fetching from database
    if (_isLoadingSoilCrop) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton loader
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 24,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Hide card if no data from database
    if (_farmMoodData == null || _plantMessage == null) {
      return const SizedBox.shrink();
    }

    // Display card with data fetched from database
    return UnifiedFarmStatusCard(
      farmScore: _farmMoodData!.score,
      mood: _farmMoodData!.mood,
      emoji: _farmMoodData!.emoji,
      message: _plantMessage!,
    );
  }

  // ─────────────────────────────────────────────
  // QUICK ACCESS BUTTONS
  // ─────────────────────────────────────────────
  Widget _buildQuickAccessButtons() {
    final responsivePadding = Responsive.horizontalPadding(context);
    final responsiveVertical = Responsive.verticalPadding(context);
    final isSmall = Responsive.isMobile(context);
    final weatherProvider = context.watch<WeatherProvider>();
    final displayedWeather = weatherProvider.forecast?.current ?? weatherInfo;
    final buttonPadding = isSmall ? 8.0 : 12.0;
    final fontSize = isSmall ? 12.0 : 14.0;
    final iconSize = isSmall ? 18.0 : 20.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsivePadding,
        vertical: responsiveVertical * 0.75,
      ),
      child: Column(
        children: [
          // Quick Action Buttons - Responsive layout (always horizontal with equal width)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const FieldsManagementScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.mistyBlue,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.landscape, size: iconSize),
                  label: Text('Fields', style: TextStyle(fontSize: fontSize)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const MissionListScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.mistyBlue,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.task, size: iconSize),
                  label: Text('Missions', style: TextStyle(fontSize: fontSize)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const ChatAssistantScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.mistyBlue,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.chat_bubble_outline, size: iconSize),
                  label: Text('Assistant', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ],
          ),
          
          // Weather Strip
          if (displayedWeather != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildWeatherChip(
                    icon: Icons.air,
                    label: 'Wind',
                    value: '${(displayedWeather.windSpeed).toStringAsFixed(1)} km/h',
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 8),
                  _buildWeatherChip(
                    icon: Icons.thermostat,
                    label: 'Temp Δ',
                    value: '+${(displayedWeather.temperature - 15).toStringAsFixed(1)}°',
                    color: const Color(0xFFFF6B35),
                  ),
                  const SizedBox(width: 8),
                  _buildWeatherChip(
                    icon: Icons.opacity,
                    label: 'Humidity',
                    value: '${displayedWeather.humidity.toStringAsFixed(0)}%',
                    color: const Color(0xFF4ECDC4),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          
          // Soil & Crop Health Cards Row
          Row(
            children: [
              Expanded(child: _buildSoilHealthCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildCropHealthCard()),
            ],
          ),
          const SizedBox(height: 12),
          
          // See Map Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FieldsManagementScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.fieldFreshStart,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text(
                'See Map',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption(color: color).copyWith(fontSize: 11),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall(color: color)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoilHealthCard() {
    if (_isLoadingSoilCrop) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorPalette.fieldFreshStart.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    // If soilPh is null, show "No data" message
    if (_soilPh == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass, color: AppColorPalette.fieldFreshStart, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Soil Health',
                  style: AppTextStyles.bodyMedium(color: AppColorPalette.charcoalGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'pH: No data',
              style: AppTextStyles.bodyLarge(color: Colors.grey.shade600)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Not recorded',
                style: AppTextStyles.caption(color: Colors.grey.shade600)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final phValue = _soilPh!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass, color: AppColorPalette.fieldFreshStart, size: 20),
              const SizedBox(width: 6),
              Text(
                'Soil Health',
                style: AppTextStyles.bodyMedium(color: AppColorPalette.charcoalGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'pH: ${phValue.toStringAsFixed(1)}',
            style: AppTextStyles.bodyLarge(color: AppColorPalette.charcoalGreen)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              phValue >= 6.0 && phValue <= 7.5 ? 'Optimal' : 'Adjust',
              style: AppTextStyles.caption(color: const Color(0xFF4ECDC4))
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropHealthCard() {
    if (_isLoadingSoilCrop) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_florist, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 6),
              Text(
                'Crops Count',
                style: AppTextStyles.bodyMedium(color: AppColorPalette.charcoalGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalCrops',
            style: AppTextStyles.h2(color: Colors.green.shade700)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 32),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _totalCrops > 0 ? 'Active' : 'No crops',
              style: AppTextStyles.caption(color: Colors.green.shade700)
                  .copyWith(fontWeight: FontWeight.bold),
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
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        final forecast = weatherProvider.forecast;
        final current = forecast?.current ?? weatherInfo;
        final fieldName = weatherProvider.selectedField?.name ??
            forecast?.fieldName ??
            'Selected field';

        if (weatherProvider.isLoadingFields ||
            (weatherProvider.isLoading && current == null)) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: Responsive.verticalPadding(context),
            ),
            padding: EdgeInsets.all(Responsive.cardPadding(context)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF57A0D3), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF57A0D3).withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (weatherProvider.error != null && current == null) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: Responsive.verticalPadding(context),
            ),
            padding: EdgeInsets.all(Responsive.cardPadding(context)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7D9FB6), Color(0xFF9EB7C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather unavailable',
                  style: AppTextStyles.h3(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  weatherProvider.error!,
                  style: AppTextStyles.bodySmall(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _syncWeatherWithAdviceField,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (current == null) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeatherScreen()),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: Responsive.verticalPadding(context),
              ),
              padding: EdgeInsets.all(Responsive.cardPadding(context)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF57A0D3), Color(0xFF87CEEB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Open Weather & Advice to choose a field',
                style: AppTextStyles.bodyMedium(color: Colors.white),
              ),
            ),
          );
        }

        final skyGradient = _skyGradientForCondition(current.condition);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeatherScreen()),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: Responsive.verticalPadding(context),
            ),
            padding: EdgeInsets.all(Responsive.cardPadding(context)),
            decoration: BoxDecoration(
              gradient: skyGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _skyShadowColorForCondition(current.condition)
                      .withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldName.toUpperCase(),
                  style: AppTextStyles.caption(color: Colors.white70)
                      .copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${current.temperature.toStringAsFixed(0)}°',
                            style: AppTextStyles.displayLarge(color: Colors.white)
                                .copyWith(fontSize: 58, height: 1),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            current.condition,
                            style: AppTextStyles.bodyLarge(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Text(current.weatherIcon, style: const TextStyle(fontSize: 50)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherStat('Humidity', '${current.humidity}%'),
                      _buildWeatherStat('Wind', '${current.windSpeed.toStringAsFixed(1)} km/h'),
                      _buildWeatherStat('Rain', '${current.precipitation.toStringAsFixed(1)} mm'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(color: Colors.white70),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  LinearGradient _skyGradientForCondition(String condition) {
    final normalized = condition.toLowerCase();

    if (normalized.contains('thunder') || normalized.contains('storm')) {
      return const LinearGradient(
        colors: [Color(0xFF4B5B7E), Color(0xFF283248)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (normalized.contains('rain') || normalized.contains('drizzle')) {
      return const LinearGradient(
        colors: [Color(0xFF5F86A5), Color(0xFF3A5F7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (normalized.contains('cloud') || normalized.contains('overcast') || normalized.contains('fog')) {
      return const LinearGradient(
        colors: [Color(0xFF86A4BA), Color(0xFF64839A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return const LinearGradient(
      colors: [Color(0xFF57A0D3), Color(0xFF87CEEB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _skyShadowColorForCondition(String condition) {
    final normalized = condition.toLowerCase();
    if (normalized.contains('thunder') || normalized.contains('storm')) {
      return const Color(0xFF283248);
    }
    if (normalized.contains('rain') || normalized.contains('drizzle')) {
      return const Color(0xFF3A5F7D);
    }
    if (normalized.contains('cloud') || normalized.contains('overcast') || normalized.contains('fog')) {
      return const Color(0xFF64839A);
    }
    return const Color(0xFF57A0D3);
  }

  // ─────────────────────────────────────────────
  // FARM REELS CARD
  // ─────────────────────────────────────────────
  Widget _buildFarmReelsCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShortsScreen()),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1DB954), Color(0xFF1ABC9C), Color(0xFF00D2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1DB954).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Play icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Farm Reels',
                          style: AppTextStyles.h3().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🌾', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watch agriculture tips & tricks',
                      style: AppTextStyles.bodySmall(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ATTENTION REQUIRED
  // ─────────────────────────────────────────────
  Widget _buildAnimalStatsGrid() {
    if (_animalStats == null) return const SizedBox();

    final totalAnimals = _animalStats!['totalAnimals'] ?? 0;
    final healthAlerts = _animalStats!['healthAlerts'] ?? 0;
    final vaccinesDue = _animalStats!['vaccinesDue'] ?? 0;
    final responsivePadding = Responsive.horizontalPadding(context);
    final responsiveVertical = Responsive.verticalPadding(context);
    final cardSpacing = 10.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsivePadding,
        vertical: responsiveVertical * 0.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Health Metrics',
                  style: AppTextStyles.h3().copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Tooltip(
                  message: 'View Animal Dashboard',
                  child: IconButton(
                    icon: Icon(Icons.dashboard_outlined,
                      color: Colors.white),
                    iconSize: 28,
                    padding: const EdgeInsets.all(4),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AnimalDashboardScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2x2 grid of stat cards
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Total Animals', '$totalAnimals', 'Across all types',
                  Symbols.pets, const Color(0xFF10B981),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AnimalListScreen())),
                ),
              ),
              SizedBox(width: cardSpacing),
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
          SizedBox(height: cardSpacing),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Vaccines Due', '$vaccinesDue', 'Next 7 days',
                  Symbols.vaccines, const Color(0xFF3B82F6),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VaccineDashboardScreen())),
                ),
              ),
              SizedBox(width: cardSpacing),
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
    String title, String value, String subtitle,
    IconData icon, Color color, {VoidCallback? onTap}
  ) {
    final isSmall = Responsive.isMobile(context);
    final cardPadding = Responsive.cardPadding(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
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
              padding: EdgeInsets.all(isSmall ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isSmall ? 16 : 20),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: isSmall ? 1 : 2),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 10 : 11,
              ),
            ),
            SizedBox(height: isSmall ? 1 : 2),
            Text(
              subtitle,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: isSmall ? 9 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────
  // MILK PRODUCTION BANNER
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MilkProductionScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.mistBlue, AppColors.mistBlue.withOpacity(0.8)],
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
                      const Icon(
                        Symbols.water_drop,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Today's Yield",
                        style: AppTextStyles.h4().copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  if (yesterday > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                              fontWeight: FontWeight.bold,
                            ),
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Liters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'vs ${yesterday.toStringAsFixed(0)}L yesterday',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
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
  // LIVE HEALTH METRICS
  // DASHBOARD button → AnimalDashboardScreen
  // ─────────────────────────────────────────────
  Widget _buildLiveHealthMetrics() {
    final responsivePadding = Responsive.horizontalPadding(context);
    final responsiveVertical = Responsive.verticalPadding(context);
    final isMobile = Responsive.isMobile(context);
    final cardHeight = isMobile ? 340.0 : 360.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display animals in horizontal scroll
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: responsivePadding),
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
        SizedBox(height: responsiveVertical),
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

/// Data class for background slides
class BackgroundSlide {
  final String imageAsset;
  final Color fallbackColor;

  BackgroundSlide({
    required this.imageAsset,
    required this.fallbackColor,
  });
}