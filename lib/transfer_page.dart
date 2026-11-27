import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'saved_account.dart';
import 'transfer_reference_service.dart';

const List<String> kBankList = [
  'BCA',
  'Mandiri',
  'BNI',
  'BRI',
  'BTN',
  'CIMB Niaga',
  'Permata',
  'Danamon',
  'BSI',
  'Jago',
];

class TransferPage extends StatefulWidget {
  const TransferPage({super.key, required this.userId, this.onSelectAccount});

  final String userId;

  final void Function(SavedAccount account)? onSelectAccount;

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _service = TransferReferenceService();
  final _searchCtrl = TextEditingController();
  final _tabs = const ['Semua', 'BCA', 'Bank Lain', 'Favorit'];

  int _tab = 0;
  String _query = '';
  int _navIndex = 1;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SavedAccount> _applyFilter(List<SavedAccount> all) {
    final q = _query.trim().toLowerCase();
    return all.where((a) {
      final matchTab = switch (_tab) {
        1 => a.isBca,
        2 => !a.isBca,
        3 => a.favorit,
        _ => true,
      };
      if (!matchTab) return false;
      if (q.isEmpty) return true;
      return a.nama.toLowerCase().contains(q) ||
          a.alias.toLowerCase().contains(q) ||
          a.bank.toLowerCase().contains(q) ||
          a.noRekening.contains(q);
    }).toList();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? AppColors.danger : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openForm({SavedAccount? existing}) async {
    final result = await showModalBottomSheet<SavedAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReferenceForm(existing: existing),
    );
    if (result == null) return;

    try {
      final dup = await _service.exists(
        widget.userId,
        result.bank,
        result.noRekening,
        exceptId: existing?.id,
      );
      if (dup) {
        _snack('Rekening ini sudah tersimpan di daftar transfer', error: true);
        return;
      }
      if (existing == null) {
        await _service.add(widget.userId, result);
        _snack('Rekening tersimpan, bisa dipakai lagi nanti');

        _select(result);
      } else {
        await _service.update(widget.userId, result);
        _snack('Referensi berhasil diperbarui');
      }
    } catch (e) {
      _snack('Gagal menyimpan: $e', error: true);
    }
  }

  Future<void> _confirmDelete(SavedAccount a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Referensi?',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: Text(
          '${a.displayName} (${a.bank} • ${a.noRekening}) '
          'akan dihapus dari daftar transfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(widget.userId, a.id);
      _snack('Referensi dihapus');
    } catch (e) {
      _snack('Gagal menghapus: $e', error: true);
    }
  }

  void _select(SavedAccount a) {
    if (widget.onSelectAccount != null) {
      widget.onSelectAccount!(a);
    } else {
      _snack('Transfer ke ${a.displayName} (${a.bank})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transfer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor rekening',
                hintStyle: const TextStyle(color: AppColors.textGrey),
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _tab == i;
                return ChoiceChip(
                  label: Text(_tabs[i]),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _tab = i),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.secondary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Referensi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<SavedAccount>>(
              stream: _service.watch(widget.userId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _InfoState(
                    icon: Icons.error_outline,
                    title: 'Terjadi kesalahan',
                    message: '${snap.error}',
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final all = snap.data ?? [];
                final list = _applyFilter(all);
                if (all.isEmpty) {
                  return const _InfoState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Belum ada rekening tersimpan',
                    message: 'Tekan "Tambah Referensi" untuk menyimpan rekening tujuan.',
                  );
                }
                if (list.isEmpty) {
                  return const _InfoState(
                    icon: Icons.search_off_rounded,
                    title: 'Tidak ditemukan',
                    message: 'Coba kata kunci atau kategori lain.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return _AccountCard(
                      account: a,
                      onTap: () => _select(a),
                      onFavorite: () => _service
                          .toggleFavorite(widget.userId, a)
                          .catchError((e) => _snack('Gagal: $e', error: true)),
                      onEdit: () => _openForm(existing: a),
                      onDelete: () => _confirmDelete(a),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Transfer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Mutasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedAccount account;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  account.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${account.bank} • ${account.noRekening}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                    ),
                    if (account.alias.trim().isNotEmpty)
                      Text(
                        account.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  account.favorit
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: account.favorit ? AppColors.star : AppColors.textGrey,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
                color: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit alias')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceForm extends StatefulWidget {
  const _ReferenceForm({this.existing});
  final SavedAccount? existing;

  @override
  State<_ReferenceForm> createState() => _ReferenceFormState();
}

class _ReferenceFormState extends State<_ReferenceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _noCtrl;
  late String _bank;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _namaCtrl = TextEditingController(text: e?.nama ?? '');
    _aliasCtrl = TextEditingController(text: e?.alias ?? '');
    _noCtrl = TextEditingController(text: e?.noRekening ?? '');
    _bank = e?.bank ?? 'BCA';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _aliasCtrl.dispose();
    _noCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existing;
    Navigator.pop(
      context,
      SavedAccount(
        id: e?.id ?? '',
        nama: _namaCtrl.text.trim(),
        alias: _aliasCtrl.text.trim(),
        bank: _bank,
        noRekening: _noCtrl.text.trim(),
        favorit: e?.favorit ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEdit ? 'Edit Referensi' : 'Tambah Referensi',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _bank,
                decoration: _dec('Bank Tujuan'),
                borderRadius: BorderRadius.circular(12),
                items: kBankList
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),

                onChanged: _isEdit
                    ? null
                    : (v) => setState(() => _bank = v ?? _bank),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noCtrl,
                enabled: !_isEdit,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: _dec('Nomor Rekening'),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Nomor rekening wajib diisi';
                  if (s.length < 8) return 'Nomor rekening minimal 8 digit';
                  if (_bank == 'BCA' && s.length != 10) {
                    return 'Rekening BCA harus 10 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _namaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Nama Penerima'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Nama penerima wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aliasCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Alias (opsional)', hint: 'Contoh: Ibu Kos'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEdit ? 'Simpan Perubahan' : 'Simpan',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
