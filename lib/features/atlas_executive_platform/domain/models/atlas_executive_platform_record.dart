enum AtlasExecutivePlatformModule {
  globalExecutiveDashboard,
  farmBenchmarking,
  corporateGoals,
  unifiedAlerts,
  intelligentTasks,
  professionalReports,
  exportAndSharing,
  plansAndSubscriptions,
  platformAdminPanel,
  enterpriseCommandCenter,
}

extension AtlasExecutivePlatformModuleX on AtlasExecutivePlatformModule {
  String get code => switch (this) {
    AtlasExecutivePlatformModule.globalExecutiveDashboard =>
      'global_executive_dashboard',
    AtlasExecutivePlatformModule.farmBenchmarking => 'farm_benchmarking',
    AtlasExecutivePlatformModule.corporateGoals => 'corporate_goals',
    AtlasExecutivePlatformModule.unifiedAlerts => 'unified_alerts',
    AtlasExecutivePlatformModule.intelligentTasks => 'intelligent_tasks',
    AtlasExecutivePlatformModule.professionalReports => 'professional_reports',
    AtlasExecutivePlatformModule.exportAndSharing => 'export_and_sharing',
    AtlasExecutivePlatformModule.plansAndSubscriptions =>
      'plans_and_subscriptions',
    AtlasExecutivePlatformModule.platformAdminPanel => 'platform_admin_panel',
    AtlasExecutivePlatformModule.enterpriseCommandCenter =>
      'enterprise_command_center',
  };

  String get title => switch (this) {
    AtlasExecutivePlatformModule.globalExecutiveDashboard =>
      'Dashboard Executivo Global',
    AtlasExecutivePlatformModule.farmBenchmarking =>
      'Comparação entre Fazendas',
    AtlasExecutivePlatformModule.corporateGoals => 'Metas Corporativas',
    AtlasExecutivePlatformModule.unifiedAlerts =>
      'Central de Alertas Unificada',
    AtlasExecutivePlatformModule.intelligentTasks =>
      'Central de Tarefas Inteligentes',
    AtlasExecutivePlatformModule.professionalReports =>
      'Relatórios Profissionais',
    AtlasExecutivePlatformModule.exportAndSharing =>
      'Exportação e Compartilhamento',
    AtlasExecutivePlatformModule.plansAndSubscriptions =>
      'Gestão de Planos e Assinaturas',
    AtlasExecutivePlatformModule.platformAdminPanel =>
      'Painel Administrativo da Plataforma',
    AtlasExecutivePlatformModule.enterpriseCommandCenter =>
      'Atlas Enterprise Command Center',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasExecutivePlatformModule.globalExecutiveDashboard => const [
      'Indicadores globais',
      'Visão por fazenda',
      'Riscos prioritários',
      'Resultados',
      'Resumo executivo',
    ],
    AtlasExecutivePlatformModule.farmBenchmarking => const [
      'Produtividade',
      'Custos',
      'Reprodução',
      'Sanidade',
      'Eficiência comparativa',
    ],
    AtlasExecutivePlatformModule.corporateGoals => const [
      'Objetivos',
      'Indicadores-chave',
      'Metas',
      'Responsáveis',
      'Resultados',
    ],
    AtlasExecutivePlatformModule.unifiedAlerts => const [
      'Consolidação',
      'Severidade',
      'Prioridade',
      'Responsável',
      'Tratamento',
    ],
    AtlasExecutivePlatformModule.intelligentTasks => const [
      'Origem automática',
      'Responsável',
      'Prazo',
      'Dependências',
      'Conclusão',
    ],
    AtlasExecutivePlatformModule.professionalReports => const [
      'Relatório técnico',
      'Relatório gerencial',
      'Relatório financeiro',
      'Relatório executivo',
      'Histórico de versões',
    ],
    AtlasExecutivePlatformModule.exportAndSharing => const [
      'PDF',
      'CSV',
      'Planilha',
      'Compartilhamento',
      'Controle de acesso',
    ],
    AtlasExecutivePlatformModule.plansAndSubscriptions => const [
      'Planos',
      'Limites de uso',
      'Recursos',
      'Cobrança',
      'Renovação',
    ],
    AtlasExecutivePlatformModule.platformAdminPanel => const [
      'Usuários',
      'Empresas',
      'Assinaturas',
      'Suporte',
      'Métricas da plataforma',
    ],
    AtlasExecutivePlatformModule.enterpriseCommandCenter => const [
      'Operações',
      'Inteligência',
      'Finanças',
      'Riscos e alertas',
      'Desempenho global',
    ],
  };
}

class AtlasExecutivePlatformRecord {
  const AtlasExecutivePlatformRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.farmName,
    required this.companyName,
    required this.ownerName,
    required this.metricName,
    required this.currentValue,
    required this.targetValue,
    required this.referenceValue,
    required this.unit,
    required this.progressPercent,
    required this.confidencePercent,
    required this.riskPercent,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasExecutivePlatformModule module;
  final String feature;
  final String title;
  final String date;
  final String dueDate;
  final String status;
  final String priority;
  final String farmName;
  final String companyName;
  final String ownerName;
  final String metricName;
  final double currentValue;
  final double targetValue;
  final double referenceValue;
  final String unit;
  final int progressPercent;
  final double confidencePercent;
  final double riskPercent;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Atenção' ||
      status == 'Atrasado';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Concluído' ||
      status == 'Publicado';

  bool get isOverdue {
    final parsed = parseAtlasExecutiveDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Publicado' &&
        status != 'Cancelado';
  }

  double get gap => currentValue - targetValue;

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'priority': priority,
    'farmName': farmName,
    'companyName': companyName,
    'ownerName': ownerName,
    'metricName': metricName,
    'currentValue': currentValue,
    'targetValue': targetValue,
    'referenceValue': referenceValue,
    'unit': unit,
    'progressPercent': progressPercent,
    'confidencePercent': confidencePercent,
    'riskPercent': riskPercent,
    'alertCount': alertCount,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasExecutivePlatformRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasExecutivePlatformModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasExecutivePlatformModule.globalExecutiveDashboard,
    );

    return AtlasExecutivePlatformRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dueDate: map['dueDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      farmName: map['farmName']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? '',
      metricName: map['metricName']?.toString() ?? '',
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0,
      referenceValue: (map['referenceValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasExecutiveDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);
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

String formatAtlasExecutiveDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
