import 'package:flutter/material.dart';

import 'app_style.dart';
import 'user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService userService = UserService();

  late TextEditingController namaController;
  late TextEditingController tglController;
  late TextEditingController alamatController;
  late TextEditingController negaraController;

  String gender = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.user['nama'] ?? '');
    tglController = TextEditingController(text: widget.user['tglLahir'] ?? '');
    alamatController = TextEditingController(text: widget.user['alamat'] ?? '');
    negaraController = TextEditingController(
      text: widget.user['kewarganegaraan'] ?? 'Indonesia',
    );
    gender = widget.user['gender'] ?? '';
  }

  @override
  void dispose() {
    namaController.dispose();
    tglController.dispose();
    alamatController.dispose();
    negaraController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> pilihTanggal() async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (tanggal == null) return;

    final hari = tanggal.day.toString().padLeft(2, '0');
    final bulan = tanggal.month.toString().padLeft(2, '0');
    tglController.text = '$hari/$bulan/${tanggal.year}';
  }

  Future<void> simpan() async {
    final nama = namaController.text.trim();
    if (nama.isEmpty) {
      pesan('Nama tidak boleh kosong');
      return;
    }

    final Map<String, dynamic> data = {
      'nama': nama,
      'tglLahir': tglController.text.trim(),
      'gender': gender,
      'alamat': alamatController.text.trim(),
      'kewarganegaraan': negaraController.text.trim(),
    };

    setState(() => loading = true);
    bool berhasil = true;
    try {
      await userService.updateProfil(widget.user['id'], data);
    } catch (e) {
      berhasil = false;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (!berhasil) {
      pesan('Gagal menyimpan profil');
      return;
    }
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: namaController,
              enabled: !loading,
              decoration: inputStyle(context, 'Full Name', Icons.person_outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tglController,
              readOnly: true,
              onTap: pilihTanggal,
              decoration: inputStyle(context, 'Date of Birth', Icons.cake_outlined),
            ),
            const SizedBox(height: 16),
            const Text('Gender', style: TextStyle(color: AppColors.abu)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: ['Male', 'Female']
                  .map(
                    (g) => ChoiceChip(
                      label: Text(g),
                      selected: gender == g,
                      onSelected: (_) => setState(() => gender = g),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alamatController,
              enabled: !loading,
              maxLines: 3,
              decoration: inputStyle(context, 'Address', Icons.home_outlined),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: negaraController,
              enabled: !loading,
              decoration: inputStyle(context, 'Nationality', Icons.flag_outlined),
            ),
            const SizedBox(height: 12),
            const Text(
              'Email dan nomor telepon tidak bisa diubah di versi demo.',
              style: TextStyle(color: AppColors.abu, fontSize: 12),
            ),
            const SizedBox(height: 24),
            TombolBiru(teks: 'Simpan', onPressed: simpan, loading: loading),
          ],
        ),
      ),
    );
  }
}
