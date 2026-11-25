import 'package:cloud_firestore/cloud_firestore.dart';

import 'mutasi_model.dart';

/// Semua operasi Firestore untuk halaman Mutasi.
class MutasiService {
  MutasiService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _db.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _user(userId).collection('mutasi');

  Future<MutasiProfile> fetchProfile(String userId) async {
    final snap = await _user(userId).get();
    return MutasiProfile.fromMap(snap.data());
  }

  /// Terbaru di atas. Filter tanggal/jenis/pencarian dilakukan di aplikasi
  /// sehingga tidak butuh composite index di Firestore.
  Future<List<MutasiTransaction>> fetchTransactions(String userId) async {
    final snap = await _col(userId).orderBy('tanggal', descending: true).get();
    return snap.docs.map(MutasiTransaction.fromDoc).toList();
  }

  /// Mengisi data contoh supaya halaman bisa langsung dicoba.
  /// Tidak mengubah saldo, hanya menambah riwayat.
  Future<void> seedDummy(String userId) async {
    final now = DateTime.now();
    final base = now.millisecondsSinceEpoch;

    // (tipe, nama, berita, nominal, hariLalu, jam, status)
    final data = <(String, String, String, int, int, int, String)>[
      ('kredit', 'Budi Santoso', 'Pembayaran proyek', 1500000, 0, 9, 'Berhasil'),
      ('debit', 'Siti Aminah', 'Bayar kos bulan November', 800000, 1, 14, 'Berhasil'),
      ('debit', 'Warung Makan Sederhana', 'Makan siang', 45000, 2, 12, 'Berhasil'),
      ('kredit', 'PT Maju Jaya', 'Gaji November', 5000000, 4, 8, 'Berhasil'),
      ('debit', 'PLN Prabayar', 'Token listrik', 200000, 6, 19, 'Berhasil'),
      ('debit', 'Toko Online ABC', 'Belanja online', 350000, 9, 21, 'Pending'),
      ('kredit', 'Andi Wijaya', 'Patungan makan', 120000, 12, 20, 'Berhasil'),
      ('debit', 'Pulsa Telkomsel', 'Isi pulsa', 100000, 15, 10, 'Gagal'),
      ('debit', 'Rina Marlina', 'Transfer pinjaman', 500000, 20, 16, 'Berhasil'),
      ('kredit', 'Cashback BCA', 'Cashback transaksi', 25000, 25, 11, 'Berhasil'),
    ];

    final batch = _db.batch();
    for (var i = 0; i < data.length; i++) {
      final t = data[i];
      final day = now.subtract(Duration(days: t.$5));
      final date = DateTime(day.year, day.month, day.day, t.$6, (i * 7) % 60);
      batch.set(_col(userId).doc(), {
        'idTransaksi': 'TRX${base + i}',
        'tanggal': Timestamp.fromDate(date),
        'tipe': t.$1,
        'nama': t.$2,
        'berita': t.$3,
        'nominal': t.$4,
        'status': t.$7,
      });
    }
    await batch.commit();
  }
}
