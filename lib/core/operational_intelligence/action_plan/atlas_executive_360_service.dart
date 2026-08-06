import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_360_models.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';

class AtlasExecutive360Service {
  const AtlasExecutive360Service();

  Future<AtlasExecutive360Snapshot> build({
    required String? farmName,
  }) async {
    await AtlasDigitalTwinService.instance.load();
    await AtlasDigitalTwinService.instance.start();

    final twin = _resolveTwin(farmName);
    final economicService = AtlasEconomicIntelligenceService.instance;
    final metrics =
        await economicService.loadMetrics(farmName: farmName);
    final economic = await economicService.buildSnapshot(
      farmName: farmName,
      metrics: metrics,
    );

    final health = twin.health;
    final areas = <AtlasExecutive360AreaScore>[
      _area('Rebanho', health.animal),
      _area('Sanidade', health.sanitary),
      _area('Reprodução', health.reproductive),
      _area('Financeiro', economic.financialScore),
      _area('Estoque', health.inventory),
      _area('Operacional', health.operational),
    ];

    final overall = areas.isEmpty
        ? 0.0
        : areas.fold<double>(
              0,
              (total, item) => total + item.score,
            ) /
            areas.length;

    final riskFromTwin = twin.risks.isEmpty
        ? 0.0
        : twin.risks.fold<double>(
              0,
              (total, item) => total + item.score,
            ) /
            twin.risks.length;

    final riskScore =
        (100 - overall + riskFromTwin * 0.35)
            .clamp(0, 100)
            .toDouble();

    final productivityScore =
        ((health.animal +
                    health.reproductive +
                    health.operational) /
                3)
            .clamp(0, 100)
            .toDouble();

    final bottlenecks = <AtlasExecutive360Bottleneck>[
      ...areas
          .where((item) => item.score < 70)
          .map(
            (item) => AtlasExecutive360Bottleneck(
              area: item.area,
              title: '${item.area} abaixo da meta',
              description:
                  'O score atual é ${item.score.toStringAsFixed(1)}/100.',
              severity: 100 - item.score,
              recommendedAction:
                  'Abra o módulo de ${item.area.toLowerCase()} e transforme os alertas prioritários em ações.',
            ),
          ),
      ...twin.risks
          .where(
            (item) =>
                item.level == AtlasFarmRiskLevel.high ||
                item.level == AtlasFarmRiskLevel.critical,
          )
          .map(
            (item) => AtlasExecutive360Bottleneck(
              area: item.area.name,
              title: item.title,
              description: item.description,
              severity: item.score,
              recommendedAction:
                  'Trate o risco no Plano de Ação e defina responsável e prazo.',
            ),
          ),
    ]..sort(
        (first, second) =>
            second.severity.compareTo(first.severity),
      );

    return AtlasExecutive360Snapshot(
      farmName: farmName?.trim().isNotEmpty == true
          ? farmName!.trim()
          : twin.farmName,
      generatedAt: DateTime.now(),
      overallScore: overall,
      riskScore: riskScore,
      productivityScore: productivityScore,
      areaScores: areas,
      bottlenecks: bottlenecks,
      officialRecommendation: _officialRecommendation(
        overall: overall,
        risk: riskScore,
        financial: economic.financialScore,
        bottlenecks: bottlenecks,
      ),
    );
  }

  AtlasDigitalTwin _resolveTwin(String? farmName) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) {
      for (final twin in AtlasDigitalTwinService.instance.twins) {
        if (twin.farmName.trim().toLowerCase() == normalized) {
          return twin;
        }
      }
    }
    return AtlasDigitalTwinService.instance.primaryTwin ??
        AtlasDigitalTwin.initial(
          farmId: 'global',
          farmName: farmName?.trim().isNotEmpty == true
              ? farmName!.trim()
              : 'Operação Atlas',
        );
  }

  AtlasExecutive360AreaScore _area(
    String area,
    double score,
  ) {
    return AtlasExecutive360AreaScore(
      area: area,
      score: score.clamp(0, 100),
      status: score >= 80
          ? 'Saudável'
          : score >= 65
              ? 'Atenção'
              : score >= 45
                  ? 'Alto risco'
                  : 'Crítico',
    );
  }

  String _officialRecommendation({
    required double overall,
    required double risk,
    required double financial,
    required List<AtlasExecutive360Bottleneck> bottlenecks,
  }) {
    if (risk >= 70) {
      return 'Prioridade imediata: estabilizar os riscos críticos antes de ampliar investimentos.';
    }
    if (financial < 60) {
      return 'Prioridade executiva: preservar caixa, elevar margem e revisar compromissos financeiros.';
    }
    if (bottlenecks.isNotEmpty) {
      return 'Concentre a próxima reunião de gestão nos três maiores gargalos do painel 360°.';
    }
    if (overall >= 85) {
      return 'A operação está saudável. Avance com metas de crescimento controlado e monitoramento semanal.';
    }
    return 'A operação está equilibrada, mas ainda exige disciplina de execução e acompanhamento dos indicadores.';
  }
}
