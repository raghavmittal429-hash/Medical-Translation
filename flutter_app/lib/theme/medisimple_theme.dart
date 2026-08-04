import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  MEDISIMPLE — Deep Navy + Gold Design System
//  Primary: #0A2342   Accent: #C9890A   BG: #F4F6FA
// ══════════════════════════════════════════════════════════

class AppColors {
  AppColors._();
  static const navy900  = Color(0xFF040F1E);
  static const navy800  = Color(0xFF0A2342);
  static const navy700  = Color(0xFF0E2F58);
  static const navy600  = Color(0xFF1A3A5C);
  static const navy400  = Color(0xFF4A6A8A);
  static const navy200  = Color(0xFFB8CAD9);
  static const navy100  = Color(0xFFDCE5EE);
  static const navy50   = Color(0xFFEBF0F5);

  static const gold600  = Color(0xFFC9890A);
  static const gold500  = Color(0xFFE09A12);
  static const gold100  = Color(0xFFFEF3C7);
  static const gold50   = Color(0xFFFFFBEB);

  static const bg       = Color(0xFFF4F6FA);
  static const surface  = Color(0xFFFFFFFF);
  static const border   = Color(0xFFE2E8F0);

  static const green    = Color(0xFF059669);
  static const greenBg  = Color(0xFFD1FAE5);
  static const red      = Color(0xFFDC2626);
  static const redBg    = Color(0xFFFEE2E2);
  static const amber    = Color(0xFFD97706);
  static const amberBg  = Color(0xFFFEF3C7);

  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted     = Color(0xFF94A3B8);
}

class MediSimpleTheme {
  MediSimpleTheme._();
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy800,
        onPrimary: Colors.white,
        primaryContainer: AppColors.navy50,
        secondary: AppColors.gold600,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy800,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.navy900.withValues(alpha: 0.4),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.navy50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11, fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? AppColors.navy800 : AppColors.textMuted,
        )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.navy800 : AppColors.textMuted,
          size: 22,
        )),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy800,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy800,
          side: const BorderSide(color: AppColors.navy200, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 1, space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navy50,
        labelStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.navy700,
        ),
        side: const BorderSide(color: AppColors.navy100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy900,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navy800,
        linearTrackColor: AppColors.navy50,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.border),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.navy800 : AppColors.navy100),
      ),
    );
  }
}

// Legacy alias so existing APColors.X references keep compiling
class APColors {
  static const primary      = AppColors.navy800;
  static const primaryDark  = AppColors.navy900;
  static const primaryLight = AppColors.navy50;
  static const secondary    = AppColors.gold600;
  static const surface      = AppColors.surface;
  static const background   = AppColors.bg;
  static const error        = AppColors.red;
}
