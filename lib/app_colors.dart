import 'package:flutter/material.dart';

/// Warna utama aplikasi MyBCA
/// Gabungan dari AppColors (global) dan BCAColors (history feature)
class AppColors {
  // ── Brand / Primary ───────────────────────────────────────────
  static const Color primary       = Color(0xFF0060AF); // Banking Blue (AppColors)
  static const Color primaryBlue   = Color(0xFF07549A); // BCA Primary Blue
  static const Color secondaryBlue = Color(0xFF0066B3); // BCA Secondary Blue
  static const Color secondary     = Color(0xFFEAF3FB); // Light Blue accent

  // ── Background & Surface ──────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF); // White background
  static const Color surface    = Color(0xFFF5F7FA); // Light Gray surface
  static const Color white      = Color(0xFFFFFFFF);
  static const Color lightGray  = Color(0xFFF4F6F9); // BCA light gray

  // ── Text ──────────────────────────────────────────────────────
  static const Color textDark      = Color(0xFF172B4D); // Dark Navy (AppColors)
  static const Color textGrey      = Color(0xFF6B778C); // AppColors grey
  static const Color secondaryText = Color(0xFF89939F); // BCA secondary text

  // ── Status ────────────────────────────────────────────────────
  static const Color success       = Color(0xFF24A66A); // AppColors green
  static const Color incomeGreen   = Color(0xFF16864B); // BCA income green
  static const Color danger        = Color(0xFFD64545); // AppColors red
  static const Color expenseRed    = Color(0xFFD94343); // BCA expense red
  static const Color pendingOrange = Color(0xFFE6A817); // BCA pending

  // ── Status Backgrounds ────────────────────────────────────────
  static const Color successBg = Color(0xFFE8F5EE);
  static const Color pendingBg = Color(0xFFFFF8E6);
  static const Color failedBg  = Color(0xFFFFEDED);

  // ── Border & Divider ──────────────────────────────────────────
  static const Color border  = Color(0xFFE3E8EF); // AppColors border
  static const Color divider = Color(0xFFE8ECF0); // BCA divider

  // ── Misc ──────────────────────────────────────────────────────
  static const Color star = Color(0xFFF5A623); // Rating star
}

/// Alias untuk backward compatibility —
/// file lama yang masih pakai BCAColors tidak perlu diubah
class BCAColors {
  static const Color primaryBlue   = AppColors.primaryBlue;
  static const Color secondaryBlue = AppColors.secondaryBlue;
  static const Color white         = AppColors.white;
  static const Color lightGray     = AppColors.lightGray;
  static const Color incomeGreen   = AppColors.incomeGreen;
  static const Color expenseRed    = AppColors.expenseRed;
  static const Color textDark      = AppColors.textDark;
  static const Color secondaryText = AppColors.secondaryText;
  static const Color divider       = AppColors.divider;
  static const Color successBg     = AppColors.successBg;
  static const Color pendingBg     = AppColors.pendingBg;
  static const Color failedBg      = AppColors.failedBg;
  static const Color pendingOrange = AppColors.pendingOrange;
}
