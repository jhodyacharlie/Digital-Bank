import 'package:flutter/material.dart';

import 'app_style.dart';
import 'pin_pad.dart';
import 'transaksi_repository.dart';

class PinKonfirmasiScreen extends StatefulWidget {
  const PinKonfirmasiScreen({
    super.key,
    required this.repo,
    required this.userId,
    required this.keterangan,
  });

  final TransaksiRepository repo;
  final String userId;
  final String keterangan;

  @override
  State<PinKonfirmasiScreen> createState() => _PinKonfirmasiScreenState();
}

class _PinKonfirmasiScreenState extends State<PinKonfirmasiScreen> {
  static const maksSalah = 3;

  String pin = '';
  int salah = 0;
  bool memeriksa = false;

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void hapus() {
    if (memeriksa || pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  Future<void> tekan(String angka) async {
    if (memeriksa || pin.length >= 6) return;
    setState(() => pin += angka);
    if (pin.length < 6) return;

    setState(() => memeriksa = true);
    bool benar;
    try {
      benar = await widget.repo.cekPin(widget.userId, pin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        memeriksa = false;
        pin = '';
      });
      pesan('Gagal terhubung ke server');
      return;
    }
    if (!mounted) return;

    if (benar) {
      Navigator.pop(context, pin);
      return;
    }

    salah++;
    if (salah >= maksSalah) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      memeriksa = false;
      pin = '';
    });
    pesan('PIN salah, sisa percobaan ${maksSalah - salah}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Konfirmasi PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.keterangan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.biruTua,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Masukkan 6 digit PIN kamu',
              style: TextStyle(color: AppColors.abu),
            ),
            const SizedBox(height: 24),
            PinPad(pin: pin, onDigit: tekan, onDelete: hapus),
          ],
        ),
      ),
    );
  }
}
