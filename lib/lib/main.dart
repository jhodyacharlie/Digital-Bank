import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'app_style.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppSettings.muat();

  try {
    await UserService().seedUsers();
  } catch (e) {
    debugPrint('Gagal isi data contoh: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData buatTema(Brightness kecerahan) {
    final gelap = kecerahan == Brightness.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.biru,
        brightness: kecerahan,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor:
          gelap ? AppColors.latarGelap : AppColors.biruMuda,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Digeboy',
          debugShowCheckedModeBanner: false,
          theme: buatTema(Brightness.light),
          darkTheme: buatTema(Brightness.dark),
          themeMode: mode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
