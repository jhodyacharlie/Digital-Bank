import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'security_service.dart';

// Ganti dengan kontak resmi sebelum rilis.
const emailBantuan = 'cs@digeboy.com';
const teleponBantuan = '1500-123';
const jamLayanan = 'Setiap hari, 08.00 - 20.00 WIB';

// =====================================================================
// Halaman teks (Privacy Policy & Terms)
// =====================================================================

class BagianTeks {
  const BagianTeks(this.judul, this.isi);

  final String judul;
  final String isi;
}

class HalamanTeksScreen extends StatelessWidget {
  const HalamanTeksScreen({
    super.key,
    required this.judul,
    required this.bagian,
  });

  final String judul;
  final List<BagianTeks> bagian;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru(judul),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KartuBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in bagian) ...[
                  Text(
                    b.judul,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.teksUtama,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(b.isi, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 18),
                ],
                const Text(
                  'Teks ini contoh untuk pengembangan aplikasi dan perlu '
                  'ditinjau ahli hukum sebelum dirilis.',
                  style: TextStyle(
                    color: AppColors.abu,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HalamanTeksScreen(
      judul: 'Privacy Policy',
      bagian: [
        BagianTeks(
          '1. Data yang kami kumpulkan',
          'Saat kamu mendaftar dan memakai Digeboy, kami menyimpan nama, '
              'email, nomor HP, PIN (dalam bentuk terenkripsi/hash), foto '
              'profil, serta data profil yang kamu isi seperti tanggal lahir '
              'dan alamat. Kami juga mencatat riwayat transaksi, perangkat, '
              'dan aktivitas login.',
        ),
        BagianTeks(
          '2. Cara kami memakai data',
          'Data dipakai untuk menjalankan akunmu, memproses transaksi, '
              'menjaga keamanan, dan menghubungimu bila ada masalah. Kami '
              'tidak menjual datamu kepada pihak lain.',
        ),
        BagianTeks(
          '3. Keamanan data',
          'PIN tidak disimpan dalam bentuk asli. Kamu bisa menambah '
              'perlindungan lewat sidik jari dan verifikasi 2 langkah di '
              'menu Security & Privacy. Jangan pernah membagikan PIN atau '
              'kode verifikasi kepada siapa pun, termasuk petugas Digeboy.',
        ),
        BagianTeks(
          '4. Perangkat dan aktivitas login',
          'Kami mencatat perangkat dan waktu setiap login agar kamu bisa '
              'memantau akses ke akunmu di menu Manage Devices dan '
              'Login Activity.',
        ),
        BagianTeks(
          '5. Hak kamu',
          'Kamu bisa melihat dan memperbarui data profil kapan saja lewat '
              'Edit Profile. Untuk meminta penghapusan akun atau data, '
              'hubungi tim bantuan lewat menu Contact Support.',
        ),
        BagianTeks(
          '6. Perubahan kebijakan',
          'Kebijakan ini dapat diperbarui. Perubahan penting akan kami '
              'sampaikan lewat aplikasi.',
        ),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HalamanTeksScreen(
      judul: 'Terms & Conditions',
      bagian: [
        BagianTeks(
          '1. Persetujuan',
          'Dengan membuat akun dan memakai Digeboy, kamu setuju dengan '
              'syarat dan ketentuan ini.',
        ),
        BagianTeks(
          '2. Akun dan PIN',
          'Kamu bertanggung jawab menjaga kerahasiaan PIN dan perangkatmu. '
              'Semua transaksi yang memakai PIN atau sidik jari akunmu '
              'dianggap dilakukan olehmu.',
        ),
        BagianTeks(
          '3. Penggunaan layanan',
          'Layanan hanya boleh dipakai untuk kegiatan yang sah. Kami dapat '
              'membatasi atau menutup akun yang dipakai untuk penipuan atau '
              'pelanggaran hukum.',
        ),
        BagianTeks(
          '4. Transaksi',
          'Pastikan data penerima dan nominal sudah benar sebelum '
              'mengonfirmasi. Transaksi yang sudah berhasil tidak dapat '
              'dibatalkan sepihak.',
        ),
        BagianTeks(
          '5. Batasan tanggung jawab',
          'Digeboy berusaha menjaga layanan tetap tersedia, namun tidak '
              'menjamin layanan bebas gangguan. Kami tidak bertanggung jawab '
              'atas kerugian akibat PIN atau kode verifikasi yang kamu '
              'bagikan kepada pihak lain.',
        ),
        BagianTeks(
          '6. Hukum yang berlaku',
          'Ketentuan ini tunduk pada hukum yang berlaku di Republik '
              'Indonesia.',
        ),
      ],
    );
  }
}

// =====================================================================
// Help Center
// =====================================================================

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const faq = [
    BagianTeks(
      'Bagaimana cara mendaftar akun?',
      'Di halaman login ketuk "Daftar", isi data diri, lalu buat PIN 6 '
          'angka. Setelah berhasil kamu langsung masuk ke Beranda.',
    ),
    BagianTeks(
      'Saya lupa PIN, apa yang harus dilakukan?',
      'Ketuk "Lupa PIN?" di halaman login, masukkan email atau nomor HP '
          'terdaftar, masukkan kode verifikasi, lalu buat PIN baru.',
    ),
    BagianTeks(
      'Bagaimana cara mengganti PIN?',
      'Buka Profil > Security & Privacy > Change PIN, lalu ikuti langkahnya.',
    ),
    BagianTeks(
      'Bagaimana mengaktifkan login sidik jari?',
      'Login dengan PIN satu kali, lalu pastikan Biometric Authentication '
          'aktif di Profil > Security & Privacy. HP-mu harus sudah punya '
          'sidik jari terdaftar.',
    ),
    BagianTeks(
      'Apa itu verifikasi 2 langkah?',
      'Kalau aktif, setiap kali login kamu perlu memasukkan kode 6 angka '
          'setelah PIN atau sidik jari. Aktifkan di Profil > Security & '
          'Privacy > Two-Factor Authentication.',
    ),
    BagianTeks(
      'Bagaimana memeriksa perangkat dan aktivitas login?',
      'Buka Profil > Security & Privacy, lalu pilih Manage Devices atau '
          'Login Activity. Kalau ada yang tidak kamu kenali, segera ganti PIN.',
    ),
    BagianTeks(
      'Bagaimana cara transfer dengan QRIS?',
      'Ketuk menu QRIS di Beranda, arahkan kamera ke kode QRIS Digeboy '
          'penerima, isi nominal, lalu konfirmasi. Kamu juga bisa menampilkan '
          'QRIS milikmu lewat "QRIS Saya".',
    ),
    BagianTeks(
      'Bagaimana mengubah data pribadi?',
      'Buka Profil lalu ketuk Edit Profile. Email dan nomor HP belum bisa '
          'diubah di versi demo.',
    ),
  ];

  final TextEditingController cariController = TextEditingController();

  @override
  void dispose() {
    cariController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kata = cariController.text.trim().toLowerCase();
    final hasil = faq.where((f) {
      return kata.isEmpty ||
          f.judul.toLowerCase().contains(kata) ||
          f.isi.toLowerCase().contains(kata);
    }).toList();

    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Help Center'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: cariController,
            onChanged: (_) => setState(() {}),
            decoration: inputStyle(context, 'Cari bantuan', Icons.search),
          ),
          const SizedBox(height: 16),
          if (hasil.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Tidak ada hasil. Coba kata lain atau hubungi Contact Support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.abu),
                ),
              ),
            )
          else
            KartuBox(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: hasil.map((f) {
                  return ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(
                      f.judul,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.teksUtama,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(f.isi, style: const TextStyle(height: 1.5))],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// Contact Support
// =====================================================================

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  static const kategori = ['Transaksi', 'Akun', 'Keamanan', 'Lainnya'];

  final SecurityService security = SecurityService();
  final TextEditingController pesanController = TextEditingController();

  String dipilih = 'Akun';
  bool loading = false;

  @override
  void dispose() {
    pesanController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> salin(String teks) async {
    await Clipboard.setData(ClipboardData(text: teks));
    pesan('Disalin: $teks');
  }

  Future<void> kirim() async {
    final isi = pesanController.text.trim();
    if (isi.length < 10) {
      pesan('Tulis pesanmu minimal 10 karakter');
      return;
    }

    setState(() => loading = true);
    bool berhasil = true;
    try {
      await security.kirimTiket(
        userId: widget.user['id'],
        nama: widget.user['nama'] ?? '',
        email: widget.user['email'] ?? '',
        kategori: dipilih,
        pesan: isi,
      );
    } catch (e) {
      berhasil = false;
    }
    if (!mounted) return;
    setState(() => loading = false);

    if (!berhasil) {
      pesan('Gagal mengirim pesan');
      return;
    }
    pesanController.clear();
    pesan('Pesan terkirim. Tim kami akan menghubungimu lewat email.');
  }

  Widget kontak(IconData ikon, String judul, String nilai) {
    return InkWell(
      onTap: () => salin(nilai),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(ikon, color: AppColors.biru),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(color: AppColors.abu)),
                  Text(
                    nilai,
                    style: TextStyle(
                      color: context.teksUtama,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy, size: 18, color: AppColors.abu),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.latar,
      appBar: appBarBiru('Contact Support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KartuBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  kontak(Icons.mail_outline, 'Email', emailBantuan),
                  const Divider(height: 1),
                  kontak(Icons.phone_outlined, 'Telepon', teleponBantuan),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.biru),
                        const SizedBox(width: 12),
                        Text(
                          jamLayanan,
                          style: const TextStyle(color: AppColors.abu),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            KartuBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kirim pesan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.teksUtama,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: kategori
                        .map(
                          (k) => ChoiceChip(
                            label: Text(k),
                            selected: dipilih == k,
                            onSelected: (_) => setState(() => dipilih = k),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pesanController,
                    enabled: !loading,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Ceritakan kendalamu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TombolBiru(teks: 'Kirim', onPressed: kirim, loading: loading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
