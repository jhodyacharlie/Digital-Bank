import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await UserService().seedUsers();
  } catch (e) {
    debugPrint('Gagal isi data contoh: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digeboy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.biru),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
