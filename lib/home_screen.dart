import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'app_style.dart';
import 'akun.dart';
import 'controllers/notification_controller.dart';
import 'controllers/setting_controller.dart';
import 'firestore_transaksi_repository.dart';
import 'flazz_nfc_screen.dart';
import 'login_screen.dart';
import 'models/notification_model.dart';
import 'mutasi_page.dart';
import 'pembelian_screen.dart';
import 'pembayaran_screen.dart';
import 'promo/promo_screens.dart';
import 'saved_account.dart';
import 'services/locale_service.dart';
import 'tarik_tunai_screen.dart';
import 'top_up_screen.dart';
import 'transfer_page.dart';
import 'transfer_qris_screen.dart';
import 'profile_screen.dart';
import 'qris_screen.dart';
import 'riwayat_transaksi.dart';
import 'status_transaksi_screen.dart';
import 'user_service.dart';
import 'views/account_setting_view.dart';
import 'views/notification_view.dart';
import 'views/setting_view.dart';
import 'widgets/mybca_mascot.dart';

class FiturMenu {
  const FiturMenu(
    this.keyId,
    this.labelId,
    this.labelEn,
    this.ikon,
    this.color,
  );

  final String keyId;
  final String labelId;
  final String labelEn;
  final IconData ikon;
  final Color color;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService userService = UserService();
  final ImagePicker picker = ImagePicker();

  late final SettingController settingController;
  late final NotificationController notificationController;
  late final Stream<List<RiwayatTransaksi>> mutasiTerbaru;
  late Map<String, dynamic> user;
  bool saldoTerlihat = false;
  Uint8List? fotoBytes;
  String? rekening;
  int _tipIndex = 0;

  String _t(String id, String en) => LocaleService.tr(id, en);

  static const _tipsId = [
    'Tap aku untuk tips! Salin nomor rekening langsung dari kartu utama.',
    'Cek saldo kartu Flazz kamu lewat menu Flazz NFC.',
    'Lihat promo & berita terbaru MyBCA di tab Promo.',
    'Gunakan QRIS di tengah bawah untuk bayar lebih cepat.',
  ];

  static const _tipsEn = [
    'Tap me for tips! Copy your account number right from the main card.',
    'Check your Flazz card balance anytime via Flazz NFC.',
    'Explore latest MyBCA promos & news in the Promo tab.',
    'Use the center QRIS button below for instant payments.',
  ];

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
    rekening = (user['rekening'] as String?)?.trim();
    final userId = user['id'] as String;
    mutasiTerbaru = FirestoreTransaksiRepository().pantau(userId, batas: 3);
    settingController = SettingController(userId: userId)..load();
    notificationController = NotificationController(
      userId: userId,
      onIncoming: _tampilBannerNotifikasi,
    )..start();
    final data = user['foto'];
    if (data is String && data.isNotEmpty) {
      try {
        fotoBytes = base64Decode(data);
      } catch (_) {
        fotoBytes = null;
      }
    }
    _pastikanRekening();
  }

  Future<void> _pastikanRekening() async {
    if (rekening != null && rekening!.isNotEmpty) return;
    try {
      final rek = await userService.ambilRekening(user);
      if (!mounted) return;
      setState(() {
        rekening = rek;
        user['rekening'] = rek;
      });
    } catch (_) {}
  }

  void _salinRekening() {
    final rek = rekening;
    if (rek == null || rek.isEmpty) {
      pesan(
        _t('Nomor rekening belum tersedia', 'Account number not available'),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: rek));
    pesan(_t('Nomor rekening $rek disalin', 'Account number $rek copied'));
  }

  void _tampilBannerNotifikasi(NotificationModel notif) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.biruTua,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notif.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: SnackBarAction(
          label: _t('Lihat', 'View'),
          textColor: Colors.amberAccent,
          onPressed: () {
            if (notif.type == NotificationType.promo) {
              bukaPromoBerita(initialTab: 0);
            } else if (notif.type == NotificationType.info &&
                notif.title.toLowerCase().contains('berita')) {
              bukaPromoBerita(initialTab: 1);
            } else {
              bukaHalamanNotifikasi();
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    settingController.dispose();
    notificationController.dispose();
    super.dispose();
  }

  Widget denganController(Widget halaman) => MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingController>.value(value: settingController),
      ChangeNotifierProvider<NotificationController>.value(
        value: notificationController,
      ),
    ],
    child: halaman,
  );

  Future<void> bukaHalamanPengaturan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => denganController(const SettingView())),
    );
  }

  Future<void> bukaHalamanNotifikasi() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => denganController(const NotificationView()),
      ),
    );
  }

  Future<void> bukaPengaturanAkun() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => denganController(const AccountSettingView()),
      ),
    );
  }

  Future<void> bukaStatusTransaksi() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusTransaksiScreen(
          repo: FirestoreTransaksiRepository(),
          userId: user['id'] as String,
        ),
      ),
    );
    await muatUlang();
  }

  Future<void> bukaPembayaran() async {
    try {
      final rek = await userService.ambilRekening(user);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PembayaranScreen(
            repo: FirestoreTransaksiRepository(),
            akun: Akun(
              id: user['id'] as String,
              nama: (user['nama'] ?? 'Pengguna').toString(),
              rekening: rek,
              saldo: (user['saldo'] as num?)?.toInt() ?? 0,
            ),
          ),
        ),
      );
      await muatUlang();
    } catch (e) {
      pesan(_t('Gagal memuat data rekening', 'Failed to load account data'));
    }
  }

  Future<void> bukaTopUp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TopUpScreen(user: user)),
    );
    await muatUlang();
  }

  Future<void> bukaPembelian() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PembelianScreen(user: user)),
    );
    await muatUlang();
  }

  Future<void> bukaTarikTunai() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TarikTunaiScreen(user: user)),
    );
    await muatUlang();
  }

  Future<void> bukaFlazzNfc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlazzNfcScreen(user: user)),
    );
    await muatUlang();
  }

  void bukaPromoBerita({int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromoListScreen(initialTab: initialTab),
      ),
    );
  }

  void infoSegeraHadir(String fitur) {
    pesan(
      _t(
        'Fitur $fitur segera hadir di pembaruan berikutnya',
        '$fitur feature is coming soon',
      ),
    );
  }

  static const daftarMenu = [
    FiturMenu(
      'info',
      'Mutasi',
      'History',
      Icons.account_balance_wallet_outlined,
      Color(0xFF0060AF),
    ),
    FiturMenu(
      'topup',
      'Top Up',
      'Top Up',
      Icons.add_card_rounded,
      Color(0xFF16864B),
    ),
    FiturMenu(
      'transfer',
      'Transfer',
      'Transfer',
      Icons.swap_horiz_rounded,
      Color(0xFF1565C0),
    ),
    FiturMenu(
      'bayar',
      'Pembayaran',
      'Payments',
      Icons.receipt_long_outlined,
      Color(0xFFE08A00),
    ),
    FiturMenu(
      'beli',
      'Pembelian',
      'Purchase',
      Icons.shopping_bag_outlined,
      Color(0xFF7B1FA2),
    ),
    FiturMenu('qris', 'QRIS', 'QRIS', Icons.qr_code_scanner, Color(0xFF00838F)),
    FiturMenu('tarik', 'Tarik Tunai', 'Cash Out', Icons.atm, Color(0xFFD84315)),
    FiturMenu('flazz', 'Flazz NFC', 'Flazz NFC', Icons.nfc, Color(0xFF0277BD)),
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
        title: Text(_t('Keluar', 'Sign Out')),
        content: Text(
          _t(
            'Apakah kamu yakin ingin keluar dari MyBCA?',
            'Are you sure you want to sign out of MyBCA?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Batal', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Keluar', 'Sign Out')),
          ),
        ],
      ),
    );

    if (keluar != true || !mounted) return;
    await UserService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> pilihFoto(ImageSource sumber) async {
    try {
      final file = await picker.pickImage(
        source: sumber,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return;

      final namaFile = file.name.toLowerCase();
      final gambar = ['.jpg', '.jpeg', '.png', '.webp'].any(namaFile.endsWith);
      if (!gambar) {
        pesan(_t('File harus berupa gambar', 'File must be an image'));
        return;
      }

      final bytes = await file.readAsBytes();
      final fotoBase64 = base64Encode(bytes);
      await userService.simpanFoto(user['id'], fotoBase64);
      if (!mounted) return;
      setState(() {
        fotoBytes = bytes;
        user['foto'] = fotoBase64;
      });
    } catch (e) {
      pesan(_t('Gagal menyimpan foto profil', 'Failed to save profile photo'));
    }
  }

  void tampilPilihanFoto() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_t('Pilih dari galeri', 'Choose from gallery')),
              onTap: () {
                Navigator.pop(ctx);
                pilihFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(_t('Ambil foto', 'Take a photo')),
              onTap: () {
                Navigator.pop(ctx);
                pilihFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget avatar(String nama) {
    return GestureDetector(
      onTap: tampilPilihanFoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white,
            backgroundImage: fotoBytes != null ? MemoryImage(fotoBytes!) : null,
            child: fotoBytes == null
                ? Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.biru,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.biru,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> muatUlang() async {
    try {
      final terbaru = await userService.getUser(user['id']);
      if (!mounted || terbaru == null) return;
      setState(() {
        user = terbaru;
        rekening = (terbaru['rekening'] as String?)?.trim() ?? rekening;
      });
    } catch (e) {
      debugPrint('Gagal memuat ulang data: $e');
    }
  }

  Future<void> bukaQris() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrisScreen(user: user)),
    );
    await muatUlang();
  }

  Future<void> bukaProfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: user,
          onOpenSettings: bukaHalamanPengaturan,
          onOpenNotifications: bukaHalamanNotifikasi,
          onOpenAccountSettings: bukaPengaturanAkun,
        ),
      ),
    );
    await muatUlang();
  }

  Future<void> bukaMutasi() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MutasiPage(userId: user['id'] as String),
      ),
    );
    await muatUlang();
  }

  Future<void> bukaTransfer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferPage(
          userId: user['id'] as String,
          onSelectAccount: prosesTransferKeRekening,
        ),
      ),
    );
    await muatUlang();
  }

  Future<void> prosesTransferKeRekening(SavedAccount tujuan) async {
    if (!tujuan.isBca) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_t('Bank belum didukung', 'Bank not supported yet')),
          content: Text(
            _t(
              'MyBCA saat ini hanya bisa memproses transfer ke sesama '
                  'rekening MyBCA (BCA). Transfer ke ${tujuan.bank} belum '
                  'tersedia di aplikasi ini.',
              'MyBCA currently supports transfers between MyBCA (BCA) accounts only. Transfers to ${tujuan.bank} are not yet available.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('Mengerti', 'Got it')),
            ),
          ],
        ),
      );
      return;
    }

    if (tujuan.noRekening == (user['rekening'] as String?)) {
      pesan(
        _t(
          'Tidak bisa transfer ke rekening sendiri',
          'Cannot transfer to your own account',
        ),
      );
      return;
    }

    Map<String, dynamic>? penerima;
    try {
      penerima = await userService.findByRekening(tujuan.noRekening);
    } catch (e) {
      pesan(
        _t('Gagal terhubung ke server, coba lagi', 'Server connection failed'),
      );
      return;
    }
    if (!mounted) return;

    if (penerima == null) {
      pesan(
        _t(
          'Nomor rekening MyBCA ${tujuan.noRekening} tidak ditemukan',
          'MyBCA account ${tujuan.noRekening} not found',
        ),
      );
      return;
    }

    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransferQrisScreen(pengirim: user, penerima: penerima!),
      ),
    );
    if (berhasil == true) await muatUlang();
  }

  Widget kartuPutih(Widget isi) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.25 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isi,
    );
  }

  Widget kartuSaldo(int saldo) {
    final rekText = (rekening != null && rekening!.isNotEmpty)
        ? rekening!
        : '••••••••••';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.3 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _t('Tahapan BCA • Utama', 'Tahapan BCA • Primary'),
                  style: TextStyle(
                    color: AppColors.accent(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: bukaMutasi,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _t('Mutasi', 'History'),
                        style: TextStyle(
                          color: AppColors.accent(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.accent(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardAlt(context).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 16,
                  color: AppColors.accent(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Nomor Rekening', 'Account Number'),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      SelectableText(
                        rekText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _salinRekening,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    _t('Salin', 'Copy'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Saldo Aktif', 'Available Balance'),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      saldoTerlihat ? formatRupiah(saldo) : 'Rp ••••••••',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => saldoTerlihat = !saldoTerlihat),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.cardAlt(context),
                ),
                icon: Icon(
                  saldoTerlihat
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.accent(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bagianHeader(String nama, int saldo) {
    final tips = LocaleService.isEnglish ? _tipsEn : _tipsId;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003268), AppColors.biru, Color(0xFF1577CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -25,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'myBCA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: notificationController,
                      builder: (context, _) {
                        final unread = notificationController.unreadCount;
                        return Stack(
                          children: [
                            IconButton(
                              onPressed: bukaHalamanNotifikasi,
                              tooltip: _t('Notifikasi', 'Notifications'),
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: CircleAvatar(
                                  radius: 7,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    unread > 9 ? '9+' : '$unread',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      onPressed: bukaHalamanPengaturan,
                      tooltip: _t('Pengaturan', 'Settings'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: konfirmasiKeluar,
                      tooltip: _t('Keluar', 'Sign Out'),
                      icon: const Icon(
                        Icons.power_settings_new,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    avatar(nama),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Selamat datang,', 'Welcome back,'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                MyBcaMascot(
                  size: 56,
                  mood: MascotMood.waving,
                  speechText: tips[_tipIndex % tips.length],
                  onTap: () => setState(() => _tipIndex++),
                ),
                const SizedBox(height: 14),
                kartuSaldo(saldo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget itemMenu(FiturMenu menu) {
    final label = LocaleService.isEnglish ? menu.labelEn : menu.labelId;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: switch (menu.keyId) {
        'info' => bukaMutasi,
        'topup' => bukaTopUp,
        'transfer' => bukaTransfer,
        'bayar' => bukaPembayaran,
        'beli' => bukaPembelian,
        'tarik' => bukaTarikTunai,
        'qris' => bukaQris,
        'flazz' => bukaFlazzNfc,
        _ => () => infoSegeraHadir(label),
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: menu.color.withValues(
                alpha: AppColors.isDark(context) ? 0.22 : 0.11,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              menu.ikon,
              color: AppColors.isDark(context)
                  ? Color.lerp(menu.color, Colors.white, 0.35)
                  : menu.color,
              size: 27,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget bagianMenu() {
    return kartuPutih(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _t('Menu Transaksi', 'Transaction Menu'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              Text(
                _t('Semua Layanan', 'All Services'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          colors: [Color(0xFF004B93), Color(0xFF1E8FD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _t('Info Terkini', 'Latest Updates'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _t('Promo & Berita MyBCA', 'MyBCA Promos & News'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Temukan penawaran promo menarik dan berita terbaru MyBCA.',
              'Discover exclusive promos and latest MyBCA news.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => bukaPromoBerita(initialTab: 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.biruTua,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.local_offer_outlined, size: 18),
                  label: Text(_t('Promo', 'Promos')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => bukaPromoBerita(initialTab: 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.newspaper_outlined, size: 18),
                  label: Text(_t('Berita', 'News')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatTanggalTransaksi(DateTime tanggal) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  Widget barisTransaksi(RiwayatTransaksi t) {
    final masuk = t.tipe.toLowerCase() == 'kredit';
    final tanda = masuk ? '+' : '-';
    final judul = t.berita.trim().isNotEmpty
        ? t.berita.trim()
        : '${t.jenis} ${t.nama}'.trim();
    final warna = masuk
        ? (AppColors.isDark(context)
              ? Colors.green.shade400
              : Colors.green.shade700)
        : (AppColors.isDark(context)
              ? Colors.red.shade400
              : Colors.red.shade700);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: warna.withValues(alpha: 0.12),
            child: Icon(
              masuk ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: warna,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatTanggalTransaksi(t.tanggal),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$tanda${formatRupiah(t.nominal)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: warna),
          ),
        ],
      ),
    );
  }

  Widget bagianMutasi() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: bukaStatusTransaksi,
      child: kartuPutih(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _t('Mutasi Terakhir', 'Recent Transactions'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  _t('Lihat Semua', 'See All'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<RiwayatTransaksi>>(
              stream: mutasiTerbaru,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _t(
                        'Mutasi belum dapat dimuat.',
                        'Unable to load transactions.',
                      ),
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final transaksi = snapshot.data ?? const [];
                if (transaksi.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _t('Belum ada transaksi.', 'No transactions yet.'),
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  );
                }

                return Column(children: transaksi.map(barisTransaksi).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget itemBawah(
    IconData ikon,
    String teks,
    bool aktif, {
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    final warna = aktif
        ? AppColors.accent(context)
        : AppColors.textSecondary(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(ikon, color: warna),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(teks, style: TextStyle(fontSize: 11, color: warna)),
          ],
        ),
      ),
    );
  }

  Widget menuBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: notificationController,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              itemBawah(Icons.home_filled, _t('Beranda', 'Home'), true),
              itemBawah(
                Icons.local_offer_outlined,
                _t('Promo', 'Promos'),
                false,
                onTap: () => bukaPromoBerita(initialTab: 0),
              ),
              GestureDetector(
                onTap: bukaQris,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.biruTua, AppColors.biru],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.biru.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'QRIS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent(context),
                      ),
                    ),
                  ],
                ),
              ),
              itemBawah(
                Icons.mail_outline,
                _t('Inbox', 'Inbox'),
                false,
                badgeCount: notificationController.unreadCount,
                onTap: bukaHalamanNotifikasi,
              ),
              itemBawah(
                Icons.person_outline,
                _t('Profil', 'Profile'),
                false,
                onTap: bukaProfil,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (user['nama'] ?? 'Pengguna').toString();
    final saldo = (user['saldo'] as num?)?.toInt() ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) konfirmasiKeluar();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: RefreshIndicator(
          onRefresh: muatUlang,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
        ),
        bottomNavigationBar: menuBawah(),
      ),
    );
  }
}
