import 'package:flutter/material.dart';

import 'app_style.dart';
import 'home_screen.dart';
import 'memory_transaksi_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Payment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.biru),
        useMaterial3: true,
      ),
      home: const DemoShell(),
    );
  }
}

/// Pembungkus demo: data di memori + tombol ganti akun (budi, siti, andi).
/// Saat disambungkan ke app asli, ganti dengan HomeScreen langsung dan
/// repository Firestore (lihat README).
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  final MemoryTransaksiRepository repo = MemoryTransaksiRepository();
  String userId = 'budi';

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      key: ValueKey(userId),
      repo: repo,
      userId: userId,
      pilihanAkun: repo.daftarAkun,
      onGantiAkun: (id) => setState(() => userId = id),
    );
  }
}
