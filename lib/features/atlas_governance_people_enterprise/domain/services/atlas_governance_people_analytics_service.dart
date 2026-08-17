import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_governance_people_enterprise/domain/models/atlas_governance_people_record.dart';

class AtlasGovernancePeopleAnalytics {
  const AtlasGovernancePeopleAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.overdueCount,
    required this.averageProbability,
    required this.averageImpact,
    required this.averageRiskScore,
    required this.averageProgress,
    required this.averageCompliance,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int overdueCount;
  final double averageProbability;
  final double averageImpact;
  final double averageRiskScore;
  final double averageProgress;
  final double averageCompliance;
  final int score;
  final List<String> recommendations;
}

class AtlasGovernancePeopleAnalyticsService {
  const AtlasGovernancePeopleAnalyticsService();

  AtlasGovernancePeopleAnalytics analyze({
    required AtlasGovernancePeopleModule module,
    required List<AtlasGovernancePeopleRecord> records,
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

    double averageOf(double Function(AtlasGovernancePeopleRecord) selector) {
      if (moduleRecords.isEmpty) return 0;
      return moduleRecords.map(selector).reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final averageProbability = averageOf((record) => record.probabilityPercent);
    final averageImpact = averageOf((record) => record.impactPercent);
    final averageRisk = averageOf((record) => record.riskScore);
    final averageProgress = averageOf(
      (record) => record.progressPercent.toDouble(),
    );
    final averageCompliance = averageOf((record) => record.compliancePercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageProgress.round() * 15 ~/ 100);
    score += math.min(15, averageCompliance.round() * 15 ~/ 100);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, overdue * 5);
    score -= math.min(15, averageRisk.round() * 15 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        recommendations.add('Implantar ou registrar: $feature.');
      }
    }

    if (overdue > 0) {
      recommendations.add(
        'Existem $overdue registros vencidos; revise prazos, documentos e responsáveis.',
      );
    }

    if (alerts > 0) {
      recommendations.add(
        'Existem $alerts alertas de governança; priorize riscos e não conformidades.',
      );
    }

    if (moduleRecords.isEmpty) {
      recommendations.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      recommendations.addAll(switch (module) {
        AtlasGovernancePeopleModule.peopleManagement => const [
          'Mantenha contratos, cargos e histórico atualizados.',
          'Restrinja dados pessoais conforme o nível de acesso.',
        ],
        AtlasGovernancePeopleModule.trainingAndQualification => const [
          'Associe capacitação às competências exigidas.',
          'Acompanhe certificados e respectivas validades.',
        ],
        AtlasGovernancePeopleModule.occupationalHealthAndSafety => const [
          'Trate acidentes e riscos com ações preventivas.',
          'Valide exames e registros com profissionais responsáveis.',
        ],
        AtlasGovernancePeopleModule.personalProtectiveEquipment => const [
          'Controle entrega, validade, devolução e substituição.',
          'Mantenha comprovantes vinculados ao colaborador.',
        ],
        AtlasGovernancePeopleModule.documentManagement => const [
          'Controle versões, validade, acesso e evidências.',
          'Evite documentos críticos sem responsável definido.',
        ],
        AtlasGovernancePeopleModule.complianceControl => const [
          'Associe requisitos a evidências e responsáveis.',
          'Transforme não conformidades em planos corretivos.',
        ],
        AtlasGovernancePeopleModule.internalAudits => const [
          'Registre escopo, evidências, achados e acompanhamento.',
          'Não encerre auditoria sem tratar achados relevantes.',
        ],
        AtlasGovernancePeopleModule.corporateRiskManagement => const [
          'Avalie probabilidade, impacto e controles.',
          'Revise riscos críticos em periodicidade definida.',
        ],
        AtlasGovernancePeopleModule.permissionMatrix => const [
          'Aplique o princípio do menor privilégio.',
          'Revise acessos após mudanças de função ou desligamento.',
        ],
        AtlasGovernancePeopleModule.governanceCenter => const [
          'Centralize pessoas, documentos, conformidade e riscos.',
          'Priorize decisões por impacto, urgência e obrigação.',
        ],
      });
    }

    return AtlasGovernancePeopleAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      overdueCount: overdue,
      averageProbability: averageProbability,
      averageImpact: averageImpact,
      averageRiskScore: averageRisk,
      averageProgress: averageProgress,
      averageCompliance: averageCompliance,
      score: score,
      recommendations: recommendations,
    );
  }
}
