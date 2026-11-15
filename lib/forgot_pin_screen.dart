import 'package:flutter/material.dart';

import 'app_style.dart';
import 'pin_pad.dart';
import 'user_service.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final UserService userService = UserService();
  final TextEditingController kontakController = TextEditingController();
  final TextEditingController kodeController = TextEditingController();

  int langkah = 1;
  bool loading = false;
  Map<String, dynamic>? user;
  String tujuan = '';
  String pinBaru = '';
  String pinPertama = '';

  @override
  void dispose() {
    kontakController.dispose();
    kodeController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void kirimKode() async {
    final input = kontakController.text.trim();
    if (input.isEmpty) {
      pesan('Isi email atau nomor HP dulu');
      return;
    }

    setState(() => loading = true);
    String? kode;
    try {
      final hasil = await userService.findUser(input);
      if (hasil == null) {
        pesan('Email / nomor HP tidak terdaftar');
      } else {
        kode = await userService.createResetCode(hasil['id']);
        user = hasil;
        tujuan = input.contains('@') ? 'email' : 'nomor HP';
      }
    } catch (e) {
      pesan('Gagal terhubung ke server');
    }

    if (!mounted) return;
    setState(() => loading = false);

    if (kode != null) {
      await tampilKodeDemo(kode);
      if (!mounted) return;
      setState(() => langkah = 2);
    }
  }

  Future<void> tampilKodeDemo(String kode) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kode dikirim ke $tujuan'),
        content: Text(
          'MODE DEMO: kode verifikasi kamu adalah $kode\n\n'
          'Di aplikasi sungguhan kode dikirim lewat email atau SMS, '
          'bukan ditampilkan di layar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------- Langkah 2: cek kode ----------
  void cekKode() async {
    setState(() => loading = true);
    bool benar = false;
    try {
      benar = await userService.checkResetCode(
        user!['id'],
        kodeController.text.trim(),
      );
    } catch (e) {
      benar = false;
    }
    if (!mounted) return;
    setState(() {
      loading = false;
      if (benar) langkah = 3;
    });
    if (!benar) pesan('Kode salah atau sudah kadaluarsa');
  }

  // ---------- Langkah 3: PIN baru ----------
  void tambahAngka(String angka) {
    if (pinBaru.length >= 6 || loading) return;
    setState(() => pinBaru += angka);
    if (pinBaru.length == 6) cekPinBaru();
  }

  void hapusAngka() {
    if (pinBaru.isEmpty) return;
    setState(() => pinBaru = pinBaru.substring(0, pinBaru.length - 1));
  }

  void cekPinBaru() async {
    // PIN pertama selesai -> minta ketik ulang
    if (pinPertama.isEmpty) {
      setState(() {
        pinPertama = pinBaru;
        pinBaru = '';
      });
      return;
    }

    // PIN kedua harus sama dengan yang pertama
    if (pinPertama != pinBaru) {
      pesan('PIN tidak sama, ulangi dari awal');
      setState(() {
        pinPertama = '';
        pinBaru = '';
      });
      return;
    }

    setState(() => loading = true);
    bool berhasil = true;
    try {
      await userService.changePin(user!['id'], pinBaru);
    } catch (e) {
      berhasil = false;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (berhasil) {
      pesan('PIN baru tersimpan. Silakan login.');
      Navigator.pop(context);
    } else {
      pesan('Gagal menyimpan PIN');
    }
  }

  // ---------- Tampilan ----------
  Widget tampilanKontak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukkan email atau nomor HP yang terdaftar. '
          'Kami akan mengirim kode verifikasi ke sana.',
          style: TextStyle(color: AppColors.abu),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: kontakController,
          keyboardType: TextInputType.emailAddress,
          decoration: inputStyle('Email atau No. HP', Icons.mail_outline),
        ),
        const SizedBox(height: 24),
        TombolBiru(teks: 'Kirim Kode', onPressed: kirimKode, loading: loading),
      ],
    );
  }

  Widget tampilanKode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masukkan 6 angka kode yang dikirim ke $tujuan kamu.',
          style: const TextStyle(color: AppColors.abu),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: kodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: inputStyle('Kode verifikasi', Icons.lock_outline),
        ),
        const SizedBox(height: 16),
        TombolBiru(teks: 'Verifikasi', onPressed: cekKode, loading: loading),
        Center(
          child: TextButton(
            onPressed: kirimKode,
            child: const Text('Kirim ulang kode'),
          ),
        ),
      ],
    );
  }

  Widget tampilanPinBaru() {
    return Column(
      children: [
        Text(
          pinPertama.isEmpty ? 'Buat PIN baru (6 angka)' : 'Ulangi PIN baru',
          style: const TextStyle(fontSize: 16, color: AppColors.biruTua),
        ),
        const SizedBox(height: 24),
        PinPad(pin: pinBaru, onDigit: tambahAngka, onDelete: hapusAngka),
        const SizedBox(height: 16),
        if (loading) const CircularProgressIndicator(),
      ],
    );
  }

  Widget isiHalaman() {
    if (langkah == 1) return tampilanKontak();
    if (langkah == 2) return tampilanKode();
    return tampilanPinBaru();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Lupa PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: isiHalaman(),
      ),
    );
  }
}
