import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'forgot_pin_screen.dart';
import 'home_screen.dart';
import 'pin_pad.dart';
import 'register_screen.dart';
import 'services/locale_service.dart';
import 'user_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'widgets/mybca_mascot.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserService userService = UserService();
  final LocalAuthentication auth = LocalAuthentication();
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
    String idTersimpan = '';
    bool aktif = true;
    try {
      final prefs = SharedPreferencesAsync();
      idTersimpan = await prefs.getString('lastLogin') ?? '';
      aktif = await prefs.getBool('biometrik') ?? true;
    } catch (_) {
      idTersimpan = '';
      aktif = true;
    }
    bool bisa = false;
    try {
      bisa = await auth.canCheckBiometrics;
    } catch (e) {
      bisa = false;
    }
    if (!mounted) return;
    setState(() {
      idController.text = idTersimpan;
      bisaFingerprint = bisa && aktif;
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
    final page = user['isAdmin'] == true
        ? const AdminDashboardScreen()
        : HomeScreen(user: user);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  void loginPin() async {
    final id = idController.text.trim();
    if (id.isEmpty) {
      pesan('Isi email dulu');
      setState(() => pin = '');
      return;
    }

    setState(() => loading = true);
    Map<String, dynamic>? user;
    String? error;
    try {
      user = await userService.login(id, pin);
      if (user != null && user['isAdmin'] != true)
        await userService.recordLoginActivity();
    } on RegisterException catch (e) {
      error = e.pesan;
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

    await SharedPreferencesAsync().setString('lastLogin', user['email']);
    if (!mounted) return;
    masuk(user);
  }

  void loginFingerprint() async {
    String idTersimpan =
        await SharedPreferencesAsync().getString('lastLogin') ?? '';
    if (idTersimpan.isEmpty) {
      pesan('Login pakai PIN sekali dulu supaya fingerprint aktif');
      return;
    }

    try {
      bool berhasil = await auth.authenticate(
        localizedReason: 'Tempelkan jari untuk masuk ke MyBCA',
      );
      if (!berhasil) return;

      final user = await userService.getCurrentUser();
      if (!mounted) return;
      if (user == null) {
        pesan('Akun tidak ditemukan');
        return;
      }
      final status = (user['verificationStatus'] ?? 'approved').toString();
      if (status != 'approved') {
        pesan(
          status == 'pending'
              ? 'Akun masih menunggu verifikasi admin'
              : 'Akun belum disetujui',
        );
        return;
      }
      await userService.recordLoginActivity();
      masuk(user);
    } catch (e) {
      pesan('Fingerprint tidak bisa dipakai');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LocaleService.tr;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003268), AppColors.biru, Color(0xFF1577CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'myBCA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(
                          'Masuk ke akun digital banking kamu',
                          'Sign in to your digital banking account',
                        ),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                MyBcaMascot(
                  size: 74,
                  mood: MascotMood.waving,
                  onTap: () => pesan(
                    t(
                      'Halo! Aku Bibo, asisten MyBCA kamu.',
                      'Hi! I am Bibo, your MyBCA buddy.',
                    ),
                  ),
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
                      'Email',
                      Icons.mail_outline,
                      context: context,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('Masukkan PIN 6 angka', 'Enter 6-digit PIN'),
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 16),
                  PinPad(
                    pin: pin,
                    onDigit: tambahAngka,
                    onDelete: hapusAngka,
                    leftButton: bisaFingerprint
                        ? IconButton(
                            onPressed: loginFingerprint,
                            icon: Icon(
                              Icons.fingerprint,
                              size: 36,
                              color: AppColors.accent(context),
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
                    child: Text(t('Lupa PIN?', 'Forgot PIN?')),
                  ),
                  if (loading) const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t('Belum punya akun? ', "Don't have an account? "),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                        child: Text(t('Daftar sekarang', 'Register now')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
