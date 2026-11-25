import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu transaksi mutasi.
/// Path Firestore: users/{userId}/mutasi/{id}
class MutasiTransaction {
  final String id; // id dokumen
  final String idTransaksi; // contoh: TRX17956000001
  final DateTime tanggal;
  final String tipe; // 'kredit' (uang masuk) atau 'debit' (uang keluar)
  final int nominal;
  final String nama; // pengirim / penerima
  final String berita;
  final String status; // 'Berhasil', 'Pending', 'Gagal'

  const MutasiTransaction({
    required this.id,
    required this.idTransaksi,
    required this.tanggal,
    required this.tipe,
    required this.nominal,
    required this.nama,
    required this.berita,
    required this.status,
  });

  bool get isKredit => tipe == 'kredit';

  factory MutasiTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MutasiTransaction(
      id: doc.id,
      idTransaksi: (d['idTransaksi'] ?? doc.id) as String,
      tanggal: (d['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipe: (d['tipe'] ?? 'debit') as String,
      nominal: (d['nominal'] as num?)?.toInt() ?? 0,
      nama: (d['nama'] ?? '-') as String,
      berita: (d['berita'] ?? '') as String,
      status: (d['status'] ?? 'Berhasil') as String,
    );
  }
}

/// Informasi rekening milik user (diambil dari dokumen users/{userId}).
class MutasiProfile {
  final String nama;
  final String noRekening;
  final int saldo;

  const MutasiProfile({
    required this.nama,
    required this.noRekening,
    required this.saldo,
  });

  factory MutasiProfile.fromMap(Map<String, dynamic>? d) {
    d ??= {};
    return MutasiProfile(
      nama: (d['nama'] ?? '-') as String,
      noRekening: (d['noRekening'] ?? '-') as String,
      saldo: (d['saldo'] as num?)?.toInt() ?? 0,
    );
  }
}
