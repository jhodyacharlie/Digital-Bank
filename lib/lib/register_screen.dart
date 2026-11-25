import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'home_screen.dart';
import 'security_service.dart';
import 'user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final UserService userService = UserService();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  final namaDepanController = TextEditingController();
  final namaBelakangController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool lihatPin = false;
  bool lihatKonfirmasi = false;
  bool loading = false;

  @override
  void dispose() {
    namaDepanController.dispose();
    namaBelakangController.dispose();
    emailController.dispose();
    phoneController.dispose();
    pinController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  // ---------- validasi ----------

  String get pin => pinController.text;

  bool get namaValid =>
      namaDepanController.text.trim().isNotEmpty &&
      namaBelakangController.text.trim().isNotEmpty;

  bool get emailValid => RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(emailController.text.trim());

  bool get phoneValid => RegExp(
        r'^08\d{8,11}$',
      ).hasMatch(UserService.normalisasiPhone(phoneController.text));

  bool get pinEnamAngka => RegExp(r'^\d{6}$').hasMatch(pin);

  bool get pinTidakMudahTebak {
    if (!pinEnamAngka) return false;
    final d = pin.split('').map(int.parse).toList();
    final semuaSama = d.every((x) => x == d[0]);
    final naik = List.generate(5, (i) => d[i + 1] - d[i]).every((x) => x == 1);
    final turun =
        List.generate(5, (i) => d[i + 1] - d[i]).every((x) => x == -1);
    return !(semuaSama || naik || turun);
  }

  bool get pinSama => pin.isNotEmpty && pin == konfirmasiController.text;

  bool get formValid =>
      namaValid &&
      emailValid &&
      phoneValid &&
      pinEnamAngka &&
      pinTidakMudahTebak &&
      pinSama;

  // ---------- aksi ----------

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> daftar() async {
    if (!formValid || loading) return;
    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    Map<String, dynamic>? user;
    String? error;
    try {
      user = await userService.register(
        namaDepan: namaDepanController.text,
        namaBelakang: namaBelakangController.text,
        email: emailController.text,
        phone: phoneController.text,
        pin: pin,
      );
    } on RegisterException catch (e) {
      error = e.pesan;
    } catch (e) {
      error = 'Gagal terhubung ke server';
    }
    if (!mounted) return;
    setState(() => loading = false);

    final akun = user;
    if (akun == null) {
      pesan(error ?? 'Gagal membuat akun');
      return;
    }

    // Simpan supaya fingerprint di halaman login langsung bisa dipakai.
    await prefs.setString('lastLogin', akun['email']);
    await SecurityService().catatLogin(akun['id'], metode: 'Registrasi');
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(user: akun)),
      (route) => false,
    );
  }

  // ---------- tampilan ----------

  InputDecoration dekor(String label, {Widget? suffix, String? hint}) {
    final garis = context.garis;
    OutlineInputBorder border(Color warna, [double lebar = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: warna, width: lebar),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: context.kartu,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      enabledBorder: border(garis),
      disabledBorder: border(garis),
      focusedBorder: border(AppColors.biru, 1.6),
      border: border(garis),
    );
  }

  Widget kolom(
    TextEditingController c,
    String label, {
    TextInputType tipe = TextInputType.text,
    TextCapitalization kapital = TextCapitalization.none,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        enabled: !loading,
        keyboardType: tipe,
        textCapitalization: kapital,
        onChanged: (_) => setState(() {}),
        decoration: dekor(label, hint: hint),
      ),
    );
  }

  Widget kolomPin(
    TextEditingController c,
    String label,
    bool terlihat,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: c,
      enabled: !loading,
      obscureText: !terlihat,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: (_) => setState(() {}),
      decoration: dekor(
        label,
        suffix: IconButton(
          onPressed: onToggle,
          icon: Icon(
            terlihat ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.abu,
          ),
        ),
      ),
    );
  }

  Widget syarat(String teks, bool terpenuhi) {
    final warna = terpenuhi ? Colors.green.shade600 : Colors.grey.shade500;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            terpenuhi ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: warna,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(teks, style: TextStyle(fontSize: 12, color: warna)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.layar,
      appBar: AppBar(
        backgroundColor: context.layar,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: context.teksUtama,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Digeboy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.biru,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ayo buat akunmu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.teksUtama,
                ),
              ),
              const SizedBox(height: 28),
              kolom(
                namaDepanController,
                'Nama depan',
                kapital: TextCapitalization.words,
              ),
              kolom(
                namaBelakangController,
                'Nama belakang',
                kapital: TextCapitalization.words,
              ),
              kolom(
                emailController,
                'Email',
                tipe: TextInputType.emailAddress,
              ),
              kolom(
                phoneController,
                'No. HP',
                tipe: TextInputType.phone,
                hint: '08xxxxxxxxxx',
              ),
              kolomPin(
                pinController,
                'PIN (6 angka)',
                lihatPin,
                () => setState(() => lihatPin = !lihatPin),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 0, 12),
                child: Column(
                  children: [
                    syarat('Tepat 6 angka', pinEnamAngka),
                    syarat(
                      'Bukan angka sama / berurutan (111111, 123456)',
                      pinTidakMudahTebak,
                    ),
                  ],
                ),
              ),
              kolomPin(
                konfirmasiController,
                'Konfirmasi PIN',
                lihatKonfirmasi,
                () => setState(() => lihatKonfirmasi = !lihatKonfirmasi),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
                child: syarat('PIN dan konfirmasi sama', pinSama),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: formValid && !loading ? daftar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.biru,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Buat akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(color: AppColors.abu),
                  ),
                  GestureDetector(
                    onTap: loading ? null : () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Text(
                        'Masuk',
                        style: TextStyle(
                          color: AppColors.biru,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
