import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_platform_resilience/domain/models/atlas_platform_resilience_record.dart';

class AtlasPlatformResilienceAnalytics {
  const AtlasPlatformResilienceAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.financialImpact,
    required this.totalQuantity,
    required this.averageScore,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int pendingCount;
  final int alertCount;
  final double financialImpact;
  final int totalQuantity;
  final double averageScore;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasPlatformResilienceAnalyticsService {
  const AtlasPlatformResilienceAnalyticsService();

  AtlasPlatformResilienceAnalytics analyze({
    required AtlasPlatformResilienceModule module,
    required List<AtlasPlatformResilienceRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final pending = moduleRecords.where((record) {
      return !record.isOperational && !record.isCritical;
    }).length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    final financialImpact = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.financialImpact,
    );

    final totalQuantity = moduleRecords.fold<int>(
      0,
      (total, record) => total + record.quantity,
    );

    final averageScore = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.scoreValue)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    final averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.progressPercent)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    var score = 30;
    score += math.min(30, coverage.round() * 30 ~/ 100);
    score += math.min(25, operational * 5);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(40, alerts * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasPlatformResilienceAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
      financialImpact: financialImpact,
      totalQuantity: totalQuantity,
      averageScore: averageScore,
      averageProgress: averageProgress,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        represented: represented,
        alerts: alerts,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasPlatformResilienceModule module,
    required List<AtlasPlatformResilienceRecord> records,
    required Set<String> represented,
    required int alerts,
  }) {
    final items = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        items.add('Implantar ou registrar: $feature.');
      }
    }

    if (alerts > 0) {
      items.add(
        'Existem $alerts alertas ou riscos críticos; priorize responsáveis, prazo e plano de resposta.',
      );
    }

    if (records.isEmpty) {
      items.add('Cadastre o primeiro registro do ${module.packageLabel}.');
    } else {
      items.addAll(switch (module) {
        AtlasPlatformResilienceModule.dataGovernance => const [
          'Defina proprietário, significado, qualidade e retenção para cada dado crítico.',
          'Monitore completude, duplicidade, consistência e origem dos dados.',
        ],
        AtlasPlatformResilienceModule.integrationHub => const [
          'Use identificadores idempotentes, filas, retentativas e rastreabilidade ponta a ponta.',
          'Documente contrato, versão, autenticação, mapeamento e tratamento de falhas.',
        ],
        AtlasPlatformResilienceModule.cybersecurity => const [
          'Aplique menor privilégio, autenticação forte, revisão periódica e segregação de funções.',
          'Mantenha inventário, avaliação de riscos, evidências e plano de resposta a incidentes.',
        ],
        AtlasPlatformResilienceModule.observability => const [
          'Acompanhe disponibilidade, latência, erros, saturação e capacidade dos serviços.',
          'Todo alerta deve ter prioridade, responsável, contexto e procedimento de resposta.',
        ],
        AtlasPlatformResilienceModule.digitalTwin => const [
          'Mantenha o modelo digital sincronizado com dados confiáveis do ambiente físico.',
          'Valide cenários simulados antes de usá-los em decisões operacionais.',
        ],
      });
    }

    return items;
  }
}
