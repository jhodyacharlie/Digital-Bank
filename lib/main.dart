import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_style.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'services/local_notification_service.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeService.load();
  await LocaleService.load();
  await LocalNotificationService.instance.init();

  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  if (kDebugMode && useEmulators) {
    const host = String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    );
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeService.mode, LocaleService.language]),
      builder: (context, _) {
        final lightScheme = ColorScheme.fromSeed(
          seedColor: AppColors.biru,
          brightness: Brightness.light,
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: AppColors.biru,
          brightness: Brightness.dark,
        );
        return MaterialApp(
          title: 'MyBCA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F6FC),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.biru,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D1420),
            cardColor: const Color(0xFF162032),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF102A4C),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          themeMode: ThemeService.mode.value,
          home: const LoginScreen(),
        );
      },
    );
  }
}
