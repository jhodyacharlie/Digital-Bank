import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'firestore_transaksi_repository.dart';
import 'pin_konfirmasi_screen.dart';
import 'user_service.dart';

class _ProdukPembelian {
  const _ProdukPembelian(this.nama, this.keterangan, this.harga);

  final String nama;
  final String keterangan;
  final int harga;
}

class _KategoriPembelian {
  const _KategoriPembelian(this.nama, this.ikon, this.produk);

  final String nama;
  final IconData ikon;
  final List<_ProdukPembelian> produk;
}

class PembelianScreen extends StatefulWidget {
  const PembelianScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<PembelianScreen> createState() => _PembelianScreenState();
}

class _PembelianScreenState extends State<PembelianScreen> {
  final UserService userService = UserService();

  static const _kategori = [
    _KategoriPembelian('Pulsa', Icons.phone_android, [
      _ProdukPembelian('Pulsa Rp5.000', 'Masa aktif 30 hari', 5000),
      _ProdukPembelian('Pulsa Rp10.000', 'Masa aktif 30 hari', 10000),
      _ProdukPembelian('Pulsa Rp25.000', 'Masa aktif 30 hari', 25000),
      _ProdukPembelian('Pulsa Rp50.000', 'Masa aktif 30 hari', 50000),
    ]),
    _KategoriPembelian('Paket Data', Icons.wifi, [
      _ProdukPembelian('Paket 1 GB', 'Masa aktif 7 hari', 10000),
      _ProdukPembelian('Paket 3 GB', 'Masa aktif 30 hari', 25000),
      _ProdukPembelian('Paket 8 GB', 'Masa aktif 30 hari', 50000),
    ]),
    _KategoriPembelian('Token PLN', Icons.bolt, [
      _ProdukPembelian('Token Rp20.000', 'Token listrik prabayar', 20000),
      _ProdukPembelian('Token Rp50.000', 'Token listrik prabayar', 50000),
      _ProdukPembelian('Token Rp100.000', 'Token listrik prabayar', 100000),
    ]),
    _KategoriPembelian('BPJS', Icons.health_and_safety_outlined, [
      _ProdukPembelian('Iuran BPJS', 'Tagihan 1 bulan Rp35.000', 35000),
      _ProdukPembelian('Iuran BPJS', 'Tagihan 1 bulan Rp100.000', 100000),
    ]),
    _KategoriPembelian('Asuransi', Icons.shield_outlined, [
      _ProdukPembelian('Premi Asuransi', 'Tagihan 1 bulan Rp25.000', 25000),
      _ProdukPembelian('Premi Asuransi', 'Tagihan 1 bulan Rp50.000', 50000),
    ]),
  ];

  final _tujuanController = TextEditingController();
  int _kategoriTerpilih = 0;
  int? _produkTerpilih;
  bool _loading = false;

  @override
  void dispose() {
    _tujuanController.dispose();
    super.dispose();
  }

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
    final tujuan = _tujuanController.text.trim();
    if (_produkTerpilih == null) {
      _pesan('Pilih produk terlebih dahulu');
      return;
    }
    if (!RegExp(r'^\d{8,16}$').hasMatch(tujuan)) {
      _pesan('Masukkan nomor tujuan / ID pelanggan (8–16 digit)');
      return;
    }

    final kategori = _kategori[_kategoriTerpilih];
    final produk = kategori.produk[_produkTerpilih!];
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi pembelian'),
        content: Text(
          '${kategori.nama}\n${produk.nama} • ${produk.keterangan}\n'
          'Total: ${_rupiah(produk.harga)}\n'
          'Tujuan: $tujuan\n\n'
          'Saldo kamu akan dipotong sebesar ${_rupiah(produk.harga)}.',
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
          keterangan: '${produk.nama} ke $tujuan',
        ),
      ),
    );
    if (!mounted || pin == null) return;

    setState(() => _loading = true);
    String? error;
    try {
      error = await userService.belanjaProduk(
        widget.user['id'] as String,
        produk.harga,
        pin: pin,
        namaProduk: produk.nama,
        tujuan: tujuan,
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
        title: const Text('Pembelian berhasil'),
        content: Text(
          '${produk.nama} untuk $tujuan berhasil diproses. Saldo kamu '
          'sudah diperbarui.',
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
    final kategori = _kategori[_kategoriTerpilih];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Pembelian'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          Text(
            'Pilih kategori',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: _kategori.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final item = _kategori[index];
              final aktif = index == _kategoriTerpilih;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _loading
                    ? null
                    : () => setState(() {
                        _kategoriTerpilih = index;
                        _produkTerpilih = null;
                      }),
                child: Container(
                  decoration: BoxDecoration(
                    color: aktif ? AppColors.biru : AppColors.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: aktif ? AppColors.biru : AppColors.border(context),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.ikon,
                        size: 20,
                        color: aktif ? Colors.white : AppColors.accent(context),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          item.nama,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: aktif
                                ? Colors.white
                                : AppColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih produk',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: _produkTerpilih,
            onChanged: (value) {
              if (_loading) return;
              setState(() => _produkTerpilih = value);
            },
            child: Column(
              children: List.generate(kategori.produk.length, (index) {
                final produk = kategori.produk[index];
                return Card(
                  color: AppColors.card(context),
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                  child: RadioListTile<int>(
                    value: index,
                    activeColor: AppColors.biru,
                    title: Text(produk.nama),
                    subtitle: Text(
                      '${produk.keterangan} • ${_rupiah(produk.harga)}',
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tujuanController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: inputStyle(
              'Nomor tujuan / ID pelanggan',
              Icons.confirmation_number_outlined,
            ),
          ),
          const SizedBox(height: 16),
          TombolBiru(
            teks: 'Beli Sekarang',
            onPressed: _lanjutkan,
            loading: _loading,
          ),
        ],
      ),
    );
  }
}
