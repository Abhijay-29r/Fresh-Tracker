import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'main_navigation.dart';
import 'splash_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready before doing background work
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive (our local storage)
  await Hive.initFlutter();

  // 3. Turn on our custom database engine so it's ready to save/load
  await DatabaseService.init();
  // Open the simple box for the shopping list
  await Hive.openBox('shoppingBox');

  // Open a box to save user settings
  await Hive.openBox('settingsBox');

  // 4
  await NotificationService.init();

  // 5. Run the app
  runApp(const FreshTrackApp());
}

class FreshTrackApp extends StatelessWidget {
  const FreshTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // 5. Tell the app to start on the SplashScreen
      home: const SplashScreen(),
    );
  }
}
