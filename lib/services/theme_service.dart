import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    mode.value = (p.getBool('dark') ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', dark);
  }
}
