import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/design_system/theme/atlas_theme.dart';

/// Fachada de compatibilidade para telas legadas.
///
/// O tema canônico vive em `core/design_system`. Manter esta classe evita uma
/// migração big-bang de imports durante a transformação premium da interface.
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => AtlasTheme.light;
}
