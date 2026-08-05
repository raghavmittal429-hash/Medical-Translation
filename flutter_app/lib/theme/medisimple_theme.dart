import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  MEDIVAANII — Saffron + Dark Brown (Traditional Indian)
//  Primary: #C45E00   Dark: #8B3E00   BG: #FDF6EC
// ══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();
  static const brown900 = Color(0xFF3D1A00);
  static const brown800 = Color(0xFF8B3E00);  // app bar / dark
  static const brown700 = Color(0xFFA04800);
  static const saffron  = Color(0xFFC45E00);  // primary
  static const saffron2 = Color(0xFFD97706);  // mid
  static const saffron3 = Color(0xFFE08A00);  // light variant
  static const gold     = Color(0xFFD4A017);  // accent gold
  static const gold600  = Color(0xFFD4A017);  // alias used in main.dart
  static const gold100  = Color(0xFFFEF3C7);  // alias used in main.dart
  static const goldBg   = Color(0xFFFEF3C7);  // gold tint
  static const cream    = Color(0xFFFDF6EC);  // page background
  static const border   = Color(0xFFF0D5B0);  // warm border
  static const surface  = Color(0xFFFFFFFF);
  static const bg       = Color(0xFFFDF6EC);

  static const success  = Color(0xFF059669);
  static const red      = Color(0xFFDC2626);
  static const amber    = Color(0xFFD97706);

  static const textPrimary   = Color(0xFF3D1A00);
  static const textSecondary = Color(0xFF7C3D0A);
  static const textMuted     = Color(0xFFB8865A);

  // Aliases so existing code compiles unchanged
  static const navy900  = brown900;
  static const navy800  = saffron;
  static const navy700  = saffron2;
  static const navy600  = saffron3;
  static const navy400  = Color(0xFFE8A060);
  static const navy200  = border;
  static const navy100  = Color(0xFFF5DBA0);
  static const navy50   = goldBg;
  static const green800 = saffron;
  static const green900 = brown800;
  static const green700 = saffron2;
  static const green50  = goldBg;
}

class MediSimpleTheme {
  MediSimpleTheme._();
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.saffron,
        onPrimary: Colors.white,
        primaryContainer: AppColors.goldBg,
        secondary: AppColors.gold,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.brown800,
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
        indicatorColor: AppColors.goldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? AppColors.brown800 : AppColors.textMuted,
        )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? AppColors.brown800 : AppColors.textMuted,
          size: 22,
        )),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.saffron,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.goldBg,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brown800),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.brown900,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.saffron,
        linearTrackColor: AppColors.goldBg,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.border),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.saffron : AppColors.goldBg),
      ),
    );
  }
}

class APColors {
  static const primary      = AppColors.saffron;
  static const primaryDark  = AppColors.brown800;
  static const primaryLight = AppColors.goldBg;
  static const secondary    = AppColors.gold;
  static const surface      = AppColors.surface;
  static const background   = AppColors.cream;
  static const error        = AppColors.red;
}
