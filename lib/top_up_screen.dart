import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'app_style.dart';
import 'user_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key, required this.user});
  final Map<String, dynamic> user;
  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final amount = TextEditingController();
  final pin = TextEditingController();
  final otherMerchant = TextEditingController();
  final db = FirebaseFirestore.instance;
  final users = UserService();
  String method = 'merchant';
  String merchant = 'Indomaret';
  bool loading = false;
  DocumentSnapshot<Map<String, dynamic>>? currentRequest;
  static const merchants = [
    'Indomaret',
    'Alfamart',
    'Alfamidi',
    'Lawson',
    'Other',
  ];

  String rupiah(int n) =>
      'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  void dispose() {
    amount.dispose();
    pin.dispose();
    otherMerchant.dispose();
    super.dispose();
  }

  Future<void> createRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final n = int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null ||
        n < 50000 ||
        n > 1000000 ||
        (method == 'merchant' && n % 50000 != 0)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Nominal minimal Rp50.000 dan maksimal Rp1.000.000. Untuk merchant, nominal harus kelipatan Rp50.000.',
          ),
        ),
      );
      return;
    }
    if (pin.text.length != 6 ||
        !await users.cekPin(widget.user['id'] as String, pin.text)) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN salah atau belum lengkap.')),
      );
      return;
    }
    if (!mounted) return;
    final provider = method == 'merchant'
        ? (merchant == 'Other' ? otherMerchant.text.trim() : merchant)
        : 'E-Wallet';
    if (provider.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Masukkan nama merchant.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final now = DateTime.now();
      final ref = db.collection('topup_requests').doc();
      await ref.set({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'amount': n,
        'method': method,
        'provider': provider,
        'accountOrMerchant': method == 'merchant'
            ? provider
            : '277${widget.user['rekening'] ?? ''}',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
        'requestCode': ref.id,
      });
      currentRequest = await ref.get();
      pin.clear();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat permintaan: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user['id'] as String;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Top Up Saldo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.biru,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo saat ini',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  rupiah((widget.user['saldo'] as num?)?.toInt() ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Pilih metode top up',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          RadioGroup<String>(
            groupValue: method,
            onChanged: (v) {
              if (v != null) setState(() => method = v);
            },
            child: const Column(
              children: [
                RadioListTile<String>(
                  value: 'merchant',
                  title: Text('Merchant'),
                  subtitle: Text(
                    'Indomaret, Alfamart, Alfamidi, Lawson, atau lainnya',
                  ),
                ),
                RadioListTile<String>(
                  value: 'ewallet',
                  title: Text('E-Wallet / Transfer'),
                ),
              ],
            ),
          ),
          if (method == 'merchant')
            DropdownButtonFormField<String>(
              initialValue: merchant,
              decoration: const InputDecoration(labelText: 'Pilih merchant'),
              items: merchants
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => merchant = v ?? 'Indomaret'),
            ),
          if (method == 'merchant' && merchant == 'Other')
            TextField(
              controller: otherMerchant,
              decoration: const InputDecoration(
                labelText: 'Nama merchant lainnya',
              ),
            ),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nominal (maksimal Rp1.000.000)',
            ),
          ),
          TextField(
            controller: pin,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Security PIN'),
          ),
          if (method == 'ewallet')
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                'Instruksi simulasi E-Wallet\nKode bank MyBCA: 277\nNomor tujuan: 277${widget.user['rekening'] ?? '-'}\nMasukkan nominal sesuai permintaan. Pembayaran akan diverifikasi admin; saldo tidak bertambah otomatis.',
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: loading ? null : createRequest,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Lanjutkan dan Buat Instruksi'),
          ),
          if (currentRequest != null) _requestCard(currentRequest!),
          const SizedBox(height: 20),
          const Text(
            'Riwayat permintaan top up',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('topup_requests')
                .where('uid', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Text('Gagal memuat riwayat: ${snapshot.error}');
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs.toList();
              docs.sort(
                (a, b) =>
                    ((b.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0)
                        .compareTo(
                          (a.data()['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0,
                        ),
              );
              if (docs.isEmpty)
                return const Text('Belum ada permintaan top up');
              return Column(
                children: docs.map((d) {
                  final x = d.data();
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${x['provider']} • ${rupiah((x['amount'] as num).toInt())}',
                      ),
                      subtitle: Text('Status: ${x['status']}'),
                      onTap: () => setState(() => currentRequest = d),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _requestCard(DocumentSnapshot<Map<String, dynamic>> snap) {
    final x = snap.data()!;
    final expires = (x['expiresAt'] as Timestamp).toDate();
    final active = DateTime.now().isBefore(expires) && x['status'] == 'pending';
    final payload =
        'MYBCA|TOPUP|${snap.id}|${x['uid']}|${x['amount']}|${expires.toIso8601String()}';
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Instruksi Top Up • ${x['status']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (x['method'] == 'merchant' && active)
              QrImageView(data: payload, size: 210),
            if (x['method'] == 'ewallet')
              Text(
                'Transfer simulasi ke 277${widget.user['rekening']}\nNominal: ${rupiah((x['amount'] as num).toInt())}',
              ),
            Text('Berlaku sampai: $expires'),
            Text(
              active
                  ? 'Instruksi masih aktif'
                  : 'Instruksi kedaluwarsa / sudah diproses',
            ),
            SelectableText(snap.id),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: snap.id)),
              icon: const Icon(Icons.copy),
              label: const Text('Salin kode permintaan'),
            ),
          ],
        ),
      ),
    );
  }
}
