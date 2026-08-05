import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  MEDIVAANII — Deep Green + Gold (Ayurvedic, Natural)
//  Primary: #1A5C2A   Accent: #C9890A   BG: #F1F8F2
// ══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();
  static const green900 = Color(0xFF0A2E12);
  static const green800 = Color(0xFF1A5C2A);  // primary
  static const green700 = Color(0xFF1F6E32);
  static const green600 = Color(0xFF2E7D40);
  static const green400 = Color(0xFF5A9E68);
  static const green200 = Color(0xFFA5D6A7);
  static const green100 = Color(0xFFC8E6C9);
  static const green50  = Color(0xFFE8F5E9);

  static const gold600  = Color(0xFFC9890A);
  static const gold500  = Color(0xFFE09A12);
  static const gold100  = Color(0xFFFFF8E1);
  static const gold50   = Color(0xFFFFFBEB);

  static const bg       = Color(0xFFF1F8F2);
  static const surface  = Color(0xFFFFFFFF);
  static const border   = Color(0xFFDCEEDE);

  static const success  = Color(0xFF059669);
  static const red      = Color(0xFFDC2626);
  static const amber    = Color(0xFFD97706);

  static const textPrimary   = Color(0xFF0A2E12);
  static const textSecondary = Color(0xFF4A7A52);
  static const textMuted     = Color(0xFF8AB890);

  // Aliases so existing code using navy* keeps compiling
  static const navy800  = green800;
  static const navy900  = green900;
  static const navy700  = green700;
  static const navy600  = green600;
  static const navy400  = green400;
  static const navy200  = green200;
  static const navy100  = green100;
  static const navy50   = green50;
}

class MediSimpleTheme {
  MediSimpleTheme._();
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green800,
        onPrimary: Colors.white,
        primaryContainer: AppColors.green50,
        secondary: AppColors.gold600,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.green900,
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
        shadowColor: AppColors.green900.withValues(alpha: 0.4),
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
        indicatorColor: AppColors.green50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11, fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? AppColors.green800 : AppColors.textMuted,
        )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.green800 : AppColors.textMuted,
          size: 22,
        )),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green800,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green800,
          side: const BorderSide(color: AppColors.green200, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.green50,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.green700),
        side: const BorderSide(color: AppColors.green100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.green900,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.green800,
        linearTrackColor: AppColors.green50,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.border),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.green800 : AppColors.green100),
      ),
    );
  }
}

class APColors {
  static const primary      = AppColors.green800;
  static const primaryDark  = AppColors.green900;
  static const primaryLight = AppColors.green50;
  static const secondary    = AppColors.gold600;
  static const surface      = AppColors.surface;
  static const background   = AppColors.bg;
  static const error        = AppColors.red;
}
