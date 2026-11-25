import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'app_style.dart';
import 'change_pin_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screens.dart';
import 'login_screen.dart';
import 'security_screens.dart';
import 'settings_screens.dart';
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
  final ImagePicker picker = ImagePicker();

  late Map<String, dynamic> user;
  Uint8List? fotoBytes;
  String rekening = '...';
  bool biometrik = true;
  bool duaLangkah = false;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    duaLangkah = user['twoFactor'] == true;
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

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> buka(Widget halaman) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => halaman),
    );
    if (mounted) setState(() {});
  }

  Future<void> gantiPassword() async {
    final hash = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(user: user)),
    );
    if (hash == null || !mounted) return;
    setState(() => user['password'] = hash);
    pesan('Password berhasil disimpan');
  }

  Future<void> ubahDuaLangkah(bool nilai) async {
    final lolos = await tanyaPin(
      context,
      user,
      judul: nilai ? 'Aktifkan 2FA' : 'Matikan 2FA',
    );
    if (!lolos || !mounted) return;

    try {
      await userService.updateProfil(user['id'], {'twoFactor': nilai});
      user['twoFactor'] = nilai;
      if (!mounted) return;
      setState(() => duaLangkah = nilai);
      pesan(nilai ? 'Verifikasi 2 langkah aktif' : 'Verifikasi 2 langkah mati');
    } catch (e) {
      pesan('Gagal mengubah pengaturan');
    }
  }

  Future<void> pilihFoto(ImageSource sumber) async {
    try {
      final file = await picker.pickImage(
        source: sumber,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return;

      final namaFile = file.name.toLowerCase();
      final gambar = ['.jpg', '.jpeg', '.png', '.webp'].any(namaFile.endsWith);
      if (!gambar) {
        pesan('File harus berupa gambar');
        return;
      }

      final bytes = await file.readAsBytes();
      final fotoBase64 = base64Encode(bytes);
      await userService.simpanFoto(user['id'], fotoBase64);
      if (!mounted) return;
      setState(() {
        fotoBytes = bytes;
        user['foto'] = fotoBase64;
      });
    } catch (e) {
      pesan('Gagal menyimpan foto profil');
    }
  }

  void tampilPilihanFoto() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                pilihFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(ctx);
                pilihFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> keluar() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari Digeboy?'),
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
          GestureDetector(
            onTap: tampilPilihanFoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      fotoBytes != null ? MemoryImage(fotoBytes!) : null,
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.biru,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              pil('ID: ${user['id']}', Colors.white24),
              pil('Verified', Colors.green.shade600, ikon: Icons.verified),
              pil('Active', Colors.teal.shade600, ikon: Icons.check_circle),
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
        color: context.kartu,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.teksUtama,
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
              style: TextStyle(
                color: context.teksUtama,
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
                style: TextStyle(color: context.teksUtama),
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
      barisMenu(
        Icons.lock_outline,
        'Change Password',
        teks: user['password'] == null ? 'Belum diatur' : null,
        onTap: gantiPassword,
      ),
      barisMenu(Icons.pin_outlined, 'Change PIN', onTap: gantiPin),
      barisMenu(
        Icons.fingerprint,
        'Biometric Authentication',
        trailing: Switch(value: biometrik, onChanged: ubahBiometrik),
      ),
      barisMenu(
        Icons.security_outlined,
        'Two-Factor Authentication',
        trailing: Switch(value: duaLangkah, onChanged: ubahDuaLangkah),
      ),
      barisMenu(
        Icons.devices_outlined,
        'Manage Devices',
        onTap: () => buka(ManageDevicesScreen(user: user)),
      ),
      barisMenu(
        Icons.history,
        'Login Activity',
        onTap: () => buka(LoginActivityScreen(user: user)),
      ),
    ]);
  }

  Widget bagianPengaturan() {
    return kartu('Other Settings', [
      barisMenu(
        Icons.notifications_outlined,
        'Notification Preferences',
        onTap: () => buka(NotificationPrefsScreen(user: user)),
      ),
      barisMenu(
        Icons.language,
        'Language',
        teks: AppSettings.labelBahasa(AppSettings.bahasa.value),
        onTap: () => buka(const LanguageScreen()),
      ),
      barisMenu(
        Icons.brightness_6_outlined,
        'Dark Mode / Light Mode',
        teks: AppSettings.labelTema(AppSettings.themeMode.value),
        onTap: () => buka(const AppearanceScreen()),
      ),
      barisMenu(
        Icons.privacy_tip_outlined,
        'Privacy Policy',
        onTap: () => buka(const PrivacyPolicyScreen()),
      ),
      barisMenu(
        Icons.description_outlined,
        'Terms & Conditions',
        onTap: () => buka(const TermsScreen()),
      ),
      barisMenu(
        Icons.help_outline,
        'Help Center',
        onTap: () => buka(const HelpCenterScreen()),
      ),
      barisMenu(
        Icons.support_agent,
        'Contact Support',
        onTap: () => buka(ContactSupportScreen(user: user)),
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
      backgroundColor: context.latar,
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
