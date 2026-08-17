import 'package:flutter/material.dart';

enum AtlasRouteMaturity { v1Core, advancedValidation, internalTool }

extension AtlasRouteMaturityLabel on AtlasRouteMaturity {
  String get label => switch (this) {
    AtlasRouteMaturity.v1Core => 'V1 operacional',
    AtlasRouteMaturity.advancedValidation => 'Avançado em validação',
    AtlasRouteMaturity.internalTool => 'Ferramenta interna',
  };

  bool get isProductionCore => this == AtlasRouteMaturity.v1Core;
}

class AtlasRouteDefinition {
  const AtlasRouteDefinition({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.permission,
    this.maturity = AtlasRouteMaturity.v1Core,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
  final String? permission;
  final AtlasRouteMaturity maturity;
}
