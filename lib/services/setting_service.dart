import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Operasi Firestore untuk pengaturan akun.
///
/// Dokumen: users/{userId}  (dokumen yang sama dengan UserService milik Charlie)
///   nama, email, pin (sha256), password (sha256 "$userId:$password"), ...
///   settings: { language, isDarkMode, notifTransaksi, notifPromo, notifInfo }
///
/// Preferensi disimpan di map `settings` supaya tidak bentrok dengan field
/// milik fitur lain. Biometrik sengaja TIDAK di sini: itu pengaturan per
/// perangkat, tetap di shared_preferences.
class SettingService {
  SettingService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _db.collection('users').doc(userId);

  // Sama persis dengan UserService.hashPin / SecurityService.hashPassword
  // milik Charlie, agar PIN & password yang diubah di sini tetap valid saat login.
  String _hash(String teks) => sha256.convert(utf8.encode(teks)).toString();
  String _hashPin(String pin) => _hash(pin);
  String _hashPassword(String userId, String password) =>
      _hash('$userId:$password');

  /// null = pengguna tidak ada.
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final snap = await _user(userId).get();
    return snap.data();
  }

  /// Contoh: updateSettings(id, {'language': 'English'})
  /// -> update field bertingkat settings.language
  Future<void> updateSettings(String userId, Map<String, dynamic> values) {
    return _user(userId).update({
      for (final e in values.entries) 'settings.${e.key}': e.value,
    });
  }

  // ---------- PIN ----------

  Future<bool> cekPin(String userId, String pin) async {
    final data = (await _user(userId).get()).data();
    return data != null && data['pin'] == _hashPin(pin);
  }

  Future<void> ubahPin(String userId, String pinBaru) {
    return _user(userId).update({'pin': _hashPin(pinBaru)});
  }

  // ---------- Password ----------

  /// Akun yang belum punya password (mis. akun contoh) -> true untuk
  /// password lama kosong, supaya bisa dibuatkan pertama kali.
  Future<bool> cekPassword(String userId, String password) async {
    final data = (await _user(userId).get()).data();
    if (data == null) return false;
    final tersimpan = data['password'];
    if (tersimpan == null) return password.isEmpty;
    return tersimpan == _hashPassword(userId, password);
  }

  Future<void> ubahPassword(String userId, String passwordBaru) {
    return _user(userId).update({'password': _hashPassword(userId, passwordBaru)});
  }

  // ---------- Email ----------

  Future<bool> emailDipakaiOrangLain(String userId, String email) async {
    final hasil = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(2)
        .get();
    return hasil.docs.any((d) => d.id != userId);
  }

  Future<void> ubahEmail(String userId, String email) {
    return _user(userId).update({'email': email});
  }
}
