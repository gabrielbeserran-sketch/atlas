import 'package:flutter/material.dart';

/// Paleta semântica oficial do Atlas.
///
/// Regra: telas e componentes novos devem preferir estes tokens em vez de
/// cores literais. Os nomes descrevem intenção, não pigmento.
abstract final class AtlasColors {
  static const Color brand = Color(0xFF173E2C);
  static const Color brandStrong = Color(0xFF0E2C1F);
  static const Color brandSoft = Color(0xFFE8F1EC);
  static const Color accent = Color(0xFFB58A45);
  static const Color accentSoft = Color(0xFFF5EEE2);

  static const Color canvas = Color(0xFFF4F5F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8F9F6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceInverse = Color(0xFF17201B);

  static const Color textPrimary = Color(0xFF1D2521);
  static const Color textSecondary = Color(0xFF5E6B64);
  static const Color textTertiary = Color(0xFF7D8982);
  static const Color textInverse = Color(0xFFF8FAF8);

  static const Color border = Color(0xFFD9DFDB);
  static const Color borderStrong = Color(0xFFBAC5BE);
  static const Color focus = Color(0xFF2C6E4A);

  static const Color success = Color(0xFF287A4A);
  static const Color successSoft = Color(0xFFE7F4EC);
  static const Color warning = Color(0xFFA56817);
  static const Color warningSoft = Color(0xFFFFF3DF);
  static const Color critical = Color(0xFFA63A32);
  static const Color criticalSoft = Color(0xFFFCE9E7);
  static const Color info = Color(0xFF356A8B);
  static const Color infoSoft = Color(0xFFE8F1F6);

  static const Color disabled = Color(0xFFB5BDB8);
  static const Color overlay = Color(0x520E1A13);
}
