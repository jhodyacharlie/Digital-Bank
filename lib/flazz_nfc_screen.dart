import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import 'app_style.dart';
import 'firestore_transaksi_repository.dart';
import 'pin_konfirmasi_screen.dart';
import 'services/locale_service.dart';
import 'user_service.dart';
import 'widgets/mybca_mascot.dart';

class FlazzNfcScreen extends StatefulWidget {
  const FlazzNfcScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<FlazzNfcScreen> createState() => _FlazzNfcScreenState();
}

class _FlazzNfcScreenState extends State<FlazzNfcScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  NfcAvailability _availability = NfcAvailability.unsupported;
  bool _checkingNfc = true;
  bool _scanning = false;
  bool _loadingCard = false;

  String? _scannedUid;
  String? _cardTech;
  int? _hardwareBalance;
  String? _hardwareNote;
  Map<String, dynamic>? _firestoreCard;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  @override
  void dispose() {
    _stopScan(silent: true);
    super.dispose();
  }

  String _formatBytesHex(Uint8List bytes, {String separator = ':'}) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(separator);
  }

  String _rupiah(int nilai) {
    final teks = nilai.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $teks';
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _checkNfc() async {
    NfcAvailability avail = NfcAvailability.unsupported;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        avail = await NfcManager.instance.checkAvailability();
      } catch (_) {
        avail = NfcAvailability.unsupported;
      }
    }
    if (!mounted) return;
    setState(() {
      _availability = avail;
      _checkingNfc = false;
    });
  }

  Future<void> _stopScan({bool silent = false}) async {
    if (!_scanning) return;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
    if (!silent && mounted) {
      setState(() => _scanning = false);
    }
  }

  Future<void> _startScan() async {
    if (_availability != NfcAvailability.enabled) {
      _pesan(
        _availability == NfcAvailability.disabled
            ? 'Aktifkan NFC di pengaturan HP terlebih dahulu.'
            : 'Perangkat ini tidak mendukung NFC.',
      );
      return;
    }

    setState(() {
      _scanning = true;
      _hardwareNote = null;
      _hardwareBalance = null;
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso18092},
        alertMessageIos: 'Tempelkan kartu Flazz di bagian atas iPhone.',
        onDiscovered: (NfcTag tag) async {
          await _handleDiscoveredTag(tag);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      _pesan('Gagal memulai sesi NFC: $e');
    }
  }

  Future<void> _handleDiscoveredTag(NfcTag tag) async {
    String? uidHex;
    String techLabel = 'NFC Tag';
    int? hwBalance;
    String? note;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidTag = NfcTagAndroid.from(tag);
      if (androidTag != null) {
        uidHex = _formatBytesHex(androidTag.id);
        final techs = androidTag.techList
            .map((t) => t.split('.').last)
            .join(', ');
        if (techs.isNotEmpty) techLabel = techs;
      }

      final isoDep = IsoDepAndroid.from(tag);
      if (isoDep != null) {
        techLabel = 'ISO-DEP (Smartcard / Flazz Gen 2)';
        final probe = await _probeIsoDepBalance(isoDep);
        hwBalance = probe.$1;
        note = probe.$2;
      } else {
        final nfcA = NfcAAndroid.from(tag);
        if (nfcA != null) {
          techLabel =
              'NFC-A (SAK: 0x${nfcA.sak.toRadixString(16).toUpperCase()})';
          note = 'Kartu terdeteksi via NFC-A. Jika ini Flazz Gen 1 / chip terenkripsi, saldo chip tidak dapat dibaca langsung tanpa kunci SAM BCA.';
        }
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iso7816 = Iso7816Ios.from(tag);
      if (iso7816 != null) {
        uidHex = _formatBytesHex(iso7816.identifier);
        techLabel = 'ISO-7816 (Smartcard)';
        note = 'UID kartu terbaca. Pembacaan saldo chip Flazz secara langsung memerlukan autentikasi SAM BCA.';
      }
    }

    await _stopScan(silent: true);

    if (!mounted) return;
    setState(() {
      _scanning = false;
      _scannedUid = uidHex ?? 'UNKNOWN';
      _cardTech = techLabel;
      _hardwareBalance = hwBalance;
      _hardwareNote = note;
    });

    if (uidHex != null) {
      await _loadFirestoreCard(uidHex);
    }
  }

  Future<(int?, String)> _probeIsoDepBalance(IsoDepAndroid isoDep) async {
    try {
      final selectCandidates = <List<int>>[
        [
          0x00,
          0xA4,
          0x04,
          0x00,
          0x08,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x01,
        ],
      ];
      for (final cmd in selectCandidates) {
        final resp = await isoDep.transceive(Uint8List.fromList(cmd));
        if (_isSuccessSw(resp)) {
          final balResp = await isoDep.transceive(
            Uint8List.fromList([0x00, 0xB5, 0x00, 0x00, 0x0A]),
          );
          if (_isSuccessSw(balResp) && balResp.length >= 6) {
            final parsed = ByteData.sublistView(balResp, 0, 4).getUint32(0);
            return (
              parsed,
              'Saldo berhasil dibaca langsung dari chip kartu ISO-DEP.',
            );
          }
        }
      }
      return (
        null,
        'Chip ISO-DEP terdeteksi, namun saldo chip terenkripsi (memerlukan modul SAM BCA). Kamu tetap bisa menghubungkan UID kartu ini ke akun MyBCA untuk cek & top up saldo simulasi.',
      );
    } catch (_) {
      return (
        null,
        'Chip terdeteksi, namun tidak merespons perintah saldo publik. Hubungkan UID kartu ini ke MyBCA untuk cek & top up saldo.',
      );
    }
  }

  bool _isSuccessSw(Uint8List resp) {
    if (resp.length < 2) return false;
    return resp[resp.length - 2] == 0x90 && resp[resp.length - 1] == 0x00;
  }

  String _docIdForUid(String uid) => uid.replaceAll(':', '').toUpperCase();

  Future<void> _loadFirestoreCard(String uid) async {
    setState(() => _loadingCard = true);
    try {
      final doc = await _db
          .collection('flazz_cards')
          .doc(_docIdForUid(uid))
          .get();
      if (!mounted) return;
      setState(() {
        _firestoreCard = doc.exists ? {'id': doc.id, ...?doc.data()} : null;
        _loadingCard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCard = false);
      _pesan('Gagal memuat data kartu dari Firebase: $e');
    }
  }

  Future<void> _registerOrSyncCard(String uid) async {
    final labelCtrl = TextEditingController(text: 'Flazz MyBCA');
    final initialSaldoCtrl = TextEditingController(
      text: (_hardwareBalance ?? 0).toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daftarkan Kartu Flazz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UID Kartu: $uid', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Nama kartu'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: initialSaldoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Saldo awal kartu (simulasi Rp)',
              ),
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final label = labelCtrl.text.trim().isEmpty
        ? 'Flazz MyBCA'
        : labelCtrl.text.trim();
    final saldoAwal = int.tryParse(initialSaldoCtrl.text.trim()) ?? 0;
    labelCtrl.dispose();
    initialSaldoCtrl.dispose();

    if (ok != true) return;

    setState(() => _loadingCard = true);
    try {
      final docId = _docIdForUid(uid);
      await _db.collection('flazz_cards').doc(docId).set({
        'uid': uid,
        'label': label,
        'saldo': saldoAwal,
        'ownerUid': widget.user['id'],
        'tech': _cardTech ?? 'NFC',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadFirestoreCard(uid);
      _pesan('Kartu Flazz berhasil dihubungkan ke akun MyBCA');
    } catch (e) {
      if (mounted) setState(() => _loadingCard = false);
      _pesan('Gagal menyimpan kartu: $e');
    }
  }

  Future<void> _topUpCard(String uid) async {
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top Up Kartu Flazz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kartu UID: $uid', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal top up (Rp)',
                hintText: 'Contoh: 50000',
              ),
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
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    final nominal = int.tryParse(amountCtrl.text.trim()) ?? 0;
    amountCtrl.dispose();

    if (ok != true) return;
    if (nominal < 10000) {
      _pesan('Minimal top up Flazz Rp10.000');
      return;
    }

    if (!mounted) return;
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PinKonfirmasiScreen(
          repo: FirestoreTransaksiRepository(),
          userId: widget.user['id'] as String,
          keterangan: 'Top Up Flazz ${_rupiah(nominal)} ($uid)',
        ),
      ),
    );
    if (!mounted || pin == null) return;

    setState(() => _loadingCard = true);
    final err = await _userService.belanjaProduk(
      widget.user['id'] as String,
      nominal,
      pin: pin,
      namaProduk: 'Top Up Flazz NFC',
      tujuan: _docIdForUid(uid),
    );
    if (err != null) {
      if (mounted) setState(() => _loadingCard = false);
      _pesan(err);
      return;
    }

    try {
      await _db.collection('flazz_cards').doc(_docIdForUid(uid)).update({
        'saldo': FieldValue.increment(nominal),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadFirestoreCard(uid);
      _pesan('Top up Flazz ${_rupiah(nominal)} berhasil!');
    } catch (e) {
      if (mounted) setState(() => _loadingCard = false);
      _pesan('Saldo terpotong, gagal update kartu: $e');
    }
  }

  void _simulasiScan() {
    final ctrl = TextEditingController(text: '04:A1:2B:3C:4D:5E:6F');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulasi Scan Kartu Flazz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gunakan mode simulasi jika menguji di emulator atau perangkat tanpa NFC.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'UID Kartu Flazz (Hex)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final uid = ctrl.text.trim().toUpperCase();
              Navigator.pop(ctx);
              if (uid.isEmpty) return;
              setState(() {
                _scannedUid = uid;
                _cardTech = 'Simulasi ISO-DEP (Flazz Gen 2)';
                _hardwareBalance = null;
                _hardwareNote = 'Mode simulasi aktif. Data saldo diambil dari database Firebase kartu Flazz.';
              });
              _loadFirestoreCard(uid);
            },
            child: const Text('Cek Kartu'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  Widget _buildAvailabilityBanner() {
    IconData icon;
    Color color;
    String title;
    String desc;

    switch (_availability) {
      case NfcAvailability.enabled:
        icon = Icons.nfc;
        color = Colors.green;
        title = 'NFC Aktif & Siap';
        desc = 'Tekan tombol Mulai Scan NFC lalu tempelkan kartu Flazz di belakang HP.';
      case NfcAvailability.disabled:
        icon = Icons.nfc_outlined;
        color = Colors.orange;
        title = 'NFC Belum Aktif';
        desc =
            'Nyalakan NFC di pengaturan perangkat kamu untuk scan kartu Flazz.';
      case NfcAvailability.unsupported:
        icon = Icons.phonelink_erase_outlined;
        color = Colors.red;
        title = 'NFC Tidak Tersedia';
        desc = 'Perangkat/platform ini tidak memiliki NFC. Kamu masih bisa memakai Mode Simulasi di bawah.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedResult() {
    if (_scannedUid == null) return const SizedBox.shrink();

    final fbSaldo = (_firestoreCard?['saldo'] as num?)?.toInt();
    final displaySaldo = _hardwareBalance ?? fbSaldo;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.biruTua, AppColors.biru],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'FLAZZ BCA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (_firestoreCard != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (_firestoreCard!['label'] ?? 'Terhubung').toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'UID Kartu',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            _scannedUid!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          if (_cardTech != null) ...[
            const SizedBox(height: 4),
            Text(
              _cardTech!,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Saldo Kartu',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (_loadingCard)
            const LinearProgressIndicator(color: Colors.white)
          else if (displaySaldo != null)
            Text(
              _rupiah(displaySaldo),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const Text(
              'Belum terbaca / Belum terdaftar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_hardwareNote != null) ...[
            const SizedBox(height: 10),
            Text(
              _hardwareNote!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          if (_firestoreCard == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingCard
                    ? null
                    : () => _registerOrSyncCard(_scannedUid!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.biruTua,
                ),
                icon: const Icon(Icons.add_card),
                label: const Text('Hubungkan Kartu ke MyBCA'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingCard ? null : () => _topUpCard(_scannedUid!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.biruTua,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Top Up Saldo Flazz'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = LocaleService.tr;
    final ownerUid = widget.user['id'] as String;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: Text(t('Cek Saldo Flazz (NFC)', 'Flazz Balance Check (NFC)')),
        actions: [
          IconButton(
            tooltip: t('Periksa ulang NFC', 'Recheck NFC'),
            icon: const Icon(Icons.refresh),
            onPressed: _checkNfc,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_checkingNfc)
            const Center(child: CircularProgressIndicator())
          else
            _buildAvailabilityBanner(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _scanning ? () => _stopScan() : _startScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: _scanning ? Colors.red : AppColors.biru,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(_scanning ? Icons.stop_circle : Icons.nfc),
                  label: Text(
                    _scanning
                        ? t('Hentikan Scan', 'Stop Scan')
                        : t('Mulai Scan NFC', 'Start NFC Scan'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _simulasiScan,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                ),
                icon: const Icon(Icons.sim_card_outlined),
                label: Text(t('Simulasi', 'Simulate')),
              ),
            ],
          ),
          if (_scanning)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  const MyBcaMascot(size: 52, mood: MascotMood.scanning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(
                        'Menunggu kartu... Tempelkan kartu Flazz di bagian belakang HP kamu.',
                        'Waiting for card... Tap your Flazz card on the back of your phone.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildScannedResult(),
          const SizedBox(height: 24),
          Text(
            t('Kartu Flazz Tersimpan', 'Saved Flazz Cards'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('flazz_cards')
                .where('ownerUid', isEqualTo: ownerUid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Gagal memuat kartu: ${snap.error}');
              }
              if (!snap.hasData) return const LinearProgressIndicator();
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.credit_card_off_outlined),
                    title: Text('Belum ada kartu Flazz terhubung'),
                    subtitle: Text(
                      'Scan kartu Flazz atau gunakan mode simulasi untuk menghubungkan kartu.',
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((d) {
                  final x = d.data();
                  final uid = (x['uid'] ?? d.id).toString();
                  final saldo = (x['saldo'] as num?)?.toInt() ?? 0;
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.biruMuda,
                        child: Icon(Icons.credit_card, color: AppColors.biru),
                      ),
                      title: Text((x['label'] ?? 'Flazz MyBCA').toString()),
                      subtitle: Text('UID: $uid'),
                      trailing: Text(
                        _rupiah(saldo),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.biruTua,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _scannedUid = uid;
                          _cardTech = (x['tech'] ?? 'NFC').toString();
                          _hardwareBalance = null;
                          _hardwareNote = null;
                          _firestoreCard = {'id': d.id, ...x};
                        });
                      },
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
}
