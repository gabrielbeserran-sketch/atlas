
enum AtlasBackendFoundationModule {
  backendFoundation,
  environmentConfiguration,
  postgresqlDatabase,
  versionedMigrations,
  multiCompanyArchitecture,
  usersCompaniesApi,
  farmsGroupsApi,
  animalsApi,
  livestockEventsApi,
  backendAdministrationCenter,
}

extension AtlasBackendFoundationModuleX on AtlasBackendFoundationModule {
  String get code => switch (this) {
    AtlasBackendFoundationModule.backendFoundation => 'backend_foundation',
    AtlasBackendFoundationModule.environmentConfiguration => 'environment_configuration',
    AtlasBackendFoundationModule.postgresqlDatabase => 'postgresql_database',
    AtlasBackendFoundationModule.versionedMigrations => 'versioned_migrations',
    AtlasBackendFoundationModule.multiCompanyArchitecture => 'multi_company_architecture',
    AtlasBackendFoundationModule.usersCompaniesApi => 'users_companies_api',
    AtlasBackendFoundationModule.farmsGroupsApi => 'farms_groups_api',
    AtlasBackendFoundationModule.animalsApi => 'animals_api',
    AtlasBackendFoundationModule.livestockEventsApi => 'livestock_events_api',
    AtlasBackendFoundationModule.backendAdministrationCenter => 'backend_administration_center',
  };

  String get title => switch (this) {
    AtlasBackendFoundationModule.backendFoundation => 'Fundação do Backend Atlas',
    AtlasBackendFoundationModule.environmentConfiguration => 'Configuração de Ambientes',
    AtlasBackendFoundationModule.postgresqlDatabase => 'Banco de Dados PostgreSQL',
    AtlasBackendFoundationModule.versionedMigrations => 'Migrações Versionadas',
    AtlasBackendFoundationModule.multiCompanyArchitecture => 'Arquitetura Multempresa',
    AtlasBackendFoundationModule.usersCompaniesApi => 'API de Usuários e Empresas',
    AtlasBackendFoundationModule.farmsGroupsApi => 'API de Fazendas e Lotes',
    AtlasBackendFoundationModule.animalsApi => 'API de Animais',
    AtlasBackendFoundationModule.livestockEventsApi => 'API de Eventos Pecuários',
    AtlasBackendFoundationModule.backendAdministrationCenter => 'Central de Administração do Backend',
  };

  String get packageLabel => switch (this) {
    AtlasBackendFoundationModule.backendFoundation => 'Pacote 251',
    AtlasBackendFoundationModule.environmentConfiguration => 'Pacote 252',
    AtlasBackendFoundationModule.postgresqlDatabase => 'Pacote 253',
    AtlasBackendFoundationModule.versionedMigrations => 'Pacote 254',
    AtlasBackendFoundationModule.multiCompanyArchitecture => 'Pacote 255',
    AtlasBackendFoundationModule.usersCompaniesApi => 'Pacote 256',
    AtlasBackendFoundationModule.farmsGroupsApi => 'Pacote 257',
    AtlasBackendFoundationModule.animalsApi => 'Pacote 258',
    AtlasBackendFoundationModule.livestockEventsApi => 'Pacote 259',
    AtlasBackendFoundationModule.backendAdministrationCenter => 'Pacote 260',
  };

  List<String> get features => switch (this) {
    AtlasBackendFoundationModule.backendFoundation => const [
      'Rotas e controladores', 'Serviços', 'Validações', 'Tratamento de erros', 'Saúde do servidor'
    ],
    AtlasBackendFoundationModule.environmentConfiguration => const [
      'Desenvolvimento', 'Homologação', 'Produção', 'Variáveis de ambiente', 'Segredos'
    ],
    AtlasBackendFoundationModule.postgresqlDatabase => const [
      'Conexão', 'Schema', 'Índices', 'Integridade', 'Monitoramento'
    ],
    AtlasBackendFoundationModule.versionedMigrations => const [
      'Criação', 'Execução', 'Rollback', 'Histórico', 'Validação'
    ],
    AtlasBackendFoundationModule.multiCompanyArchitecture => const [
      'Empresas', 'Fazendas', 'Escopo de dados', 'Isolamento', 'Auditoria'
    ],
    AtlasBackendFoundationModule.usersCompaniesApi => const [
      'Usuários', 'Empresas', 'Convites', 'Papéis', 'Desativação'
    ],
    AtlasBackendFoundationModule.farmsGroupsApi => const [
      'Fazendas', 'Lotes', 'Grupos', 'Movimentações', 'Consultas'
    ],
    AtlasBackendFoundationModule.animalsApi => const [
      'Cadastro', 'Edição', 'Consulta', 'Movimentação', 'Histórico'
    ],
    AtlasBackendFoundationModule.livestockEventsApi => const [
      'Pesagens', 'Sanidade', 'Reprodução', 'Nutrição', 'Eventos operacionais'
    ],
    AtlasBackendFoundationModule.backendAdministrationCenter => const [
      'Serviços', 'Banco', 'Filas', 'Falhas', 'Painel técnico'
    ],
  };
}

class AtlasBackendFoundationRecord {
  const AtlasBackendFoundationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.priority,
    required this.environment,
    required this.resourceName,
    required this.routeOrTable,
    required this.companyName,
    required this.ownerName,
    required this.progressPercent,
    required this.availabilityPercent,
    required this.errorRatePercent,
    required this.latencyMs,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasBackendFoundationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String priority;
  final String environment;
  final String resourceName;
  final String routeOrTable;
  final String companyName;
  final String ownerName;
  final int progressPercent;
  final double availabilityPercent;
  final double errorRatePercent;
  final double latencyMs;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isOperational => const ['Ativo', 'Validado', 'Concluído', 'Disponível'].contains(status);
  bool get isCritical => const ['Crítico', 'Bloqueado', 'Indisponível', 'Atenção'].contains(status);

  Map<String, dynamic> toMap() => {
    'id': id, 'module': module.code, 'feature': feature, 'title': title,
    'date': date, 'status': status, 'priority': priority, 'environment': environment,
    'resourceName': resourceName, 'routeOrTable': routeOrTable, 'companyName': companyName,
    'ownerName': ownerName, 'progressPercent': progressPercent,
    'availabilityPercent': availabilityPercent, 'errorRatePercent': errorRatePercent,
    'latencyMs': latencyMs, 'alertCount': alertCount, 'notes': notes,
    'createdAt': createdAt, 'updatedAt': updatedAt,
  };

  factory AtlasBackendFoundationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasBackendFoundationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasBackendFoundationModule.backendFoundation,
    );
    return AtlasBackendFoundationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      environment: map['environment']?.toString() ?? '',
      resourceName: map['resourceName']?.toString() ?? '',
      routeOrTable: map['routeOrTable']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? '',
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      availabilityPercent: (map['availabilityPercent'] as num?)?.toDouble() ?? 0,
      errorRatePercent: (map['errorRatePercent'] as num?)?.toDouble() ?? 0,
      latencyMs: (map['latencyMs'] as num?)?.toDouble() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasBackendDate(String value) {
  final iso = DateTime.tryParse(value.trim());
  if (iso != null) return iso;
  final parts = value.trim().split('/');
  if (parts.length != 3) return DateTime(1900);
  return DateTime(int.tryParse(parts[2]) ?? 1900, int.tryParse(parts[1]) ?? 1, int.tryParse(parts[0]) ?? 1);
}

String formatAtlasBackendDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
