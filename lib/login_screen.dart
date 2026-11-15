import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'forgot_pin_screen.dart';
import 'home_screen.dart';
import 'pin_pad.dart';
import 'user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserService userService = UserService();
  final LocalAuthentication auth = LocalAuthentication();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  final TextEditingController idController = TextEditingController();

  String pin = '';
  bool loading = false;
  bool bisaFingerprint = false;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  @override
  void dispose() {
    idController.dispose();
    super.dispose();
  }

  void muatData() async {
    String idTersimpan = await prefs.getString('lastLogin') ?? '';
    bool bisa = false;
    try {
      bisa = await auth.canCheckBiometrics;
    } catch (e) {
      bisa = false;
    }
    if (!mounted) return;
    setState(() {
      idController.text = idTersimpan;
      bisaFingerprint = bisa;
    });
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void tambahAngka(String angka) {
    if (pin.length >= 6 || loading) return;
    setState(() => pin += angka);
    if (pin.length == 6) loginPin();
  }

  void hapusAngka() {
    if (pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  void masuk(Map<String, dynamic> user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
    );
  }

  void loginPin() async {
    final id = idController.text.trim();
    if (id.isEmpty) {
      pesan('Isi email atau nomor HP dulu');
      setState(() => pin = '');
      return;
    }

    setState(() => loading = true);
    Map<String, dynamic>? user;
    String? error;
    try {
      user = await userService.login(id, pin);
    } catch (e) {
      error = 'Gagal terhubung ke server';
    }
    if (!mounted) return;
    setState(() {
      loading = false;
      pin = '';
    });

    if (user == null) {
      pesan(error ?? 'Akun atau PIN salah');
      return;
    }

    await prefs.setString('lastLogin', user['email']);
    if (!mounted) return;
    masuk(user);
  }

  void loginFingerprint() async {
    String idTersimpan = await prefs.getString('lastLogin') ?? '';
    if (idTersimpan.isEmpty) {
      pesan('Login pakai PIN sekali dulu supaya fingerprint aktif');
      return;
    }

    try {
      bool berhasil = await auth.authenticate(
        localizedReason: 'Tempelkan jari untuk masuk ke Digeboy',
      );
      if (!berhasil) return;

      final user = await userService.findUser(idTersimpan);
      if (!mounted) return;
      if (user == null) {
        pesan('Akun tidak ditemukan');
        return;
      }
      masuk(user);
    } catch (e) {
      pesan('Fingerprint tidak bisa dipakai');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.biruTua, AppColors.biru],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digeboy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Masuk ke akun digital banking kamu',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: idController,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputStyle(
                      'Email atau No. HP',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Masukkan PIN 6 angka',
                    style: TextStyle(color: AppColors.abu),
                  ),
                  const SizedBox(height: 16),
                  PinPad(
                    pin: pin,
                    onDigit: tambahAngka,
                    onDelete: hapusAngka,
                    leftButton: bisaFingerprint
                        ? IconButton(
                            onPressed: loginFingerprint,
                            icon: const Icon(
                              Icons.fingerprint,
                              size: 36,
                              color: AppColors.biru,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPinScreen(),
                        ),
                      );
                    },
                    child: const Text('Lupa PIN?'),
                  ),
                  if (loading) const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
