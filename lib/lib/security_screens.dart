import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'security_service.dart';
import 'user_service.dart';

/// Dialog minta PIN untuk aksi sensitif. Mengembalikan true kalau PIN benar.
Future<bool> tanyaPin(
  BuildContext context,
  Map<String, dynamic> user, {
  String judul = 'Konfirmasi dengan PIN',
}) async {
  final controller = TextEditingController();
  final userService = UserService();
  String? error;
  bool loading = false;

  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) {
        Future<void> cek() async {
          setDialog(() {
            loading = true;
            error = null;
          });
          bool benar = false;
          try {
            benar = await userService.cekPin(user['id'], controller.text);
          } catch (e) {
            benar = false;
          }
          if (!ctx.mounted) return;
          if (benar) {
            Navigator.pop(ctx, true);
          } else {
            setDialog(() {
              loading = false;
              error = 'PIN salah';
            });
          }
        }

        return AlertDialog(
          title: Text(judul),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: 'PIN 6 angka',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: loading ? null : cek,
              child: const Text('Lanjut'),
            ),
          ],
        );
      },
    ),
  );
  return hasil == true;
}

// =====================================================================
// Verifikasi 2 langkah (dipakai saat login kalau 2FA aktif)
// =====================================================================

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final SecurityService security = SecurityService();
  final TextEditingController kodeController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => kirimKode());
  }

  @override
  void dispose() {
    kodeController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> kirimKode() async {
    if (!mounted) return;
    setState(() => loading = true);
    String? kode;
    try {
      kode = await security.buatOtp(widget.user['id']);
    } catch (e) {
      pesan('Gagal mengirim kode');
    }
    if (!mounted) return;
    setState(() => loading = false);
    if (kode == null) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kode verifikasi dikirim'),
        content: Text(
          'MODE DEMO: kode verifikasi kamu adalah $kode\n\n'
          'Di aplikasi sungguhan kode dikirim lewat SMS atau email, '
          'bukan ditampilkan di layar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> verifikasi() async {
    final kode = kodeController.text.trim();
    if (kode.length != 6) {
      pesan('Masukkan 6 angka kode');
      return;
    }

    setState(() => loading = true);
    bool benar = false;
    try {
      benar = await security.cekOtp(widget.user['id'], kode);
    } catch (e) {
      benar = false;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (!benar) {
      pesan('Kode salah atau sudah kadaluarsa');
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Verifikasi 2 Langkah'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akun ini memakai verifikasi 2 langkah. '
              'Masukkan 6 angka kode yang kami kirim.',
              style: TextStyle(color: AppColors.abu),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: kodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: inputStyle(
                context,
                'Kode verifikasi',
                Icons.sms_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TombolBiru(teks: 'Verifikasi', onPressed: verifikasi, loading: loading),
            Center(
              child: TextButton(
                onPressed: loading ? null : kirimKode,
                child: const Text('Kirim ulang kode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Change Password
// =====================================================================

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final SecurityService security = SecurityService();
  final UserService userService = UserService();

  final lamaController = TextEditingController();
  final baruController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool lihatBaru = false;
  bool lihatKonfirmasi = false;
  bool loading = false;

  bool get sudahPunyaPassword => widget.user['password'] != null;

  String get baru => baruController.text;

  bool get minDelapan => baru.length >= 8;
  bool get huruf =>
      RegExp(r'[A-Z]').hasMatch(baru) &&
      RegExp(r'[a-z]').hasMatch(baru) &&
      RegExp(r'\d').hasMatch(baru);
  bool get simbol => RegExp(r'[^A-Za-z0-9]').hasMatch(baru);
  bool get sama => baru.isNotEmpty && baru == konfirmasiController.text;

  bool get formValid =>
      lamaController.text.isNotEmpty && minDelapan && huruf && simbol && sama;

  @override
  void dispose() {
    lamaController.dispose();
    baruController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> simpan() async {
    if (!formValid || loading) return;
    final id = widget.user['id'] as String;

    setState(() => loading = true);
    String? hash;
    String? error;
    try {
      final benar = sudahPunyaPassword
          ? await security.cekPassword(id, lamaController.text)
          : await userService.cekPin(id, lamaController.text);
      if (!benar) {
        error = sudahPunyaPassword ? 'Password saat ini salah' : 'PIN salah';
      } else {
        hash = await security.simpanPassword(id, baru);
      }
    } catch (e) {
      error = 'Gagal terhubung ke server';
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (hash == null) {
      pesan(error ?? 'Gagal menyimpan password');
      return;
    }
    Navigator.pop(context, hash);
  }

  InputDecoration dekor(String label, IconData ikon, {Widget? suffix}) {
    return inputStyle(context, label, ikon).copyWith(suffixIcon: suffix);
  }

  Widget tombolMata(bool terlihat, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        terlihat ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.abu,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Change Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sudahPunyaPassword
                  ? 'Masukkan password saat ini, lalu buat password baru.'
                  : 'Kamu belum punya password. Masukkan PIN untuk '
                      'memverifikasi, lalu buat password.',
              style: const TextStyle(color: AppColors.abu),
            ),
            const SizedBox(height: 4),
            const Text(
              'Login tetap memakai PIN 6 angka.',
              style: TextStyle(color: AppColors.abu, fontSize: 12),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: lamaController,
              enabled: !loading,
              obscureText: true,
              keyboardType:
                  sudahPunyaPassword ? TextInputType.text : TextInputType.number,
              inputFormatters: sudahPunyaPassword
                  ? null
                  : [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
              onChanged: (_) => setState(() {}),
              decoration: dekor(
                sudahPunyaPassword ? 'Password saat ini' : 'PIN kamu',
                Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: baruController,
              enabled: !loading,
              obscureText: !lihatBaru,
              onChanged: (_) => setState(() {}),
              decoration: dekor(
                'Password baru',
                Icons.lock_reset,
                suffix: tombolMata(
                  lihatBaru,
                  () => setState(() => lihatBaru = !lihatBaru),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 12),
              child: Column(
                children: [
                  SyaratItem('Minimal 8 karakter', minDelapan),
                  SyaratItem('Ada huruf besar, huruf kecil, dan angka', huruf),
                  SyaratItem('Ada minimal 1 karakter spesial', simbol),
                ],
              ),
            ),
            TextField(
              controller: konfirmasiController,
              enabled: !loading,
              obscureText: !lihatKonfirmasi,
              onChanged: (_) => setState(() {}),
              decoration: dekor(
                'Konfirmasi password baru',
                Icons.lock_reset,
                suffix: tombolMata(
                  lihatKonfirmasi,
                  () => setState(() => lihatKonfirmasi = !lihatKonfirmasi),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
              child: SyaratItem('Password dan konfirmasi sama', sama),
            ),
            const SizedBox(height: 24),
            TombolBiru(
              teks: 'Simpan Password',
              onPressed: formValid ? simpan : () {},
              loading: loading,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Manage Devices
// =====================================================================

class ManageDevicesScreen extends StatefulWidget {
  const ManageDevicesScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ManageDevicesScreen> createState() => _ManageDevicesScreenState();
}

class _ManageDevicesScreenState extends State<ManageDevicesScreen> {
  final SecurityService security = SecurityService();

  List<Map<String, dynamic>>? perangkat;
  String idIni = '';
  String? error;

  @override
  void initState() {
    super.initState();
    muat();
  }

  Future<void> muat() async {
    try {
      final ini = await security.perangkatIni();
      final daftar = await security.daftarPerangkat(widget.user['id']);
      if (!mounted) return;
      setState(() {
        idIni = ini.id;
        perangkat = daftar;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Gagal memuat daftar perangkat');
    }
  }

  Future<void> hapus(Map<String, dynamic> p) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus perangkat'),
        content: Text('Hapus ${p['nama']} dari daftar perangkat terpercaya?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (setuju != true) return;

    try {
      await security.hapusPerangkat(widget.user['id'], p['id']);
      await muat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus perangkat')),
      );
    }
  }

  Widget baris(Map<String, dynamic> p) {
    final ini = p['id'] == idIni;
    final id = p['id'] as String;
    final kode = id.length > 6 ? id.substring(id.length - 6) : id;
    final aktif = formatWaktu((p['terakhirAktif'] ?? 0) as int);

    return KartuBox(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.smartphone, color: AppColors.biru, size: 32),
        title: Text(
          p['nama'] ?? 'Perangkat',
          style: TextStyle(
            color: context.teksUtama,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('Terakhir aktif: $aktif\nID: …$kode'),
        isThreeLine: true,
        trailing: ini
            ? Chip(
                label: const Text('Perangkat ini'),
                backgroundColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: Colors.green.shade900,
                  fontSize: 11,
                ),
                visualDensity: VisualDensity.compact,
              )
            : IconButton(
                onPressed: () => hapus(p),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
              ),
      ),
    );
  }

  Widget isi() {
    if (error != null) {
      return Center(child: Text(error!));
    }
    final daftar = perangkat;
    if (daftar == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (daftar.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada perangkat tercatat.',
          style: TextStyle(color: AppColors.abu),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Perangkat yang pernah dipakai masuk ke akunmu.',
            style: TextStyle(color: AppColors.abu),
          ),
        ),
        ...daftar.map(baris),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Manage Devices'),
      body: RefreshIndicator(onRefresh: muat, child: isi()),
    );
  }
}

// =====================================================================
// Login Activity
// =====================================================================

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  final SecurityService security = SecurityService();

  List<Map<String, dynamic>>? aktivitas;
  String? error;

  @override
  void initState() {
    super.initState();
    muat();
  }

  Future<void> muat() async {
    try {
      final data = await security.aktivitasLogin(widget.user['id']);
      if (!mounted) return;
      setState(() {
        aktivitas = data;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Gagal memuat aktivitas login');
    }
  }

  Widget baris(Map<String, dynamic> a) {
    final berhasil = a['berhasil'] == true;
    final catatan = a['catatan'];
    final waktu = formatWaktu((a['waktu'] ?? 0) as int);

    return KartuBox(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          berhasil ? Icons.check_circle : Icons.cancel,
          color: berhasil ? Colors.green.shade600 : Colors.red.shade600,
        ),
        title: Text(
          '${berhasil ? 'Login berhasil' : 'Login gagal'} • ${a['metode']}',
          style: TextStyle(
            color: context.teksUtama,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${a['perangkat'] ?? '-'}\n$waktu'
          '${catatan != null ? '\n$catatan' : ''}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget isi() {
    if (error != null) {
      return Center(child: Text(error!));
    }
    final daftar = aktivitas;
    if (daftar == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (daftar.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada aktivitas login.',
          style: TextStyle(color: AppColors.abu),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '30 aktivitas login terakhir. Kalau ada yang tidak kamu kenali, '
            'segera ganti PIN.',
            style: TextStyle(color: AppColors.abu),
          ),
        ),
        ...daftar.map(baris),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Login Activity'),
      body: RefreshIndicator(onRefresh: muat, child: isi()),
    );
  }
}
