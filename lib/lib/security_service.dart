import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String formatWaktu(int ms) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final jam = d.hour.toString().padLeft(2, '0');
  final menit = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year}, $jam:$menit';
}

class PerangkatIni {
  const PerangkatIni(this.id, this.nama);

  final String id;
  final String nama;
}

class SecurityService {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  String _hash(String teks) => sha256.convert(utf8.encode(teks)).toString();

  // ---------- perangkat ----------

  /// ID acak yang dibuat sekali lalu disimpan di HP ini.
  Future<PerangkatIni> perangkatIni() async {
    var id = await prefs.getString('deviceId');
    if (id == null) {
      id = 'dev${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      await prefs.setString('deviceId', id);
    }
    final os = Platform.isAndroid
        ? 'Android'
        : (Platform.isIOS ? 'iPhone' : Platform.operatingSystem);
    return PerangkatIni(id, '$os device');
  }

  Future<List<Map<String, dynamic>>> daftarPerangkat(String userId) async {
    final hasil = await users
        .doc(userId)
        .collection('devices')
        .orderBy('terakhirAktif', descending: true)
        .get();
    return hasil.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  Future<void> hapusPerangkat(String userId, String deviceId) {
    return users.doc(userId).collection('devices').doc(deviceId).delete();
  }

  // ---------- aktivitas login ----------

  /// Mencatat percobaan login. Kalau gagal mencatat, login tetap jalan.
  Future<void> catatLogin(
    String userId, {
    required String metode,
    bool berhasil = true,
    String? catatan,
  }) async {
    try {
      final dev = await perangkatIni();
      final sekarang = DateTime.now().millisecondsSinceEpoch;
      final ref = users.doc(userId);

      await ref.collection('loginActivity').add({
        'waktu': sekarang,
        'metode': metode,
        'berhasil': berhasil,
        'perangkat': dev.nama,
        'deviceId': dev.id,
        if (catatan != null) 'catatan': catatan,
      });

      if (!berhasil) return;
      final devRef = ref.collection('devices').doc(dev.id);
      final ada = await devRef.get();
      await devRef.set({
        'nama': dev.nama,
        'terakhirAktif': sekarang,
        if (!ada.exists) 'pertamaKali': sekarang,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Gagal mencatat aktivitas login: $e');
    }
  }

  Future<List<Map<String, dynamic>>> aktivitasLogin(
    String userId, {
    int batas = 30,
  }) async {
    final hasil = await users
        .doc(userId)
        .collection('loginActivity')
        .orderBy('waktu', descending: true)
        .limit(batas)
        .get();
    return hasil.docs.map((d) => d.data()).toList();
  }

  // ---------- kode verifikasi 2 langkah ----------

  Future<String> buatOtp(String userId) async {
    final kode = (100000 + Random().nextInt(900000)).toString();
    final batas = DateTime.now().add(const Duration(minutes: 5));
    await users.doc(userId).update({
      'otpHash': _hash('otp:$userId:$kode'),
      'otpExpired': batas.millisecondsSinceEpoch,
    });
    return kode;
  }

  Future<bool> cekOtp(String userId, String kode) async {
    final doc = await users.doc(userId).get();
    final data = doc.data() as Map<String, dynamic>;

    final hash = data['otpHash'];
    final batas = (data['otpExpired'] ?? 0) as num;
    if (hash == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > batas) return false;
    if (hash != _hash('otp:$userId:$kode')) return false;

    await users.doc(userId).update({
      'otpHash': FieldValue.delete(),
      'otpExpired': FieldValue.delete(),
    });
    return true;
  }

  // ---------- password akun ----------

  String hashPassword(String userId, String password) {
    return _hash('$userId:$password');
  }

  Future<bool> cekPassword(String userId, String password) async {
    final doc = await users.doc(userId).get();
    final data = doc.data() as Map<String, dynamic>;
    return data['password'] == hashPassword(userId, password);
  }

  Future<String> simpanPassword(String userId, String password) async {
    final hash = hashPassword(userId, password);
    await users.doc(userId).update({'password': hash});
    return hash;
  }

  // ---------- bantuan ----------

  Future<void> kirimTiket({
    required String userId,
    required String nama,
    required String email,
    required String kategori,
    required String pesan,
  }) {
    return FirebaseFirestore.instance.collection('support_tickets').add({
      'userId': userId,
      'nama': nama,
      'email': email,
      'kategori': kategori,
      'pesan': pesan,
      'status': 'Baru',
      'dibuat': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
