import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'models/shift.dart';
import 'models/scanned_roster.dart';
import 'models/user_preferences.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/colors.dart';

Future<void> main() async {
  // 1. Enable Device Preview FIRST (it sets up the binding itself).
  DevicePreview.enable(enabled: !kReleaseMode);

  // 2. Load environment variables (.env with GEMINI_API_KEY).
  await dotenv.load(fileName: '.env');

  // 3. Initialise Hive and register adapters.
  await Hive.initFlutter();
  Hive.registerAdapter(ShiftAdapter());
  Hive.registerAdapter(ScannedRosterAdapter());
  Hive.registerAdapter(UserPreferencesAdapter());

  // 4. Open the boxes we'll use throughout the app.
  await Hive.openBox<Shift>('shifts');
  await Hive.openBox<ScannedRoster>('rosters');
  await Hive.openBox<UserPreferences>('preferences');

  // 5. Initialise notifications.
  await NotificationService().init();

  // 6. Run the app wrapped in a Riverpod scope.
  runApp(
    const ProviderScope(child: ShiftSnapApp()),
  );
}

class ShiftSnapApp extends StatelessWidget {
  const ShiftSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}