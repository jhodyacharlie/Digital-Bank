import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'qris_saya_screen.dart';
import 'transfer_qris_screen.dart';
import 'user_service.dart';

class QrisScreen extends StatefulWidget {
  const QrisScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends State<QrisScreen> {
  final MobileScannerController controller = MobileScannerController();
  final ImagePicker picker = ImagePicker();
  final UserService userService = UserService();

  bool senter = false;
  bool memproses = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> lepasKunci() async {
    await Future.delayed(const Duration(seconds: 2));
    memproses = false;
  }

  Future<bool?> bukaHalaman(Widget halaman) async {
    await controller.stop();
    if (!mounted) return null;
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => halaman),
    );
    if (hasil == true || !mounted) return hasil;
    setState(() => senter = false);
    await controller.start();
    memproses = false;
    return hasil;
  }

  Future<void> tanganiKode(String kode) async {
    if (memproses) return;
    memproses = true;

    if (!kode.startsWith('MYBCA|')) {
      await controller.stop();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hasil scan'),
          content: SelectableText('Ini bukan QRIS MyBCA.\n\nIsi kode:\n$kode'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => senter = false);
      await controller.start();
      memproses = false;
      return;
    }

    Map<String, dynamic>? penerima;
    try {
      penerima = await userService.findByRekening(kode.substring(6));
    } catch (e) {
      penerima = null;
    }
    if (!mounted) return;

    if (penerima == null) {
      pesan('Penerima tidak ditemukan');
      lepasKunci();
      return;
    }

    if (penerima['id'] == widget.user['id']) {
      pesan('Tidak bisa transfer ke rekening sendiri');
      lepasKunci();
      return;
    }

    final berhasil = await bukaHalaman(
      TransferQrisScreen(pengirim: widget.user, penerima: penerima),
    );
    if (berhasil == true && mounted) Navigator.pop(context, true);
  }

  Future<void> pilihDariGaleri() async {
    try {
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final hasil = await controller.analyzeImage(file.path);
      String? kode;
      if (hasil != null && hasil.barcodes.isNotEmpty) {
        kode = hasil.barcodes.first.rawValue;
      }

      if (kode == null) {
        pesan('Barcode tidak ditemukan pada gambar');
        return;
      }
      await tanganiKode(kode);
    } catch (e) {
      pesan('Gagal membaca gambar');
    }
  }

  Future<void> nyalakanSenter() async {
    try {
      await controller.toggleTorch();
      if (!mounted) return;
      setState(() => senter = !senter);
    } catch (e) {
      pesan('Flash tidak tersedia');
    }
  }

  Widget tombolAksi(IconData ikon, String teks, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(ikon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(teks, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final kode = capture.barcodes.first.rawValue;
              if (kode != null) tanganiKode(kode);
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text(
                    'Scan QRIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    tombolAksi(
                      senter ? Icons.flash_on : Icons.flash_off,
                      'Flash',
                      nyalakanSenter,
                    ),
                    tombolAksi(
                      Icons.photo_library_outlined,
                      'Galeri',
                      pilihDariGaleri,
                    ),
                    tombolAksi(
                      Icons.qr_code_2,
                      'QRIS Saya',
                      () => bukaHalaman(QrisSayaScreen(user: widget.user)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
