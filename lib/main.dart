import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/parcel_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/irrigation_provider.dart';
import 'providers/vaccine_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/shorts_provider.dart';
import 'providers/field_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/catalogue_provider.dart';
import 'providers/voice_access_mode_provider.dart';
import 'providers/global_voice_controller.dart';
import 'providers/asset_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/billing_return_screen.dart';
import 'screens/farmer_home_screen_v2.dart';
import 'screens/asset_list_screen.dart';
import 'screens/control_room_screen.dart';
import 'screens/skill_certification_screen.dart';
import 'screens/security/incident_detail_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/vaccines/vaccine_dashboard_screen.dart';
import 'screens/soil/soil_measurements_list_screen.dart';
import 'screens/soil/soil_alert_notifications_screen.dart';
import 'services/local_notification_service.dart';
import 'widgets/global_voice_fab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/constants.dart';

/// Global navigator key — used for navigating from notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are shown automatically by the OS
}

/// Handle incoming FCM message — extract incidentId and navigate
void handleNotificationData(Map<String, dynamic> data) {
  final screen = (data['screen'] ?? '').toString().toUpperCase();
  final type = (data['type'] ?? '').toString().toUpperCase();

  if (screen == 'SOIL_ALERTS' || type == 'SOIL_WEATHER_ALERT') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const SoilAlertNotificationsScreen()),
    );
    return;
  }

  if (screen == 'ASSET_DETAILS' || type == 'ASSET_MAINTENANCE_ALERT') {
    final assetId = (data['assetId'] ?? '').toString();
    navigatorKey.currentState?.pushNamed(
      '/assets',
      arguments: assetId.isEmpty ? null : {'assetId': assetId},
    );
    return;
  }

  final incidentId = data['incidentId'];
  if (incidentId != null && incidentId.toString().isNotEmpty) {
    navigatorKey.currentState?.pushNamed(
      '/incident-details',
      arguments: incidentId,
    );
  }
}

void handleMessage(RemoteMessage message) {
  handleNotificationData(Map<String, dynamic>.from(message.data));
}

class MyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await LocalNotificationService.initialize(onTap: handleNotificationData);
  }

  await initializeDateFormatting('fr_FR', null);

  runApp(const FieldlyApp());
}

class FieldlyApp extends StatefulWidget {
  const FieldlyApp({super.key});

  @override
  State<FieldlyApp> createState() => _FieldlyAppState();
}

class _FieldlyAppState extends State<FieldlyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
    _setupDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupNotificationNavigation() async {
    if (kIsWeb) {
      return;
    }

    // App was terminated → user tapped notification to open it
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Small delay to let the navigator finish building
      Future.delayed(const Duration(milliseconds: 500), () {
        handleMessage(initialMessage);
      });
    }

    // App was in background → user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // App is in foreground → show local notification so it appears in the phone tray.
    FirebaseMessaging.onMessage.listen((message) {
      LocalNotificationService.showFromRemoteMessage(message);
    });
  }

  Future<void> _setupDeepLinks() async {
    if (kIsWeb) {
      return;
    }

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingDeepLink(initialUri);
      }
    } catch (_) {}

    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingDeepLink,
      onError: (_) {},
    );
  }

  void _handleIncomingDeepLink(Uri uri) {
    if (uri.scheme != AppConfig.appScheme) {
      return;
    }

    if (uri.host == 'billing-return' || uri.path == '/billing-return') {
      final sessionId = uri.queryParameters['session_id'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/billing-return',
          (route) => false,
          arguments: {'sessionId': sessionId},
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SoilMeasurementsProvider()),
        ChangeNotifierProvider(create: (_) => ParcelProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => IrrigationProvider()),
        ChangeNotifierProvider(create: (_) => VaccineProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ShortsProvider()),
        ChangeNotifierProvider(create: (_) => FieldProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => CatalogueProvider()),
        ChangeNotifierProvider(
          create: (_) => VoiceAccessModeProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => GlobalVoiceController(
            accessModeProvider: context.read<VoiceAccessModeProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        title: 'Fieldly',
        scrollBehavior: MyScrollBehavior(),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const GlobalVoiceFab(),
            ],
          );
        },
        routes: {
          '/billing-return': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final sessionId = args is Map ? args['sessionId']?.toString() : null;
            return BillingReturnScreen(sessionId: sessionId);
          },
          '/owner_dashboard': (context) => const HomeScreen(),
          '/worker_home': (context) => const FarmerHomeScreenV2(),
          '/farmer_home': (context) => const FarmerHomeScreenV2(),
          '/control_room': (context) => const ControlRoomScreen(),
          '/skill_certification': (context) => const SkillCertificationScreen(),
          '/assets': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final assetId = args is Map ? args['assetId']?.toString() : null;
            return AssetListScreen(focusAssetId: assetId);
          },
          '/incident-details': (context) {
            final incidentId =
                ModalRoute.of(context)!.settings.arguments as String;
            return IncidentDetailScreen(incidentId: incidentId);
          },
          '/notifications': (context) => const NotificationCenterScreen(),
          '/vaccine-dashboard': (context) =>
              const VaccineDashboardScreen(), // assuming this exists or maps to the correct screen
        },
      ),
    );
  }
}
