import 'package:cloud_firestore/cloud_firestore.dart';

import 'akun.dart';
import 'riwayat_transaksi.dart';
import 'transaksi_repository.dart';
import 'user_service.dart';

class FirestoreTransaksiRepository implements TransaksiRepository {
  FirestoreTransaksiRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String id) =>
      _db.collection('users').doc(id);

  CollectionReference<Map<String, dynamic>> _mutasi(String id) =>
      _user(id).collection('mutasi');

  Akun _akunDari(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Akun(
      id: doc.id,
      nama: (d['nama'] ?? '-') as String,
      rekening: (d['rekening'] ?? '-') as String,
      saldo: (d['saldo'] as num?)?.toInt() ?? 0,
    );
  }

  RiwayatTransaksi _dariDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RiwayatTransaksi(
      id: (d['idTransaksi'] ?? doc.id) as String,
      tanggal: (d['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipe: (d['tipe'] ?? 'debit') as String,
      nominal: (d['nominal'] as num?)?.toInt() ?? 0,
      nama: (d['nama'] ?? '-') as String,
      berita: (d['berita'] ?? '') as String,
      status: (d['status'] ?? 'Berhasil') as String,
      jenis: (d['jenis'] ?? 'Transfer') as String,
      rekeningLawan: (d['rekeningLawan'] ?? '-') as String,
    );
  }

  @override
  Stream<Akun> pantauAkun(String userId) {
    return _user(userId).snapshots().map(_akunDari);
  }

  @override
  Future<Akun?> cariByRekening(String rekening) async {
    final hasil = await UserService().findByRekening(rekening);
    if (hasil == null) return null;
    return Akun(
      id: hasil['id'],
      nama: hasil['nama'] ?? '-',
      rekening: hasil['rekening'] ?? '-',
      saldo: 0,
    );
  }

  @override
  Future<bool> cekPin(String userId, String pin) async {
    return UserService().cekPin(userId, pin);
  }

  @override
  Future<HasilBayar> bayar({
    required String dariId,
    required String keId,
    required int nominal,
    required String pin,
    required String rekeningTujuan,
    String berita = '',
    String jenis = 'Pembayaran',
  }) async {
    try {
      final result = await UserService().bayar(
        dariId,
        keId,
        nominal,
        pin: pin,
        rekeningTujuan: rekeningTujuan,
        berita: berita,
        jenis: jenis,
      );
      final struk = RiwayatTransaksi(
        id: result['id'] as String,
        tanggal: DateTime.now(),
        tipe: 'debit',
        nominal: nominal,
        nama: (result['nama'] ?? '-') as String,
        berita: berita,
        status: 'Berhasil',
        jenis: jenis,
        rekeningLawan: (result['rekeningLawan'] ?? '-') as String,
      );
      return HasilBayar.berhasil(struk);
    } catch (e) {
      return HasilBayar.gagal(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Stream<List<RiwayatTransaksi>> pantau(String userId, {int batas = 100}) {
    return _mutasi(userId)
        .orderBy('tanggal', descending: true)
        .limit(batas)
        .snapshots()
        .map((snap) => snap.docs.map(_dariDoc).toList());
  }
}
