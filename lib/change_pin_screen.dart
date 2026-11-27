import 'package:flutter/material.dart';

import 'app_style.dart';
import 'pin_pad.dart';
import 'user_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final UserService userService = UserService();

  int langkah = 1;
  String pin = '';
  String pinBaru = '';
  String pinLama = '';
  bool loading = false;

  String get judul {
    if (langkah == 1) return 'Masukkan PIN lama';
    if (langkah == 2) return 'Buat PIN baru (6 angka)';
    return 'Ulangi PIN baru';
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void tambahAngka(String angka) {
    if (pin.length >= 6 || loading) return;
    setState(() => pin += angka);
    if (pin.length == 6) prosesPin();
  }

  void hapusAngka() {
    if (pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  Future<void> prosesPin() async {
    if (langkah == 1) {
      setState(() => loading = true);
      bool benar = false;
      try {
        benar = await userService.cekPin(widget.user['id'], pin);
      } catch (e) {
        benar = false;
      }
      if (!mounted) return;
      final pinTeruji = pin;
      setState(() {
        loading = false;
        pin = '';
        if (benar) {
          pinLama = pinTeruji;
          langkah = 2;
        }
      });
      if (!benar) pesan('PIN lama salah');
      return;
    }

    if (langkah == 2) {
      setState(() {
        pinBaru = pin;
        pin = '';
        langkah = 3;
      });
      return;
    }

    if (pin != pinBaru) {
      pesan('PIN tidak sama, ulangi dari awal');
      setState(() {
        pin = '';
        pinBaru = '';
        langkah = 2;
      });
      return;
    }

    setState(() => loading = true);
    bool berhasil = true;
    try {
      await userService.changePin(widget.user['id'], pin, pinLama: pinLama);
    } catch (e) {
      berhasil = false;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (!berhasil) {
      pesan('Gagal menyimpan PIN');
      return;
    }
    pesan('PIN berhasil diganti');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Change PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              judul,
              style: const TextStyle(fontSize: 16, color: AppColors.biruTua),
            ),
            const SizedBox(height: 24),
            PinPad(pin: pin, onDigit: tambahAngka, onDelete: hapusAngka),
            const SizedBox(height: 16),
            if (loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
