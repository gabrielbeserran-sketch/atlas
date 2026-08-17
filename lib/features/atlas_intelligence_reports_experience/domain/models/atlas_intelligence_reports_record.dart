enum AtlasIntelligenceReportsModule {
  consolidatedIndicatorEngine,
  realDataExecutiveDashboard,
  realFarmBenchmarking,
  traceableRecommendationEngine,
  validatedPredictiveDiagnostics,
  technicalPdfReports,
  financialExecutiveReports,
  spreadsheetCsvExport,
  secureSharing,
  professionalNavigationExperience,
}

extension AtlasIntelligenceReportsModuleX on AtlasIntelligenceReportsModule {
  String get code => switch (this) {
    AtlasIntelligenceReportsModule.consolidatedIndicatorEngine =>
      'consolidated_indicator_engine',
    AtlasIntelligenceReportsModule.realDataExecutiveDashboard =>
      'real_data_executive_dashboard',
    AtlasIntelligenceReportsModule.realFarmBenchmarking =>
      'real_farm_benchmarking',
    AtlasIntelligenceReportsModule.traceableRecommendationEngine =>
      'traceable_recommendation_engine',
    AtlasIntelligenceReportsModule.validatedPredictiveDiagnostics =>
      'validated_predictive_diagnostics',
    AtlasIntelligenceReportsModule.technicalPdfReports =>
      'technical_pdf_reports',
    AtlasIntelligenceReportsModule.financialExecutiveReports =>
      'financial_executive_reports',
    AtlasIntelligenceReportsModule.spreadsheetCsvExport =>
      'spreadsheet_csv_export',
    AtlasIntelligenceReportsModule.secureSharing => 'secure_sharing',
    AtlasIntelligenceReportsModule.professionalNavigationExperience =>
      'professional_navigation_experience',
  };

  String get title => switch (this) {
    AtlasIntelligenceReportsModule.consolidatedIndicatorEngine =>
      'Motor de Indicadores Consolidado',
    AtlasIntelligenceReportsModule.realDataExecutiveDashboard =>
      'Dashboard Executivo com Dados Reais',
    AtlasIntelligenceReportsModule.realFarmBenchmarking =>
      'Comparação Real entre Fazendas',
    AtlasIntelligenceReportsModule.traceableRecommendationEngine =>
      'Motor de Recomendações Rastreável',
    AtlasIntelligenceReportsModule.validatedPredictiveDiagnostics =>
      'Diagnósticos Preditivos Validados',
    AtlasIntelligenceReportsModule.technicalPdfReports =>
      'Relatórios Técnicos em PDF',
    AtlasIntelligenceReportsModule.financialExecutiveReports =>
      'Relatórios Financeiros e Executivos',
    AtlasIntelligenceReportsModule.spreadsheetCsvExport =>
      'Exportação para Planilhas e CSV',
    AtlasIntelligenceReportsModule.secureSharing => 'Compartilhamento Seguro',
    AtlasIntelligenceReportsModule.professionalNavigationExperience =>
      'Nova Experiência de Navegação',
  };

  String get packageLabel => switch (this) {
    AtlasIntelligenceReportsModule.consolidatedIndicatorEngine => 'Pacote 281',
    AtlasIntelligenceReportsModule.realDataExecutiveDashboard => 'Pacote 282',
    AtlasIntelligenceReportsModule.realFarmBenchmarking => 'Pacote 283',
    AtlasIntelligenceReportsModule.traceableRecommendationEngine =>
      'Pacote 284',
    AtlasIntelligenceReportsModule.validatedPredictiveDiagnostics =>
      'Pacote 285',
    AtlasIntelligenceReportsModule.technicalPdfReports => 'Pacote 286',
    AtlasIntelligenceReportsModule.financialExecutiveReports => 'Pacote 287',
    AtlasIntelligenceReportsModule.spreadsheetCsvExport => 'Pacote 288',
    AtlasIntelligenceReportsModule.secureSharing => 'Pacote 289',
    AtlasIntelligenceReportsModule.professionalNavigationExperience =>
      'Pacote 290',
  };

  List<String> get features => switch (this) {
    AtlasIntelligenceReportsModule.consolidatedIndicatorEngine => const [
      'Fórmula',
      'Período',
      'Fonte',
      'Unidade',
      'Regra de cálculo',
    ],
    AtlasIntelligenceReportsModule.realDataExecutiveDashboard => const [
      'Dados consolidados',
      'Atualização automática',
      'Riscos',
      'Metas',
      'Decisões',
    ],
    AtlasIntelligenceReportsModule.realFarmBenchmarking => const [
      'Sistema produtivo',
      'Escala',
      'Categoria animal',
      'Período',
      'Referência comparável',
    ],
    AtlasIntelligenceReportsModule.traceableRecommendationEngine => const [
      'Dados de origem',
      'Regras usadas',
      'Confiança',
      'Justificativa',
      'Histórico',
    ],
    AtlasIntelligenceReportsModule.validatedPredictiveDiagnostics => const [
      'Premissas',
      'Cenários',
      'Intervalo de confiança',
      'Limites técnicos',
      'Validação',
    ],
    AtlasIntelligenceReportsModule.technicalPdfReports => const [
      'Identificação',
      'Tabelas',
      'Gráficos',
      'Conclusões',
      'Assinatura',
    ],
    AtlasIntelligenceReportsModule.financialExecutiveReports => const [
      'Custos',
      'Rentabilidade',
      'Fluxo de caixa',
      'Indicadores',
      'Resumo executivo',
    ],
    AtlasIntelligenceReportsModule.spreadsheetCsvExport => const [
      'Animais',
      'Eventos',
      'Estoque',
      'Finanças',
      'Indicadores',
    ],
    AtlasIntelligenceReportsModule.secureSharing => const [
      'Links temporários',
      'Proteção',
      'Permissões',
      'Expiração',
      'Registro de acesso',
    ],
    AtlasIntelligenceReportsModule.professionalNavigationExperience => const [
      'Menus por área',
      'Pesquisa global',
      'Favoritos',
      'Atalhos',
      'Personalização',
    ],
  };
}

class AtlasIntelligenceReportsRecord {
  const AtlasIntelligenceReportsRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.priority,
    required this.farmName,
    required this.indicatorName,
    required this.dataSource,
    required this.periodLabel,
    required this.responsible,
    required this.currentValue,
    required this.targetValue,
    required this.confidencePercent,
    required this.riskPercent,
    required this.progressPercent,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasIntelligenceReportsModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String priority;
  final String farmName;
  final String indicatorName;
  final String dataSource;
  final String periodLabel;
  final String responsible;
  final double currentValue;
  final double targetValue;
  final double confidencePercent;
  final double riskPercent;
  final int progressPercent;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Publicado' ||
      status == 'Concluído';

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Falha' ||
      status == 'Atenção';

  double get gap => currentValue - targetValue;

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'status': status,
    'priority': priority,
    'farmName': farmName,
    'indicatorName': indicatorName,
    'dataSource': dataSource,
    'periodLabel': periodLabel,
    'responsible': responsible,
    'currentValue': currentValue,
    'targetValue': targetValue,
    'confidencePercent': confidencePercent,
    'riskPercent': riskPercent,
    'progressPercent': progressPercent,
    'alertCount': alertCount,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasIntelligenceReportsRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasIntelligenceReportsModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasIntelligenceReportsModule.consolidatedIndicatorEngine,
    );

    return AtlasIntelligenceReportsRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      farmName: map['farmName']?.toString() ?? '',
      indicatorName: map['indicatorName']?.toString() ?? '',
      dataSource: map['dataSource']?.toString() ?? '',
      periodLabel: map['periodLabel']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0,
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasIntelligenceReportsDate(String value) {
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

String formatAtlasIntelligenceReportsDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
