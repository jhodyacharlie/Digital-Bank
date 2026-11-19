import 'package:flutter/material.dart';

import 'app_style.dart';
import 'login_screen.dart';

class FiturMenu {
  const FiturMenu(this.nama, this.ikon);

  final String nama;
  final IconData ikon;
}

class Transaksi {
  const Transaksi(this.judul, this.tanggal, this.nominal);

  final String judul;
  final String tanggal;
  final int nominal;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool saldoTerlihat = false;

  static const daftarMenu = [
    FiturMenu('Info', Icons.account_balance_wallet_outlined),
    FiturMenu('Transfer', Icons.swap_horiz),
    FiturMenu('Pembayaran', Icons.receipt_long_outlined),
    FiturMenu('Pembelian', Icons.shopping_bag_outlined),
    FiturMenu('QRIS', Icons.qr_code_scanner),
    FiturMenu('Tarik Tunai', Icons.atm),
    FiturMenu('Kartu', Icons.credit_card),
    FiturMenu('Investasi', Icons.trending_up),
  ];

  static const daftarTransaksi = [
    Transaksi('Transfer ke Siti Aminah', '18 Nov 2026', -250000),
    Transaksi('Pembayaran Listrik', '17 Nov 2026', -385000),
    Transaksi('Setoran Tunai', '15 Nov 2026', 1000000),
  ];

  String formatRupiah(int angka) {
    final teks = angka.abs().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
        );
    return 'Rp $teks';
  }

  Future<void> konfirmasiKeluar() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
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

    if (keluar != true || !mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget kartuPutih(Widget isi) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isi,
    );
  }

  Widget kartuSaldo(int saldo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tabungan Utama',
                  style: TextStyle(color: AppColors.abu),
                ),
                const SizedBox(height: 6),
                Text(
                  saldoTerlihat ? formatRupiah(saldo) : 'Rp ••••••••',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.biruTua,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => saldoTerlihat = !saldoTerlihat),
            icon: Icon(
              saldoTerlihat
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.biru,
            ),
          ),
        ],
      ),
    );
  }

  Widget bagianHeader(String nama, int saldo) {
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  nama.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.biru,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: konfirmasiKeluar,
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          kartuSaldo(saldo),
        ],
      ),
    );
  }

  Widget itemMenu(FiturMenu menu) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.biruMuda,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(menu.ikon, color: AppColors.biru, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          menu.nama,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.biruTua),
        ),
      ],
    );
  }

  Widget bagianMenu() {
    return kartuPutih(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Utama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.biruTua,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: daftarMenu.map(itemMenu).toList(),
          ),
        ],
      ),
    );
  }

  Widget bagianPromo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.biru, Color(0xFF1E8FD5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo MyBCA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Nikmati kemudahan transaksi setiap hari.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget barisTransaksi(Transaksi t) {
    final masuk = t.nominal > 0;
    final tanda = masuk ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.biruTua,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.tanggal,
                  style: const TextStyle(color: AppColors.abu, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$tanda${formatRupiah(t.nominal)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: masuk ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget bagianMutasi() {
    return kartuPutih(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mutasi Terakhir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.biruTua,
            ),
          ),
          const SizedBox(height: 8),
          ...daftarTransaksi.map(barisTransaksi),
        ],
      ),
    );
  }

  Widget itemBawah(IconData ikon, String teks, bool aktif) {
    final warna = aktif ? AppColors.biru : AppColors.abu;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, color: warna),
        const SizedBox(height: 4),
        Text(teks, style: TextStyle(fontSize: 11, color: warna)),
      ],
    );
  }

  Widget menuBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            itemBawah(Icons.home_filled, 'Beranda', true),
            itemBawah(Icons.local_offer_outlined, 'Promo', false),
            itemBawah(Icons.qr_code_2, 'QRIS', false),
            itemBawah(Icons.mail_outline, 'Inbox', false),
            itemBawah(Icons.person_outline, 'Profil', false),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.user['nama'] as String;
    final saldo = (widget.user['saldo'] as num).toInt();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) konfirmasiKeluar();
      },
      child: Scaffold(
        backgroundColor: AppColors.biruMuda,
        body: SingleChildScrollView(
          child: Column(
            children: [
              bagianHeader(nama, saldo),
              bagianMenu(),
              bagianPromo(),
              bagianMutasi(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: menuBawah(),
      ),
    );
  }
}
