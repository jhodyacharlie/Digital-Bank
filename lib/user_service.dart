import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'models/notification_model.dart';
import 'services/notification_service.dart';
import 'admin/admin_service.dart';

class RegisterException implements Exception {
  RegisterException(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}

class UserService {
  UserService({this._firestore, FirebaseAuth? auth}) : _firebaseAuth = auth;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _firebaseAuth;

  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _firebaseAuth ??= FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _rekeningIndex =>
      _db.collection('rekening_index');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _users.doc(uid);

  static String normalisasiPhone(String input) {
    var phone = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (phone.startsWith('+62')) {
      phone = '0${phone.substring(3)}';
    } else if (phone.startsWith('62')) {
      phone = '0${phone.substring(2)}';
    }
    return phone;
  }

  static String _randomSecretPassword([String prefix = 'Tmp']) {
    final rng = Random.secure();
    final hex = List.generate(
      12,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '$prefix#$hex!Aa1';
  }

  Future<Map<String, dynamic>> register({
    required String namaDepan,
    required String namaBelakang,
    required String email,
    required String phone,
    required DateTime tanggalLahir,
    required String gender,
    required String alamat,
    required String kewarganegaraan,
  }) async {
    final emailBersih = email.trim().toLowerCase();
    final phoneBersih = normalisasiPhone(phone);
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailBersih)) {
      throw RegisterException('Format email tidak valid');
    }
    if (!RegExp(r'^08\d{8,11}$').hasMatch(phoneBersih)) {
      throw RegisterException('Nomor HP tidak valid');
    }

    if (_auth.currentUser != null) {
      await _auth.signOut();
    }

    final sementara = _randomSecretPassword();

    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: emailBersih,
        password: sementara,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw RegisterException(
            'Email sudah terdaftar. Jika belum selesai verifikasi sebelumnya, coba Lupa PIN atau gunakan email lain.',
          );
        case 'invalid-email':
          throw RegisterException('Format email tidak valid');
        case 'weak-password':
          throw RegisterException(
            'Kebijakan password Firebase Auth menolak password sementara (${e.message ?? e.code})',
          );
        case 'network-request-failed':
          throw RegisterException(
            'Gagal terhubung ke server Firebase. Periksa koneksi internet.',
          );
        case 'operation-not-allowed':
          throw RegisterException(
            'Login Email/Password belum diaktifkan di Firebase Console',
          );
        case 'too-many-requests':
          throw RegisterException(
            'Terlalu banyak percobaan pendaftaran. Coba lagi beberapa menit lagi.',
          );
        case 'app-not-authorized':
        case 'invalid-app-credential':
        case 'configuration-not-found':
          throw RegisterException(
            'Konfigurasi Firebase Auth belum lengkap (${e.code}). Periksa SHA-1 / Firebase Console.',
          );
        default:
          throw RegisterException(
            'Pendaftaran gagal (${e.code}): ${e.message ?? ''}',
          );
      }
    }

    var verificationSent = false;
    String? verificationError;
    try {
      await _auth.setLanguageCode('id');
      await cred.user!.sendEmailVerification();
      verificationSent = true;
    } on FirebaseAuthException catch (e) {
      verificationError = '${e.code}: ${e.message ?? 'gagal mengirim email'}';
      debugPrint('sendEmailVerification error: $verificationError');
    } catch (e) {
      verificationError = e.toString();
      debugPrint('sendEmailVerification error: $verificationError');
    }

    final depan = namaDepan.trim();
    final belakang = namaBelakang.trim();
    return {
      'uid': cred.user!.uid,
      'namaDepan': depan,
      'namaBelakang': belakang,
      'nama': '$depan $belakang'.trim(),
      'email': emailBersih,
      'phone': phoneBersih,
      'tanggalLahirMillis': tanggalLahir.millisecondsSinceEpoch,
      'gender': gender,
      'alamat': alamat.trim(),
      'kewarganegaraan': kewarganegaraan.trim(),
      'verificationSent': verificationSent,
      'verificationError': ?verificationError,
    };
  }

  Future<void> batalkanPendaftaranSementara() async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      await u.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  Future<void> kirimUlangVerifikasiEmail() async {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Belum ada sesi pendaftaran aktif');
    await u.sendEmailVerification();
  }

  Future<bool> cekEmailTerverifikasi() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    try {
      await u.reload();
    } catch (_) {
      return false;
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<String> _buatRekening() async {
    while (true) {
      final no = (1000000000 + Random().nextInt(900000000)).toString();
      final ada = await _rekeningIndex.doc(no).get();
      if (!ada.exists) return no;
    }
  }

  String _bulanTahun(DateTime d) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${bulan[d.month - 1]} ${d.year}';
  }

  Future<Map<String, dynamic>> registerWithPin(
    Map<String, dynamic> profile,
    String pin,
  ) async {
    final u = _auth.currentUser;
    if (u == null || u.email != profile['email']) {
      throw RegisterException(
        'Sesi pendaftaran sudah berakhir, silakan daftar ulang.',
      );
    }
    if (!(u.emailVerified)) {
      throw RegisterException('Email belum diverifikasi.');
    }

    try {
      await u.updatePassword(pin);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw RegisterException(
          'Sesi terlalu lama, silakan daftar ulang dari awal.',
        );
      }
      throw RegisterException('Gagal menyimpan PIN (${e.code})');
    }

    final rekening = await _buatRekening();
    final sekarang = DateTime.now();
    final data = <String, dynamic>{
      'namaDepan': profile['namaDepan'],
      'namaBelakang': profile['namaBelakang'],
      'nama': profile['nama'],
      'email': profile['email'],
      'phone': profile['phone'],
      'tglLahir': profile['tanggalLahirMillis'],
      'gender': profile['gender'],
      'alamat': profile['alamat'],
      'kewarganegaraan': profile['kewarganegaraan'],
      'saldo': 0,
      'verificationStatus': 'pending',
      'isVerified': false,
      'rekening': rekening,
      'tipeRekening': 'Savings',
      'cabang': 'KCU Jakarta',
      'memberSince': _bulanTahun(sekarang),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(_userRef(u.uid), data);
    batch.set(_rekeningIndex.doc(rekening), {
      'uid': u.uid,
      'nama': profile['nama'],
    });
    await batch.commit();

    data['id'] = u.uid;
    return data;
  }

  Future<Map<String, dynamic>?> login(String email, String pin) async {
    final emailBersih = email.trim().toLowerCase();
    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: emailBersih,
        password: pin,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') rethrow;
      return null;
    }
    final uid = cred.user!.uid;
    if (AdminService.masterUids.contains(uid)) {
      return {
        'id': uid,
        'nama': 'Admin Master',
        'email': cred.user!.email ?? emailBersih,
        'saldo': 0,
        'isAdmin': true,
      };
    }
    final profile = await getUser(uid);
    if (profile == null) return null;
    final status = (profile['verificationStatus'] ?? 'approved').toString();
    if (status == 'pending')
      throw RegisterException('Akun kamu masih menunggu verifikasi admin.');
    if (status == 'rejected')
      throw RegisterException(
        'Pendaftaran akun belum disetujui. Silakan hubungi admin.',
      );
    return profile;
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _userRef(uid).get();
    final data = snap.data();
    if (data == null) return null;
    data['id'] = snap.id;
    return data;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return getUser(uid);
  }

  Future<void> recordLoginActivity() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await _userRef(u.uid).collection('login_activity').add({
      'email': u.email ?? '',
      'platform': 'Flutter app',
      'createdAt': FieldValue.serverTimestamp(),
      'deviceLabel': 'Perangkat yang digunakan',
    });
  }

  Future<void> logout() => _auth.signOut();

  Future<bool> cekPin(String uid, String pin) async {
    final u = _auth.currentUser;
    if (u == null || u.uid != uid || u.email == null) return false;
    try {
      await u.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: u.email!, password: pin),
      );
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<void> changePin(
    String uid,
    String pinBaru, {
    required String pinLama,
  }) async {
    final benar = await cekPin(uid, pinLama);
    if (!benar) {
      throw FirebaseAuthException(code: 'wrong-pin', message: 'PIN lama salah');
    }
    await _auth.currentUser!.updatePassword(pinBaru);
  }

  Future<bool> hasPIN(String uid) async {
    final data = await getUser(uid);
    return data != null;
  }

  Future<bool> deletePIN(String uid) async {
    final u = _auth.currentUser;
    if (u == null || u.uid != uid) return false;
    try {
      await u.updatePassword(_randomSecretPassword('Terkunci'));
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<void> kirimResetPin(String email) async {
    final emailBersih = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailBersih)) {
      throw RegisterException('Format email tidak valid');
    }
    try {
      await _auth.setLanguageCode('id');
      await _auth.sendPasswordResetEmail(email: emailBersih);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw RegisterException('Format email tidak valid');
      }
      if (e.code == 'user-not-found') {
        throw RegisterException('Email belum terdaftar di sistem.');
      }
      if (e.code == 'too-many-requests') {
        throw RegisterException(
          'Terlalu banyak permintaan. Coba lagi beberapa saat.',
        );
      }
      if (e.code == 'network-request-failed') {
        throw RegisterException('Tidak ada koneksi internet.');
      }
      if (e.code == 'operation-not-allowed') {
        throw RegisterException(
          'Reset password Email belum aktif di Firebase Console.',
        );
      }
      throw RegisterException(
        'Firebase Auth (${e.code}): ${e.message ?? 'gagal mengirim email'}',
      );
    }
  }

  Future<bool> cekKodeReset(String kode) async {
    try {
      await _auth.checkActionCode(kode.trim());
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<void> selesaikanResetPin(String kode, String pinBaru) async {
    try {
      await _auth.confirmPasswordReset(code: kode.trim(), newPassword: pinBaru);
    } on FirebaseAuthException catch (e) {
      throw RegisterException('Gagal menyimpan PIN baru (${e.code})');
    }
  }

  Future<void> simpanFoto(String uid, String fotoBase64) async {
    await _userRef(
      uid,
    ).update({'foto': fotoBase64, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateProfil(String uid, Map<String, dynamic> data) async {
    if (_auth.currentUser?.uid != uid) {
      throw FirebaseAuthException(code: 'unauthenticated');
    }
    final clean = Map<String, dynamic>.from(data)
      ..remove('id')
      ..remove('saldo')
      ..remove('rekening')
      ..remove('email');
    await _userRef(uid)
        .update({...clean, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> changeAccountEmail(String email) async {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Belum login');

    await u.verifyBeforeUpdateEmail(email.trim().toLowerCase());
  }

  Future<void> changeAccountPassword(
    String oldPassword,
    String newPassword,
  ) async {
    final u = _auth.currentUser;
    if (u == null || u.email == null) throw StateError('Belum login');
    await u.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: u.email!, password: oldPassword),
    );
    await u.updatePassword(newPassword);
  }

  Future<String> ambilRekening(Map<String, dynamic> user) async {
    final rekening = user['rekening'];
    if (rekening is String && rekening.isNotEmpty) return rekening;

    final baru = await _buatRekening();
    final batch = _db.batch();
    batch.update(_userRef(user['id']), {'rekening': baru});
    batch.set(_rekeningIndex.doc(baru), {
      'uid': user['id'],
      'nama': user['nama'],
    });
    await batch.commit();
    user['rekening'] = baru;
    return baru;
  }

  Future<Map<String, dynamic>?> findByRekening(String rekening) async {
    final idx = await _rekeningIndex.doc(rekening).get();
    final data = idx.data();
    if (data == null) return null;
    return {'id': data['uid'], 'nama': data['nama'], 'rekening': rekening};
  }

  Future<void> topUpSaldo(String userId, int nominal) async {
    throw RegisterException(
      'Top up langsung dinonaktifkan. Buat permintaan melalui Merchant atau E-Wallet.',
    );
  }

  Future<String?> transfer(
    String dariId,
    String keId,
    int nominal, {
    required String pin,
    required String rekeningTujuan,
  }) async {
    if (nominal <= 0) return 'Nominal tidak valid';
    final benar = await cekPin(dariId, pin);
    if (!benar) return 'PIN salah';
    if (dariId == keId) return 'Tidak bisa transfer ke rekening sendiri';

    try {
      final dariRef = _userRef(dariId);
      final keRef = _userRef(keId);
      final indexRef = _rekeningIndex.doc(rekeningTujuan);
      await _db.runTransaction((trx) async {
        final dari = await trx.get(dariRef);
        final index = await trx.get(indexRef);
        if (!dari.exists || !index.exists) {
          throw RegisterException('Akun atau rekening tujuan tidak ditemukan');
        }
        final indexData = index.data()!;
        if (indexData['uid'] != keId) {
          throw RegisterException('Data rekening tujuan tidak sesuai');
        }
        final saldoDari = ((dari.data()!['saldo'] as num?) ?? 0).toInt();
        if (saldoDari < nominal) throw RegisterException('Saldo tidak cukup');

        final namaPenerima = (indexData['nama'] ?? '-') as String;
        final namaPengirim = (dari.data()!['nama'] ?? '-') as String;
        final rekeningPengirim = (dari.data()!['rekening'] ?? '-') as String;
        final sekarang = DateTime.now();
        final trxId = dariRef.collection('mutasi').doc().id;

        trx.update(dariRef, {'saldo': saldoDari - nominal});

        trx.update(keRef, {'saldo': FieldValue.increment(nominal)});
        trx.set(dariRef.collection('mutasi').doc(trxId), {
          'idTransaksi': trxId,
          'tanggal': Timestamp.fromDate(sekarang),
          'tipe': 'debit',
          'nominal': nominal,
          'nama': namaPenerima,
          'berita': 'Transfer',
          'status': 'Berhasil',
          'jenis': 'Transfer',
          'rekeningLawan': rekeningTujuan,
        });
        trx.set(keRef.collection('mutasi').doc(trxId), {
          'idTransaksi': trxId,
          'tanggal': Timestamp.fromDate(sekarang),
          'tipe': 'kredit',
          'nominal': nominal,
          'nama': namaPengirim,
          'berita': 'Transfer',
          'status': 'Berhasil',
          'jenis': 'Transfer',
          'rekeningLawan': rekeningPengirim,
        });
      });
      await _sendTransferNotifications(dariId, keId, nominal, rekeningTujuan);
      return null;
    } on RegisterException catch (e) {
      return e.pesan;
    } on FirebaseException catch (e) {
      return 'Firestore ${e.code}: ${e.message ?? 'transaksi ditolak'}';
    } catch (e) {
      return 'Transaksi gagal: $e';
    }
  }

  String _rupiah(int nilai) {
    final angka = nilai.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp$angka';
  }

  Future<void> _sendTransferNotifications(
    String fromUid,
    String toUid,
    int amount,
    String targetAccount,
  ) async {
    try {
      final from = await getUser(fromUid);
      final index = await _rekeningIndex.doc(targetAccount).get();
      final recipientName = (index.data()?['nama'] ?? 'Pengguna MyBCA')
          .toString();
      final senderName = (from?['nama'] ?? 'Pengguna MyBCA').toString();
      final notif = NotificationService();
      await notif.kirim(
        userId: fromUid,
        title: 'Transfer Berhasil',
        message: 'Transfer ${_rupiah(amount)} ke $recipientName berhasil.',
        type: NotificationType.transaksi,
      );
      await notif.kirim(
        userId: toUid,
        title: 'Uang Masuk',
        message: 'Kamu menerima ${_rupiah(amount)} dari $senderName.',
        type: NotificationType.transaksi,
      );
    } catch (e) {
      debugPrint('Gagal membuat notifikasi transaksi: $e');
    }
  }

  Future<Map<String, dynamic>> bayar(
    String dariId,
    String keId,
    int nominal, {
    required String pin,
    required String rekeningTujuan,
    String berita = '',
    String jenis = 'Pembayaran',
  }) async {
    if (nominal <= 0) throw RegisterException('Nominal tidak valid');
    final benar = await cekPin(dariId, pin);
    if (!benar) throw RegisterException('PIN salah');
    if (dariId == keId)
      throw RegisterException('Tidak bisa membayar ke rekening sendiri');

    late String trxId;
    late String namaPenerima;
    final dariRef = _userRef(dariId);
    final keRef = _userRef(keId);
    final indexRef = _rekeningIndex.doc(rekeningTujuan);

    await _db.runTransaction((trx) async {
      final dari = await trx.get(dariRef);
      final index = await trx.get(indexRef);
      if (!dari.exists || !index.exists) {
        throw RegisterException('Akun atau rekening tujuan tidak ditemukan');
      }
      final indexData = index.data()!;
      if (indexData['uid'] != keId) {
        throw RegisterException('Data rekening tujuan tidak sesuai');
      }
      final saldoDari = ((dari.data()!['saldo'] as num?) ?? 0).toInt();
      if (saldoDari < nominal) throw RegisterException('Saldo tidak cukup');

      namaPenerima = (indexData['nama'] ?? '-') as String;
      final namaPengirim = (dari.data()!['nama'] ?? '-') as String;
      final rekeningPengirim = (dari.data()!['rekening'] ?? '-') as String;
      final sekarang = DateTime.now();
      trxId = dariRef.collection('mutasi').doc().id;

      trx.update(dariRef, {'saldo': saldoDari - nominal});
      trx.update(keRef, {'saldo': FieldValue.increment(nominal)});
      trx.set(dariRef.collection('mutasi').doc(trxId), {
        'idTransaksi': trxId,
        'tanggal': Timestamp.fromDate(sekarang),
        'tipe': 'debit',
        'nominal': nominal,
        'nama': namaPenerima,
        'berita': berita,
        'status': 'Berhasil',
        'jenis': jenis,
        'rekeningLawan': rekeningTujuan,
      });
      trx.set(keRef.collection('mutasi').doc(trxId), {
        'idTransaksi': trxId,
        'tanggal': Timestamp.fromDate(sekarang),
        'tipe': 'kredit',
        'nominal': nominal,
        'nama': namaPengirim,
        'berita': berita,
        'status': 'Berhasil',
        'jenis': jenis,
        'rekeningLawan': rekeningPengirim,
      });
    });

    await _sendTransferNotifications(dariId, keId, nominal, rekeningTujuan);
    return {'id': trxId, 'nama': namaPenerima, 'rekeningLawan': rekeningTujuan};
  }

  Future<String?> _potongSaldo(
    String uid,
    int nominal, {
    required String pin,
    required String jenis,
    required String berita,
    String rekeningLawan = '-',
  }) async {
    final benar = await cekPin(uid, pin);
    if (!benar) return 'PIN salah';
    if (nominal <= 0) return 'Nominal tidak valid';

    try {
      await _db.runTransaction((trx) async {
        final ref = _userRef(uid);
        final snap = await trx.get(ref);
        if (!snap.exists) throw RegisterException('Akun tidak ditemukan');

        final saldo = ((snap.data()!['saldo'] as num?) ?? 0).toInt();
        if (saldo < nominal) throw RegisterException('Saldo tidak cukup');

        final sekarang = DateTime.now();
        final trxId = ref.collection('mutasi').doc().id;

        trx.update(ref, {'saldo': saldo - nominal});
        trx.set(ref.collection('mutasi').doc(trxId), {
          'idTransaksi': trxId,
          'tanggal': Timestamp.fromDate(sekarang),
          'tipe': 'debit',
          'nominal': nominal,
          'nama': jenis,
          'berita': berita,
          'status': 'Berhasil',
          'jenis': jenis,
          'rekeningLawan': rekeningLawan,
        });
      });
      unawaited(() async {
        try {
          await NotificationService().kirim(
            userId: uid,
            title: jenis == 'Tarik Tunai'
                ? 'Tarik Tunai Berhasil'
                : 'Pembelian Berhasil',
            message: '$berita • ${_rupiah(nominal)} berhasil diproses.',
            type: NotificationType.transaksi,
          );
        } catch (_) {}
      }());
      return null;
    } on RegisterException catch (e) {
      return e.pesan;
    } catch (e) {
      return 'Transaksi gagal, coba lagi';
    }
  }

  Future<String?> tarikTunai(
    String uid,
    int nominal, {
    required String pin,
    required String metode,
  }) {
    return _potongSaldo(
      uid,
      nominal,
      pin: pin,
      jenis: 'Tarik Tunai',
      berita: 'Tarik tunai via $metode',
    );
  }

  Future<String?> belanjaProduk(
    String uid,
    int nominal, {
    required String pin,
    required String namaProduk,
    required String tujuan,
  }) {
    return _potongSaldo(
      uid,
      nominal,
      pin: pin,
      jenis: 'Pembelian',
      berita: '$namaProduk • $tujuan',
    );
  }
}
