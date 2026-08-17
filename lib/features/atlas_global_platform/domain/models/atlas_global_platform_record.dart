enum AtlasGlobalPlatformFeature {
  multiCompany,
  advancedMultiUser,
  integrationMarketplace,
  publicApi,
  commandCenter,
}

extension AtlasGlobalPlatformFeatureX on AtlasGlobalPlatformFeature {
  String get code => switch (this) {
    AtlasGlobalPlatformFeature.multiCompany => 'multi_company',
    AtlasGlobalPlatformFeature.advancedMultiUser => 'advanced_multi_user',
    AtlasGlobalPlatformFeature.integrationMarketplace =>
      'integration_marketplace',
    AtlasGlobalPlatformFeature.publicApi => 'public_api',
    AtlasGlobalPlatformFeature.commandCenter => 'command_center',
  };

  String get title => switch (this) {
    AtlasGlobalPlatformFeature.multiCompany => 'Multiempresa',
    AtlasGlobalPlatformFeature.advancedMultiUser => 'Multiusuário avançado',
    AtlasGlobalPlatformFeature.integrationMarketplace =>
      'Marketplace de integrações',
    AtlasGlobalPlatformFeature.publicApi => 'API pública para parceiros',
    AtlasGlobalPlatformFeature.commandCenter => 'Atlas Command Center',
  };

  String get description => switch (this) {
    AtlasGlobalPlatformFeature.multiCompany =>
      'Empresas, fazendas, escopos e consolidação executiva.',
    AtlasGlobalPlatformFeature.advancedMultiUser =>
      'Usuários, perfis, permissões e segregação de acesso.',
    AtlasGlobalPlatformFeature.integrationMarketplace =>
      'Catálogo, homologação e acompanhamento de integrações.',
    AtlasGlobalPlatformFeature.publicApi =>
      'Parceiros, credenciais, escopos, limites e auditoria.',
    AtlasGlobalPlatformFeature.commandCenter =>
      'Visão consolidada de risco, operação, dados e estratégia.',
  };
}

class AtlasGlobalPlatformRecord {
  const AtlasGlobalPlatformRecord({
    required this.id,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.entityName,
    required this.roleOrScope,
    required this.primaryValue,
    required this.secondaryValue,
    required this.unit,
    required this.endpointOrReference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasGlobalPlatformFeature feature;
  final String title;
  final String date;
  final String status;
  final String entityName;
  final String roleOrScope;
  final double primaryValue;
  final double secondaryValue;
  final String unit;
  final String endpointOrReference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Atenção' ||
      status == 'Bloqueado' ||
      status == 'Offline';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Conectado' ||
      status == 'Homologado' ||
      status == 'Concluído';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feature': feature.code,
      'title': title,
      'date': date,
      'status': status,
      'entityName': entityName,
      'roleOrScope': roleOrScope,
      'primaryValue': primaryValue,
      'secondaryValue': secondaryValue,
      'unit': unit,
      'endpointOrReference': endpointOrReference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasGlobalPlatformRecord.fromMap(Map<String, dynamic> map) {
    final code = map['feature']?.toString() ?? '';

    final feature = AtlasGlobalPlatformFeature.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasGlobalPlatformFeature.multiCompany,
    );

    return AtlasGlobalPlatformRecord(
      id: map['id']?.toString() ?? '',
      feature: feature,
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      entityName: map['entityName']?.toString() ?? '',
      roleOrScope: map['roleOrScope']?.toString() ?? '',
      primaryValue: (map['primaryValue'] as num?)?.toDouble() ?? 0,
      secondaryValue: (map['secondaryValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      endpointOrReference: map['endpointOrReference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasGlobalDate(String value) {
  final iso = DateTime.tryParse(value.trim());
  if (iso != null) return iso;

  final parts = value.trim().split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasGlobalDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
