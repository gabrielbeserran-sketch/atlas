enum AtlasQualityReleaseModule {
  architecturalReview,
  comprehensiveUnitTests,
  integrationTests,
  interfaceTests,
  securityTests,
  performanceTests,
  monitoringAndFailureHandling,
  stagingPublication,
  farmPilotProgram,
  atlasVersionOne,
}

extension AtlasQualityReleaseModuleX on AtlasQualityReleaseModule {
  String get code => switch (this) {
    AtlasQualityReleaseModule.architecturalReview => 'architectural_review',
    AtlasQualityReleaseModule.comprehensiveUnitTests =>
      'comprehensive_unit_tests',
    AtlasQualityReleaseModule.integrationTests => 'integration_tests',
    AtlasQualityReleaseModule.interfaceTests => 'interface_tests',
    AtlasQualityReleaseModule.securityTests => 'security_tests',
    AtlasQualityReleaseModule.performanceTests => 'performance_tests',
    AtlasQualityReleaseModule.monitoringAndFailureHandling =>
      'monitoring_and_failure_handling',
    AtlasQualityReleaseModule.stagingPublication => 'staging_publication',
    AtlasQualityReleaseModule.farmPilotProgram => 'farm_pilot_program',
    AtlasQualityReleaseModule.atlasVersionOne => 'atlas_version_one',
  };

  String get title => switch (this) {
    AtlasQualityReleaseModule.architecturalReview =>
      'Revisão Arquitetural Completa',
    AtlasQualityReleaseModule.comprehensiveUnitTests =>
      'Testes Unitários Abrangentes',
    AtlasQualityReleaseModule.integrationTests => 'Testes de Integração',
    AtlasQualityReleaseModule.interfaceTests => 'Testes de Interface',
    AtlasQualityReleaseModule.securityTests => 'Testes de Segurança',
    AtlasQualityReleaseModule.performanceTests => 'Testes de Desempenho',
    AtlasQualityReleaseModule.monitoringAndFailureHandling =>
      'Monitoramento e Tratamento de Falhas',
    AtlasQualityReleaseModule.stagingPublication =>
      'Publicação em Ambiente de Homologação',
    AtlasQualityReleaseModule.farmPilotProgram => 'Programa-Piloto em Fazenda',
    AtlasQualityReleaseModule.atlasVersionOne => 'Atlas Versão 1.0',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasQualityReleaseModule.architecturalReview => const [
      'Código duplicado',
      'Arquivos obsoletos',
      'Imports e dependências',
      'Separação de responsabilidades',
      'Plano de refatoração',
    ],
    AtlasQualityReleaseModule.comprehensiveUnitTests => const [
      'Modelos',
      'Regras de negócio',
      'Indicadores',
      'Permissões',
      'Sincronização',
    ],
    AtlasQualityReleaseModule.integrationTests => const [
      'Aplicativo e API',
      'API e banco',
      'Armazenamento',
      'Serviços externos',
      'Fluxos completos',
    ],
    AtlasQualityReleaseModule.interfaceTests => const [
      'Login',
      'Cadastro',
      'Consulta',
      'Edição',
      'Fluxos críticos',
    ],
    AtlasQualityReleaseModule.securityTests => const [
      'Autenticação',
      'Permissões',
      'Isolamento multempresa',
      'Exposição de dados',
      'Ataques comuns',
    ],
    AtlasQualityReleaseModule.performanceTests => const [
      'Abertura de telas',
      'Consultas',
      'Sincronização',
      'Grandes rebanhos',
      'Memória e relatórios',
    ],
    AtlasQualityReleaseModule.monitoringAndFailureHandling => const [
      'Captura de erros',
      'Logs',
      'Métricas',
      'Alertas técnicos',
      'Saúde dos serviços',
    ],
    AtlasQualityReleaseModule.stagingPublication => const [
      'Build de homologação',
      'Dados de teste',
      'Usuários convidados',
      'Checklist de publicação',
      'Registro de feedback',
    ],
    AtlasQualityReleaseModule.farmPilotProgram => const [
      'Plano do piloto',
      'Treinamento',
      'Uso em campo',
      'Coleta de feedback',
      'Correções prioritárias',
    ],
    AtlasQualityReleaseModule.atlasVersionOne => const [
      'Instalador',
      'Backend',
      'Banco',
      'Documentação e políticas',
      'Suporte e lançamento',
    ],
  };
}

class AtlasQualityReleaseRecord {
  const AtlasQualityReleaseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.priority,
    required this.environment,
    required this.responsible,
    required this.scope,
    required this.evidence,
    required this.progressPercent,
    required this.passRatePercent,
    required this.coveragePercent,
    required this.riskPercent,
    required this.failureCount,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasQualityReleaseModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String priority;
  final String environment;
  final String responsible;
  final String scope;
  final String evidence;
  final int progressPercent;
  final double passRatePercent;
  final double coveragePercent;
  final double riskPercent;
  final int failureCount;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Aprovado' ||
      status == 'Concluído';

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Reprovado' ||
      status == 'Atenção';

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'status': status,
    'priority': priority,
    'environment': environment,
    'responsible': responsible,
    'scope': scope,
    'evidence': evidence,
    'progressPercent': progressPercent,
    'passRatePercent': passRatePercent,
    'coveragePercent': coveragePercent,
    'riskPercent': riskPercent,
    'failureCount': failureCount,
    'alertCount': alertCount,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasQualityReleaseRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasQualityReleaseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasQualityReleaseModule.architecturalReview,
    );

    return AtlasQualityReleaseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      environment: map['environment']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      scope: map['scope']?.toString() ?? '',
      evidence: map['evidence']?.toString() ?? '',
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      passRatePercent: (map['passRatePercent'] as num?)?.toDouble() ?? 0,
      coveragePercent: (map['coveragePercent'] as num?)?.toDouble() ?? 0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0,
      failureCount: (map['failureCount'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasQualityReleaseDate(String value) {
  final text = value.trim();
  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasQualityReleaseDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
