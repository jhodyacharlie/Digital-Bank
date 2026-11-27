import 'package:flutter/material.dart';

class AppColors {
  static const biru = Color(0xFF0060AF);
  static const biruTua = Color(0xFF003B73);
  static const biruMuda = Color(0xFFE8F1FA);
  static const abu = Color(0xFF6B7785);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0D1420) : const Color(0xFFF2F6FC);

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF162032) : Colors.white;

  static Color cardAlt(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E2D45) : const Color(0xFFE8F1FA);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFEDF2FA) : const Color(0xFF003B73);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF9FB0C7) : const Color(0xFF6B7785);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF26364F) : const Color(0xFFDDE3EA);

  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFF4BA3FF) : biru;
}

InputDecoration inputStyle(
  String label,
  IconData ikon, {
  BuildContext? context,
}) {
  final fill = context != null ? AppColors.card(context) : Colors.white;
  final iconColor = context != null
      ? AppColors.accent(context)
      : AppColors.biru;
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(ikon, color: iconColor),
    filled: true,
    fillColor: fill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
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
            : Text(
                teks,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
