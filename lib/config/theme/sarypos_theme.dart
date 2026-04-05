import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WarnaSarypos {
  static const Color saryRed = Color(0xFFD3291E);
  static const Color deepTeal = Color(0xFF1C4546);
  static const Color saryGold = Color(0xFFE4AF1A);
  static const Color cleanWhite = Color(0xFFFEFEFE);
  static const Color warmGray = Color(0xFFCDC5BB);
  static const Color darkStone = Color(0xFF6E6B61);

  static const Color hijauSukses = Color(0xFF1E8E3E);

  static const Color _latarGelap = Color(0xFF121A1C);
  static const Color _permukaanGelap = Color(0xFF1A2629);
  static const Color _permukaanKartuGelap = Color(0xFF223034);
  static const Color _teksUtamaGelap = Color(0xFFF0EBE3);
  static const Color _teksSekunderGelap = Color(0xFFADA59A);

  static const Color _onGoldTerang = Color(0xFF2B2104);
  static const Color _onGoldGelap = Color(0xFF1C1608);
  static const Color _errorGelapLebihTerang = Color(0xFFFF6B5C);
  static const Color _outlineGelap = Color(0xFF3D4D50);
  static const Color _outlineVarianGelap = Color(0xFF2A3639);
  static const Color _bayanganHitam = Color(0xFF000000);
}

Color warnaAksenJudulBagian(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? WarnaSarypos.saryGold
      : WarnaSarypos.deepTeal;
}

TextTheme _teksPlusJakarta(ColorScheme colorScheme, Brightness brightness) {
  final baseTextTheme = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  final base = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
  return base.copyWith(
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
    ),
  );
}

const PageTransitionsTheme _transisiHalamanStandar = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
  },
);

ThemeData temaSaryposTerang() {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: WarnaSarypos.saryRed,
        brightness: Brightness.light,
      ).copyWith(
        primary: WarnaSarypos.saryRed,
        onPrimary: Colors.white,
        secondary: WarnaSarypos.saryGold,
        onSecondary: WarnaSarypos._onGoldTerang,
        tertiary: WarnaSarypos.deepTeal,
        onTertiary: Colors.white,
        error: WarnaSarypos.saryRed,
        surface: WarnaSarypos.cleanWhite,
        onSurface: Colors.black87,
        onSurfaceVariant: WarnaSarypos.darkStone,
      );

  final textTheme = _teksPlusJakarta(colorScheme, Brightness.light);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: WarnaSarypos.cleanWhite,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WarnaSarypos.warmGray.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WarnaSarypos.warmGray.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WarnaSarypos.warmGray.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WarnaSarypos.deepTeal.withValues(alpha: 0.95),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WarnaSarypos.saryRed.withValues(alpha: 0.95),
          width: 1.6,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WarnaSarypos.saryRed.withValues(alpha: 0.95),
          width: 1.6,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minLeadingWidth: 40,
      horizontalTitleGap: 12,
      minVerticalPadding: 8,
      visualDensity: VisualDensity.comfortable,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: WarnaSarypos.deepTeal,
      foregroundColor: colorScheme.onTertiary,
      elevation: 2,
      centerTitle: false,
      iconTheme: IconThemeData(color: colorScheme.onTertiary),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onTertiary,
        height: 1.25,
      ),
      toolbarTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorScheme.onTertiary,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.onSurface,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: WarnaSarypos.deepTeal,
      selectedItemColor: WarnaSarypos.saryGold,
      unselectedItemColor: WarnaSarypos.warmGray,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.tertiary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.9)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: const CardThemeData(
      color: WarnaSarypos.cleanWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.all(8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 3,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onInverseSurface,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerColor: WarnaSarypos.warmGray,
    dialogTheme: DialogThemeData(
      backgroundColor: WarnaSarypos.cleanWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    iconTheme: const IconThemeData(color: WarnaSarypos.darkStone),
    pageTransitionsTheme: _transisiHalamanStandar,
  );
}

ThemeData temaSaryposGelap() {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: WarnaSarypos.saryRed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: WarnaSarypos.saryRed,
        onPrimary: Colors.white,
        secondary: WarnaSarypos.saryGold,
        onSecondary: WarnaSarypos._onGoldGelap,
        tertiary: WarnaSarypos.deepTeal,
        onTertiary: Colors.white,
        error: WarnaSarypos._errorGelapLebihTerang,
        onError: Colors.white,
        surface: WarnaSarypos._latarGelap,
        onSurface: WarnaSarypos._teksUtamaGelap,
        onSurfaceVariant: WarnaSarypos._teksSekunderGelap,
        surfaceContainerHighest: WarnaSarypos._permukaanKartuGelap,
        surfaceContainerHigh: WarnaSarypos._permukaanGelap,
        outline: WarnaSarypos._outlineGelap,
        outlineVariant: WarnaSarypos._outlineVarianGelap,
      );

  final textTheme = _teksPlusJakarta(colorScheme, Brightness.dark);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: WarnaSarypos._latarGelap,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.95),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.85),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.85),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WarnaSarypos.saryGold.withValues(alpha: 0.9),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.95),
          width: 1.6,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.95),
          width: 1.6,
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minLeadingWidth: 40,
      horizontalTitleGap: 12,
      minVerticalPadding: 8,
      visualDensity: VisualDensity.comfortable,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: WarnaSarypos.deepTeal,
      foregroundColor: colorScheme.onTertiary,
      elevation: 2,
      centerTitle: false,
      iconTheme: IconThemeData(color: colorScheme.onTertiary),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onTertiary,
        height: 1.25,
      ),
      toolbarTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorScheme.onTertiary,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.onSurface,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.secondary,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: WarnaSarypos.deepTeal,
      selectedItemColor: WarnaSarypos.saryGold,
      unselectedItemColor: WarnaSarypos.warmGray,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.secondary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.9)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: WarnaSarypos._permukaanKartuGelap,
      elevation: 4,
      shadowColor: WarnaSarypos._bayanganHitam.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: const EdgeInsets.all(8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 3,
      backgroundColor: WarnaSarypos._permukaanGelap,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerColor: colorScheme.outline.withValues(alpha: 0.5),
    dialogTheme: DialogThemeData(
      backgroundColor: WarnaSarypos._permukaanGelap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    pageTransitionsTheme: _transisiHalamanStandar,
  );
}

ThemeData temaSarypos({Brightness brightness = Brightness.light}) =>
    brightness == Brightness.dark ? temaSaryposGelap() : temaSaryposTerang();
