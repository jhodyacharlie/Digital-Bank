import 'package:flutter/material.dart';

import 'akun.dart';
import 'app_style.dart';
import 'pembayaran_screen.dart';
import 'riwayat_transaksi.dart';
import 'status_transaksi_screen.dart';
import 'transaksi_repository.dart';

/// Beranda: saldo, tombol Pembayaran dan Status, serta 3 mutasi terakhir.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repo,
    required this.userId,
    this.pilihanAkun = const [],
    this.onGantiAkun,
  });

  final TransaksiRepository repo;
  final String userId;

  /// Khusus demo: kalau diisi, muncul tombol untuk berganti akun supaya
  /// kirim dan terima bisa dicoba dalam satu app.
  final List<Akun> pilihanAkun;
  final ValueChanged<String>? onGantiAkun;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<Akun> akunStream;
  late final Stream<List<RiwayatTransaksi>> riwayat;
  bool saldoTerlihat = false;

  @override
  void initState() {
    super.initState();
    akunStream = widget.repo.pantauAkun(widget.userId);
    riwayat = widget.repo.pantau(widget.userId, batas: 3);
  }

  void bukaPembayaran(Akun akun) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PembayaranScreen(repo: widget.repo, akun: akun),
      ),
    );
  }

  void bukaStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusTransaksiScreen(
          repo: widget.repo,
          userId: widget.userId,
        ),
      ),
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

  Widget kartuSaldo(Akun akun) {
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
                  saldoTerlihat ? rupiahTeks(akun.saldo) : 'Rp ••••••••',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.biruTua,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No. Rekening ${akun.rekening}',
                  style: const TextStyle(color: AppColors.abu, fontSize: 12),
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

  Widget bagianHeader(Akun akun) {
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
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  akun.nama.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.biru,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
                      akun.nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.pilihanAkun.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  tooltip: 'Ganti akun (demo)',
                  onSelected: (id) => widget.onGantiAkun?.call(id),
                  itemBuilder: (_) => widget.pilihanAkun
                      .map(
                        (a) => PopupMenuItem<String>(
                          value: a.id,
                          child: Text('${a.nama} (${a.rekening})'),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          kartuSaldo(akun),
        ],
      ),
    );
  }

  Widget tombolMenu(IconData ikon, String teks, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.biruMuda,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(ikon, color: AppColors.biru, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              teks,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.biruTua),
            ),
          ],
        ),
      ),
    );
  }

  Widget bagianMenu(Akun akun) {
    return kartuPutih(
      Row(
        children: [
          tombolMenu(
            Icons.receipt_long_outlined,
            'Pembayaran',
            () => bukaPembayaran(akun),
          ),
          tombolMenu(
            Icons.swap_vert,
            'Status Transaksi',
            bukaStatus,
          ),
        ],
      ),
    );
  }

  Widget barisTransaksi(RiwayatTransaksi t) {
    final tanda = t.masuk ? '+' : '-';
    final judul = t.masuk ? 'Terima dari ${t.nama}' : '${t.jenis} ke ${t.nama}';
    final warna = t.gagal
        ? AppColors.abu
        : (t.masuk ? Colors.green.shade700 : Colors.red.shade700);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.biruTua,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tanggalTeks(t.tanggal)} • ${t.labelStatus}',
                  style: const TextStyle(color: AppColors.abu, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$tanda${rupiahTeks(t.nominal)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: warna),
          ),
        ],
      ),
    );
  }

  Widget isiMutasi() {
    return StreamBuilder<List<RiwayatTransaksi>>(
      stream: riwayat,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Text(
            'Gagal memuat mutasi',
            style: TextStyle(color: AppColors.abu),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data!;
        if (data.isEmpty) {
          return const Text(
            'Belum ada transaksi',
            style: TextStyle(color: AppColors.abu),
          );
        }
        return Column(children: data.map(barisTransaksi).toList());
      },
    );
  }

  Widget bagianMutasi() {
    return kartuPutih(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mutasi Terakhir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.biruTua,
                  ),
                ),
              ),
              TextButton(
                onPressed: bukaStatus,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isiMutasi(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      body: StreamBuilder<Akun>(
        stream: akunStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat akun'));
          }
          final akun = snap.data;
          if (akun == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                bagianHeader(akun),
                bagianMenu(akun),
                bagianMutasi(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
