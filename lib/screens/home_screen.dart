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
import '../l10n/l10n_extensions.dart';
import '../models/animal.dart';
import '../models/alert_item.dart';
import '../models/soil_intelligence.dart';
import '../models/weather_info.dart';
import '../models/parcel.dart';

import '../providers/parcel_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/notification_provider.dart';
import '../services/animal_service.dart';
import '../services/local_notification_service.dart';
import '../services/soil_repository.dart';
import '../services/soil_intelligence_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/security_alert_overlay.dart';
import 'asset_list_screen.dart';
import 'animals/animal_list_screen.dart';
import 'animals/milk_production_screen.dart';
import 'finance/finance_dashboard_screen.dart';
import 'vaccines/vaccine_dashboard_screen.dart';
import 'profile_screen.dart';
import 'fields_management_screen.dart';
import 'mission_list_screen.dart';
import 'chat_assistant_screen.dart';
import 'notification_center_screen.dart';
import 'weather_screen.dart';
import 'shorts_screen.dart';
import '../widgets/language_selector.dart';

/// Main home screen displaying the farm dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late WeatherInfo? weatherInfo;
  late List<AlertItem> alerts;
  late List<Animal> animals;

  // Staggered intro animation (mirrors AppDrawer's drawer-open animation)
  late final AnimationController _intro;

  final AnimalService _animalService = AnimalService();
  final SoilRepository _soilRepository = SoilRepository();
  final SoilIntelligenceService _soilIntelligenceService =
      SoilIntelligenceService();
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

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
    _selectedBackgroundIndex = 0;
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

      _syncWeatherWithAdviceField();
      _loadParcels();
      _fetchDashboardStats();
      _fetchAnimals();
      _fetchSoilAndCropData();
    });
  }

  bool _backgroundsPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_backgroundsPrecached) {
      _backgroundsPrecached = true;
      // Preload all hero backgrounds so there's no green flash on first paint.
      for (final slide in _backgroundSlides) {
        precacheImage(AssetImage(slide.imageAsset), context);
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _soilAlertPollTimer?.cancel();
    _socket.disconnect();
    _socket.dispose();

    try {
      final parcelProvider = context.read<ParcelProvider>();
      parcelProvider.removeListener(_onParcelProviderChanged);
    } catch (e) {
      debugPrint('Error removing parcel listener: $e');
    }

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // PARCEL PROVIDER LISTENER
  // ─────────────────────────────────────────────

  void _onParcelProviderChanged() {
    if (!mounted) return;
    final parcelProvider = context.read<ParcelProvider>();
    final parcels = parcelProvider.parcels;

    debugPrint(
      '🔄 Parcel provider changed: ${parcels.length} parcels available',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_selectedParcel != null &&
          !parcels.any((p) => p.id == _selectedParcel!.id)) {
        debugPrint('⚠️ Selected parcel was deleted: ${_selectedParcel!.id}');
        setState(() {
          _selectedParcel = parcels.isNotEmpty ? parcels.first : null;
        });
        if (_selectedParcel != null) {
          debugPrint('📍 Auto-selected new parcel: ${_selectedParcel!.id}');
          _fetchAnimalsForField(_selectedParcel!.id);
          _fetchSoilAndCropData();
          _refreshSoilAlertsForBell();
        } else {
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
        debugPrint('📍 No parcel selected, auto-selecting first parcel');
        setState(() {
          _selectedParcel = parcels.first;
        });
        _fetchAnimalsForField(_selectedParcel!.id);
        _fetchSoilAndCropData();
        _refreshSoilAlertsForBell();
      }

      debugPrint(
        'Parcel provider changed, selected: ${_selectedParcel?.location}',
      );
    });
  }

  // ─────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────

  Future<void> _loadParcels() async {
    try {
      if (!mounted) return;
      final parcelProvider = context.read<ParcelProvider>();
      await parcelProvider.fetchParcels();
      if (mounted && parcelProvider.parcels.isNotEmpty) {
        setState(() {
          _selectedParcel = parcelProvider.parcels.first;
        });
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
        setState(() => alerts = []);
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
      setState(() => alerts = mapped);
    } catch (e) {
      debugPrint('Error refreshing soil alerts for bell: $e');
    }
  }

  Future<void> _notifyNewSoilAlertsLocally(
    List<SoilWeatherAlert> alertsList,
  ) async {
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

    if (alertsList.isEmpty) return;

    final newUnreadAlerts = alertsList.where(
      (alert) => !alert.isRead && !_notifiedSoilAlertIds.contains(alert.id),
    );

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
      if (!mounted) return;

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
        setState(() => animals = animalList);
      }
    } catch (e) {
      debugPrint('Error fetching animals: $e');
    }
  }

  Future<void> _fetchAnimalsForField(String fieldId) async {
    try {
      final animalList = await _animalService.getAnimals(fieldId: fieldId);
      if (mounted) {
        setState(() => animals = animalList);
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
    if (!mounted) return;
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
          .where(
            (p) =>
                p.location.trim().toLowerCase() ==
                selectedField.name.trim().toLowerCase(),
          )
          .toList();
      final fieldParcels = parcels
          .where((p) => p.fieldId == selectedFieldId)
          .toList();

      final parcelsForField = namedParcels.isNotEmpty
          ? namedParcels
          : (fieldParcels.isNotEmpty ? fieldParcels : <Parcel>[]);

      final totalCropsForField = parcelsForField.fold<int>(
        0,
        (sum, p) => sum + p.crops.length,
      );

      final measurementsResponse = await _soilRepository.getMeasurements(
        page: 1,
        limit: 100,
        sortBy: 'createdAt',
        order: 'DESC',
      );
      final matchingMeasurements = measurementsResponse.data
          .where((m) => m.fieldId == selectedFieldId)
          .toList();
      final soilMeasurement = matchingMeasurements.isNotEmpty
          ? matchingMeasurements.first
          : null;

      debugPrint(
        '✅ Data fetched: soilPh=${soilMeasurement?.ph}, crops count=$totalCropsForField',
      );

      if (mounted) {
        final calculatedData = _calculateSoilMetrics(soilMeasurement);

        final farmScore = calculateFarmScore(
          soilHealthScore: calculatedData['healthScore'] as int,
          wiltingRisk: calculatedData['wiltingRisk'] as String,
        );
        final moodData = getMoodData(farmScore);
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
      if (mounted) setState(() => _isLoadingSoilCrop = false);
    }
  }

  Map<String, dynamic> _calculateSoilMetrics(dynamic soilMeasurement) {
    if (soilMeasurement == null) {
      return {'healthScore': 50, 'wiltingRisk': 'moderate'};
    }

    final ph = (soilMeasurement.ph as num?)?.toDouble() ?? 6.5;
    final moisture = (soilMeasurement.soilMoisture as num?)?.toDouble() ?? 50.0;
    final temp = (soilMeasurement.temperature as num?)?.toDouble() ?? 20.0;

    int nitrogen = 0;
    int phosphorus = 0;
    int potassium = 0;

    final nutrients = soilMeasurement.nutrients;
    if (nutrients is Map) {
      nitrogen = (nutrients['nitrogen'] as num?)?.toInt() ?? 0;
      phosphorus = (nutrients['phosphorus'] as num?)?.toInt() ?? 0;
      potassium = (nutrients['potassium'] as num?)?.toInt() ?? 0;
    }

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

    String wiltingRisk = 'moderate';
    if (moisture < 20) {
      wiltingRisk = 'high';
    } else if (moisture >= 20 && moisture <= 70) {
      wiltingRisk = 'low';
    } else {
      wiltingRisk = 'moderate';
    }

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

    final healthScore =
        ((phScore * 0.25) +
                (moistureScore * 0.35) +
                (nutrientScore * 0.25) +
                ((temp >= 15 && temp <= 30 ? 100 : 50) * 0.15))
            .toInt();

    debugPrint(
      '📊 Soil Metrics: pH=$ph (score=$phScore), Moisture=$moisture% (score=$moistureScore), Nutrients=$avgNutrient (score=$nutrientScore), Health=$healthScore, Wilting=$wiltingRisk',
    );

    return {
      'healthScore': healthScore.clamp(0, 100),
      'wiltingRisk': wiltingRisk,
    };
  }

  // ─────────────────────────────────────────────
  // SOCKET & FCM
  // ─────────────────────────────────────────────

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

      if (screen == 'SOIL_ALERTS' ||
          type.toUpperCase() == 'SOIL_WEATHER_ALERT') {
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

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Sections rendered as a flat list so they can be staggered on intro.
    final sections = <Widget>[
      _buildParcelSelectorButton(),
      _buildUnifiedFarmStatus(),
      _buildQuickAccessButtons(),
      _buildWeatherSoilCard(),
      _buildFarmReelsCard(),
      if (_isLoadingStats)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        )
      else ...[
        _buildAnimalStatsGrid(),
        _buildMilkProductionBanner(),
        _buildLiveHealthMetrics(),
      ],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF12211A),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildHeader(),
                for (var i = 0; i < sections.length; i++)
                  SliverToBoxAdapter(
                    child: _FadeSlideIn(
                      index: i,
                      controller: _intro,
                      child: sections[i],
                    ),
                  ),
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
  // HEADER BACKGROUND
  // ─────────────────────────────────────────────

  Widget _buildHeaderBackground() {
    return Positioned.fill(
      child: Container(
        // Neutral dark slate (not bright green) so any first-paint flash is invisible
        // against the dark gradient overlay above.
        color: const Color(0xFF12211A),
        child: Stack(
          children: [
            _buildAssetBackgroundImage(
              _backgroundSlides[_selectedBackgroundIndex],
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetBackgroundImage(BackgroundSlide slide) {
    return Image.asset(
      slide.imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      // Fade the image in over the dark slate base — eliminates any visible
      // colour flash while the asset is being decoded on first paint.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF12211A),
        width: double.infinity,
        height: double.infinity,
      ),
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
      backgroundColor: Colors.transparent,
      toolbarHeight: 80,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColorPalette.white),
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
                  '${context.l10n.hi}, ${context.l10n.timeBasedGreeting}',
                  style: AppTextStyles.h3().copyWith(
                    color: AppColorPalette.white,
                  ),
                ),
                if (_selectedFieldName != null)
                  Text(
                    _selectedFieldName!,
                    style: AppTextStyles.bodySmall(
                      color: AppColorPalette.white.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_rounded, color: AppColorPalette.white),
          tooltip: 'Language',
          onPressed: () => LanguageSelector.show(context),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColorPalette.white,
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(),
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
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, _) => Text(
                      '${notificationProvider.unreadCount}',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.white,
                      ).copyWith(fontSize: 10),
                    ),
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

  // ─────────────────────────────────────────────
  // PARCEL SELECTOR
  // ─────────────────────────────────────────────

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
            horizontal: isSmall ? 14 : 18,
            vertical: isSmall ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: isSmall ? 14 : 16,
                ),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              if (_selectedFieldName != null)
                Flexible(
                  child: Text(
                    _selectedFieldName!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(
                      color: Colors.white,
                    ).copyWith(
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                )
              else
                Text(
                  'Select a field',
                  style: AppTextStyles.bodyMedium(
                    color: Colors.white.withValues(alpha: 0.85),
                  ).copyWith(
                    fontSize: isSmall ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(width: isSmall ? 8 : 10),
              Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white.withValues(alpha: 0.85),
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
                    style: AppTextStyles.h3(
                      color: AppColorPalette.charcoalGreen,
                    ),
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
                        final isSelected =
                            weatherProvider.selectedFieldId == field.id;
                        return GestureDetector(
                          onTap: () async {
                            await weatherProvider.selectField(field.id);
                            if (!mounted) return;
                            setState(() => _selectedFieldName = field.name);
                            Navigator.pop(context);
                            _fetchAnimalsForField(field.id);
                            _fetchSoilAndCropData();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColorPalette.fieldFreshStart.withValues(
                                      alpha: 0.1,
                                    )
                                  : Colors.grey.shade100,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColorPalette.fieldFreshStart,
                                      width: 2,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColorPalette.fieldFreshStart
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.grass,
                                    color: AppColorPalette.fieldFreshStart,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        field.name,
                                        style: AppTextStyles.bodyLarge(
                                          color: AppColorPalette.charcoalGreen,
                                        ),
                                      ),
                                      Text(
                                        field.name,
                                        style: AppTextStyles.bodyLarge(
                                          color: AppColorPalette.charcoalGreen,
                                        ),
                                      ),
                                      Text(
                                        field.areaSize != null
                                            ? '${field.areaSize} ha'
                                            : 'Area not set',
                                        style: AppTextStyles.bodySmall(
                                          color: AppColorPalette.softSlate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColorPalette.fieldFreshStart,
                                  ),
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
  // UNIFIED FARM STATUS CARD
  // ─────────────────────────────────────────────

  Widget _buildUnifiedFarmStatus() {
    if (_isLoadingSoilCrop) {
      return _GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: SizedBox(
                height: 22,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0x22FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CC2A0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_farmMoodData == null || _plantMessage == null) {
      return const SizedBox.shrink();
    }

    final mood = _farmMoodData!;
    final accent = switch (mood.mood.toLowerCase()) {
      'happy' || 'great' || 'excellent' => const Color(0xFF34D399),
      'good' => const Color(0xFF60A5FA),
      'okay' || 'fair' => const Color(0xFFFBBF24),
      'concerned' || 'critical' || 'bad' => const Color(0xFFF87171),
      _ => const Color(0xFF34D399),
    };

    return _GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'FARM STATUS',
                          style: AppTextStyles.caption(
                            color: Colors.white.withValues(alpha: 0.70),
                          ).copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.55),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mood.mood,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${mood.score.round()}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (mood.score / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _plantMessage!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

    final actions = <_QuickAction>[
      _QuickAction(
        label: 'Fields',
        icon: Icons.landscape_rounded,
        gradient: const [Color(0xFF309448), Color(0xFF1F7A38)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FieldsManagementScreen(),
          ),
        ),
      ),
      _QuickAction(
        label: 'Missions',
        icon: Icons.task_alt_rounded,
        gradient: const [Color(0xFF3DBE6E), Color(0xFF227A47)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MissionListScreen()),
        ),
      ),
      _QuickAction(
        label: 'Assistant',
        icon: Icons.smart_toy_rounded,
        gradient: const [Color(0xFF4CC2A0), Color(0xFF1F8C72)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatAssistantScreen(),
          ),
        ),
      ),
      _QuickAction(
        label: 'Assets',
        icon: Icons.construction_rounded,
        gradient: const [Color(0xFF5BB55F), Color(0xFF2E7D32)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AssetListScreen()),
        ),
      ),
      _QuickAction(
        label: 'Skill Path',
        icon: Icons.workspace_premium_rounded,
        gradient: const [Color(0xFF1FB07A), Color(0xFF0A7E52)],
        onTap: () => Navigator.pushNamed(context, '/skill_certification'),
      ),
      _QuickAction(
        label: 'Control',
        icon: Icons.videogame_asset_rounded,
        gradient: const [Color(0xFF6A8FE0), Color(0xFF3955A8)],
        onTap: () => Navigator.pushNamed(context, '/control_room'),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsivePadding,
        vertical: responsiveVertical * 0.75,
      ),
      child: Column(
        children: [
          // ── Stylish glass quick-action grid ────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final a in actions)
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionTile(action: a, compact: isSmall),
                    ),
                ],
              );
            },
          ),

          // Weather Strip
          if (displayedWeather != null) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildWeatherChip(
                    icon: Icons.air,
                    label: 'Wind',
                    value:
                        '${displayedWeather.windSpeed.toStringAsFixed(1)} km/h',
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 8),
                  _buildWeatherChip(
                    icon: Icons.thermostat,
                    label: 'Temp Δ',
                    value:
                        '+${(displayedWeather.temperature - 15).toStringAsFixed(1)}°',
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
          ],
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _buildSoilHealthCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildCropHealthCard()),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FieldsManagementScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.mistyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColorPalette.mistyBlue.withValues(alpha: 0.35),
              ),
              icon: const Icon(Icons.map_rounded, color: Colors.white),
              label: const Text(
                'See Map',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
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
                style: AppTextStyles.caption(
                  color: color,
                ).copyWith(fontSize: 11),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall(
                  color: color,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoilHealthCard() {
    if (_isLoadingSoilCrop) {
      return _GlassCard(
        padding: const EdgeInsets.all(14),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CC2A0)),
            ),
          ),
        ),
      );
    }

    final hasPh = _soilPh != null;
    final phValue = _soilPh ?? 0;
    final isOptimal = hasPh && phValue >= 6.0 && phValue <= 7.5;
    final accent = const Color(0xFF4CC2A0);

    return _GlassCard(
      padding: const EdgeInsets.all(14),
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass_rounded, color: accent, size: 20),
              const SizedBox(width: 6),
              Text(
                'Soil Health',
                style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasPh ? 'pH ${phValue.toStringAsFixed(1)}' : 'pH —',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          _GlassChip(
            label: !hasPh
                ? 'Not recorded'
                : (isOptimal ? 'Optimal' : 'Adjust'),
            color: !hasPh
                ? Colors.white.withValues(alpha: 0.55)
                : (isOptimal ? accent : const Color(0xFFFBBF24)),
          ),
        ],
      ),
    );
  }

  Widget _buildCropHealthCard() {
    if (_isLoadingSoilCrop) {
      return _GlassCard(
        padding: const EdgeInsets.all(14),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
            ),
          ),
        ),
      );
    }

    const accent = Color(0xFF34D399);
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_florist_rounded,
                  color: accent, size: 20),
              const SizedBox(width: 6),
              Text(
                'Crops',
                style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$_totalCrops',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          _GlassChip(
            label: _totalCrops > 0 ? 'Active' : 'No crops',
            color: _totalCrops > 0
                ? accent
                : Colors.white.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WEATHER & SOIL CARD
  // ─────────────────────────────────────────────

  Widget _buildWeatherSoilCard() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        final forecast = weatherProvider.forecast;
        final current = forecast?.current ?? weatherInfo;
        final fieldName =
            weatherProvider.selectedField?.name ??
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
                  color: _skyShadowColorForCondition(
                    current.condition,
                  ).withValues(alpha: 0.30),
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
                  style: AppTextStyles.caption(
                    color: Colors.white70,
                  ).copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w600),
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
                            style: AppTextStyles.displayLarge(
                              color: Colors.white,
                            ).copyWith(fontSize: 58, height: 1),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            current.condition,
                            style: AppTextStyles.bodyLarge(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      current.weatherIcon,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherStat('Humidity', '${current.humidity}%'),
                      _buildWeatherStat(
                        'Wind',
                        '${current.windSpeed.toStringAsFixed(1)} km/h',
                      ),
                      _buildWeatherStat(
                        'Rain',
                        '${current.precipitation.toStringAsFixed(1)} mm',
                      ),
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
        Text(label, style: AppTextStyles.caption(color: Colors.white70)),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            color: Colors.white,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  LinearGradient _skyGradientForCondition(String condition) {
    final n = condition.toLowerCase();
    if (n.contains('thunder') || n.contains('storm')) {
      return const LinearGradient(
        colors: [Color(0xFF4B5B7E), Color(0xFF283248)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (n.contains('rain') || n.contains('drizzle')) {
      return const LinearGradient(
        colors: [Color(0xFF5F86A5), Color(0xFF3A5F7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (n.contains('cloud') || n.contains('overcast') || n.contains('fog')) {
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
    final n = condition.toLowerCase();
    if (n.contains('thunder') || n.contains('storm')) {
      return const Color(0xFF283248);
    }
    if (n.contains('rain') || n.contains('drizzle')) {
      return const Color(0xFF3A5F7D);
    }
    if (n.contains('cloud') || n.contains('overcast') || n.contains('fog')) {
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
  // ANIMAL STATS GRID
  // ─────────────────────────────────────────────

  Widget _buildAnimalStatsGrid() {
    if (_animalStats == null) return const SizedBox();

    final totalAnimals = _animalStats!['totalAnimals'] ?? 0;
    final healthAlerts = _animalStats!['healthAlerts'] ?? 0;
    final vaccinesDue = _animalStats!['vaccinesDue'] ?? 0;
    final responsivePadding = Responsive.horizontalPadding(context);
    final responsiveVertical = Responsive.verticalPadding(context);
    const cardSpacing = 10.0;

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
              ],
            ),
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnimalListScreen()),
                  ),
                ),
              ),
              const SizedBox(width: cardSpacing),
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
          const SizedBox(height: cardSpacing),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Vaccines Due',
                  '$vaccinesDue',
                  'Next 7 days',
                  Symbols.vaccines,
                  const Color(0xFF3B82F6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VaccineDashboardScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: cardSpacing),
              Expanded(
                child: _buildDashboardStatCard(
                  'Monthly Spend',
                  '${_animalStats!['monthlySpend'] ?? 0} DT',
                  'Feed & Care',
                  Symbols.payments,
                  const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinanceDashboardScreen(),
                    ),
                  ),
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
    final isSmall = Responsive.isMobile(context);
    final cardPadding = Responsive.cardPadding(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: isSmall ? 16 : 20),
              ),
              SizedBox(height: isSmall ? 10 : 14),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isSmall ? 2 : 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 11 : 12,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: isSmall ? 1 : 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: isSmall ? 10 : 11,
                ),
              ),
            ],
          ),
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
                    today.toStringAsFixed(1),
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
  // ─────────────────────────────────────────────

  Widget _buildLiveHealthMetrics() {
    final responsivePadding = Responsive.horizontalPadding(context);
    final responsiveVertical = Responsive.verticalPadding(context);
    final isMobile = Responsive.isMobile(context);
    final cardHeight = isMobile ? 340.0 : 360.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  BackgroundSlide({required this.imageAsset, required this.fallbackColor});
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION TILE
// Stylish glass-style tile used in the Home quick-access grid.
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  final bool compact;

  const _QuickActionTile({required this.action, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final iconBox = compact ? 42.0 : 48.0;
    final iconSize = compact ? 22.0 : 24.0;
    final fontSize = compact ? 11.5 : 12.5;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: action.gradient.first.withValues(alpha: 0.25),
        highlightColor: action.gradient.last.withValues(alpha: 0.10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            // Dark translucent "glass" — no white card.
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: action.gradient.first.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: action.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradient.last.withValues(alpha: 0.55),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(action.icon, size: iconSize, color: Colors.white),
              ),
              SizedBox(height: compact ? 9 : 11),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED GLASS PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────────

/// Translucent dark "glass" card. White text reads cleanly on top of the
/// home-screen hero image thanks to the dark gradient overlay.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double radius;

  const _GlassCard({
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.tint,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? Colors.white;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (tint != null)
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: child,
    );
  }
}

/// Small pill used inside glass cards.
class _GlassChip extends StatelessWidget {
  final String label;
  final Color color;
  const _GlassChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Staggered fade + slide-in for each home-screen section.
/// Mirrors the per-row intro used in [AppDrawer].
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;

  const _FadeSlideIn({
    required this.index,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Each row enters slightly later than the previous one.
    final start = (index * 0.06).clamp(0.0, 0.6);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 22),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
