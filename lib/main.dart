import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/parcel_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/irrigation_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/incident_detail_screen.dart';
import 'screens/soil/soil_measurements_list_screen.dart';


/// Global navigator key — used for navigating from notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are shown automatically by the OS
}

/// Handle incoming FCM message — extract incidentId and navigate
void handleMessage(RemoteMessage message) {
  final incidentId = message.data['incidentId'];
  if (incidentId != null && incidentId.toString().isNotEmpty) {
    navigatorKey.currentState?.pushNamed(
      '/incident-details',
      arguments: incidentId,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const FieldlyApp());
}

class FieldlyApp extends StatefulWidget {
  const FieldlyApp({super.key});

  @override
  State<FieldlyApp> createState() => _FieldlyAppState();
}

class _FieldlyAppState extends State<FieldlyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
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
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Fieldly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/incident-details': (context) {
            final incidentId =
                ModalRoute.of(context)!.settings.arguments as String;
            return IncidentDetailScreen(incidentId: incidentId);
          },
        },
      ),
    );
  }
}
