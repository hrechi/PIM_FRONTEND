import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/parcel_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'soil/screens/soil_measurements_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FieldlyApp());
}

class FieldlyApp extends StatelessWidget {
  const FieldlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SoilMeasurementsProvider()),
        ChangeNotifierProvider(create: (_) => ParcelProvider()),
      ],
      child: MaterialApp(
        title: 'Fieldly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
