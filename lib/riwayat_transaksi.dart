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

  final String id;
  final DateTime tanggal;

  final String tipe;
  final int nominal;

  final String nama;
  final String berita;

  final String status;

  final String jenis;
  final String rekeningLawan;

  bool get masuk => tipe == 'kredit';
  bool get berhasil => status == 'Berhasil';
  bool get gagal => status == 'Gagal';

  String get labelStatus {
    if (gagal) return 'Gagal';
    if (!berhasil) return 'Diproses';
    return masuk ? 'Diterima' : 'Terkirim';
  }
}

String rupiahTeks(int angka) {
  final teks = angka.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return 'Rp $teks';
}

String tanggalTeks(DateTime d) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final jam = d.hour.toString().padLeft(2, '0');
  final menit = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year}, $jam:$menit';
}
