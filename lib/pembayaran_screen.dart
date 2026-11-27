import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'akun.dart';
import 'app_style.dart';
import 'pin_konfirmasi_screen.dart';
import 'riwayat_transaksi.dart';
import 'struk_screen.dart';
import 'transaksi_repository.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key, required this.repo, required this.akun});

  final TransaksiRepository repo;

  final Akun akun;

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final TextEditingController rekeningController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    rekeningController.dispose();
    nominalController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<bool> konfirmasi(Akun penerima, int nominal, String catatan) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penerima: ${penerima.nama}'),
            Text('Rekening: ${penerima.rekening}'),
            Text('Nominal: ${rupiahTeks(nominal)}'),
            if (catatan.isNotEmpty) Text('Catatan: $catatan'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    return setuju == true;
  }

  Future<void> bayar() async {
    final rekening = rekeningController.text.trim();
    final nominal = int.tryParse(nominalController.text.trim()) ?? 0;
    final catatan = catatanController.text.trim();

    if (rekening.isEmpty) {
      pesan('Isi nomor rekening tujuan dulu');
      return;
    }
    if (nominal <= 0) {
      pesan('Isi nominal pembayaran dulu');
      return;
    }

    setState(() => loading = true);
    Akun? penerima;
    try {
      penerima = await widget.repo.cariByRekening(rekening);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      pesan('Gagal terhubung ke server');
      return;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (penerima == null) {
      pesan('Rekening tidak ditemukan');
      return;
    }
    if (penerima.id == widget.akun.id) {
      pesan('Tidak bisa membayar ke rekening sendiri');
      return;
    }

    final tujuan = penerima;
    final lanjut = await konfirmasi(tujuan, nominal, catatan);
    if (!lanjut || !mounted) return;

    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PinKonfirmasiScreen(
          repo: widget.repo,
          userId: widget.akun.id,
          keterangan: 'Bayar ${rupiahTeks(nominal)} ke ${tujuan.nama}',
        ),
      ),
    );
    if (!mounted) return;
    if (pin == null) {
      pesan('Pembayaran dibatalkan');
      return;
    }

    setState(() => loading = true);
    final hasil = await widget.repo.bayar(
      dariId: widget.akun.id,
      keId: tujuan.id,
      nominal: nominal,
      pin: pin,
      rekeningTujuan: rekening,
      berita: catatan,
      jenis: 'Pembayaran',
    );
    if (!mounted) return;
    setState(() => loading = false);

    final struk = hasil.struk;
    if (struk == null) {
      pesan(hasil.error ?? 'Pembayaran gagal');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StrukScreen(struk: struk, alasan: hasil.error),
      ),
    );
    if (!mounted) return;
    if (hasil.berhasil) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Pembayaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bayar ke rekening MyBCA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rekeningController,
              enabled: !loading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputStyle(
                'Nomor rekening tujuan',
                Icons.account_balance_outlined,
                context: context,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nominalController,
              enabled: !loading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputStyle(
                'Nominal (Rp)',
                Icons.payments_outlined,
                context: context,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: catatanController,
              enabled: !loading,
              maxLength: 60,
              decoration: inputStyle(
                'Catatan (opsional)',
                Icons.edit_note,
                context: context,
              ),
            ),
            const SizedBox(height: 16),
            TombolBiru(teks: 'Lanjut', onPressed: bayar, loading: loading),
          ],
        ),
      ),
    );
  }
}
