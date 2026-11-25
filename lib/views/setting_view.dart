import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/setting_controller.dart';
import '../controllers/notification_controller.dart';
import 'widgets/menu_tile.dart';
import 'account_setting_view.dart';
import 'notification_view.dart';

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SettingController>();
    final s = c.setting;
    final unread = context.watch<NotificationController>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1456A5),
        foregroundColor: Colors.white,
        title: const Text('Pengaturan'),
        centerTitle: true,
        actions: [
          // Ikon lonceng + badge jumlah notifikasi belum dibaca
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationView()),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$unread',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // ===== Header biru =====
          Container(
            width: double.infinity,
            color: const Color(0xFF1456A5),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengaturan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Atur aplikasi sesuai preferensi kamu',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          // ===== Gagal memuat data akun dari Firebase =====
          if (c.loadError != null)
            Container(
              width: double.infinity,
              color: Colors.red.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                c.loadError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // ===== Kartu profil =====
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE3EEFB),
              child: Icon(Icons.person_outline, color: Color(0xFF1456A5)),
            ),
            title: Text(
              s.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID Pengguna: ${s.userId}'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),

          // ===== PERSONALISASI =====
          const SectionTitle('PERSONALISASI'),
          MenuTile(
            icon: Icons.notifications_none,
            title: 'Pengaturan Notifikasi',
            subtitle: 'Atur pemberitahuan aplikasi',
            onTap: () => _showNotifSettings(context),
          ),
          MenuTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema Aplikasi',
            subtitle: 'Light / Dark Mode',
            trailing: StatusBadge(
              s.isDarkMode ? 'Dark' : 'Light',
              color: Colors.blue,
            ),
            onTap: () => c.toggleDarkMode(!s.isDarkMode),
          ),
          MenuTile(
            icon: Icons.translate,
            title: 'Bahasa',
            subtitle: s.language,
            onTap: () => _pilihBahasa(context, c),
          ),
          const Divider(),

          // ===== KEAMANAN =====
          const SectionTitle('KEAMANAN'),
          MenuTile(
            icon: Icons.fingerprint,
            title: 'Login Biometrik',
            subtitle: 'Gunakan sidik jari atau wajah',
            trailing: StatusBadge(
              s.biometricEnabled ? 'Aktif' : 'Nonaktif',
              color: s.biometricEnabled ? Colors.green : Colors.grey,
            ),
            onTap: () => _openAccount(context),
          ),
          MenuTile(
            icon: Icons.lock_outline,
            title: 'PIN Aplikasi',
            subtitle: 'Pengaturan PIN keamanan',
            trailing: StatusBadge(
              s.pinEnabled ? 'Aktif' : 'Nonaktif',
              color: s.pinEnabled ? Colors.green : Colors.grey,
            ),
            onTap: () => _openAccount(context),
          ),
          MenuTile(
            icon: Icons.shield_outlined,
            title: 'Keamanan Akun',
            subtitle: 'Pengaturan perlindungan akun',
            trailing: StatusBadge(
              s.accountProtection ? 'Aktif' : 'Nonaktif',
              color: s.accountProtection ? Colors.green : Colors.grey,
            ),
            onTap: () => _openAccount(context),
          ),
          const Divider(),

          // ===== LAINNYA =====
          const SectionTitle('LAINNYA'),
          MenuTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi dan informasi aplikasi',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'myBCA',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Aplikasi latihan Flutter',
            ),
          ),
          MenuTile(
            icon: Icons.logout,
            title: 'Keluar dari Akun',
            color: Colors.redAccent,
            trailing: const SizedBox.shrink(),
            onTap: () => _konfirmasiKeluar(context, c),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openAccount(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AccountSettingView()),
  );

  void _pilihBahasa(BuildContext context, SettingController c) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Bahasa Indonesia', 'English'].map((b) {
          return ListTile(
            title: Text(b),
            trailing: c.setting.language == b
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              c.setLanguage(b);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showNotifSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer<NotificationController>(
        builder: (_, n, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pengaturan Notifikasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SwitchListTile(
              title: const Text('Notifikasi Transaksi'),
              value: n.notifTransaksi,
              onChanged: n.setTransaksi,
            ),
            SwitchListTile(
              title: const Text('Notifikasi Promo'),
              value: n.notifPromo,
              onChanged: n.setPromo,
            ),
            SwitchListTile(
              title: const Text('Notifikasi Info'),
              value: n.notifInfo,
              onChanged: n.setInfo,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _konfirmasiKeluar(BuildContext context, SettingController c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await c.logout();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Berhasil keluar')),
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
