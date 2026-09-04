import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_radius.dart';
import '../foundations/atlas_spacing.dart';
import '../foundations/atlas_typography.dart';

abstract final class AtlasTheme {
  static const double minimumTouchTarget = 48;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AtlasColors.brand,
      brightness: Brightness.light,
      primary: AtlasColors.brand,
      secondary: AtlasColors.accent,
      surface: AtlasColors.surface,
      error: AtlasColors.critical,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.canvas,
      textTheme: AtlasTypography.textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: AtlasColors.focus.withValues(alpha: 0.10),
      hoverColor: AtlasColors.brand.withValues(alpha: 0.05),
      dividerColor: AtlasColors.border,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AtlasColors.surface,
        foregroundColor: AtlasColors.textPrimary,
        toolbarHeight: 68,
        titleTextStyle: TextStyle(
          color: AtlasColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AtlasColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          side: const BorderSide(color: AtlasColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.md,
          vertical: AtlasSpacing.md,
        ),
        labelStyle: const TextStyle(color: AtlasColors.textSecondary),
        hintStyle: const TextStyle(color: AtlasColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          borderSide: const BorderSide(color: AtlasColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          borderSide: const BorderSide(color: AtlasColors.focus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          borderSide: const BorderSide(color: AtlasColors.critical, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          borderSide: const BorderSide(color: AtlasColors.critical, width: 2),
        ),
        helperMaxLines: 2,
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AtlasColors.brand,
          foregroundColor: AtlasColors.textInverse,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: AtlasColors.brand,
          side: const BorderSide(color: AtlasColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          foregroundColor: AtlasColors.brand,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
          foregroundColor: AtlasColors.textPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AtlasColors.surfaceMuted,
        side: const BorderSide(color: AtlasColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        labelStyle: const TextStyle(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AtlasColors.surfaceInverse,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
        ),
        contentTextStyle: const TextStyle(
          color: AtlasColors.textInverse,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AtlasColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
          side: const BorderSide(color: AtlasColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AtlasColors.border),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AtlasColors.brand,
        linearTrackColor: AtlasColors.brandSoft,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AtlasColors.surfaceInverse,
          borderRadius: BorderRadius.circular(AtlasRadius.xs),
        ),
        textStyle: const TextStyle(color: AtlasColors.textInverse),
      ),
    );
  }
}
