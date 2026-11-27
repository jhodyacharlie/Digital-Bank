import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/setting_model.dart';
import '../services/locale_service.dart';
import '../services/setting_service.dart';
import '../user_service.dart';
import '../services/theme_service.dart';

class SettingController extends ChangeNotifier {
  SettingController({required this.userId, SettingService? service})
    : _service = service ?? SettingService(),
      _setting = SettingModel(userId: userId);

  final String userId;
  final SettingService _service;

  SettingModel _setting;
  SettingModel get setting => _setting;

  String? loadError;

  final LocalAuthentication _auth = LocalAuthentication();

  static const _errJaringan = 'Gagal terhubung ke server. Coba lagi.';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _setting = _setting.copyWith(
      isDarkMode: p.getBool('dark') ?? false,
      language: p.getString('lang') ?? 'Bahasa Indonesia',
      biometricEnabled: p.getBool('bio') ?? false,
      pinEnabled: p.getBool('pinOn') ?? true,
      accountProtection: p.getBool('protect') ?? true,
    );
    notifyListeners();

    try {
      final data = await _service.getUser(userId);
      if (data == null) {
        loadError = 'Pengguna "$userId" tidak ditemukan di Firestore';
      } else {
        final s = (data['settings'] as Map<String, dynamic>?) ?? const {};
        _setting = _setting.copyWith(
          name: (data['nama'] ?? _setting.name) as String,
          email: (data['email'] ?? '') as String,
          isDarkMode: (s['isDarkMode'] as bool?) ?? _setting.isDarkMode,
          language: (s['language'] as String?) ?? _setting.language,
        );
        loadError = null;

        await p.setBool('dark', _setting.isDarkMode);
        await ThemeService.setDark(_setting.isDarkMode);
        await LocaleService.setLanguage(_setting.language);
      }
    } on FirebaseException catch (e) {
      loadError = 'Gagal memuat data akun (${e.code})';
    } catch (e) {
      loadError = _errJaringan;
    }
    notifyListeners();
  }

  Future<void> _sinkron(Map<String, dynamic> values) async {
    try {
      await _service.updateSettings(userId, values);
    } catch (e) {
      debugPrint('Gagal menyimpan pengaturan ke Firebase: $e');
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    _setting = _setting.copyWith(isDarkMode: value);
    notifyListeners();
    await ThemeService.setDark(value);
    await _sinkron({'isDarkMode': value});
  }

  Future<void> setLanguage(String lang) async {
    _setting = _setting.copyWith(language: lang);
    notifyListeners();
    await LocaleService.setLanguage(lang);
    await _sinkron({'language': lang});
  }

  Future<String?> toggleBiometric(bool value) async {
    final p = await SharedPreferences.getInstance();
    if (value) {
      try {
        final bisa =
            await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (!bisa) return 'Perangkat tidak mendukung biometrik';
        final ok = await _auth.authenticate(
          localizedReason: 'Verifikasi untuk mengaktifkan biometrik',
        );
        if (!ok) return 'Verifikasi dibatalkan';
      } catch (e) {
        return 'Biometrik tidak tersedia di perangkat ini';
      }
    }
    _setting = _setting.copyWith(biometricEnabled: value);
    await p.setBool('bio', value);
    notifyListeners();
    return null;
  }

  Future<void> toggleAccountProtection(bool value) async {
    _setting = _setting.copyWith(accountProtection: value);
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('protect', value);
  }

  Future<String?> changePin(String oldPin, String newPin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(newPin)) {
      return 'PIN baru harus 6 digit angka';
    }
    try {
      await _service.ubahPin(userId, newPin, oldPin: oldPin);
      return null;
    } catch (e) {
      return _errJaringan;
    }
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    return 'Password terpisah belum tersedia: pada versi ini PIN 6 digit adalah password Firebase untuk login. Gunakan menu Ubah PIN agar akses login tidak rusak.';
  }

  Future<String?> changeEmail(String newEmail) async {
    final email = newEmail.trim().toLowerCase();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    try {
      await _service.ubahEmail(userId, email);
    } catch (e) {
      return _errJaringan;
    }
    _setting = _setting.copyWith(email: email);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await UserService().logout();
    final p = await SharedPreferences.getInstance();
    await p.setBool('bio', false);
    _setting = _setting.copyWith(biometricEnabled: false);
    notifyListeners();
  }
}
