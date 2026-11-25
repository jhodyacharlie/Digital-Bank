import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/setting_controller.dart';
import 'controllers/notification_controller.dart';
import 'views/setting_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingController()..load()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
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
