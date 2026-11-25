/// Satu catatan transaksi milik satu user.
/// Dart murni (tanpa Firebase), jadi bisa dipakai dengan database apa pun.
class RiwayatTransaksi {
  const RiwayatTransaksi({
    required this.id,
    required this.tanggal,
    required this.tipe,
    required this.nominal,
    required this.nama,
    required this.berita,
    required this.status,
    required this.jenis,
    required this.rekeningLawan,
  });

  /// ID transaksi. Sama di sisi pengirim dan sisi penerima.
  final String id;
  final DateTime tanggal;

  /// 'debit' (uang keluar) atau 'kredit' (uang masuk).
  final String tipe;
  final int nominal;

  /// Nama lawan transaksi (penerima kalau debit, pengirim kalau kredit).
  final String nama;
  final String berita;

  /// 'Berhasil', 'Pending', atau 'Gagal'.
  final String status;

  /// Contoh: 'Pembayaran', 'Transfer QRIS'.
  final String jenis;
  final String rekeningLawan;

  bool get masuk => tipe == 'kredit';
  bool get berhasil => status == 'Berhasil';
  bool get gagal => status == 'Gagal';

  /// Label status yang dilihat user: uang sudah terkirim atau diterima.
  String get labelStatus {
    if (gagal) return 'Gagal';
    if (!berhasil) return 'Diproses';
    return masuk ? 'Diterima' : 'Terkirim';
  }
}

/// 1500000 -> 'Rp 1.500.000'
String rupiahTeks(int angka) {
  final teks = angka.abs().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );
  return 'Rp $teks';
}

/// '25 Nov 2026, 16:55'
String tanggalTeks(DateTime d) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final jam = d.hour.toString().padLeft(2, '0');
  final menit = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year}, $jam:$menit';
}
