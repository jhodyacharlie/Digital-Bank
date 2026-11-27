import 'dart:async';

import 'akun.dart';
import 'riwayat_transaksi.dart';
import 'transaksi_repository.dart';

class _DataAkun {
  _DataAkun(this.id, this.nama, this.rekening, this.pin, this.saldo);

  final String id;
  final String nama;
  final String rekening;
  final String pin;
  int saldo;

  Akun toAkun() => Akun(id: id, nama: nama, rekening: rekening, saldo: saldo);
}

class MemoryTransaksiRepository implements TransaksiRepository {
  MemoryTransaksiRepository() {
    for (final a in [
      _DataAkun('budi', 'Budi Santoso', '1000000001', '123456', 15000000),
      _DataAkun('siti', 'Siti Aminah', '1000000002', '654321', 8500000),
      _DataAkun('andi', 'Andi Pratama', '1000000003', '246810', 2250000),
    ]) {
      _akun[a.id] = a;
    }
  }

  final Map<String, _DataAkun> _akun = {};
  final Map<String, List<RiwayatTransaksi>> _riwayat = {};
  final StreamController<void> _berubah = StreamController<void>.broadcast();
  int _urut = 0;

  List<Akun> get daftarAkun => _akun.values.map((a) => a.toAkun()).toList();

  Stream<T> _pantauPerubahan<T>(T Function() ambil) {
    late StreamController<T> pengendali;
    StreamSubscription<void>? langganan;
    pengendali = StreamController<T>(
      onListen: () {
        pengendali.add(ambil());
        langganan = _berubah.stream.listen((_) => pengendali.add(ambil()));
      },
      onCancel: () => langganan?.cancel(),
    );
    return pengendali.stream;
  }

  void _catat(String userId, RiwayatTransaksi t) {
    _riwayat.putIfAbsent(userId, () => []).insert(0, t);
  }

  @override
  Stream<Akun> pantauAkun(String userId) {
    return _pantauPerubahan(() => _akun[userId]!.toAkun());
  }

  @override
  Future<Akun?> cariByRekening(String rekening) async {
    for (final a in _akun.values) {
      if (a.rekening == rekening) return a.toAkun();
    }
    return null;
  }

  @override
  Future<bool> cekPin(String userId, String pin) async {
    return _akun[userId]?.pin == pin;
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
    if (nominal <= 0) {
      return const HasilBayar.gagal('Nominal harus lebih dari 0');
    }
    if (dariId == keId) {
      return const HasilBayar.gagal('Tidak bisa membayar ke rekening sendiri');
    }
    final dari = _akun[dariId];
    final ke = _akun[keId];
    if (dari == null || ke == null) {
      return const HasilBayar.gagal('Rekening tidak ditemukan');
    }

    final id = 'TRX${DateTime.now().millisecondsSinceEpoch}${_urut++}';
    final tanggal = DateTime.now();

    RiwayatTransaksi sisiPengirim(String status) => RiwayatTransaksi(
      id: id,
      tanggal: tanggal,
      tipe: 'debit',
      nominal: nominal,
      nama: ke.nama,
      berita: berita,
      status: status,
      jenis: jenis,
      rekeningLawan: ke.rekening,
    );

    if (dari.saldo < nominal) {
      final gagal = sisiPengirim('Gagal');
      _catat(dariId, gagal);
      _berubah.add(null);
      return HasilBayar.gagal('Saldo tidak cukup', struk: gagal);
    }

    dari.saldo -= nominal;
    ke.saldo += nominal;

    final struk = sisiPengirim('Berhasil');
    _catat(dariId, struk);
    _catat(
      keId,
      RiwayatTransaksi(
        id: id,
        tanggal: tanggal,
        tipe: 'kredit',
        nominal: nominal,
        nama: dari.nama,
        berita: berita,
        status: 'Berhasil',
        jenis: jenis,
        rekeningLawan: dari.rekening,
      ),
    );
    _berubah.add(null);
    return HasilBayar.berhasil(struk);
  }

  @override
  Stream<List<RiwayatTransaksi>> pantau(String userId, {int batas = 100}) {
    return _pantauPerubahan(
      () =>
          (_riwayat[userId] ?? const <RiwayatTransaksi>[]).take(batas).toList(),
    );
  }
}
