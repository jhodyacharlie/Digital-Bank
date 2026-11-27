import 'package:flutter/material.dart';

import 'app_style.dart';
import 'firestore_transaksi_repository.dart';
import 'pin_konfirmasi_screen.dart';
import 'user_service.dart';

class _MetodeTarikTunai {
  const _MetodeTarikTunai(this.nama, this.keterangan, this.ikon);

  final String nama;
  final String keterangan;
  final IconData ikon;
}

class TarikTunaiScreen extends StatefulWidget {
  const TarikTunaiScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<TarikTunaiScreen> createState() => _TarikTunaiScreenState();
}

class _TarikTunaiScreenState extends State<TarikTunaiScreen> {
  final UserService userService = UserService();

  static const _metode = [
    _MetodeTarikTunai(
      'Indomaret',
      'Tarik tunai tanpa kartu di gerai Indomaret',
      Icons.storefront_outlined,
    ),
    _MetodeTarikTunai(
      'Alfamart',
      'Tarik tunai tanpa kartu di gerai Alfamart',
      Icons.storefront_outlined,
    ),
    _MetodeTarikTunai(
      'Alfamidi',
      'Tarik tunai tanpa kartu di gerai Alfamidi',
      Icons.storefront_outlined,
    ),
    _MetodeTarikTunai(
      'ATM BCA',
      'Tarik tunai tanpa kartu lewat ATM BCA',
      Icons.local_atm_outlined,
    ),
    _MetodeTarikTunai(
      'ATM lainnya',
      'Tarik tunai tanpa kartu lewat ATM bank lain berlogo BCA',
      Icons.account_balance_outlined,
    ),
  ];

  static const _nominal = [50000, 100000, 200000, 500000];

  int _metodeTerpilih = 0;
  int? _nominalTerpilih;
  bool _loading = false;

  String _rupiah(int nilai) {
    final angka = nilai.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp$angka';
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _lanjutkan() async {
    final nominal = _nominalTerpilih;
    if (nominal == null) {
      _pesan('Pilih nominal terlebih dahulu');
      return;
    }

    final metode = _metode[_metodeTerpilih];
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi tarik tunai'),
        content: Text(
          'Metode: ${metode.nama}\n'
          'Nominal: ${_rupiah(nominal)}\n\n'
          'Saldo kamu akan dipotong sebesar ${_rupiah(nominal)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PinKonfirmasiScreen(
          repo: FirestoreTransaksiRepository(),
          userId: widget.user['id'] as String,
          keterangan: 'Tarik tunai ${_rupiah(nominal)} via ${metode.nama}',
        ),
      ),
    );
    if (!mounted || pin == null) return;

    setState(() => _loading = true);
    String? error;
    try {
      error = await userService.tarikTunai(
        widget.user['id'] as String,
        nominal,
        pin: pin,
        metode: metode.nama,
      );
    } catch (e) {
      error = 'Gagal terhubung ke server';
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _pesan(error);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: AppColors.biru),
        title: const Text('Tarik tunai berhasil'),
        content: Text(
          'Permintaan tarik tunai ${_rupiah(nominal)} via ${metode.nama} '
          'berhasil diproses. Saldo kamu sudah diperbarui.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Tarik Tunai'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.biru),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pilih tempat dan nominal, lalu konfirmasi dengan PIN. '
                    'Saldo kamu akan langsung terpotong setelah berhasil.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih tempat tarik tunai',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_metode.length, (index) {
            final metode = _metode[index];
            final aktif = index == _metodeTerpilih;
            return Card(
              color: aktif
                  ? AppColors.cardAlt(context)
                  : AppColors.card(context),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: aktif ? AppColors.biru : AppColors.border(context),
                ),
              ),
              child: ListTile(
                leading: Icon(metode.ikon, color: AppColors.biru),
                title: Text(
                  metode.nama,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(metode.keterangan),
                trailing: Icon(
                  aktif ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: aktif ? AppColors.biru : AppColors.abu,
                ),
                onTap: _loading
                    ? null
                    : () => setState(() => _metodeTerpilih = index),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Pilih nominal',
            style: TextStyle(
              color: AppColors.biruTua,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nominal.map((nilai) {
              return ChoiceChip(
                label: Text(_rupiah(nilai)),
                selected: _nominalTerpilih == nilai,
                selectedColor: AppColors.biru.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: _nominalTerpilih == nilai
                      ? AppColors.biruTua
                      : AppColors.abu,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: _loading
                    ? null
                    : (_) => setState(() => _nominalTerpilih = nilai),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TombolBiru(
            teks: 'Tarik Tunai',
            onPressed: _lanjutkan,
            loading: _loading,
          ),
        ],
      ),
    );
  }
}
