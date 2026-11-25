import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class RegisterException implements Exception {
  RegisterException(this.pesan);
  final String pesan;
}

class UserService {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );

  String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> seedUsers() async {
    final cek = await users.limit(1).get();
    if (cek.docs.isNotEmpty) return;

    final dataContoh = [
      {
        'id': 'budi',
        'nama': 'Budi Santoso',
        'email': 'budi@digeboy.com',
        'phone': '081234567890',
        'pin': '123456',
        'saldo': 15000000,
      },
      {
        'id': 'siti',
        'nama': 'Siti Aminah',
        'email': 'siti@digeboy.com',
        'phone': '081298765432',
        'pin': '654321',
        'saldo': 8500000,
      },
      {
        'id': 'andi',
        'nama': 'Andi Pratama',
        'email': 'andi@digeboy.com',
        'phone': '085711112222',
        'pin': '246810',
        'saldo': 2250000,
      },
    ];

    for (final u in dataContoh) {
      await users.doc(u['id'] as String).set({
        'nama': u['nama'],
        'email': u['email'],
        'phone': u['phone'],
        'pin': hashPin(u['pin'] as String),
        'saldo': u['saldo'],
      });
    }
  }

  Future<Map<String, dynamic>?> findUser(String input) async {
    input = input.trim().toLowerCase().replaceAll(' ', '');
    final field = input.contains('@') ? 'email' : 'phone';

    final hasil = await users.where(field, isEqualTo: input).limit(1).get();
    if (hasil.docs.isEmpty) return null;

    final doc = hasil.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<Map<String, dynamic>?> login(String input, String pin) async {
    final user = await findUser(input);
    if (user == null) return null;
    if (user['pin'] != hashPin(pin)) return null;
    return user;
  }

  Future<String> createResetCode(String userId) async {
    final kode = (100000 + Random().nextInt(900000)).toString();
    final batas = DateTime.now().add(const Duration(minutes: 5));

    await users.doc(userId).update({
      'resetCode': kode,
      'resetExpired': batas.millisecondsSinceEpoch,
    });
    return kode;
  }

  Future<bool> checkResetCode(String userId, String kode) async {
    final doc = await users.doc(userId).get();
    final data = doc.data() as Map<String, dynamic>;

    final kodeAsli = data['resetCode'];
    final batas = data['resetExpired'] ?? 0;

    if (kodeAsli == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > batas) return false;
    return kodeAsli == kode;
  }

  Future<void> changePin(String userId, String pinBaru) async {
    await users.doc(userId).update({
      'pin': hashPin(pinBaru),
      'resetCode': FieldValue.delete(),
      'resetExpired': FieldValue.delete(),
    });
  }

  Future<void> simpanFoto(String userId, String fotoBase64) async {
    await users.doc(userId).update({'foto': fotoBase64});
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    final doc = await users.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<Map<String, dynamic>?> findByRekening(String rekening) async {
    final hasil = await users
        .where('rekening', isEqualTo: rekening)
        .limit(1)
        .get();
    if (hasil.docs.isEmpty) return null;
    final doc = hasil.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<String> ambilRekening(Map<String, dynamic> user) async {
    final ada = user['rekening'];
    if (ada != null) return ada as String;

    final baru = (1000000000 + Random().nextInt(900000000)).toString();
    await users.doc(user['id']).update({'rekening': baru});
    user['rekening'] = baru;
    return baru;
  }

  Future<String?> transfer(String dariId, String keId, int nominal) {
    return FirebaseFirestore.instance.runTransaction<String?>((trx) async {
      if (nominal <= 0) return 'Nominal harus lebih dari 0';
      if (dariId == keId) return 'Tidak bisa transfer ke rekening sendiri';

      final dariRef = users.doc(dariId);
      final keRef = users.doc(keId);

      final dari = await trx.get(dariRef);
      final ke = await trx.get(keRef);
      if (!dari.exists || !ke.exists) return 'Rekening tidak ditemukan';

      final dataDari = dari.data() as Map<String, dynamic>;
      final dataKe = ke.data() as Map<String, dynamic>;
      final saldoDari = (dataDari['saldo'] as num?)?.toInt() ?? 0;
      final saldoKe = (dataKe['saldo'] as num?)?.toInt() ?? 0;

      if (saldoDari < nominal) return 'Saldo tidak cukup';

      final mutasiDari = dariRef.collection('mutasi').doc();
      final idTransaksi = 'TRX${mutasiDari.id}';
      final mutasiKe = keRef.collection('mutasi').doc(idTransaksi);
      final notifikasiDari = dariRef.collection('notifications').doc();
      final notifikasiKe = keRef.collection('notifications').doc();
      final tanggal = FieldValue.serverTimestamp();

      trx.update(dariRef, {'saldo': saldoDari - nominal});
      trx.update(keRef, {'saldo': saldoKe + nominal});
      trx.set(mutasiDari, {
        'idTransaksi': idTransaksi,
        'tanggal': tanggal,
        'tipe': 'debit',
        'nominal': nominal,
        'nama': dataKe['nama'] ?? '-',
        'berita': 'Transfer QRIS',
        'status': 'Berhasil',
        'jenis': 'Transfer QRIS',
        'rekeningLawan': dataKe['rekening'] ?? '-',
      });
      trx.set(mutasiKe, {
        'idTransaksi': idTransaksi,
        'tanggal': tanggal,
        'tipe': 'kredit',
        'nominal': nominal,
        'nama': dataDari['nama'] ?? '-',
        'berita': 'Transfer QRIS',
        'status': 'Berhasil',
        'jenis': 'Transfer QRIS',
        'rekeningLawan': dataDari['rekening'] ?? '-',
      });
      trx.set(notifikasiDari, {
        'title': 'Transfer Berhasil',
        'message':
            'Transfer Rp$nominal ke ${dataKe['nama'] ?? 'penerima'} berhasil.',
        'type': 'transaksi',
        'isRead': false,
        'tanggal': tanggal,
      });
      trx.set(notifikasiKe, {
        'title': 'Dana Diterima',
        'message':
            'Anda menerima transfer Rp$nominal dari ${dataDari['nama'] ?? 'pengirim'}.',
        'type': 'transaksi',
        'isRead': false,
        'tanggal': tanggal,
      });
      return null;
    });
  }

  Future<bool> cekPin(String userId, String pin) async {
    final doc = await users.doc(userId).get();
    final data = doc.data() as Map<String, dynamic>;
    return data['pin'] == hashPin(pin);
  }

  Future<void> updateProfil(String userId, Map<String, dynamic> data) async {
    await users.doc(userId).update(data);
  }

  static String normalisasiPhone(String input) {
    var p = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (p.startsWith('+62')) {
      p = '0${p.substring(3)}';
    } else if (p.startsWith('62')) {
      p = '0${p.substring(2)}';
    }
    return p;
  }

  Future<String> _buatUserId() async {
    while (true) {
      final id = 'DGB${1000000 + Random().nextInt(9000000)}';
      final ada = await users.doc(id).get();
      if (!ada.exists) return id;
    }
  }

  Future<String> _buatRekening() async {
    while (true) {
      final no = (1000000000 + Random().nextInt(900000000)).toString();
      final ada = await users.where('rekening', isEqualTo: no).limit(1).get();
      if (ada.docs.isEmpty) return no;
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

    final cekEmail = await users
        .where('email', isEqualTo: emailBersih)
        .limit(1)
        .get();
    if (cekEmail.docs.isNotEmpty) {
      throw RegisterException('Email sudah terdaftar');
    }
    final cekPhone = await users
        .where('phone', isEqualTo: phoneBersih)
        .limit(1)
        .get();
    if (cekPhone.docs.isNotEmpty) {
      throw RegisterException('Nomor HP sudah terdaftar');
    }

    final id = await _buatUserId();
    final rekening = await _buatRekening();
    final sekarang = DateTime.now();
    final depan = namaDepan.trim();
    final belakang = namaBelakang.trim();

    final data = <String, dynamic>{
      'namaDepan': depan,
      'namaBelakang': belakang,
      'nama': '$depan $belakang',
      'email': emailBersih,
      'phone': phoneBersih,
      'tanggalLahir': Timestamp.fromDate(tanggalLahir),
      'gender': gender,
      'alamat': alamat.trim(),
      'kewarganegaraan': kewarganegaraan.trim(),
      'saldo': 0,
      'rekening': rekening,
      'tipeRekening': 'Savings',
      'cabang': 'KCU Jakarta',
      'memberSince': _bulanTahun(sekarang),
      'accountStatus': 'pending_verification',
      'isVerified': false,
      'registrationCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Tidak menyimpan password/PIN di Firestore.
    await users.doc(id).set(data);
    data['id'] = id;
    return data;
  }
}
