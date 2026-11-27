import 'package:flutter/material.dart';

import 'app_style.dart';
import 'history_page.dart';
import 'riwayat_transaksi.dart';
import 'struk_screen.dart';
import 'transaksi_repository.dart';

class StatusTransaksiScreen extends StatefulWidget {
  const StatusTransaksiScreen({
    super.key,
    required this.repo,
    required this.userId,
  });

  final TransaksiRepository repo;
  final String userId;

  @override
  State<StatusTransaksiScreen> createState() => _StatusTransaksiScreenState();
}

class _StatusTransaksiScreenState extends State<StatusTransaksiScreen> {
  static const daftarFilter = ['Semua', 'Terkirim', 'Diterima', 'Gagal'];

  late final Stream<List<RiwayatTransaksi>> riwayat;
  String filter = 'Semua';

  @override
  void initState() {
    super.initState();
    riwayat = widget.repo.pantau(widget.userId);
  }

  bool cocok(RiwayatTransaksi t) {
    switch (filter) {
      case 'Terkirim':
        return !t.masuk && t.berhasil;
      case 'Diterima':
        return t.masuk && t.berhasil;
      case 'Gagal':
        return t.gagal;
      default:
        return true;
    }
  }

  Widget barisFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: daftarFilter.map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: filter == f,
              onSelected: (_) => setState(() => filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget kartuTransaksi(RiwayatTransaksi t) {
    final warna = t.gagal
        ? AppColors.abu
        : (t.masuk ? Colors.green.shade700 : Colors.red.shade700);
    final tanda = t.masuk ? '+' : '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StrukScreen(struk: t)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.biruMuda,
              child: Icon(
                t.masuk ? Icons.south_west : Icons.north_east,
                color: AppColors.biru,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.biruTua,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.jenis} • ${tanggalTeks(t.tanggal)}',
                    style: const TextStyle(color: AppColors.abu, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$tanda${rupiahTeks(t.nominal)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: warna),
                ),
                const SizedBox(height: 4),
                LencanaStatus(transaksi: t),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget pesanTengah(String teks) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          teks,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.abu),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Status Transaksi'),
        actions: [
          IconButton(
            tooltip: 'Riwayat transaksi lengkap',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          barisFilter(),
          Expanded(
            child: StreamBuilder<List<RiwayatTransaksi>>(
              stream: riwayat,
              builder: (context, snap) {
                if (snap.hasError) {
                  return pesanTengah('Gagal memuat transaksi');
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data!.where(cocok).toList();
                if (data.isEmpty) {
                  return pesanTengah('Belum ada transaksi di sini');
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) => kartuTransaksi(data[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
