import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/setting_controller.dart';

class AccountSettingView extends StatelessWidget {
  const AccountSettingView({super.key});

  static const biru = Color(0xFF0B4C9A);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SettingController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: biru,
        foregroundColor: Colors.white,
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          _judul('KEAMANAN'),
          _menu(context, 'Ubah Password', () => _ubahPassword(context, c)),
          _menu(context, 'Ubah PIN', () => _ubahPin(context, c)),
          _menu(context, 'Ubah Email', () => _ubahEmail(context, c)),

          // Baris biometrik dengan switch (seperti sorotan di Gambar 1)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: biru, width: 2),
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: SwitchListTile(
              title: const Text(
                'Masuk dengan Biometrik',
                style: TextStyle(color: biru),
              ),
              value: c.setting.biometricEnabled,
              activeColor: Colors.white,
              activeTrackColor: biru,
              onChanged: (v) async {
                final error = await c.toggleBiometric(v);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
          ),

          _judul('AKUN'),
          _menu(context, 'Keluar', () => _keluar(context, c)),
          _menu(context, 'Masuk dengan BCA ID lain', () => _idLain(context)),
        ],
      ),
    );
  }

  Widget _judul(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      t,
      style: const TextStyle(
        color: biru,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    ),
  );

  Widget _menu(BuildContext context, String t, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          title: Text(t, style: const TextStyle(color: biru, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: biru),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  // ---------- Dialog Input (dipakai berulang) ----------
  Future<void> _dialogInput({
    required BuildContext context,
    required String title,
    required List<String> labels,
    required List<bool> obscure,
    required Future<String?> Function(List<String> values) onSubmit,
    List<TextInputType>? types,
  }) async {
    final ctrls = labels.map((_) => TextEditingController()).toList();
    String? error;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                TextField(
                  controller: ctrls[i],
                  obscureText: obscure[i],
                  keyboardType: types?[i],
                  decoration: InputDecoration(labelText: labels[i]),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final hasil = await onSubmit(
                  ctrls.map((e) => e.text.trim()).toList(),
                );
                if (hasil == null) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$title berhasil')));
                  }
                } else {
                  setState(() => error = hasil);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _ubahPassword(BuildContext context, SettingController c) => _dialogInput(
    context: context,
    title: 'Ubah Password',
    labels: ['Password lama', 'Password baru', 'Ulangi password baru'],
    obscure: [true, true, true],
    onSubmit: (v) async {
      if (v[1] != v[2]) return 'Konfirmasi password tidak sama';
      return c.changePassword(v[0], v[1]);
    },
  );

  void _ubahPin(BuildContext context, SettingController c) => _dialogInput(
    context: context,
    title: 'Ubah PIN',
    labels: ['PIN lama', 'PIN baru (6 digit)'],
    obscure: [true, true],
    types: [TextInputType.number, TextInputType.number],
    onSubmit: (v) => c.changePin(v[0], v[1]),
  );

  void _ubahEmail(BuildContext context, SettingController c) => _dialogInput(
    context: context,
    title: 'Ubah Email',
    labels: ['Email baru'],
    obscure: [false],
    types: [TextInputType.emailAddress],
    onSubmit: (v) => c.changeEmail(v[0]),
  );

  void _keluar(BuildContext context, SettingController c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await c.logout();
              if (context.mounted) {
                Navigator.pop(context); // tutup dialog
                Navigator.pop(context); // kembali ke Pengaturan
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _idLain(BuildContext context) {
    _dialogInput(
      context: context,
      title: 'Masuk dengan BCA ID lain',
      labels: ['BCA ID', 'Password'],
      obscure: [false, true],
      onSubmit: (v) async {
        if (v[0].isEmpty || v[1].isEmpty)
          return 'BCA ID dan password wajib diisi';
        return null;
      },
    );
  }
}
