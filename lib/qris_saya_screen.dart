import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'app_style.dart';
import 'user_service.dart';

class QrisSayaScreen extends StatefulWidget {
  const QrisSayaScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<QrisSayaScreen> createState() => _QrisSayaScreenState();
}

class _QrisSayaScreenState extends State<QrisSayaScreen> {
  final UserService userService = UserService();

  String? rekening;
  bool gagal = false;

  @override
  void initState() {
    super.initState();
    terangkanLayar();
    muatRekening();
  }

  @override
  void dispose() {
    kembalikanLayar();
    super.dispose();
  }

  Future<void> terangkanLayar() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Gagal mengatur kecerahan: $e');
    }
  }

  Future<void> kembalikanLayar() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Gagal mengembalikan kecerahan: $e');
    }
  }

  Future<void> muatRekening() async {
    try {
      final hasil = await userService.ambilRekening(widget.user);
      if (!mounted) return;
      setState(() => rekening = hasil);
    } catch (e) {
      if (!mounted) return;
      setState(() => gagal = true);
    }
  }

  Widget isiKartu() {
    if (gagal) {
      return const Text('Gagal memuat QRIS, coba lagi nanti');
    }
    if (rekening == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'QRIS MyBCA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.biruTua,
          ),
        ),
        const SizedBox(height: 16),
        QrImageView(
          data: 'MYBCA|$rekening',
          size: 220,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          widget.user['nama'] as String,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.biruTua,
          ),
        ),
        const SizedBox(height: 4),
        const Text('No. Rekening', style: TextStyle(color: AppColors.abu)),
        Text(
          rekening!,
          style: const TextStyle(
            fontSize: 18,
            letterSpacing: 1.5,
            color: AppColors.biruTua,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('QRIS Saya'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Center(child: isiKartu()),
            ),
            const SizedBox(height: 16),
            const Text(
              'Minta pengirim untuk scan kode ini. Layar otomatis dibuat paling terang supaya mudah dibaca.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.abu),
            ),
          ],
        ),
      ),
    );
  }
}
