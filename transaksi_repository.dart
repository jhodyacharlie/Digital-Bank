import 'akun.dart';
import 'riwayat_transaksi.dart';

/// Hasil satu pembayaran.
/// - berhasil: error == null dan struk berisi catatan pengirim.
/// - ditolak (misal saldo kurang): error terisi dan struk berisi catatan
///   berstatus 'Gagal' yang juga tersimpan di riwayat pengirim.
/// - gagal karena koneksi: error terisi dan struk null (tidak ada yang tersimpan).
class HasilBayar {
  const HasilBayar.berhasil(this.struk) : error = null;
  const HasilBayar.gagal(this.error, {this.struk});

  final String? error;
  final RiwayatTransaksi? struk;

  bool get berhasil => error == null;
}

/// Satu-satunya pintu ke data. Semua layar hanya bicara ke kelas ini,
/// jadi menyambungkan ke database cukup dengan membuat satu implementasi baru
/// (lihat connect/firestore_transaksi_repository.dart.example).
abstract class TransaksiRepository {
  /// Data rekening yang berubah sendiri (saldo ikut berubah saat uang masuk).
  Stream<Akun> pantauAkun(String userId);

  /// Cari pemilik rekening. Null kalau tidak ada.
  Future<Akun?> cariByRekening(String rekening);

  Future<bool> cekPin(String userId, String pin);

  /// Memindahkan saldo dan mencatat transaksi di kedua sisi sebagai satu
  /// kesatuan: saldo dan riwayat tidak boleh tidak sinkron.
  /// Tidak boleh melempar error; kegagalan dikembalikan lewat HasilBayar.
  Future<HasilBayar> bayar({
    required String dariId,
    required String keId,
    required int nominal,
    String berita = '',
    String jenis = 'Pembayaran',
  });

  /// Riwayat realtime, terbaru di atas.
  Stream<List<RiwayatTransaksi>> pantau(String userId, {int batas = 100});
}
