import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'app_style.dart';
import 'user_service.dart';

// =====================================================================
// Notification Preferences
// =====================================================================

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  final UserService userService = UserService();

  static const pilihan = [
    ['transaksi', 'Transaksi', 'Info setiap uang masuk dan keluar'],
    ['keamanan', 'Keamanan', 'Login baru, perubahan PIN, dan aktivitas akun'],
    ['promo', 'Promo & Informasi', 'Penawaran dan kabar terbaru dari Digeboy'],
  ];

  late Map<String, bool> pref;

  @override
  void initState() {
    super.initState();
    final mentah = widget.user['notifPrefs'];
    pref = {
      for (final p in pilihan)
        p[0]: (mentah is Map && mentah[p[0]] is bool) ? mentah[p[0]] : true,
    };
  }

  Future<void> ubah(String kunci, bool nilai) async {
    final lama = pref[kunci] ?? true;
    setState(() => pref[kunci] = nilai);
    try {
      await userService.updateProfil(widget.user['id'], {'notifPrefs': pref});
      widget.user['notifPrefs'] = Map<String, bool>.from(pref);
    } catch (e) {
      if (!mounted) return;
      setState(() => pref[kunci] = lama);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan pengaturan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Notification Preferences'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KartuBox(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: pilihan.map((p) {
                return SwitchListTile(
                  value: pref[p[0]] ?? true,
                  onChanged: (nilai) => ubah(p[0], nilai),
                  title: Text(
                    p[1],
                    style: TextStyle(color: context.teksUtama),
                  ),
                  subtitle: Text(p[2]),
                );
              }).toList(),
            ),
          ),
          const Text(
            'Pengaturan ini tersimpan di akunmu. Pengiriman notifikasi push '
            'belum aktif di versi demo.',
            style: TextStyle(color: AppColors.abu, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Language
// =====================================================================

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const bahasa = [
    ['id', 'Bahasa Indonesia'],
    ['en', 'English'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Language'),
      body: ValueListenableBuilder<String>(
        valueListenable: AppSettings.bahasa,
        builder: (context, dipilih, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              KartuBox(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: bahasa.map((b) {
                    return ListTile(
                      title: Text(
                        b[1],
                        style: TextStyle(color: context.teksUtama),
                      ),
                      trailing: dipilih == b[0]
                          ? const Icon(Icons.check_circle, color: AppColors.biru)
                          : const Icon(
                              Icons.circle_outlined,
                              color: AppColors.abu,
                            ),
                      onTap: () => AppSettings.setBahasa(b[0]),
                    );
                  }).toList(),
                ),
              ),
              const Text(
                'Pilihan bahasa tersimpan di HP ini. Terjemahan seluruh '
                'halaman belum tersedia, jadi sebagian besar teks masih '
                'berbahasa Indonesia.',
                style: TextStyle(color: AppColors.abu, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// Dark Mode / Light Mode
// =====================================================================

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  static const pilihan = [
    [ThemeMode.light, 'Light', 'Tampilan terang', Icons.light_mode_outlined],
    [ThemeMode.dark, 'Dark', 'Tampilan gelap', Icons.dark_mode_outlined],
    [
      ThemeMode.system,
      'System',
      'Ikuti pengaturan HP',
      Icons.settings_suggest_outlined,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Dark Mode / Light Mode'),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppSettings.themeMode,
        builder: (context, dipilih, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              KartuBox(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: pilihan.map((p) {
                    final mode = p[0] as ThemeMode;
                    return ListTile(
                      leading: Icon(p[3] as IconData, color: AppColors.biru),
                      title: Text(
                        p[1] as String,
                        style: TextStyle(color: context.teksUtama),
                      ),
                      subtitle: Text(p[2] as String),
                      trailing: dipilih == mode
                          ? const Icon(Icons.check_circle, color: AppColors.biru)
                          : const Icon(
                              Icons.circle_outlined,
                              color: AppColors.abu,
                            ),
                      onTap: () => AppSettings.setThemeMode(mode),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
