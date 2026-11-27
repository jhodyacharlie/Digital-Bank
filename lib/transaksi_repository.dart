import 'akun.dart';
import 'riwayat_transaksi.dart';

class HasilBayar {
  const HasilBayar.berhasil(this.struk) : error = null;
  const HasilBayar.gagal(this.error, {this.struk});

  final String? error;
  final RiwayatTransaksi? struk;

  bool get berhasil => error == null;
}

abstract class TransaksiRepository {
  Stream<Akun> pantauAkun(String userId);

  Future<Akun?> cariByRekening(String rekening);

  Future<bool> cekPin(String userId, String pin);

  Future<HasilBayar> bayar({
    required String dariId,
    required String keId,
    required int nominal,
    required String pin,
    required String rekeningTujuan,
    String berita = '',
    String jenis = 'Pembayaran',
  });

  Stream<List<RiwayatTransaksi>> pantau(String userId, {int batas = 100});
}
