import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_operations_enterprise/domain/models/atlas_operations_enterprise_record.dart';

class AtlasOperationsEnterpriseAnalytics {
  const AtlasOperationsEnterpriseAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.overdueCount,
    required this.totalPlannedHours,
    required this.totalActualHours,
    required this.totalPlannedCost,
    required this.totalActualCost,
    required this.averageProgress,
    required this.averageQuality,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int overdueCount;
  final double totalPlannedHours;
  final double totalActualHours;
  final double totalPlannedCost;
  final double totalActualCost;
  final double averageProgress;
  final double averageQuality;
  final int score;
  final List<String> recommendations;

  double get costDeviation => totalActualCost - totalPlannedCost;
  double get hourDeviation => totalActualHours - totalPlannedHours;
}

class AtlasOperationsEnterpriseAnalyticsService {
  const AtlasOperationsEnterpriseAnalyticsService();

  AtlasOperationsEnterpriseAnalytics analyze({
    required AtlasOperationsEnterpriseModule module,
    required List<AtlasOperationsEnterpriseRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final overdue = moduleRecords.where((record) => record.isOverdue).length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    double averageOf(
      double Function(AtlasOperationsEnterpriseRecord) selector,
    ) {
      if (moduleRecords.isEmpty) return 0;
      return moduleRecords.map(selector).reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final plannedHours = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.plannedHours,
    );
    final actualHours = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.actualHours,
    );
    final plannedCost = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.plannedCost,
    );
    final actualCost = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.actualCost,
    );

    final averageProgress = averageOf(
      (record) => record.progressPercent.toDouble(),
    );
    final averageQuality = averageOf((record) => record.qualityPercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageProgress.round() * 15 ~/ 100);
    score += math.min(10, averageQuality.round() ~/ 10);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, overdue * 5);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        recommendations.add('Implantar ou registrar: $feature.');
      }
    }

    if (overdue > 0) {
      recommendations.add(
        'Existem $overdue registros vencidos; revise prazos, responsáveis e dependências.',
      );
    }

    if (alerts > 0) {
      recommendations.add(
        'Existem $alerts alertas operacionais; priorize os de maior impacto.',
      );
    }

    if (moduleRecords.isEmpty) {
      recommendations.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      recommendations.addAll(switch (module) {
        AtlasOperationsEnterpriseModule.farmOperationalPlanning => const [
          'Conecte metas, responsáveis, prazos e recursos.',
          'Revise o plano quando houver mudanças de prioridade.',
        ],
        AtlasOperationsEnterpriseModule.intelligentActivityAgenda => const [
          'Evite conflitos de horário e dependências não resolvidas.',
          'Converta atividades críticas em tarefas acompanháveis.',
        ],
        AtlasOperationsEnterpriseModule.workOrders => const [
          'Registre abertura, execução, evidências e encerramento.',
          'Não encerre ordens sem validação do responsável.',
        ],
        AtlasOperationsEnterpriseModule.teamManagement => const [
          'Distribua tarefas conforme competência e disponibilidade.',
          'Evite sobrecarga recorrente da mesma equipe.',
        ],
        AtlasOperationsEnterpriseModule.workdayControl => const [
          'Mantenha registros de jornada auditáveis.',
          'Trate horas extras e ausências com aprovação.',
        ],
        AtlasOperationsEnterpriseModule.machineryManagement => const [
          'Atualize horímetro, operador e disponibilidade.',
          'Separe custo fixo, variável e tempo parado.',
        ],
        AtlasOperationsEnterpriseModule.preventiveMaintenance => const [
          'Planeje manutenção antes do limite de uso.',
          'Associe peças, custos, prazo e responsável.',
        ],
        AtlasOperationsEnterpriseModule.correctiveMaintenance => const [
          'Registre causa, reparo e tempo de indisponibilidade.',
          'Use falhas recorrentes para melhorar o plano preventivo.',
        ],
        AtlasOperationsEnterpriseModule.operationalIndicators => const [
          'Padronize período, fórmula e fonte de cada indicador.',
          'Compare resultado com meta e histórico.',
        ],
        AtlasOperationsEnterpriseModule.operationsCenter => const [
          'Centralize atividades, equipes, máquinas e ordens.',
          'Priorize por impacto, urgência e dependência.',
        ],
      });
    }

    return AtlasOperationsEnterpriseAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      overdueCount: overdue,
      totalPlannedHours: plannedHours,
      totalActualHours: actualHours,
      totalPlannedCost: plannedCost,
      totalActualCost: actualCost,
      averageProgress: averageProgress,
      averageQuality: averageQuality,
      score: score,
      recommendations: recommendations,
    );
  }
}
