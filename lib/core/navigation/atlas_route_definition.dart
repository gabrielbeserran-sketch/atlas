import 'package:flutter/material.dart';

enum AtlasRouteMaturity { v1Core, advancedValidation, internalTool }

enum AtlasNavigationGroup {
  today,
  herd,
  farm,
  management,
  support,
  administration,
}

extension AtlasNavigationGroupLabel on AtlasNavigationGroup {
  String get label => switch (this) {
    AtlasNavigationGroup.today => 'Hoje',
    AtlasNavigationGroup.herd => 'Animais',
    AtlasNavigationGroup.farm => 'Fazenda',
    AtlasNavigationGroup.management => 'Gestão',
    AtlasNavigationGroup.support => 'Apoio',
    AtlasNavigationGroup.administration => 'Administração',
  };

  IconData get icon => switch (this) {
    AtlasNavigationGroup.today => Icons.today_outlined,
    AtlasNavigationGroup.herd => Icons.pets_outlined,
    AtlasNavigationGroup.farm => Icons.agriculture_outlined,
    AtlasNavigationGroup.management => Icons.assessment_outlined,
    AtlasNavigationGroup.support => Icons.support_agent_outlined,
    AtlasNavigationGroup.administration => Icons.admin_panel_settings_outlined,
  };
}

extension AtlasRouteMaturityLabel on AtlasRouteMaturity {
  String get label => switch (this) {
    AtlasRouteMaturity.v1Core => 'Operacional',
    AtlasRouteMaturity.advancedValidation => 'Em validação interna',
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
    required this.group,
    this.menuLabel,
  });

  final String label;
  final String? menuLabel;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
  final String? permission;
  final AtlasRouteMaturity maturity;
  final AtlasNavigationGroup group;

  String get visibleLabel => menuLabel?.trim().isNotEmpty == true
      ? menuLabel!.trim()
      : label;
}
