import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  MEDIVAANII — Royal Blue + White (Clinical, Professional)
//  Primary: #1565C0   Accent: #0288D1   BG: #F5F8FF
// ══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  static const blue900  = Color(0xFF0A2472);
  static const blue800  = Color(0xFF1565C0);  // primary
  static const blue700  = Color(0xFF1976D2);
  static const blue600  = Color(0xFF1E88E5);
  static const blue400  = Color(0xFF42A5F5);
  static const blue200  = Color(0xFFBBDEFB);
  static const blue100  = Color(0xFFE3F2FD);
  static const blue50   = Color(0xFFF5F8FF);

  static const accent   = Color(0xFF0288D1);  // sky blue accent
  static const accentBg = Color(0xFFE1F5FE);

  static const bg       = Color(0xFFF5F8FF);
  static const surface  = Color(0xFFFFFFFF);
  static const border   = Color(0xFFBBDEFB);

  static const success  = Color(0xFF059669);
  static const successBg= Color(0xFFD1FAE5);
  static const red      = Color(0xFFDC2626);
  static const redBg    = Color(0xFFFEE2E2);
  static const amber    = Color(0xFFD97706);

  static const textPrimary   = Color(0xFF0A2472);
  static const textSecondary = Color(0xFF1565C0);
  static const textMuted     = Color(0xFF90CAF9);

  // Aliases for existing code
  static const navy900  = blue900;
  static const navy800  = blue800;
  static const navy700  = blue700;
  static const navy600  = blue600;
  static const navy400  = blue400;
  static const navy200  = blue200;
  static const navy100  = blue100;
  static const navy50   = blue50;
  static const gold600  = accent;
  static const gold100  = accentBg;
  static const error    = red;
}

class MediSimpleTheme {
  MediSimpleTheme._();
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.blue800,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blue100,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.blue900,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: Colors.white, letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
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
      indicatorColor: AppColors.blue100,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
        fontSize: 11,
        fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        color: s.contains(WidgetState.selected) ? AppColors.blue800 : AppColors.textMuted,
      )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
        color: s.contains(WidgetState.selected) ? AppColors.blue800 : AppColors.textMuted,
        size: 22,
      )),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue800,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue800,
        side: const BorderSide(color: AppColors.blue200, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.blue100,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue800),
      side: const BorderSide(color: AppColors.blue200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.blue900,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.blue800,
      linearTrackColor: AppColors.blue100,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : AppColors.border),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.blue800 : AppColors.blue100),
    ),
  );
}

class APColors {
  static const primary      = AppColors.blue800;
  static const primaryDark  = AppColors.blue900;
  static const primaryLight = AppColors.blue50;
  static const secondary    = AppColors.accent;
  static const surface      = AppColors.surface;
  static const background   = AppColors.bg;
  static const error        = AppColors.red;
}
