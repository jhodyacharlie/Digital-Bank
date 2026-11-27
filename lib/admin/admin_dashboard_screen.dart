import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_screen.dart';
import 'admin_service.dart';
import '../app_style.dart';
import '../promo/promo_screens.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final service = AdminService();
  late final TabController tabs = TabController(length: 3, vsync: this);
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  String money(num n) =>
      'Rp${n.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  Future<void> credit(String uid, String name) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah saldo • $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal rupiah'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Catatan admin'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.addBalance(
        uid,
        int.parse(amount.text),
        note.text.trim().isEmpty ? 'Penyesuaian saldo' : note.text.trim(),
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saldo berhasil ditambahkan')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg(context),
    appBar: AppBar(
      backgroundColor: AppColors.biru,
      foregroundColor: Colors.white,
      title: const Text('Admin Master'),
      actions: [
        IconButton(
          tooltip: 'Keluar',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
          },
        ),
      ],
      bottom: TabBar(
        controller: tabs,
        tabs: const [
          Tab(text: 'Pengguna'),
          Tab(text: 'Top Up'),
          Tab(text: 'Konten'),
        ],
      ),
    ),
    body: TabBarView(
      controller: tabs,
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.users(),
          builder: (context, snap) {
            if (snap.hasError)
              return Center(
                child: Text('Gagal memuat pengguna: ${snap.error}'),
              );
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                final u = d.data();
                final status = (u['verificationStatus'] ?? 'approved')
                    .toString();
                return Card(
                  child: ListTile(
                    title: Text((u['nama'] ?? 'Tanpa nama').toString()),
                    subtitle: Text(
                      '${u['email'] ?? '-'}\n${u['rekening'] ?? '-'} • ${money((u['saldo'] as num?) ?? 0)}\nStatus: $status',
                    ),
                    isThreeLine: true,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          (u['nama'] ?? 'Detail pengguna').toString(),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: u.entries
                                .where((e) => !['foto'].contains(e.key))
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text('${e.key}: ${e.value}'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          if (v == 'approve' || v == 'reject') {
                            await service.verifyUser(
                              d.id,
                              approve: v == 'approve',
                            );
                          }
                          if (v == 'credit') {
                            await credit(
                              d.id,
                              (u['nama'] ?? 'Pengguna').toString(),
                            );
                          }
                        } catch (e) {
                          if (mounted)
                            messenger.showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                        }
                      },
                      itemBuilder: (_) => [
                        if (status != 'approved')
                          const PopupMenuItem(
                            value: 'approve',
                            child: Text('Setujui akun'),
                          ),
                        if (status != 'rejected')
                          const PopupMenuItem(
                            value: 'reject',
                            child: Text('Tolak akun'),
                          ),
                        const PopupMenuItem(
                          value: 'credit',
                          child: Text('Tambah saldo'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.pendingTopUps(),
          builder: (context, snap) {
            if (snap.hasError)
              return Center(child: Text('Gagal memuat top up: ${snap.error}'));
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty)
              return const Center(
                child: Text('Tidak ada top up menunggu verifikasi'),
              );
            return ListView(
              children: docs.map((d) {
                final x = d.data();
                return Card(
                  child: ListTile(
                    title: Text(
                      '${x['provider']} • ${money((x['amount'] as num?) ?? 0)}',
                    ),
                    subtitle: Text(
                      'UID: ${x['uid']}\n${x['accountOrMerchant'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await service.reviewTopUp(
                            d.id,
                            approve: v == 'approve',
                          );
                        } catch (e) {
                          if (mounted)
                            messenger.showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'approve',
                          child: Text('Verifikasi dibayar'),
                        ),
                        PopupMenuItem(value: 'reject', child: Text('Tolak')),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        _ContentAdminLauncher(service: service),
      ],
    ),
  );
}

class _ContentAdminLauncher extends StatelessWidget {
  const _ContentAdminLauncher({required this.service});
  final AdminService service;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PromoComposerScreen()),
              ),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Buat Promo'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewsComposerScreen()),
              ),
              icon: const Icon(Icons.newspaper_outlined),
              label: const Text('Buat Berita'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Setelah dipublikasikan, promo & berita langsung muncul di halaman Promo & Berita dan mengirim notifikasi ke seluruh pengguna.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.abu),
      ),
      const SizedBox(height: 20),
      Text(
        'Promo Terpublikasi',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allPromos(),
        builder: (context, snap) {
          if (snap.hasError) return Text('Gagal memuat promo: ${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Card(child: ListTile(title: Text('Belum ada promo')));
          }
          return Column(
            children: docs.map((d) {
              final x = d.data();
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.biru,
                  ),
                  title: Text((x['title'] ?? '-').toString()),
                  subtitle: Text(
                    (x['description'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Hapus promo',
                    onPressed: () => service.deletePromo(d.id),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      const SizedBox(height: 20),
      Text(
        'Berita Terpublikasi',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allNews(),
        builder: (context, snap) {
          if (snap.hasError) return Text('Gagal memuat berita: ${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Card(child: ListTile(title: Text('Belum ada berita')));
          }
          return Column(
            children: docs.map((d) {
              final x = d.data();
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.newspaper_outlined,
                    color: AppColors.biru,
                  ),
                  title: Text((x['title'] ?? '-').toString()),
                  subtitle: Text(
                    (x['summary'] ?? x['body'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Hapus berita',
                    onPressed: () => service.deleteNews(d.id),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}
