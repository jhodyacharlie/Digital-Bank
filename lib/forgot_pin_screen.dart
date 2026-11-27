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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController kodeController = TextEditingController();

  int langkah = 1;
  bool loading = false;
  String pinBaru = '';
  String pinPertama = '';

  @override
  void dispose() {
    emailController.dispose();
    kodeController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void kirimKode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      pesan('Isi email dulu');
      return;
    }

    setState(() => loading = true);
    String? errorMessage;
    try {
      await userService.kirimResetPin(email);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('RegisterException: ', '');
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (errorMessage != null) {
      pesan(errorMessage);
      return;
    }
    setState(() => langkah = 2);
    pesan(
      'Permintaan diproses. Jika email terdaftar, tautan reset dikirim. Periksa Inbox, Spam, dan Promotions.',
    );
  }

  String _ekstrakKode(String input) {
    final raw = input.trim();
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.queryParameters.containsKey('oobCode')) {
      return uri.queryParameters['oobCode']!.trim();
    }
    final match = RegExp(r'oobCode=([^&\s]+)').firstMatch(raw);
    if (match != null) {
      return Uri.decodeComponent(match.group(1)!).trim();
    }
    return raw;
  }

  void cekKode() async {
    final kode = _ekstrakKode(kodeController.text);
    if (kode.isEmpty) {
      pesan('Tempelkan dulu kode atau tautan dari email');
      return;
    }
    kodeController.text = kode;

    setState(() => loading = true);
    bool valid = false;
    try {
      valid = await userService.cekKodeReset(kode);
    } catch (e) {
      valid = false;
    }
    if (!mounted) return;
    setState(() {
      loading = false;
      if (valid) langkah = 3;
    });
    if (!valid) pesan('Kode salah, sudah dipakai, atau sudah kedaluwarsa');
  }

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
    if (pinPertama.isEmpty) {
      setState(() {
        pinPertama = pinBaru;
        pinBaru = '';
      });
      return;
    }

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
      await userService.selesaikanResetPin(
        _ekstrakKode(kodeController.text),
        pinBaru,
      );
    } catch (e) {
      berhasil = false;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (berhasil) {
      pesan('PIN baru tersimpan. Silakan login.');
      Navigator.pop(context);
    } else {
      pesan('Gagal menyimpan PIN. Mungkin kodenya sudah kedaluwarsa.');
      setState(() {
        pinPertama = '';
        pinBaru = '';
      });
    }
  }

  Widget tampilanKontak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukkan email akunmu. Firebase akan mengirim email berisi '
          'tautan reset PIN ke alamat itu.',
          style: TextStyle(color: AppColors.abu),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: emailController,
          enabled: !loading,
          keyboardType: TextInputType.emailAddress,
          decoration: inputStyle('Email', Icons.mail_outline),
        ),
        const SizedBox(height: 24),
        TombolBiru(teks: 'Kirim Email', onPressed: kirimKode, loading: loading),
      ],
    );
  }

  Widget tampilanKode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buka email reset dari Firebase (cek Inbox, Spam, atau Promotions).\n\n'
          '• Kamu bisa mengetuk tautannya langsung untuk reset lewat browser, atau\n'
          '• Salin tautan lengkap / nilai "oobCode=" dari email dan tempel di bawah ini untuk atur PIN 6 digit di aplikasi.',
          style: TextStyle(color: AppColors.abu),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: kodeController,
          enabled: !loading,
          decoration: inputStyle(
            'Tautan atau oobCode dari email',
            Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 16),
        TombolBiru(teks: 'Verifikasi', onPressed: cekKode, loading: loading),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: loading ? null : () => setState(() => langkah = 1),
              child: const Text('Ganti email'),
            ),
            TextButton(
              onPressed: loading ? null : kirimKode,
              child: const Text('Kirim ulang email'),
            ),
          ],
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
      backgroundColor: AppColors.bg(context),
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
