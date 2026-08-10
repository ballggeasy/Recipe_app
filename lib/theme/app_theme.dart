import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ธีมกลางของแอป — มินิมอล สีขาวสะอาด มีจุดเน้นสีเขียวมะกอกอุ่น ๆ
/// รองรับทั้งโหมดสว่างและมืด
class AppTheme {
  // ---- โหมดสว่าง ----
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF4A6B4D); // เขียวมะกอกหม่น
  static const Color primaryLight = Color(0xFFE8EEE6);
  static const Color textPrimary = Color(0xFF2B2B26);
  static const Color textSecondary = Color(0xFF8A8A82);
  static const Color divider = Color(0xFFEDEDE8);
  static const Color accentRed = Color(0xFFC4564A);

  // ---- โหมดมืด ----
  static const Color backgroundDark = Color(0xFF15170F);
  static const Color surfaceDark = Color(0xFF1F2219);
  static const Color primaryDark = Color(0xFF8FBB8F);
  static const Color primaryLightDark = Color(0xFF2A3324);
  static const Color textPrimaryDark = Color(0xFFEDEDE6);
  static const Color textSecondaryDark = Color(0xFFA3A79A);
  static const Color dividerDark = Color(0xFF2E3226);
  static const Color accentRedDark = Color(0xFFE0837A);

  // ---- Design tokens ----
  static const double radiusCard = 18.0;
  static const double radiusButton = 14.0;
  static const double radiusInput = 14.0;
  static const double radiusChip = 20.0;

  // ---- Shadows ----
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF2B2B26).withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF2B2B26).withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardShadowDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.nunitoTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textPrimary),
        bodySmall: textTheme.bodySmall?.copyWith(color: textSecondary),
        titleLarge: textTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      dividerColor: divider,
      cardColor: surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusChip)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimaryDark),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textPrimaryDark),
        bodySmall: textTheme.bodySmall?.copyWith(color: textSecondaryDark),
        titleLarge: textTheme.titleLarge?.copyWith(color: textPrimaryDark, fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(color: textPrimaryDark, fontWeight: FontWeight.w600),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDark,
        brightness: Brightness.dark,
        surface: surfaceDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          color: textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      dividerColor: dividerDark,
      cardColor: surfaceDark,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: backgroundDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: dividerDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondaryDark, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryLightDark,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryDark,
        labelStyle: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusChip)),
      ),
    );
  }

  // ---- helper แบบ context-aware สำหรับ widget ที่ต้องสลับสีเอง ----
  static Color bg(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? backgroundDark : background;
  static Color surf(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? surfaceDark : surface;
  static Color prim(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? primaryDark : primary;
  static Color primLight(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? primaryLightDark : primaryLight;
  static Color txtPrimary(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? textPrimaryDark : textPrimary;
  static Color txtSecondary(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? textSecondaryDark : textSecondary;
  static Color div(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? dividerDark : divider;
  static Color accRed(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? accentRedDark : accentRed;
  static List<BoxShadow> shadow(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? cardShadowDark : cardShadow;
}
