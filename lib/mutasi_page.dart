import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'formatters.dart';
import 'mutasi_colors.dart';
import 'mutasi_model.dart';
import 'mutasi_pdf.dart';
import 'mutasi_service.dart';

enum _JenisFilter { semua, masuk, keluar }

class _MutasiData {
  final MutasiProfile profile;
  final List<MutasiTransaction> items;
  const _MutasiData(this.profile, this.items);
}

class MutasiPage extends StatefulWidget {
  const MutasiPage({super.key, required this.userId});

  /// ID dokumen user di koleksi `users` (contoh: "andi").
  final String userId;

  @override
  State<MutasiPage> createState() => _MutasiPageState();
}

class _MutasiPageState extends State<MutasiPage> {
  final _service = MutasiService();
  final _searchCtrl = TextEditingController();

  late Future<_MutasiData> _future;
  String _query = '';
  DateTimeRange? _range;
  _JenisFilter _jenis = _JenisFilter.semua;
  bool _hideSaldo = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<_MutasiData> _load() async {
    final profile = await _service.fetchProfile(widget.userId);
    final items = await _service.fetchTransactions(widget.userId);
    return _MutasiData(profile, items);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  // ---------------------------------------------------------------- filter
  List<MutasiTransaction> _applyFilter(List<MutasiTransaction> all) {
    final q = _query.trim().toLowerCase();
    return all.where((t) {
      if (_jenis == _JenisFilter.masuk && !t.isKredit) return false;
      if (_jenis == _JenisFilter.keluar && t.isKredit) return false;

      if (_range != null) {
        final start = DateTime(
            _range!.start.year, _range!.start.month, _range!.start.day);
        final end = DateTime(
            _range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59);
        if (t.tanggal.isBefore(start) || t.tanggal.isAfter(end)) return false;
      }

      if (q.isEmpty) return true;
      return t.nama.toLowerCase().contains(q) ||
          t.berita.toLowerCase().contains(q) ||
          t.idTransaksi.toLowerCase().contains(q);
    }).toList();
  }

  String get _periodeText => _range == null
      ? 'Semua periode'
      : '${tanggalSingkat(_range!.start)} - ${tanggalSingkat(_range!.end)}';

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
      helpText: 'Pilih periode mutasi',
      saveText: 'Terapkan',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MutasiColors.primary,
            onPrimary: Colors.white,
            onSurface: MutasiColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  // ------------------------------------------------------------- actions
  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? MutasiColors.keluar : MutasiColors.masuk,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _downloadPdf(_MutasiData data) async {
    final items = _applyFilter(data.items);
    if (items.isEmpty) {
      _snack('Tidak ada transaksi untuk diunduh', error: true);
      return;
    }
    try {
      await exportMutasiPdf(
        profile: data.profile,
        items: items,
        periode: _periodeText,
      );
    } catch (e) {
      _snack('Gagal membuat PDF: $e', error: true);
    }
  }

  Future<void> _seed() async {
    try {
      await _service.seedDummy(widget.userId);
      _snack('Data contoh ditambahkan');
      await _refresh();
    } catch (e) {
      _snack('Gagal menambah data: $e', error: true);
    }
  }

  String _shareText(MutasiTransaction t, MutasiProfile p) => '''
MyBCA - Rincian Transaksi
ID Transaksi : ${t.idTransaksi}
Tanggal      : ${tanggalPanjang(t.tanggal)}, ${jam(t.tanggal)}
Jenis        : ${t.isKredit ? 'Uang Masuk' : 'Uang Keluar'}
${t.isKredit ? 'Pengirim' : 'Penerima'}     : ${t.nama}
Nominal      : ${rupiah(t.nominal)}
Berita       : ${t.berita.isEmpty ? '-' : t.berita}
Status       : ${t.status}
''';

  void _openDetail(MutasiTransaction t, MutasiProfile p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MutasiColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DetailSheet(
        t: t,
        onShare: () => SharePlus.instance
            .share(ShareParams(text: _shareText(t, p))),
        onCopy: () {
          Clipboard.setData(ClipboardData(text: t.idTransaksi));
          _snack('ID transaksi disalin');
        },
      ),
    );
  }

  // --------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MutasiData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        return Scaffold(
          backgroundColor: MutasiColors.background,
          appBar: AppBar(
            backgroundColor: MutasiColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text('Mutasi Rekening',
                style: TextStyle(fontWeight: FontWeight.w600)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refresh,
              ),
              PopupMenuButton<String>(
                color: MutasiColors.background,
                onSelected: (v) {
                  if (v == 'pdf' && data != null) _downloadPdf(data);
                  if (v == 'seed') _seed();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pdf',
                    enabled: data != null,
                    child: const ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Unduh PDF'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'seed',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.data_saver_on_outlined),
                      title: Text('Tambah data contoh'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(snap),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_MutasiData> snap) {
    if (snap.hasError) {
      return _InfoState(
        icon: Icons.error_outline,
        title: 'Terjadi kesalahan',
        message: '${snap.error}',
        action: TextButton(onPressed: _refresh, child: const Text('Coba lagi')),
      );
    }
    if (!snap.hasData) {
      return const Center(
          child: CircularProgressIndicator(color: MutasiColors.primary));
    }

    final data = snap.data!;
    final filtered = _applyFilter(data.items);
    final totalMasuk =
        filtered.where((e) => e.isKredit).fold<int>(0, (s, e) => s + e.nominal);
    final totalKeluar =
        filtered.where((e) => !e.isKredit).fold<int>(0, (s, e) => s + e.nominal);

    return RefreshIndicator(
      color: MutasiColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _AccountCard(
            profile: data.profile,
            hidden: _hideSaldo,
            onToggle: () => setState(() => _hideSaldo = !_hideSaldo),
          ),
          _buildFilters(),
          _SummaryRow(masuk: totalMasuk, keluar: totalKeluar),
          ..._buildList(data, filtered),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: MutasiColors.textDark),
            decoration: InputDecoration(
              hintText: 'Cari nama, berita, atau ID transaksi',
              hintStyle: const TextStyle(color: MutasiColors.textGrey),
              prefixIcon:
                  const Icon(Icons.search, color: MutasiColors.textGrey),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close,
                          size: 20, color: MutasiColors.textGrey),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: MutasiColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter tanggal
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: MutasiColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MutasiColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 20, color: MutasiColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_periodeText,
                        style: const TextStyle(
                            color: MutasiColors.textDark,
                            fontWeight: FontWeight.w500)),
                  ),
                  if (_range != null)
                    GestureDetector(
                      onTap: () => setState(() => _range = null),
                      child: const Icon(Icons.close,
                          size: 20, color: MutasiColors.textGrey),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: MutasiColors.textGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter jenis transaksi
          Wrap(
            spacing: 8,
            children: [
              _chip('Semua', _JenisFilter.semua),
              _chip('Uang Masuk', _JenisFilter.masuk),
              _chip('Uang Keluar', _JenisFilter.keluar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _JenisFilter value) {
    final selected = _jenis == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _jenis = value),
      selectedColor: MutasiColors.primary,
      backgroundColor: MutasiColors.card,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : MutasiColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  List<Widget> _buildList(_MutasiData data, List<MutasiTransaction> filtered) {
    if (data.items.isEmpty) {
      return [
        const SizedBox(height: 48),
        const _InfoState(
          icon: Icons.receipt_long_outlined,
          title: 'Belum ada transaksi',
          message:
              'Riwayat mutasi akan muncul di sini.\nUntuk mencoba, pilih menu titik tiga > "Tambah data contoh".',
        ),
      ];
    }
    if (filtered.isEmpty) {
      return [
        const SizedBox(height: 48),
        const _InfoState(
          icon: Icons.search_off_rounded,
          title: 'Tidak ditemukan',
          message: 'Coba ubah periode, jenis transaksi, atau kata kunci.',
        ),
      ];
    }

    final widgets = <Widget>[];
    String? lastDay;
    for (final t in filtered) {
      final day = tanggalPanjang(t.tanggal);
      if (day != lastDay) {
        lastDay = day;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(day,
              style: const TextStyle(
                  color: MutasiColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _TransactionTile(
          t: t,
          onTap: () => _openDetail(t, data.profile),
        ),
      ));
    }
    return widgets;
  }
}

// ===========================================================================
// Kartu informasi rekening + saldo
// ===========================================================================
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.profile,
    required this.hidden,
    required this.onToggle,
  });

  final MutasiProfile profile;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [MutasiColors.primary, MutasiColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.nama,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Tabungan  •  ${profile.noRekening}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          const Text('Saldo Aktif',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  hidden ? 'Rp ••••••••' : rupiah(profile.saldo),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Ringkasan total masuk / keluar
// ===========================================================================
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.masuk, required this.keluar});
  final int masuk;
  final int keluar;

  @override
  Widget build(BuildContext context) {
    Widget box(String label, int value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MutasiColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: MutasiColors.textGrey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(rupiah(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          box('Total Uang Masuk', masuk, MutasiColors.masuk),
          const SizedBox(width: 10),
          box('Total Uang Keluar', keluar, MutasiColors.keluar),
        ],
      ),
    );
  }
}

// ===========================================================================
// Satu baris transaksi
// ===========================================================================
Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'berhasil':
      return MutasiColors.masuk;
    case 'pending':
      return MutasiColors.pending;
    default:
      return MutasiColors.keluar;
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.t, required this.onTap});
  final MutasiTransaction t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = t.isKredit ? MutasiColors.masuk : MutasiColors.keluar;
    return Material(
      color: MutasiColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  t.isKredit
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MutasiColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      t.berita.isEmpty ? '-' : t.berita,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: MutasiColors.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(jam(t.tanggal),
                        style: const TextStyle(
                            color: MutasiColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${t.isKredit ? '+' : '-'} ${rupiah(t.nominal)}',
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(t.status,
                      style: TextStyle(
                          color: _statusColor(t.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Detail transaksi
// ===========================================================================
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.t,
    required this.onShare,
    required this.onCopy,
  });

  final MutasiTransaction t;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final color = t.isKredit ? MutasiColors.masuk : MutasiColors.keluar;

    Widget row(String label, String value, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(label,
                    style: const TextStyle(
                        color: MutasiColors.textGrey, fontSize: 13)),
              ),
              Expanded(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: MutasiColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MutasiColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                t.isKredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(t.isKredit ? 'Uang Masuk' : 'Uang Keluar',
                style: const TextStyle(
                    color: MutasiColors.textGrey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('${t.isKredit ? '+' : '-'} ${rupiah(t.nominal)}',
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(t.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.status,
                  style: TextStyle(
                      color: _statusColor(t.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: MutasiColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  row('ID Transaksi', t.idTransaksi,
                      trailing: GestureDetector(
                        onTap: onCopy,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.copy_rounded,
                              size: 16, color: MutasiColors.primary),
                        ),
                      )),
                  const Divider(height: 1, color: MutasiColors.divider),
                  row('Tanggal & Waktu',
                      '${tanggalPanjang(t.tanggal)}, ${jam(t.tanggal)}'),
                  const Divider(height: 1, color: MutasiColors.divider),
                  row(t.isKredit ? 'Pengirim' : 'Penerima', t.nama),
                  const Divider(height: 1, color: MutasiColors.divider),
                  row('Nominal', rupiah(t.nominal)),
                  const Divider(height: 1, color: MutasiColors.divider),
                  row('Berita', t.berita.isEmpty ? '-' : t.berita),
                  const Divider(height: 1, color: MutasiColors.divider),
                  row('Status', t.status),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Bagikan',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MutasiColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Empty / error state
// ===========================================================================
class _InfoState extends StatelessWidget {
  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 56, color: MutasiColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: MutasiColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MutasiColors.textGrey)),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
