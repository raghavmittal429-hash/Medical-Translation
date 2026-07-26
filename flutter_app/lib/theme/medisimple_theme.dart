import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  MEDISIMPLE — Clinical Indigo Theme
//  Palette: Deep Indigo · Cyan · Emerald · Slate
//  Direction: premium digital health — trustworthy, precise, modern.
//  Departing from the previous crimson/blush (red = danger in healthcare)
//  toward a calmer, more clinical indigo that reads as authoritative
//  without feeling alarming.
// ═══════════════════════════════════════════════════════════════

class APColors {
  APColors._();

  // Primary — Deep Indigo
  static const Color primary900 = Color(0xFF1E1B4B);
  static const Color primary800 = Color(0xFF2E2A78);  // AppBar / header
  static const Color primary700 = Color(0xFF3730A3);
  static const Color primary600 = Color(0xFF4F46E5);  // ← Main brand colour
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary50  = Color(0xFFEEF2FF);

  // Accent — Cyan (action highlights, TTS, links)
  static const Color cyan600    = Color(0xFF0891B2);
  static const Color cyan500    = Color(0xFF06B6D4);
  static const Color cyan100    = Color(0xFFCFFAFE);
  static const Color cyan50     = Color(0xFFECFEFF);

  // Semantic
  static const Color success    = Color(0xFF059669);  // Emerald
  static const Color successBg  = Color(0xFFD1FAE5);
  static const Color warning    = Color(0xFFD97706);  // Amber
  static const Color warningBg  = Color(0xFFFEF3C7);
  static const Color danger     = Color(0xFFDC2626);  // Red (kept for critical lab values)
  static const Color dangerBg   = Color(0xFFFEE2E2);
  static const Color info       = Color(0xFF0284C7);  // Sky blue
  static const Color infoBg     = Color(0xFFE0F2FE);

  // Neutral — Slate
  static const Color slate900   = Color(0xFF0F172A);
  static const Color slate800   = Color(0xFF1E293B);
  static const Color slate700   = Color(0xFF334155);
  static const Color slate600   = Color(0xFF475569);
  static const Color slate400   = Color(0xFF94A3B8);
  static const Color slate200   = Color(0xFFE2E8F0);
  static const Color slate100   = Color(0xFFF1F5F9);
  static const Color slate50    = Color(0xFFF8FAFC);

  // Surfaces
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5FB);  // cool blue-tinted page bg

  // Legacy aliases kept so existing widget references compile unchanged
  static const Color crimson600 = primary600;
  static const Color crimson800 = primary800;
  static const Color crimson900 = primary900;
  static const Color crimson50  = primary50;
  static const Color crimson100 = primary100;
  static const Color crimson200 = primary200;
  static const Color charcoal900 = slate900;
  static const Color charcoal800 = slate800;
  static const Color charcoal700 = slate700;
  static const Color charcoal600 = slate600;
  static const Color charcoal400 = slate400;
  static const Color charcoal200 = slate200;
  static const Color charcoal100 = slate100;
  static const Color charcoal50  = slate50;
  static const Color blush300    = primary200;
  static const Color error       = danger;
}

class APTextStyles {
  APTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: APColors.slate900, letterSpacing: -0.5,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: APColors.slate900, letterSpacing: -0.2,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600, color: APColors.slate800,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, color: APColors.slate800,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: APColors.slate800, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: APColors.slate700, height: 1.45,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: APColors.slate400, letterSpacing: 0.6,
  );
  static const TextStyle crimsonLabel = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: APColors.primary600, letterSpacing: 0.3,
  );
}

class APSpacing {
  APSpacing._();
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;
}

class APRadius {
  APRadius._();
  static const double sm   = 6.0;
  static const double md   = 8.0;
  static const double lg   = 12.0;
  static const double xl   = 16.0;
  static const double pill = 100.0;
}

class APShadows {
  APShadows._();
  static List<BoxShadow> get card => [
    BoxShadow(
      color: APColors.primary600.withValues(alpha: 0.07),
      blurRadius: 14, offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4, offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: APColors.primary600.withValues(alpha: 0.14),
      blurRadius: 24, offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8, offset: const Offset(0, 2),
    ),
  ];
}

class MediSimpleTheme {
  MediSimpleTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: APColors.background,

    colorScheme: const ColorScheme.light(
      primary: APColors.primary600,
      onPrimary: Colors.white,
      primaryContainer: APColors.primary50,
      onPrimaryContainer: APColors.primary900,
      secondary: APColors.cyan600,
      onSecondary: Colors.white,
      secondaryContainer: APColors.cyan50,
      onSecondaryContainer: APColors.slate900,
      surface: APColors.surface,
      onSurface: APColors.slate900,
      error: APColors.danger,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: APColors.primary800,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: Colors.white, letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: APColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(APRadius.lg),
        side: const BorderSide(color: APColors.primary200, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: APSpacing.md),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: APColors.primary600,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: APSpacing.xl, vertical: APSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(APRadius.md),
        ),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: APColors.primary600,
        side: const BorderSide(color: APColors.primary600, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: APSpacing.xl, vertical: APSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(APRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: APColors.primary600,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: APColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: APSpacing.lg, vertical: APSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(APRadius.md),
        borderSide: const BorderSide(color: APColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(APRadius.md),
        borderSide: const BorderSide(color: APColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(APRadius.md),
        borderSide: const BorderSide(color: APColors.primary600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(APRadius.md),
        borderSide: const BorderSide(color: APColors.danger),
      ),
      hintStyle: const TextStyle(color: APColors.slate400, fontSize: 14),
      labelStyle: const TextStyle(color: APColors.slate600, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: APColors.primary600, fontSize: 12),
    ),

    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: APColors.surface,
      indicatorColor: APColors.primary100,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? APColors.primary700 : APColors.slate400,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? APColors.primary700 : APColors.slate400,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: APColors.primary50,
      selectedColor: APColors.primary600,
      labelStyle: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: APColors.primary800,
      ),
      side: const BorderSide(color: APColors.primary200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(APRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    dividerTheme: const DividerThemeData(
      color: APColors.slate200, thickness: 1, space: 1,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: APColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(APRadius.xl),
      ),
      titleTextStyle: APTextStyles.headlineMedium,
      contentTextStyle: APTextStyles.bodyMedium,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: APColors.slate900,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: APColors.primary400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(APRadius.md),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: APColors.primary600,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: APSpacing.lg, vertical: APSpacing.xs,
      ),
      iconColor: APColors.primary600,
      titleTextStyle: APTextStyles.bodyLarge,
      subtitleTextStyle: APTextStyles.bodyMedium,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? APColors.surface : APColors.slate200,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? APColors.primary600 : APColors.slate200,
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? APColors.primary600 : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: APColors.slate400, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? APColors.primary600 : APColors.slate400,
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: APColors.primary600,
      linearTrackColor: APColors.primary100,
      circularTrackColor: APColors.primary100,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: APColors.primary700,
      unselectedLabelColor: APColors.slate400,
      indicatorColor: APColors.primary600,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: APColors.slate900,
        borderRadius: BorderRadius.circular(APRadius.sm),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

// ── Reusable Widget Components ───────────────────────────────────

class APCard extends StatelessWidget {
  const APCard({
    super.key, required this.child,
    this.accent = false, this.padding, this.margin,
  });
  final Widget child;
  final bool accent;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: APSpacing.md),
      decoration: BoxDecoration(
        color: APColors.surface,
        borderRadius: BorderRadius.circular(APRadius.lg),
        border: Border(
          left: accent
              ? const BorderSide(color: APColors.primary600, width: 3)
              : BorderSide.none,
          top:    const BorderSide(color: APColors.primary200),
          right:  const BorderSide(color: APColors.primary200),
          bottom: const BorderSide(color: APColors.primary200),
        ),
        boxShadow: APShadows.card,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(APSpacing.lg),
        child: child,
      ),
    );
  }
}

class APStatusBadge extends StatelessWidget {
  const APStatusBadge({super.key, required this.label, this.type = APBadgeType.neutral});
  final String label;
  final APBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      APBadgeType.success  => (APColors.successBg, const Color(0xFF065F46)),
      APBadgeType.warning  => (APColors.warningBg, const Color(0xFF92400E)),
      APBadgeType.danger   => (APColors.dangerBg, const Color(0xFF991B1B)),
      APBadgeType.neutral  => (APColors.slate100, APColors.slate700),
      APBadgeType.primary  => (APColors.primary50, APColors.primary800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(APRadius.pill),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.3,
      )),
    );
  }
}

enum APBadgeType { success, warning, danger, neutral, primary }

class APSectionHeader extends StatelessWidget {
  const APSectionHeader({super.key, required this.title, this.icon, this.trailing});
  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: APSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: APColors.primary50,
                borderRadius: BorderRadius.circular(APRadius.sm),
              ),
              child: Icon(icon, color: APColors.primary600, size: 18),
            ),
            const SizedBox(width: APSpacing.sm),
          ],
          Expanded(child: Text(title, style: APTextStyles.headlineMedium)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class APPrimaryButton extends StatelessWidget {
  const APPrimaryButton({
    super.key, required this.label,
    this.onPressed, this.icon, this.loading = false, this.fullWidth = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
