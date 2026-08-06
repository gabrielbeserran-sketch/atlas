
enum AtlasLivestockIntegrationModule {
  herdMigration,
  reproductionMigration,
  healthMigration,
  nutritionMigration,
  financeMigration,
  stockMigration,
  eventIntegration,
  unifiedTimeline,
  integratedAlerts,
  integratedTasks,
}

extension AtlasLivestockIntegrationModuleX
    on AtlasLivestockIntegrationModule {
  String get code => switch (this) {
        AtlasLivestockIntegrationModule.herdMigration => 'herd_migration',
        AtlasLivestockIntegrationModule.reproductionMigration => 'reproduction_migration',
        AtlasLivestockIntegrationModule.healthMigration => 'health_migration',
        AtlasLivestockIntegrationModule.nutritionMigration => 'nutrition_migration',
        AtlasLivestockIntegrationModule.financeMigration => 'finance_migration',
        AtlasLivestockIntegrationModule.stockMigration => 'stock_migration',
        AtlasLivestockIntegrationModule.eventIntegration => 'event_integration',
        AtlasLivestockIntegrationModule.unifiedTimeline => 'unified_timeline',
        AtlasLivestockIntegrationModule.integratedAlerts => 'integrated_alerts',
        AtlasLivestockIntegrationModule.integratedTasks => 'integrated_tasks',
      };

  String get title => switch (this) {
        AtlasLivestockIntegrationModule.herdMigration =>
          'Migração do Módulo Rebanho',
        AtlasLivestockIntegrationModule.reproductionMigration =>
          'Migração do Módulo Reprodução',
        AtlasLivestockIntegrationModule.healthMigration =>
          'Migração do Módulo Sanidade',
        AtlasLivestockIntegrationModule.nutritionMigration =>
          'Migração do Módulo Nutrição',
        AtlasLivestockIntegrationModule.financeMigration =>
          'Migração do Módulo Financeiro',
        AtlasLivestockIntegrationModule.stockMigration =>
          'Migração do Módulo Estoque',
        AtlasLivestockIntegrationModule.eventIntegration =>
          'Integração entre Eventos',
        AtlasLivestockIntegrationModule.unifiedTimeline =>
          'Linha do Tempo Unificada',
        AtlasLivestockIntegrationModule.integratedAlerts =>
          'Central de Alertas Integrada',
        AtlasLivestockIntegrationModule.integratedTasks =>
          'Central de Tarefas Integrada',
      };

  String get packageLabel => switch (this) {
        AtlasLivestockIntegrationModule.herdMigration => 'Pacote 271',
        AtlasLivestockIntegrationModule.reproductionMigration => 'Pacote 272',
        AtlasLivestockIntegrationModule.healthMigration => 'Pacote 273',
        AtlasLivestockIntegrationModule.nutritionMigration => 'Pacote 274',
        AtlasLivestockIntegrationModule.financeMigration => 'Pacote 275',
        AtlasLivestockIntegrationModule.stockMigration => 'Pacote 276',
        AtlasLivestockIntegrationModule.eventIntegration => 'Pacote 277',
        AtlasLivestockIntegrationModule.unifiedTimeline => 'Pacote 278',
        AtlasLivestockIntegrationModule.integratedAlerts => 'Pacote 279',
        AtlasLivestockIntegrationModule.integratedTasks => 'Pacote 280',
      };

  List<String> get features => switch (this) {
        AtlasLivestockIntegrationModule.herdMigration => const [
            'Animais',
            'Lotes',
            'Movimentações',
            'Filtros',
            'Histórico',
          ],
        AtlasLivestockIntegrationModule.reproductionMigration => const [
            'Protocolos',
            'Inseminações',
            'Coberturas',
            'Diagnósticos',
            'Partos',
          ],
        AtlasLivestockIntegrationModule.healthMigration => const [
            'Vacinas',
            'Medicamentos',
            'Diagnósticos',
            'Tratamentos',
            'Carências',
          ],
        AtlasLivestockIntegrationModule.nutritionMigration => const [
            'Dietas',
            'Suplementos',
            'Consumo',
            'Lotes nutricionais',
            'Custos',
          ],
        AtlasLivestockIntegrationModule.financeMigration => const [
            'Receitas',
            'Despesas',
            'Fluxo de caixa',
            'Orçamento',
            'Indicadores',
          ],
        AtlasLivestockIntegrationModule.stockMigration => const [
            'Produtos',
            'Depósitos',
            'Lotes',
            'Validades',
            'Movimentações',
          ],
        AtlasLivestockIntegrationModule.eventIntegration => const [
            'Origem do evento',
            'Reflexos automáticos',
            'Validações',
            'Idempotência',
            'Auditoria',
          ],
        AtlasLivestockIntegrationModule.unifiedTimeline => const [
            'Eventos produtivos',
            'Eventos sanitários',
            'Eventos reprodutivos',
            'Eventos financeiros',
            'Eventos operacionais',
          ],
        AtlasLivestockIntegrationModule.integratedAlerts => const [
            'Vencimentos',
            'Falhas',
            'Riscos',
            'Metas',
            'Priorização',
          ],
        AtlasLivestockIntegrationModule.integratedTasks => const [
            'Origem',
            'Responsável',
            'Prazo',
            'Prioridade',
            'Comprovação',
          ],
      };
}

class AtlasLivestockIntegrationRecord {
  const AtlasLivestockIntegrationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.priority,
    required this.farmName,
    required this.animalOrLot,
    required this.sourceModule,
    required this.destinationModule,
    required this.eventType,
    required this.responsible,
    required this.progressPercent,
    required this.successRatePercent,
    required this.riskPercent,
    required this.pendingCount,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasLivestockIntegrationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String priority;
  final String farmName;
  final String animalOrLot;
  final String sourceModule;
  final String destinationModule;
  final String eventType;
  final String responsible;
  final int progressPercent;
  final double successRatePercent;
  final double riskPercent;
  final int pendingCount;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Integrado' ||
      status == 'Validado' ||
      status == 'Concluído';

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Falha' ||
      status == 'Atenção';

  Map<String, dynamic> toMap() => {
        'id': id,
        'module': module.code,
        'feature': feature,
        'title': title,
        'date': date,
        'status': status,
        'priority': priority,
        'farmName': farmName,
        'animalOrLot': animalOrLot,
        'sourceModule': sourceModule,
        'destinationModule': destinationModule,
        'eventType': eventType,
        'responsible': responsible,
        'progressPercent': progressPercent,
        'successRatePercent': successRatePercent,
        'riskPercent': riskPercent,
        'pendingCount': pendingCount,
        'alertCount': alertCount,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AtlasLivestockIntegrationRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    final code = map['module']?.toString() ?? '';

    final module =
        AtlasLivestockIntegrationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () =>
          AtlasLivestockIntegrationModule.herdMigration,
    );

    return AtlasLivestockIntegrationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      farmName: map['farmName']?.toString() ?? '',
      animalOrLot: map['animalOrLot']?.toString() ?? '',
      sourceModule: map['sourceModule']?.toString() ?? '',
      destinationModule: map['destinationModule']?.toString() ?? '',
      eventType: map['eventType']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      progressPercent:
          (map['progressPercent'] as num?)?.toInt() ?? 0,
      successRatePercent:
          (map['successRatePercent'] as num?)?.toDouble() ?? 0,
      riskPercent:
          (map['riskPercent'] as num?)?.toDouble() ?? 0,
      pendingCount:
          (map['pendingCount'] as num?)?.toInt() ?? 0,
      alertCount:
          (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasLivestockIntegrationDate(String value) {
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

String formatAtlasLivestockIntegrationDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
