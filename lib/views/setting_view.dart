import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/setting_controller.dart';
import '../controllers/notification_controller.dart';
import '../login_screen.dart';
import '../services/locale_service.dart';
import 'widgets/menu_tile.dart';
import 'account_setting_view.dart';
import 'notification_view.dart';

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  String _t(String id, String en) => LocaleService.tr(id, en);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SettingController>();
    final s = c.setting;
    final unread = context.watch<NotificationController>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1456A5),
        foregroundColor: Colors.white,
        title: Text(_t('Pengaturan', 'Settings')),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangeNotifierProvider<NotificationController>.value(
                          value: context.read<NotificationController>(),
                          child: const NotificationView(),
                        ),
                  ),
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
          Container(
            width: double.infinity,
            color: const Color(0xFF1456A5),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Pengaturan', 'Settings'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                    'Atur aplikasi sesuai preferensi kamu',
                    'Customize the app to your preferences',
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

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
            subtitle: Text('${_t('ID Pengguna', 'User ID')}: ${s.userId}'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),

          SectionTitle(_t('PERSONALISASI', 'PERSONALIZATION')),
          MenuTile(
            icon: Icons.notifications_none,
            title: _t('Pengaturan Notifikasi', 'Notification Settings'),
            subtitle: _t(
              'Atur pemberitahuan aplikasi',
              'Manage app notifications',
            ),
            onTap: () => _showNotifSettings(context),
          ),
          MenuTile(
            icon: Icons.dark_mode_outlined,
            title: _t('Tema Aplikasi', 'App Theme'),
            subtitle: _t('Light / Dark Mode', 'Light / Dark Mode'),
            trailing: StatusBadge(
              s.isDarkMode ? 'Dark' : 'Light',
              color: Colors.blue,
            ),
            onTap: () => c.toggleDarkMode(!s.isDarkMode),
          ),
          MenuTile(
            icon: Icons.translate,
            title: _t('Bahasa', 'Language'),
            subtitle: s.language,
            onTap: () => _pilihBahasa(context, c),
          ),
          const Divider(),

          SectionTitle(_t('KEAMANAN', 'SECURITY')),
          MenuTile(
            icon: Icons.fingerprint,
            title: _t('Login Biometrik', 'Biometric Login'),
            subtitle: _t(
              'Gunakan sidik jari atau wajah',
              'Use fingerprint or face unlock',
            ),
            trailing: StatusBadge(
              s.biometricEnabled
                  ? _t('Aktif', 'Active')
                  : _t('Nonaktif', 'Off'),
              color: s.biometricEnabled ? Colors.green : Colors.grey,
            ),
            onTap: () => _openAccount(context),
          ),
          MenuTile(
            icon: Icons.lock_outline,
            title: _t('PIN Aplikasi', 'App PIN'),
            subtitle: _t('Pengaturan PIN keamanan', 'Security PIN settings'),
            trailing: StatusBadge(
              s.pinEnabled ? _t('Aktif', 'Active') : _t('Nonaktif', 'Off'),
              color: s.pinEnabled ? Colors.green : Colors.grey,
            ),
            onTap: () => _openAccount(context),
          ),
          MenuTile(
            icon: Icons.shield_outlined,
            title: _t('Keamanan Akun', 'Account Security'),
            subtitle: _t(
              'Pengaturan perlindungan akun',
              'Account protection settings',
            ),
            trailing: StatusBadge(
              s.accountProtection
                  ? _t('Aktif', 'Active')
                  : _t('Nonaktif', 'Off'),
              color: s.accountProtection ? Colors.green : Colors.grey,
            ),
            onTap: () => _openAccount(context),
          ),
          const Divider(),

          SectionTitle(_t('LAINNYA', 'OTHERS')),
          MenuTile(
            icon: Icons.info_outline,
            title: _t('Tentang Aplikasi', 'About App'),
            subtitle: _t(
              'Versi dan informasi aplikasi',
              'Version and app information',
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'MyBCA',
              applicationVersion: '1.0.0',
              applicationLegalese: 'MyBCA Digital Banking Flutter App',
            ),
          ),
          MenuTile(
            icon: Icons.logout,
            title: _t('Keluar dari Akun', 'Sign Out'),
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
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<SettingController>.value(
        value: context.read<SettingController>(),
        child: const AccountSettingView(),
      ),
    ),
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
        builder: (_, n, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _t('Pengaturan Notifikasi', 'Notification Settings'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SwitchListTile(
              title: Text(
                _t('Notifikasi Transaksi', 'Transaction Notifications'),
              ),
              value: n.notifTransaksi,
              onChanged: n.setTransaksi,
            ),
            SwitchListTile(
              title: Text(_t('Notifikasi Promo', 'Promo Notifications')),
              value: n.notifPromo,
              onChanged: n.setPromo,
            ),
            SwitchListTile(
              title: Text(
                _t('Notifikasi Info & Berita', 'Info & News Notifications'),
              ),
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
      builder: (dialogCtx) => AlertDialog(
        title: Text(_t('Keluar dari Akun', 'Sign Out')),
        content: Text(
          _t(
            'Apakah kamu yakin ingin keluar?',
            'Are you sure you want to sign out?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(_t('Batal', 'Cancel')),
          ),
          TextButton(
            onPressed: () async {
              await c.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(_t('Keluar', 'Sign Out')),
          ),
        ],
      ),
    );
  }
}
