import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan tampilan yang disimpan di HP ini (bukan di Firestore).
class AppSettings {
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);
  static final ValueNotifier<String> bahasa = ValueNotifier('id');

  static Future<void> muat() async {
    try {
      final tema = await _prefs.getString('themeMode') ?? 'light';
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.name == tema,
        orElse: () => ThemeMode.light,
      );
      bahasa.value = await _prefs.getString('bahasa') ?? 'id';
    } catch (e) {
      debugPrint('Gagal memuat pengaturan: $e');
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs.setString('themeMode', mode.name);
  }

  static Future<void> setBahasa(String kode) async {
    bahasa.value = kode;
    await _prefs.setString('bahasa', kode);
  }

  static String labelTema(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
    }
  }

  static String labelBahasa(String kode) {
    return kode == 'en' ? 'English' : 'Bahasa Indonesia';
  }
}
