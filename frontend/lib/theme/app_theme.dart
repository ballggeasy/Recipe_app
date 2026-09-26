import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ธีมกลางของแอป — มินิมอล อบอุ่น พรีเมียม
/// รองรับทั้งโหมดสว่างและมืด ประกอบจาก AppColors / AppTypography / AppSpacing / AppRadius
class AppTheme {
  // ---- ค่าคงที่สี (โหมดสว่าง) — คงไว้เพื่อความเข้ากันได้ย้อนหลัง ----
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryMuted;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color divider = AppColors.divider;
  static const Color accentRed = AppColors.error;

  static const Color backgroundDark = AppColors.backgroundDark;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLightDark = AppColors.primaryMutedDark;
  static const Color textPrimaryDark = AppColors.textPrimaryDark;
  static const Color textSecondaryDark = AppColors.textSecondaryDark;
  static const Color dividerDark = AppColors.dividerDark;
  static const Color accentRedDark = AppColors.errorDark;

  static ThemeData get lightTheme {
    final textTheme = _textTheme(AppColors.textPrimary, AppColors.textSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      dividerColor: AppColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h1(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.caption(color: AppColors.textPrimary),
        secondaryLabelStyle: AppTypography.caption(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.body(color: AppColors.textSecondary),
        labelStyle: AppTypography.body(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.button(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.button(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyStrong(),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: AppTypography.h2(color: AppColors.textPrimary),
        contentTextStyle: AppTypography.body(color: AppColors.textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.bodyStrong(),
        unselectedLabelStyle: AppTypography.body(),
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.divider,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryMuted,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textSecondary);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primaryMuted : AppColors.divider,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        error: AppColors.errorDark,
        surface: AppColors.surfaceDark,
      ),
      dividerColor: AppColors.dividerDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h1(color: AppColors.textPrimaryDark),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.dividerDark),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMutedDark,
        selectedColor: AppColors.primaryDark,
        labelStyle: AppTypography.caption(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: AppTypography.caption(color: AppColors.backgroundDark),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: AppTypography.body(color: AppColors.textSecondaryDark),
        labelStyle: AppTypography.body(color: AppColors.textSecondaryDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.errorDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.backgroundDark,
          disabledBackgroundColor: AppColors.primaryDark.withValues(alpha: 0.4),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.button(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(color: AppColors.dividerDark),
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.button(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: AppTypography.bodyStrong(),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: AppTypography.h2(color: AppColors.textPrimaryDark),
        contentTextStyle: AppTypography.body(color: AppColors.textPrimaryDark),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceMutedDark,
        contentTextStyle: AppTypography.body(color: AppColors.textPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondaryDark,
        labelStyle: AppTypography.bodyStrong(),
        unselectedLabelStyle: AppTypography.body(),
        indicatorColor: AppColors.primaryDark,
        dividerColor: AppColors.dividerDark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryMutedDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption(
            color: selected ? AppColors.primaryDark : AppColors.textSecondaryDark,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primaryDark : AppColors.textSecondaryDark);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.backgroundDark,
        elevation: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primaryDark : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primaryMutedDark : AppColors.dividerDark,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryDark),
    );
  }

  static TextTheme _textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: AppTypography.display(color: primaryText),
      headlineLarge: AppTypography.h1(color: primaryText),
      headlineMedium: AppTypography.h2(color: primaryText),
      titleMedium: AppTypography.h3(color: primaryText),
      bodyMedium: AppTypography.body(color: primaryText),
      bodyLarge: AppTypography.body(color: primaryText),
      bodySmall: AppTypography.caption(color: secondaryText),
      labelLarge: AppTypography.button(color: primaryText),
    );
  }

  // ---- helper แบบ context-aware สำหรับ widget ที่ต้องสลับสีเอง ----
  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c) => isDark(c) ? AppColors.backgroundDark : AppColors.background;
  static Color surf(BuildContext c) => isDark(c) ? AppColors.surfaceDark : AppColors.surface;
  static Color surfMuted(BuildContext c) => isDark(c) ? AppColors.surfaceMutedDark : AppColors.surfaceMuted;
  static Color prim(BuildContext c) => isDark(c) ? AppColors.primaryDark : AppColors.primary;
  static Color primLight(BuildContext c) => isDark(c) ? AppColors.primaryMutedDark : AppColors.primaryMuted;
  static Color secondary(BuildContext c) => isDark(c) ? AppColors.secondaryDark : AppColors.secondary;
  static Color secondaryMuted(BuildContext c) => isDark(c) ? AppColors.secondaryMutedDark : AppColors.secondaryMuted;
  static Color txtPrimary(BuildContext c) => isDark(c) ? AppColors.textPrimaryDark : AppColors.textPrimary;
  static Color txtSecondary(BuildContext c) => isDark(c) ? AppColors.textSecondaryDark : AppColors.textSecondary;
  static Color div(BuildContext c) => isDark(c) ? AppColors.dividerDark : AppColors.divider;
  static Color accRed(BuildContext c) => isDark(c) ? AppColors.errorDark : AppColors.error;
  static Color success(BuildContext c) => isDark(c) ? AppColors.successDark : AppColors.success;
  static Color error(BuildContext c) => isDark(c) ? AppColors.errorDark : AppColors.error;
  static Color errorMuted(BuildContext c) => isDark(c) ? AppColors.errorMutedDark : AppColors.errorMuted;
  static Color star(BuildContext c) => isDark(c) ? AppColors.starDark : AppColors.star;

  /// สีข้อความ/ไอคอนบนพื้น [prim], [secondary] หรือ [error] — ผ่าน WCAG AA ทั้งสองโหมด
  static Color onAccent(BuildContext c) => isDark(c) ? AppColors.onAccentDark : AppColors.onAccent;
}
