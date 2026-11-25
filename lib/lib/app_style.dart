import 'package:flutter/material.dart';

class AppColors {
  static const biru = Color(0xFF0060AF);
  static const biruTua = Color(0xFF003B73);
  static const biruMuda = Color(0xFFE8F1FA);
  static const abu = Color(0xFF6B7785);

  // Warna khusus mode gelap
  static const latarGelap = Color(0xFF0E1621);
  static const kartuGelap = Color(0xFF182231);
  static const teksGelap = Color(0xFFE6EDF5);
  static const garisGelap = Color(0xFF2A3647);
}

/// Warna yang otomatis ikut mode terang / gelap.
/// Pakai `context.latar`, `context.kartu`, dan `context.teksUtama`
/// sebagai pengganti `AppColors.biruMuda`, `Colors.white` (kartu),
/// dan `AppColors.biruTua` (teks).
extension TemaWarna on BuildContext {
  bool get gelap => Theme.of(this).brightness == Brightness.dark;

  Color get latar => gelap ? AppColors.latarGelap : AppColors.biruMuda;
  Color get layar => gelap ? AppColors.latarGelap : Colors.white;
  Color get kartu => gelap ? AppColors.kartuGelap : Colors.white;
  Color get teksUtama => gelap ? AppColors.teksGelap : AppColors.biruTua;
  Color get garis => gelap ? AppColors.garisGelap : const Color(0xFFDDE3EA);
}

InputDecoration inputStyle(BuildContext context, String label, IconData ikon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(ikon, color: AppColors.biru),
    filled: true,
    fillColor: context.kartu,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

AppBar appBarBiru(String judul) {
  return AppBar(
    backgroundColor: AppColors.biru,
    foregroundColor: Colors.white,
    title: Text(judul),
  );
}

/// Kotak putih (gelap di dark mode) berisi konten, dipakai di halaman profil.
class KartuBox extends StatelessWidget {
  const KartuBox({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: context.kartu,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Satu baris syarat dengan ikon centang (hijau kalau sudah terpenuhi).
class SyaratItem extends StatelessWidget {
  const SyaratItem(this.teks, this.terpenuhi, {super.key});

  final String teks;
  final bool terpenuhi;

  @override
  Widget build(BuildContext context) {
    final warna = terpenuhi ? Colors.green.shade600 : Colors.grey.shade500;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            terpenuhi ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: warna,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(teks, style: TextStyle(fontSize: 12, color: warna)),
          ),
        ],
      ),
    );
  }
}

class TombolBiru extends StatelessWidget {
  const TombolBiru({
    super.key,
    required this.teks,
    required this.onPressed,
    this.loading = false,
  });

  final String teks;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.biru,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(teks, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
