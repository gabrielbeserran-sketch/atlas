import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_official_integrations/domain/models/atlas_official_integration_record.dart';

class AtlasOfficialIntegrationAnalytics {
  const AtlasOfficialIntegrationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int pendingCount;
  final int alertCount;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasOfficialIntegrationAnalyticsService {
  const AtlasOfficialIntegrationAnalyticsService();

  AtlasOfficialIntegrationAnalytics analyze({
    required AtlasOfficialIntegrationModule module,
    required List<AtlasOfficialIntegrationRecord> records,
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

    final operational =
        moduleRecords.where((record) => record.isOperational).length;

    final pending = moduleRecords.where((record) {
      return !record.isOperational && !record.isCritical;
    }).length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isExpired ? 1 : 0),
    );

    final averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.progressPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    var score = 30;
    score += math.min(35, coverage.round() * 35 ~/ 100);
    score += math.min(25, operational * 5);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(40, alerts * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasOfficialIntegrationAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
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
    required AtlasOfficialIntegrationModule module,
    required List<AtlasOfficialIntegrationRecord> records,
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
        'Existem $alerts alertas, rejeições, vencimentos ou bloqueios; revise antes de transmitir.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      items.addAll(
        switch (module) {
          AtlasOfficialIntegrationModule.sisbov => const [
              'Confirme identificação, vínculos e eventos antes da sincronização oficial.',
              'Mantenha documentos e trilha de auditoria associados ao animal.',
            ],
          AtlasOfficialIntegrationModule.gta => const [
              'Valide origem, destino, finalidade, quantidade e validade antes da emissão.',
              'Mantenha os comprovantes e a situação da autorização atualizados.',
            ],
          AtlasOfficialIntegrationModule.mapa => const [
              'Centralize protocolos, documentos e vencimentos regulatórios.',
              'Use revisão humana antes de qualquer transmissão a sistema oficial.',
            ],
          AtlasOfficialIntegrationModule.esocialRural => const [
              'Valide cadastros, lotações, eventos e prazos com o responsável contábil.',
              'Não transmita dados pessoais sem autorização, segurança e conferência.',
            ],
        },
      );
    }

    return items;
  }
}
