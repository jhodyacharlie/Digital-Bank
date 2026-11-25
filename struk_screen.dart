import 'package:flutter/material.dart';

import 'app_style.dart';
import 'riwayat_transaksi.dart';

/// Warna dan ikon untuk satu status transaksi.
class _GayaStatus {
  const _GayaStatus(this.warna, this.latar, this.ikon);

  final Color warna;
  final Color latar;
  final IconData ikon;

  static _GayaStatus dari(RiwayatTransaksi t) {
    if (t.gagal) {
      return _GayaStatus(
        Colors.red.shade700,
        Colors.red.shade50,
        Icons.cancel_outlined,
      );
    }
    if (!t.berhasil) {
      return _GayaStatus(
        Colors.orange.shade800,
        Colors.orange.shade50,
        Icons.hourglass_top,
      );
    }
    return _GayaStatus(
      Colors.green.shade700,
      Colors.green.shade50,
      t.masuk ? Icons.south_west : Icons.north_east,
    );
  }
}

/// Label kecil berwarna: Terkirim / Diterima / Diproses / Gagal.
class LencanaStatus extends StatelessWidget {
  const LencanaStatus({super.key, required this.transaksi});

  final RiwayatTransaksi transaksi;

  @override
  Widget build(BuildContext context) {
    final gaya = _GayaStatus.dari(transaksi);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gaya.latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        transaksi.labelStatus,
        style: TextStyle(
          color: gaya.warna,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Bukti transaksi. Dipakai setelah pembayaran dan saat membuka satu
/// transaksi dari daftar status.
class StrukScreen extends StatelessWidget {
  const StrukScreen({super.key, required this.struk, this.alasan});

  final RiwayatTransaksi struk;

  /// Alasan kalau transaksi gagal, misal 'Saldo tidak cukup'.
  final String? alasan;

  String get judul {
    if (struk.gagal) return 'Transaksi gagal';
    if (!struk.berhasil) return 'Transaksi diproses';
    return struk.masuk ? 'Uang diterima' : 'Uang terkirim';
  }

  Widget baris(String label, String isi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: AppColors.abu)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              isi,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.biruTua,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gaya = _GayaStatus.dari(struk);

    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Bukti Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: gaya.latar,
                    child: Icon(gaya.ikon, color: gaya.warna, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    judul,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: gaya.warna,
                    ),
                  ),
                  if (alasan != null) ...[
                    const SizedBox(height: 4),
                    Text(alasan!, style: const TextStyle(color: AppColors.abu)),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    rupiahTeks(struk.nominal),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.biruTua,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  baris('Status', struk.labelStatus),
                  baris(struk.masuk ? 'Dari' : 'Ke', struk.nama),
                  baris('No. Rekening', struk.rekeningLawan),
                  baris('Jenis', struk.jenis),
                  baris('Tanggal', tanggalTeks(struk.tanggal)),
                  baris('ID Transaksi', struk.id),
                  if (struk.berita.isNotEmpty) baris('Catatan', struk.berita),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TombolBiru(
              teks: 'Selesai',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
