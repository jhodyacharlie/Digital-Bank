import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/notification_controller.dart';
import 'controllers/setting_controller.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'views/setting_view.dart';

/// Pengguna yang sedang login.
/// TODO: saat digabung ke Digital-Bank, ganti dengan user['id'] dari LoginScreen
/// milik Charlie (mis. dikirim lewat constructor SettingView).
/// 'andi' = akun contoh dari UserService.seedUsers().
const String kUserId = 'andi';

/// Isi notifikasi contoh sekali (hanya jika koleksi masih kosong).
/// Set false saat notifikasi sudah dibuat oleh fitur transfer/QRIS yang asli.
const bool kSeedNotifikasiContoh = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kSeedNotifikasiContoh) {
    try {
      await NotificationService().seedContoh(kUserId);
    } catch (e) {
      debugPrint('Gagal mengisi notifikasi contoh: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingController(userId: kUserId)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(userId: kUserId)..start(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingController>().setting.isDarkMode;
    const biruBca = Color(0xFF0B5CAD);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'myBCA',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: biruBca),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: biruBca,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const SettingView(),
    );
  }
}
