import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/setting_model.dart';

class SettingController extends ChangeNotifier {
  SettingModel _setting = const SettingModel();
  SettingModel get setting => _setting;

  final LocalAuthentication _auth = LocalAuthentication();
  String _pin = '123456';
  String _password = 'password123';

  // Dipanggil sekali saat aplikasi dibuka
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _setting = _setting.copyWith(
      isDarkMode: p.getBool('dark') ?? false,
      language: p.getString('lang') ?? 'Bahasa Indonesia',
      biometricEnabled: p.getBool('bio') ?? false,
      pinEnabled: p.getBool('pinOn') ?? true,
      accountProtection: p.getBool('protect') ?? true,
      email: p.getString('email') ?? 'bunga@email.com',
    );
    _pin = p.getString('pin') ?? '123456';
    _password = p.getString('password') ?? 'password123';
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _setting = _setting.copyWith(isDarkMode: value);
    (await SharedPreferences.getInstance()).setBool('dark', value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _setting = _setting.copyWith(language: lang);
    (await SharedPreferences.getInstance()).setString('lang', lang);
    notifyListeners();
  }

  // Return pesan error, atau null jika berhasil
  Future<String?> toggleBiometric(bool value) async {
    final p = await SharedPreferences.getInstance();
    if (value) {
      try {
        final bisa =
            await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (!bisa) return 'Perangkat tidak mendukung biometrik';
        final ok = await _auth.authenticate(
          localizedReason: 'Verifikasi untuk mengaktifkan biometrik',
          options: const AuthenticationOptions(biometricOnly: true),
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
    (await SharedPreferences.getInstance()).setBool('protect', value);
    notifyListeners();
  }

  // ----- Ubah PIN -----
  Future<String?> changePin(String oldPin, String newPin) async {
    if (oldPin != _pin) return 'PIN lama salah';
    if (newPin.length != 6) return 'PIN baru harus 6 digit';
    _pin = newPin;
    (await SharedPreferences.getInstance()).setString('pin', newPin);
    return null;
  }

  // ----- Ubah Password -----
  Future<String?> changePassword(String oldPass, String newPass) async {
    if (oldPass != _password) return 'Password lama salah';
    if (newPass.length < 8) return 'Password baru minimal 8 karakter';
    _password = newPass;
    (await SharedPreferences.getInstance()).setString('password', newPass);
    return null;
  }

  // ----- Ubah Email -----
  Future<String?> changeEmail(String newEmail) async {
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      return 'Format email tidak valid';
    }
    _setting = _setting.copyWith(email: newEmail);
    (await SharedPreferences.getInstance()).setString('email', newEmail);
    notifyListeners();
    return null;
  }

  // ----- Keluar -----
  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('bio', false);
    _setting = _setting.copyWith(biometricEnabled: false);
    notifyListeners();
  }
}
