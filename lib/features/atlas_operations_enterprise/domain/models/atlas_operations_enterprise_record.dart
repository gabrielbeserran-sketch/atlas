enum AtlasOperationsEnterpriseModule {
  farmOperationalPlanning,
  intelligentActivityAgenda,
  workOrders,
  teamManagement,
  workdayControl,
  machineryManagement,
  preventiveMaintenance,
  correctiveMaintenance,
  operationalIndicators,
  operationsCenter,
}

extension AtlasOperationsEnterpriseModuleX
    on AtlasOperationsEnterpriseModule {
  String get code => switch (this) {
        AtlasOperationsEnterpriseModule.farmOperationalPlanning =>
          'farm_operational_planning',
        AtlasOperationsEnterpriseModule.intelligentActivityAgenda =>
          'intelligent_activity_agenda',
        AtlasOperationsEnterpriseModule.workOrders =>
          'work_orders',
        AtlasOperationsEnterpriseModule.teamManagement =>
          'team_management',
        AtlasOperationsEnterpriseModule.workdayControl =>
          'workday_control',
        AtlasOperationsEnterpriseModule.machineryManagement =>
          'machinery_management',
        AtlasOperationsEnterpriseModule.preventiveMaintenance =>
          'preventive_maintenance',
        AtlasOperationsEnterpriseModule.correctiveMaintenance =>
          'corrective_maintenance',
        AtlasOperationsEnterpriseModule.operationalIndicators =>
          'operational_indicators',
        AtlasOperationsEnterpriseModule.operationsCenter =>
          'operations_center',
      };

  String get title => switch (this) {
        AtlasOperationsEnterpriseModule.farmOperationalPlanning =>
          'Planejamento Operacional da Fazenda',
        AtlasOperationsEnterpriseModule.intelligentActivityAgenda =>
          'Agenda Inteligente de Atividades',
        AtlasOperationsEnterpriseModule.workOrders =>
          'Ordens de Serviço',
        AtlasOperationsEnterpriseModule.teamManagement =>
          'Gestão de Equipes',
        AtlasOperationsEnterpriseModule.workdayControl =>
          'Controle de Jornada',
        AtlasOperationsEnterpriseModule.machineryManagement =>
          'Gestão de Máquinas',
        AtlasOperationsEnterpriseModule.preventiveMaintenance =>
          'Manutenção Preventiva',
        AtlasOperationsEnterpriseModule.correctiveMaintenance =>
          'Manutenção Corretiva',
        AtlasOperationsEnterpriseModule.operationalIndicators =>
          'Indicadores Operacionais',
        AtlasOperationsEnterpriseModule.operationsCenter =>
          'Central de Operações Atlas',
      };

  String get packageLabel => switch (this) {
        AtlasOperationsEnterpriseModule.farmOperationalPlanning =>
          'Pacote 201',
        AtlasOperationsEnterpriseModule.intelligentActivityAgenda =>
          'Pacote 202',
        AtlasOperationsEnterpriseModule.workOrders =>
          'Pacote 203',
        AtlasOperationsEnterpriseModule.teamManagement =>
          'Pacote 204',
        AtlasOperationsEnterpriseModule.workdayControl =>
          'Pacote 205',
        AtlasOperationsEnterpriseModule.machineryManagement =>
          'Pacote 206',
        AtlasOperationsEnterpriseModule.preventiveMaintenance =>
          'Pacote 207',
        AtlasOperationsEnterpriseModule.correctiveMaintenance =>
          'Pacote 208',
        AtlasOperationsEnterpriseModule.operationalIndicators =>
          'Pacote 209',
        AtlasOperationsEnterpriseModule.operationsCenter =>
          'Pacote 210',
      };

  List<String> get features => switch (this) {
        AtlasOperationsEnterpriseModule.farmOperationalPlanning => const [
            'Plano anual',
            'Plano mensal',
            'Plano semanal',
            'Plano diário',
            'Metas e responsáveis',
          ],
        AtlasOperationsEnterpriseModule.intelligentActivityAgenda => const [
            'Calendário de atividades',
            'Prioridades',
            'Dependências',
            'Lembretes',
            'Conflitos de agenda',
          ],
        AtlasOperationsEnterpriseModule.workOrders => const [
            'Abertura',
            'Distribuição',
            'Execução',
            'Evidências',
            'Encerramento',
          ],
        AtlasOperationsEnterpriseModule.teamManagement => const [
            'Colaboradores',
            'Cargos e competências',
            'Escalas',
            'Disponibilidade',
            'Distribuição de tarefas',
          ],
        AtlasOperationsEnterpriseModule.workdayControl => const [
            'Entrada e saída',
            'Horas trabalhadas',
            'Horas extras',
            'Ausências',
            'Aprovação de jornada',
          ],
        AtlasOperationsEnterpriseModule.machineryManagement => const [
            'Cadastro de máquinas',
            'Disponibilidade',
            'Horas de uso',
            'Operadores',
            'Custos operacionais',
          ],
        AtlasOperationsEnterpriseModule.preventiveMaintenance => const [
            'Planos de revisão',
            'Horímetro e quilometragem',
            'Peças previstas',
            'Agenda preventiva',
            'Conformidade da manutenção',
          ],
        AtlasOperationsEnterpriseModule.correctiveMaintenance => const [
            'Falhas',
            'Diagnóstico',
            'Reparos',
            'Peças utilizadas',
            'Tempo de parada',
          ],
        AtlasOperationsEnterpriseModule.operationalIndicators => const [
            'Produtividade',
            'Cumprimento de prazos',
            'Utilização de máquinas',
            'Custos',
            'Eficiência operacional',
          ],
        AtlasOperationsEnterpriseModule.operationsCenter => const [
            'Atividades críticas',
            'Equipes',
            'Máquinas',
            'Ordens de serviço',
            'Painel executivo',
          ],
      };
}

class AtlasOperationsEnterpriseRecord {
  const AtlasOperationsEnterpriseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.farmName,
    required this.areaName,
    required this.responsible,
    required this.teamName,
    required this.assetName,
    required this.plannedHours,
    required this.actualHours,
    required this.plannedCost,
    required this.actualCost,
    required this.progressPercent,
    required this.qualityPercent,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasOperationsEnterpriseModule module;
  final String feature;
  final String title;
  final String date;
  final String dueDate;
  final String status;
  final String priority;
  final String farmName;
  final String areaName;
  final String responsible;
  final String teamName;
  final String assetName;
  final double plannedHours;
  final double actualHours;
  final double plannedCost;
  final double actualCost;
  final int progressPercent;
  final double qualityPercent;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Atrasado' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Em execução' ||
      status == 'Concluído' ||
      status == 'Validado';

  bool get isOverdue {
    final parsed = parseAtlasOperationsDate(dueDate);
    if (parsed.year == 1900) return false;
    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Cancelado';
  }

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
        'areaName': areaName,
        'responsible': responsible,
        'teamName': teamName,
        'assetName': assetName,
        'plannedHours': plannedHours,
        'actualHours': actualHours,
        'plannedCost': plannedCost,
        'actualCost': actualCost,
        'progressPercent': progressPercent,
        'qualityPercent': qualityPercent,
        'alertCount': alertCount,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AtlasOperationsEnterpriseRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    final code = map['module']?.toString() ?? '';
    final module =
        AtlasOperationsEnterpriseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () =>
          AtlasOperationsEnterpriseModule.farmOperationalPlanning,
    );

    return AtlasOperationsEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dueDate: map['dueDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      farmName: map['farmName']?.toString() ?? '',
      areaName: map['areaName']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      teamName: map['teamName']?.toString() ?? '',
      assetName: map['assetName']?.toString() ?? '',
      plannedHours:
          (map['plannedHours'] as num?)?.toDouble() ?? 0,
      actualHours:
          (map['actualHours'] as num?)?.toDouble() ?? 0,
      plannedCost:
          (map['plannedCost'] as num?)?.toDouble() ?? 0,
      actualCost:
          (map['actualCost'] as num?)?.toDouble() ?? 0,
      progressPercent:
          (map['progressPercent'] as num?)?.toInt() ?? 0,
      qualityPercent:
          (map['qualityPercent'] as num?)?.toDouble() ?? 0,
      alertCount:
          (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasOperationsDate(String value) {
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

String formatAtlasOperationsDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
