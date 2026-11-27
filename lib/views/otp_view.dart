import 'package:flutter/material.dart';

import '../app_style.dart';
import '../user_service.dart';
import '../widgets/mybca_mascot.dart';
import 'security_view.dart';

class OTPView extends StatefulWidget {
  final Map<String, dynamic> profile;

  const OTPView({super.key, required this.profile});

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final UserService _userService = UserService();

  String? _errorMessage;
  bool _memeriksa = false;
  bool _mengirimUlang = false;

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _sayaSudahVerifikasi() async {
    setState(() {
      _memeriksa = true;
      _errorMessage = null;
    });

    bool terverifikasi = false;
    try {
      terverifikasi = await _userService.cekEmailTerverifikasi();
    } catch (_) {
      terverifikasi = false;
    }

    if (!mounted) return;
    setState(() => _memeriksa = false);

    if (!terverifikasi) {
      setState(() {
        _errorMessage =
            'Email belum terverifikasi. Buka email kamu, ketuk tautan '
            'verifikasinya, lalu coba lagi.';
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityView(registrationData: widget.profile),
      ),
    );
  }

  Future<void> _kirimUlang() async {
    setState(() => _mengirimUlang = true);
    try {
      await _userService.kirimUlangVerifikasiEmail();
      pesan('Email verifikasi dikirim ulang. Cek inbox atau folder spam.');
    } catch (e) {
      pesan('Gagal mengirim ulang: $e');
    }
    if (!mounted) return;
    setState(() => _mengirimUlang = false);
  }

  Future<void> _batalkanPendaftaran() async {
    setState(() => _memeriksa = true);
    await _userService.batalkanPendaftaranSementara();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B3D91);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Verifikasi Email'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: MyBcaMascot(size: 80, mood: MascotMood.waving)),
            const SizedBox(height: 12),
            const Text(
              'Verifikasi Email Kamu',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.profile['verificationSent'] == false
                  ? 'Akun sementara dibuat untuk ${widget.profile['email']}, namun email verifikasi awal gagal dikirim (${widget.profile['verificationError'] ?? 'coba kirim ulang'}).'
                  : 'Kami sudah mengirim tautan verifikasi ke '
                        '${widget.profile['email']}.',
              style: TextStyle(
                fontSize: 15,
                color: widget.profile['verificationSent'] == false
                    ? Colors.red.shade700
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 20),
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
                  Row(
                    children: const [
                      Icon(Icons.mark_email_unread_outlined, color: navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Langkahnya:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Buka aplikasi email di HP kamu.'),
                  const SizedBox(height: 4),
                  const Text(
                    '2. Cari email dari Firebase/MyBCA (cek folder spam).',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '3. Ketuk tautan "Verify Email Address" di email itu.',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '4. Kembali ke aplikasi ini, lalu ketuk tombol di bawah.',
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _memeriksa ? null : _sayaSudahVerifikasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _memeriksa
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Saya sudah verifikasi'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _mengirimUlang ? null : _kirimUlang,
                child: Text(
                  _mengirimUlang ? 'Mengirim...' : 'Kirim ulang email',
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: (_memeriksa || _mengirimUlang)
                    ? null
                    : _batalkanPendaftaran,
                child: const Text(
                  'Batalkan & daftar ulang',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
