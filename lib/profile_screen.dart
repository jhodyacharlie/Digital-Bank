import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'change_pin_screen.dart';
import 'edit_profile_screen.dart';
import 'login_activity_screen.dart';
import 'login_screen.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';
import 'user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    this.onOpenSettings,
    this.onOpenNotifications,
    this.onOpenAccountSettings,
  });

  final Map<String, dynamic> user;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenAccountSettings;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService userService = UserService();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  late Map<String, dynamic> user;
  Uint8List? fotoBytes;
  String rekening = '...';
  bool biometrik = true;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
    final foto = user['foto'];
    if (foto is String && foto.isNotEmpty) {
      try {
        fotoBytes = base64Decode(foto);
      } catch (_) {
        fotoBytes = null;
      }
    }
    muatData();
  }

  Future<void> muatData() async {
    final aktif = await prefs.getBool('biometrik') ?? true;
    String noRek = '-';
    try {
      noRek = await userService.ambilRekening(user);
    } catch (e) {
      noRek = '-';
    }
    if (!mounted) return;
    setState(() {
      biometrik = aktif;
      rekening = noRek;
    });
  }

  Future<void> ubahBiometrik(bool nilai) async {
    setState(() => biometrik = nilai);
    await prefs.setBool('biometrik', nilai);
  }

  Future<void> editProfil() async {
    final hasil = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (hasil == null || !mounted) return;
    setState(() => user.addAll(hasil));
  }

  void gantiPin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChangePinScreen(user: user)),
    );
  }

  Future<void> keluar() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari MyBCA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (setuju != true || !mounted) return;
    await userService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String nilai(String kunci, String cadangan) {
    final data = user[kunci];
    if (data == null || data.toString().isEmpty) return cadangan;
    return data.toString();
  }

  String formatTanggalLahir() {
    final raw = user['tglLahir'];
    if (raw is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(raw);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return nilai('tglLahir', '-');
  }

  void bukaInfoDialog(String judul, String isi) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  List<Widget> sisipGaris(List<Widget> items) {
    final hasil = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) hasil.add(const Divider(height: 1));
      hasil.add(items[i]);
    }
    return hasil;
  }

  Widget pil(String teks, Color warna, {IconData? ikon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(teks, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget header() {
    final nama = nilai('nama', 'Pengguna');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.biruTua, AppColors.biru],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            backgroundImage: fotoBytes != null ? MemoryImage(fotoBytes!) : null,
            child: fotoBytes == null
                ? Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: AppColors.biru,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nilai('email', '-'),
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            nilai('phone', '-'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pil('ID: ${user['businessId'] ?? user['id']}', Colors.white24),
              const SizedBox(width: 8),
              pil(
                user['isVerified'] == true ? 'Verified' : 'Belum Verifikasi',
                user['isVerified'] == true
                    ? Colors.green.shade600
                    : Colors.orange.shade700,
                ikon: user['isVerified'] == true
                    ? Icons.verified
                    : Icons.info_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: editProfil,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget kartu(String judul, List<Widget> isi) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          ...sisipGaris(isi),
        ],
      ),
    );
  }

  Widget barisInfo(String label, String isi, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              isi,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing],
        ],
      ),
    );
  }

  Widget barisMenu(
    IconData ikon,
    String judul, {
    String? teks,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(ikon, color: AppColors.accent(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                judul,
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
            ),
            if (teks != null)
              Text(
                teks,
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget bagianPersonal() {
    final t = LocaleService.tr;
    return kartu(t('Informasi Pribadi', 'Personal Information'), [
      barisInfo(t('Nama Lengkap', 'Full Name'), nilai('nama', '-')),
      barisInfo(t('Tanggal Lahir', 'Date of Birth'), formatTanggalLahir()),
      barisInfo(t('Gender', 'Gender'), nilai('gender', '-')),
      barisInfo('Email', nilai('email', '-')),
      barisInfo(t('Nomor HP', 'Phone Number'), nilai('phone', '-')),
      barisInfo(t('Alamat', 'Address'), nilai('alamat', '-')),
      barisInfo(
        t('Kewarganegaraan', 'Nationality'),
        nilai('kewarganegaraan', 'Indonesia'),
      ),
    ]);
  }

  Widget bagianRekening() {
    final t = LocaleService.tr;
    return kartu(t('Informasi Rekening', 'Account Information'), [
      barisInfo(
        t('Nomor Rekening', 'Account Number'),
        rekening,
        trailing: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: t('Salin nomor rekening', 'Copy account number'),
          icon: Icon(
            Icons.copy_rounded,
            size: 17,
            color: AppColors.accent(context),
          ),
          onPressed: () {
            if (rekening == '-' || rekening == '...') return;
            Clipboard.setData(ClipboardData(text: rekening));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t(
                    'Nomor rekening $rekening disalin',
                    'Account number $rekening copied',
                  ),
                ),
              ),
            );
          },
        ),
      ),
      barisInfo(
        t('Tipe Rekening', 'Account Type'),
        nilai('tipeRekening', 'Savings'),
      ),
      barisInfo(
        t('Nama Pemilik', 'Account Name'),
        nilai('nama', '-').toUpperCase(),
      ),
      barisInfo(t('Cabang', 'Branch Name'), nilai('cabang', 'KCU Jakarta')),
      barisInfo(t('Status Rekening', 'Account Status'), t('Aktif', 'Active')),
      barisInfo(
        t('Anggota Sejak', 'Member Since'),
        nilai('memberSince', 'Januari 2025'),
      ),
    ]);
  }

  Widget bagianKeamanan() {
    final t = LocaleService.tr;
    return kartu(t('Keamanan & Privasi', 'Security & Privacy'), [
      barisMenu(
        Icons.lock_outline,
        t('Ubah Password', 'Change Password'),
        onTap: widget.onOpenAccountSettings,
      ),
      barisMenu(
        Icons.pin_outlined,
        t('Ubah PIN', 'Change PIN'),
        onTap: gantiPin,
      ),
      barisMenu(
        Icons.fingerprint,
        t('Autentikasi Biometrik', 'Biometric Authentication'),
        trailing: Switch(value: biometrik, onChanged: ubahBiometrik),
      ),
      barisMenu(
        Icons.security_outlined,
        t('Autentikasi Dua Faktor', 'Two-Factor Authentication'),
        teks: t('Email Terverifikasi', 'Email Verified'),
        onTap: () => bukaInfoDialog(
          t('Autentikasi Dua Faktor', 'Two-Factor Authentication'),
          t(
            'Akun MyBCA kamu terlindungi verifikasi email Firebase Auth dan Security PIN 6 digit.',
            'Your MyBCA account is protected by Firebase Auth email verification and a 6-digit Security PIN.',
          ),
        ),
      ),
      barisMenu(
        Icons.devices_outlined,
        t('Kelola Perangkat', 'Manage Devices'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginActivityScreen()),
        ),
      ),
      barisMenu(
        Icons.history,
        t('Aktivitas Login', 'Login Activity'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginActivityScreen()),
        ),
      ),
    ]);
  }

  Widget bagianPengaturan() {
    final t = LocaleService.tr;
    final isDark = ThemeService.mode.value == ThemeMode.dark;
    return kartu(t('Pengaturan Lainnya', 'Other Settings'), [
      barisMenu(
        Icons.notifications_outlined,
        t('Preferensi Notifikasi', 'Notification Preferences'),
        onTap: widget.onOpenNotifications,
      ),
      barisMenu(
        Icons.language,
        t('Bahasa', 'Language'),
        teks: LocaleService.language.value,
        onTap: widget.onOpenSettings,
      ),
      barisMenu(
        Icons.brightness_6_outlined,
        t('Mode Gelap / Terang', 'Dark Mode / Light Mode'),
        teks: isDark ? 'Dark' : 'Light',
        onTap: widget.onOpenSettings,
      ),
      barisMenu(
        Icons.privacy_tip_outlined,
        t('Kebijakan Privasi', 'Privacy Policy'),
        onTap: () => bukaInfoDialog(
          t('Kebijakan Privasi', 'Privacy Policy'),
          t(
            'Data pribadi dan transaksi kamu disimpan aman di Firebase untuk keperluan layanan perbankan digital MyBCA.',
            'Your personal data and transactions are securely stored in Firebase for MyBCA digital banking services.',
          ),
        ),
      ),
      barisMenu(
        Icons.description_outlined,
        t('Syarat & Ketentuan', 'Terms & Conditions'),
        onTap: () => bukaInfoDialog(
          t('Syarat & Ketentuan', 'Terms & Conditions'),
          t(
            'Dengan menggunakan MyBCA, pengguna setuju menjaga kerahasiaan PIN dan keamanan perangkat masing-masing.',
            'By using MyBCA, users agree to keep their PIN and device security confidential.',
          ),
        ),
      ),
      barisMenu(
        Icons.help_outline,
        t('Pusat Bantuan', 'Help Center'),
        onTap: () => bukaInfoDialog(
          t('Pusat Bantuan', 'Help Center'),
          t(
            'Butuh bantuan? Periksa menu Inbox atau gunakan fitur Lupa PIN di halaman Login jika terkendala akses akun.',
            'Need help? Check your Inbox or use Forgot PIN on the Login screen if you have trouble accessing your account.',
          ),
        ),
      ),
      barisMenu(
        Icons.support_agent,
        t('Hubungi Dukungan', 'Contact Support'),
        onTap: () => bukaInfoDialog(
          t('Hubungi Dukungan', 'Contact Support'),
          'Halo MyBCA Support\nEmail: support@mybca-demo.local\n24/7 Service.',
        ),
      ),
    ]);
  }

  Widget tombolKeluar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: keluar,
          icon: const Icon(Icons.logout),
          label: const Text('Logout', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                header(),
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            bagianPersonal(),
            bagianRekening(),
            bagianKeamanan(),
            bagianPengaturan(),
            tombolKeluar(),
          ],
        ),
      ),
    );
  }
}
