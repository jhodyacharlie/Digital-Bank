import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../admin/admin_service.dart';
import '../app_style.dart';
import '../services/locale_service.dart';

Uint8List? _decodeImage(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

String _formatTanggal(DateTime d) {
  try {
    return DateFormat('d MMM yyyy', 'id').format(d);
  } catch (_) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

String _formatTanggalJam(DateTime d) {
  try {
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(d);
  } catch (_) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

class PromoComposerScreen extends StatefulWidget {
  const PromoComposerScreen({super.key});
  @override
  State<PromoComposerScreen> createState() => _PromoComposerScreenState();
}

class _PromoComposerScreenState extends State<PromoComposerScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final terms = TextEditingController();
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 7));
  Uint8List? image;
  bool loading = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    terms.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 700000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gambar terlalu besar. Pilih gambar di bawah 700 KB.',
            ),
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => image = bytes);
  }

  Future<void> chooseDate(bool chooseStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = chooseStart ? start : end;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() {
      if (chooseStart) {
        start = selected;
        if (end.isBefore(start)) end = start.add(const Duration(days: 1));
      } else {
        end = selected.add(const Duration(hours: 23, minutes: 59));
      }
    });
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan deskripsi wajib diisi')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await AdminService().publishPromo(
        title: title.text,
        description: description.text,
        terms: terms.text,
        startsAt: start,
        endsAt: end,
        imageBase64: image == null ? null : base64Encode(image!),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promo dipublikasikan & notifikasi dikirim'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.biruMuda,
    appBar: AppBar(
      backgroundColor: AppColors.biru,
      foregroundColor: Colors.white,
      title: const Text('Buat Promo'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        InkWell(
          onTap: loading ? null : pickImage,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: image == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 42),
                        SizedBox(height: 6),
                        Text('Pilih gambar promo (opsional)'),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(image!, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: title,
          enabled: !loading,
          decoration: inputStyle('Judul promo', Icons.local_offer_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: description,
          enabled: !loading,
          maxLines: 3,
          decoration: inputStyle('Deskripsi promo', Icons.description_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: terms,
          enabled: !loading,
          maxLines: 4,
          decoration: inputStyle('Ketentuan promo (opsional)', Icons.rule),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                title: const Text('Mulai'),
                subtitle: Text(_formatTanggal(start)),
                trailing: const Icon(Icons.calendar_month),
                onTap: loading ? null : () => chooseDate(true),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Berakhir'),
                subtitle: Text(_formatTanggal(end)),
                trailing: const Icon(Icons.calendar_month),
                onTap: loading ? null : () => chooseDate(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TombolBiru(
          teks: 'Publikasikan Promo',
          onPressed: save,
          loading: loading,
        ),
      ],
    ),
  );
}

class NewsComposerScreen extends StatefulWidget {
  const NewsComposerScreen({super.key});
  @override
  State<NewsComposerScreen> createState() => _NewsComposerScreenState();
}

class _NewsComposerScreenState extends State<NewsComposerScreen> {
  final title = TextEditingController();
  final summary = TextEditingController();
  final body = TextEditingController();
  Uint8List? image;
  bool loading = false;

  @override
  void dispose() {
    title.dispose();
    summary.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 700000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gambar terlalu besar. Pilih gambar di bawah 700 KB.',
            ),
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => image = bytes);
  }

  Future<void> publish() async {
    if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi berita wajib diisi')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await AdminService().publishNews(
        title: title.text,
        summary: summary.text,
        body: body.text,
        publishedAt: DateTime.now(),
        imageBase64: image == null ? null : base64Encode(image!),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berita dipublikasikan & notifikasi dikirim'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mempublikasikan berita: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.biruMuda,
    appBar: AppBar(
      title: const Text('Buat Berita'),
      backgroundColor: AppColors.biru,
      foregroundColor: Colors.white,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        InkWell(
          onTap: loading ? null : pickImage,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: image == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 42),
                        SizedBox(height: 6),
                        Text('Pilih gambar berita (opsional)'),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(image!, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: title,
          enabled: !loading,
          decoration: inputStyle('Judul berita', Icons.newspaper_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: summary,
          enabled: !loading,
          maxLines: 2,
          decoration: inputStyle(
            'Ringkasan notifikasi (opsional)',
            Icons.short_text,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: body,
          enabled: !loading,
          maxLines: 7,
          decoration: inputStyle('Isi berita', Icons.article_outlined),
        ),
        const SizedBox(height: 18),
        TombolBiru(
          teks: 'Publikasikan Berita',
          onPressed: publish,
          loading: loading,
        ),
      ],
    ),
  );
}

class PromoListScreen extends StatelessWidget {
  const PromoListScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: initialTab.clamp(0, 1),
    child: Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          LocaleService.tr('Promo & Berita MyBCA', 'MyBCA Promos & News'),
        ),
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        bottom: TabBar(
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.local_offer_outlined),
              text: LocaleService.tr('Promo', 'Promos'),
            ),
            Tab(
              icon: const Icon(Icons.newspaper_outlined),
              text: LocaleService.tr('Berita', 'News'),
            ),
          ],
        ),
      ),
      body: const TabBarView(children: [_PromoFeed(), _NewsFeed()]),
    ),
  );
}

class _PromoFeed extends StatelessWidget {
  const _PromoFeed();

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('promos')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat promo: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final docs =
              snapshot.data!.docs.where((d) {
                final x = d.data();
                final a = (x['startsAt'] as Timestamp?)?.toDate();
                final b = (x['endsAt'] as Timestamp?)?.toDate();
                if (a == null || b == null) return true;
                return !now.isBefore(a) && !now.isAfter(b);
              }).toList()..sort((a, b) {
                final at =
                    (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                final bt =
                    (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                return bt.compareTo(at);
              });
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada promo aktif'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final x = docs[i].data();
              final bytes = _decodeImage(x['imageBase64']);
              final endsAt = (x['endsAt'] as Timestamp?)?.toDate();
              final terms = (x['terms'] ?? '').toString().trim();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _showPromoDetail(context, x, bytes, endsAt),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bytes != null)
                        Image.memory(
                          bytes,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
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
                                    color: Colors.orange.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'PROMO',
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (endsAt != null)
                                  Text(
                                    's.d. ${_formatTanggal(endsAt)}',
                                    style: const TextStyle(
                                      color: AppColors.abu,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              (x['title'] ?? '-').toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text((x['description'] ?? '').toString()),
                            if (terms.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Ketentuan: $terms',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

  void _showPromoDetail(
    BuildContext context,
    Map<String, dynamic> x,
    Uint8List? bytes,
    DateTime? endsAt,
  ) {
    final terms = (x['terms'] ?? '').toString().trim();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    bytes,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                (x['title'] ?? '-').toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.biruTua,
                ),
              ),
              if (endsAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Berlaku sampai ${_formatTanggal(endsAt)}',
                  style: const TextStyle(color: AppColors.abu, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Text((x['description'] ?? '').toString()),
              if (terms.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Syarat & Ketentuan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.biruTua,
                  ),
                ),
                const SizedBox(height: 4),
                Text(terms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsFeed extends StatelessWidget {
  const _NewsFeed();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('news')
        .where('active', isEqualTo: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Gagal memuat berita: ${snapshot.error}'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final docs = snapshot.data!.docs.toList()
        ..sort((a, b) {
          final at =
              (a.data()['publishedAt'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          final bt =
              (b.data()['publishedAt'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          return bt.compareTo(at);
        });
      if (docs.isEmpty) {
        return const Center(child: Text('Belum ada berita'));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: docs.length,
        itemBuilder: (context, i) {
          final x = docs[i].data();
          final bytes = _decodeImage(x['imageBase64']);
          final publishedAt = (x['publishedAt'] as Timestamp?)?.toDate();
          final summary = (x['summary'] ?? '').toString().trim();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _showNewsDetail(context, x, bytes, publishedAt),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bytes != null)
                    Image.memory(
                      bytes,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                                color: AppColors.biru.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'BERITA',
                                style: TextStyle(
                                  color: AppColors.biru,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (publishedAt != null)
                              Text(
                                _formatTanggalJam(publishedAt),
                                style: const TextStyle(
                                  color: AppColors.abu,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (x['title'] ?? '-').toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (summary.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            summary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          (x['body'] ?? '').toString(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  void _showNewsDetail(
    BuildContext context,
    Map<String, dynamic> x,
    Uint8List? bytes,
    DateTime? publishedAt,
  ) {
    final summary = (x['summary'] ?? '').toString().trim();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    bytes,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                (x['title'] ?? '-').toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.biruTua,
                ),
              ),
              if (publishedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatTanggalJam(publishedAt),
                  style: const TextStyle(color: AppColors.abu, fontSize: 13),
                ),
              ],
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Text((x['body'] ?? '').toString()),
            ],
          ),
        ),
      ),
    );
  }
}
