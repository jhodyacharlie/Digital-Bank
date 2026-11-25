import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/setting_model.dart';
import '../services/setting_service.dart';

class SettingController extends ChangeNotifier {
  SettingController({required this.userId, SettingService? service})
      : _service = service ?? SettingService(),
        _setting = SettingModel(userId: userId);

  /// ID dokumen di koleksi `users` (milik pengguna yang sedang login).
  final String userId;
  final SettingService _service;

  SettingModel _setting;
  SettingModel get setting => _setting;

  /// Pesan jika data akun gagal dimuat dari Firebase (null = aman).
  String? loadError;

  final LocalAuthentication _auth = LocalAuthentication();

  static const _errJaringan = 'Gagal terhubung ke server. Coba lagi.';

  // Dipanggil sekali saat aplikasi dibuka
  Future<void> load() async {
    // 1) Cache lokal dulu -> tema/bahasa langsung benar tanpa menunggu jaringan.
    final p = await SharedPreferences.getInstance();
    _setting = _setting.copyWith(
      isDarkMode: p.getBool('dark') ?? false,
      language: p.getString('lang') ?? 'Bahasa Indonesia',
      biometricEnabled: p.getBool('bio') ?? false,
      pinEnabled: p.getBool('pinOn') ?? true,
      accountProtection: p.getBool('protect') ?? true,
    );
    notifyListeners();

    // 2) Data akun & preferensi dari Firestore.
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
        // Samakan cache lokal dengan server.
        await p.setBool('dark', _setting.isDarkMode);
        await p.setString('lang', _setting.language);
      }
    } on FirebaseException catch (e) {
      loadError = 'Gagal memuat data akun (${e.code})';
    } catch (e) {
      loadError = _errJaringan;
    }
    notifyListeners();
  }

  /// Simpan preferensi ke Firestore. Gagal (mis. offline) tidak membatalkan
  /// perubahan di perangkat; nilai tetap tersimpan lokal.
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
    (await SharedPreferences.getInstance()).setBool('dark', value);
    await _sinkron({'isDarkMode': value});
  }

  Future<void> setLanguage(String lang) async {
    _setting = _setting.copyWith(language: lang);
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('lang', lang);
    await _sinkron({'language': lang});
  }

  // Biometrik = per perangkat -> hanya lokal, tidak ke Firebase.
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
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('protect', value);
  }

  // ----- Ubah PIN (hash di Firestore, kompatibel dengan login Charlie) -----
  Future<String?> changePin(String oldPin, String newPin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(newPin)) {
      return 'PIN baru harus 6 digit angka';
    }
    try {
      if (!await _service.cekPin(userId, oldPin)) return 'PIN lama salah';
      await _service.ubahPin(userId, newPin);
      return null;
    } catch (e) {
      return _errJaringan;
    }
  }

  // ----- Ubah Password -----
  Future<String?> changePassword(String oldPass, String newPass) async {
    if (newPass.length < 8) return 'Password baru minimal 8 karakter';
    try {
      if (!await _service.cekPassword(userId, oldPass)) {
        return 'Password lama salah';
      }
      await _service.ubahPassword(userId, newPass);
      return null;
    } catch (e) {
      return _errJaringan;
    }
  }

  // ----- Ubah Email -----
  Future<String?> changeEmail(String newEmail) async {
    final email = newEmail.trim().toLowerCase();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    try {
      if (await _service.emailDipakaiOrangLain(userId, email)) {
        return 'Email sudah terdaftar';
      }
      await _service.ubahEmail(userId, email);
    } catch (e) {
      return _errJaringan;
    }
    _setting = _setting.copyWith(email: email);
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
