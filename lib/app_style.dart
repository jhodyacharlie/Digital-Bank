import 'package:flutter/material.dart';

class AppColors {
  static const biru = Color(0xFF0060AF);
  static const biruTua = Color(0xFF003B73);
  static const biruMuda = Color(0xFFE8F1FA);
  static const abu = Color(0xFF6B7785);
}

InputDecoration inputStyle(String label, IconData ikon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(ikon, color: AppColors.biru),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
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
