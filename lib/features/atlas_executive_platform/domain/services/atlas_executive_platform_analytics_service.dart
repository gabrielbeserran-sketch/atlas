import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_executive_platform/domain/models/atlas_executive_platform_record.dart';

class AtlasExecutivePlatformAnalytics {
  const AtlasExecutivePlatformAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.overdueCount,
    required this.averageCurrent,
    required this.averageTarget,
    required this.averageGap,
    required this.averageProgress,
    required this.averageConfidence,
    required this.averageRisk,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int overdueCount;
  final double averageCurrent;
  final double averageTarget;
  final double averageGap;
  final double averageProgress;
  final double averageConfidence;
  final double averageRisk;
  final int score;
  final List<String> recommendations;
}

class AtlasExecutivePlatformAnalyticsService {
  const AtlasExecutivePlatformAnalyticsService();

  AtlasExecutivePlatformAnalytics analyze({
    required AtlasExecutivePlatformModule module,
    required List<AtlasExecutivePlatformRecord> records,
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

    double averageOf(double Function(AtlasExecutivePlatformRecord) selector) {
      if (moduleRecords.isEmpty) return 0;

      return moduleRecords.map(selector).reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final averageCurrent = averageOf((record) => record.currentValue);
    final averageTarget = averageOf((record) => record.targetValue);
    final averageGap = averageOf((record) => record.gap);
    final averageProgress = averageOf(
      (record) => record.progressPercent.toDouble(),
    );
    final averageConfidence = averageOf((record) => record.confidencePercent);
    final averageRisk = averageOf((record) => record.riskPercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageProgress.round() * 15 ~/ 100);
    score += math.min(15, averageConfidence.round() * 15 ~/ 100);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, overdue * 5);
    score -= math.min(20, averageRisk.round() * 20 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        recommendations.add('Implantar ou registrar: $feature.');
      }
    }

    if (overdue > 0) {
      recommendations.add(
        'Existem $overdue registros vencidos; revise responsáveis, prazos e dependências.',
      );
    }

    if (alerts > 0) {
      recommendations.add(
        'Existem $alerts alertas executivos; priorize impacto, urgência e risco.',
      );
    }

    if (moduleRecords.isEmpty) {
      recommendations.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      recommendations.addAll(switch (module) {
        AtlasExecutivePlatformModule.globalExecutiveDashboard => const [
          'Consolide somente indicadores com fonte e período definidos.',
          'Destaque desvios, riscos e decisões prioritárias.',
        ],
        AtlasExecutivePlatformModule.farmBenchmarking => const [
          'Compare fazendas com critérios equivalentes.',
          'Use referências ajustadas por escala e sistema produtivo.',
        ],
        AtlasExecutivePlatformModule.corporateGoals => const [
          'Associe cada meta a indicador, prazo e responsável.',
          'Revise metas sem apagar o histórico original.',
        ],
        AtlasExecutivePlatformModule.unifiedAlerts => const [
          'Elimine duplicidades e agrupe alertas correlacionados.',
          'Defina severidade, responsável e tratamento.',
        ],
        AtlasExecutivePlatformModule.intelligentTasks => const [
          'Converta alertas e recomendações em tarefas rastreáveis.',
          'Mantenha dependências e critérios de conclusão.',
        ],
        AtlasExecutivePlatformModule.professionalReports => const [
          'Controle versões e origem dos dados.',
          'Diferencie relatório técnico, gerencial e executivo.',
        ],
        AtlasExecutivePlatformModule.exportAndSharing => const [
          'Restrinja compartilhamento conforme o nível de acesso.',
          'Registre exportações e mantenha validade dos links.',
        ],
        AtlasExecutivePlatformModule.plansAndSubscriptions => const [
          'Defina limites, recursos e regras de renovação.',
          'Mantenha histórico de alteração de plano.',
        ],
        AtlasExecutivePlatformModule.platformAdminPanel => const [
          'Separe administração da plataforma e dados dos clientes.',
          'Acompanhe usuários, empresas, suporte e estabilidade.',
        ],
        AtlasExecutivePlatformModule.enterpriseCommandCenter => const [
          'Integre operações, finanças, riscos e inteligência.',
          'Priorize decisões com impacto, confiança e prazo.',
        ],
      });
    }

    return AtlasExecutivePlatformAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      overdueCount: overdue,
      averageCurrent: averageCurrent,
      averageTarget: averageTarget,
      averageGap: averageGap,
      averageProgress: averageProgress,
      averageConfidence: averageConfidence,
      averageRisk: averageRisk,
      score: score,
      recommendations: recommendations,
    );
  }
}
