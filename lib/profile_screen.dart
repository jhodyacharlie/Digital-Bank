import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'change_pin_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

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
    user = widget.user;
    final foto = user['foto'];
    if (foto != null) {
      fotoBytes = base64Decode(foto);
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
    final nama = user['nama'] as String;

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
                    nama.substring(0, 1),
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
            user['email'] as String,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            user['phone'] as String,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pil('ID: ${user['id']}', Colors.white24),
              const SizedBox(width: 8),
              pil('Verified', Colors.green.shade600, ikon: Icons.verified),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.biruTua,
            ),
          ),
          const SizedBox(height: 8),
          ...sisipGaris(isi),
        ],
      ),
    );
  }

  Widget barisInfo(String label, String isi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: AppColors.abu)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              isi,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.biruTua,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
            Icon(ikon, color: AppColors.biru),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                judul,
                style: const TextStyle(color: AppColors.biruTua),
              ),
            ),
            if (teks != null)
              Text(teks, style: const TextStyle(color: AppColors.abu)),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right, color: AppColors.abu),
          ],
        ),
      ),
    );
  }

  Widget bagianPersonal() {
    return kartu('Personal Information', [
      barisInfo('Full Name', user['nama'] as String),
      barisInfo('Date of Birth', nilai('tglLahir', '-')),
      barisInfo('Gender', nilai('gender', '-')),
      barisInfo('Email Address', user['email'] as String),
      barisInfo('Phone Number', user['phone'] as String),
      barisInfo('Address', nilai('alamat', '-')),
      barisInfo('Nationality', nilai('kewarganegaraan', 'Indonesia')),
    ]);
  }

  Widget bagianRekening() {
    return kartu('Account Information', [
      barisInfo('Account Number', rekening),
      barisInfo('Account Type', nilai('tipeRekening', 'Savings')),
      barisInfo('Account Name', (user['nama'] as String).toUpperCase()),
      barisInfo('Branch Name', nilai('cabang', 'KCU Jakarta')),
      barisInfo('Account Status', 'Active'),
      barisInfo('Member Since', nilai('memberSince', 'Januari 2025')),
    ]);
  }

  Widget bagianKeamanan() {
    return kartu('Security & Privacy', [
      barisMenu(Icons.lock_outline, 'Change Password'),
      barisMenu(Icons.pin_outlined, 'Change PIN', onTap: gantiPin),
      barisMenu(
        Icons.fingerprint,
        'Biometric Authentication',
        trailing: Switch(value: biometrik, onChanged: ubahBiometrik),
      ),
      barisMenu(
        Icons.security_outlined,
        'Two-Factor Authentication',
        teks: 'Off',
      ),
      barisMenu(Icons.devices_outlined, 'Manage Devices'),
      barisMenu(Icons.history, 'Login Activity'),
    ]);
  }

  Widget bagianPengaturan() {
    return kartu('Other Settings', [
      barisMenu(Icons.notifications_outlined, 'Notification Preferences'),
      barisMenu(Icons.language, 'Language', teks: 'Bahasa Indonesia'),
      barisMenu(Icons.brightness_6_outlined, 'Dark Mode / Light Mode', teks: 'Light'),
      barisMenu(Icons.privacy_tip_outlined, 'Privacy Policy'),
      barisMenu(Icons.description_outlined, 'Terms & Conditions'),
      barisMenu(Icons.help_outline, 'Help Center'),
      barisMenu(Icons.support_agent, 'Contact Support'),
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
      backgroundColor: AppColors.biruMuda,
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
