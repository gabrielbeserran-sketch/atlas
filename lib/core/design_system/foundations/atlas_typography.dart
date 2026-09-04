import 'package:flutter/material.dart';
import 'atlas_colors.dart';

abstract final class AtlasTypography {
  static const List<String> _fallback = <String>[
    'Segoe UI',
    'SF Pro Display',
    'Roboto',
    'Arial',
  ];

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          height: 1.10,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          height: 1.20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.30,
          fontWeight: FontWeight.w700,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.50,
          fontWeight: FontWeight.w400,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.48,
          fontWeight: FontWeight.w400,
          color: AtlasColors.textSecondary,
          fontFamilyFallback: _fallback,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: AtlasColors.textPrimary,
          fontFamilyFallback: _fallback,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          height: 1.20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AtlasColors.textSecondary,
          fontFamilyFallback: _fallback,
        ),
      );
}
