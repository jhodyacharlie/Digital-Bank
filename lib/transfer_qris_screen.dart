import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'firestore_transaksi_repository.dart';
import 'pin_konfirmasi_screen.dart';
import 'user_service.dart';

class TransferQrisScreen extends StatefulWidget {
  const TransferQrisScreen({
    super.key,
    required this.pengirim,
    required this.penerima,
  });

  final Map<String, dynamic> pengirim;
  final Map<String, dynamic> penerima;

  @override
  State<TransferQrisScreen> createState() => _TransferQrisScreenState();
}

class _TransferQrisScreenState extends State<TransferQrisScreen> {
  final UserService userService = UserService();
  final TextEditingController nominalController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nominalController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  String rupiah(int angka) {
    final teks = angka.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return 'Rp $teks';
  }

  Future<void> kirim() async {
    final nominal = int.tryParse(nominalController.text.trim()) ?? 0;
    if (nominal <= 0) {
      pesan('Isi nominal transfer dulu');
      return;
    }

    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi transfer'),
        content: Text(
          'Transfer ${rupiah(nominal)} ke ${widget.penerima['nama']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PinKonfirmasiScreen(
          repo: FirestoreTransaksiRepository(),
          userId: widget.pengirim['id'] as String,
          keterangan:
              'Transfer ${rupiah(nominal)} ke ${widget.penerima['nama']}',
        ),
      ),
    );
    if (!mounted || pin == null) return;

    setState(() => loading = true);
    String? error;
    try {
      error = await userService.transfer(
        widget.pengirim['id'],
        widget.penerima['id'],
        nominal,
        pin: pin,
        rekeningTujuan: widget.penerima['rekening'] as String,
      );
    } catch (e) {
      error = 'Gagal terhubung ke server';
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (error != null) {
      pesan(error);
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer berhasil'),
        content: Text(
          '${rupiah(nominal)} berhasil dikirim ke ${widget.penerima['nama']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Transfer QRIS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penerima',
                    style: TextStyle(color: AppColors.abu),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.penerima['nama'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.biruTua,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No. Rekening',
                    style: TextStyle(color: AppColors.abu),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.penerima['rekening'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.biruTua,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nominalController,
              enabled: !loading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputStyle('Nominal (Rp)', Icons.payments_outlined),
            ),
            const SizedBox(height: 24),
            TombolBiru(teks: 'Transfer', onPressed: kirim, loading: loading),
          ],
        ),
      ),
    );
  }
}
