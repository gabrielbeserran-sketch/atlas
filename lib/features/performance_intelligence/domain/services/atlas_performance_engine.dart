import '../models/atlas_performance_analysis.dart';
import '../models/atlas_performance_kpi.dart';

class AtlasPerformanceEngine {
  const AtlasPerformanceEngine();

  AtlasPerformanceScorecard analyze(List<AtlasPerformanceKpi> kpis) {
    final evaluations = kpis.map(_evaluate).toList();
    double categoryScore(AtlasKpiCategory category) {
      final values = evaluations
          .where((e) => e.kpi.category == category)
          .map((e) => e.achievement)
          .toList();
      return values.isEmpty
          ? 0
          : values.reduce((a, b) => a + b) / values.length;
    }

    final alerts = <AtlasPerformanceAlert>[];
    for (final evaluation in evaluations) {
      final kpi = evaluation.kpi;
      if (evaluation.status == AtlasKpiStatus.critical) {
        alerts.add(
          AtlasPerformanceAlert(
            title: '${kpi.name} em nível crítico',
            message:
                'Resultado atual de ${_format(kpi.currentValue)} ${kpi.unit}, frente à meta de ${_format(kpi.targetValue)} ${kpi.unit}.',
            severity: AtlasPerformanceAlertSeverity.critical,
            kpiId: kpi.id,
          ),
        );
      } else if (evaluation.status == AtlasKpiStatus.attention) {
        alerts.add(
          AtlasPerformanceAlert(
            title: '${kpi.name} exige atenção',
            message:
                'O indicador atingiu ${evaluation.achievement.toStringAsFixed(0)}% do desempenho esperado.',
            severity: AtlasPerformanceAlertSeverity.attention,
            kpiId: kpi.id,
          ),
        );
      }
      final worsening = kpi.direction == AtlasKpiDirection.lowerIsBetter
          ? kpi.variation > 8
          : kpi.variation < -8;
      if (worsening) {
        alerts.add(
          AtlasPerformanceAlert(
            title: 'Tendência negativa em ${kpi.name}',
            message:
                'Variação de ${kpi.variation.toStringAsFixed(1)}% em relação ao período anterior.',
            severity: AtlasPerformanceAlertSeverity.attention,
            kpiId: kpi.id,
          ),
        );
      }
    }
    final overall = evaluations.isEmpty
        ? 0.0
        : evaluations.map((e) => e.achievement).reduce((a, b) => a + b) /
              evaluations.length;
    return AtlasPerformanceScorecard(
      overallScore: overall.clamp(0, 120).toDouble(),
      productiveScore: categoryScore(AtlasKpiCategory.productive),
      financialScore: categoryScore(AtlasKpiCategory.financial),
      operationalScore: categoryScore(AtlasKpiCategory.operational),
      strategicScore: categoryScore(AtlasKpiCategory.strategic),
      evaluations: evaluations,
      alerts: alerts,
    );
  }

  AtlasKpiEvaluation _evaluate(AtlasPerformanceKpi kpi) {
    double achievement;
    switch (kpi.direction) {
      case AtlasKpiDirection.higherIsBetter:
        achievement = kpi.targetValue <= 0
            ? 0
            : (kpi.currentValue / kpi.targetValue) * 100;
      case AtlasKpiDirection.lowerIsBetter:
        achievement = kpi.currentValue <= 0
            ? 120
            : (kpi.targetValue / kpi.currentValue) * 100;
      case AtlasKpiDirection.targetRange:
        final min = kpi.minimumTarget ?? kpi.targetValue * .95;
        final max = kpi.maximumTarget ?? kpi.targetValue * 1.05;
        if (kpi.currentValue >= min && kpi.currentValue <= max) {
          achievement = 100;
        } else {
          final distance = kpi.currentValue < min
              ? min - kpi.currentValue
              : kpi.currentValue - max;
          achievement =
              (100 -
              (distance /
                      (kpi.targetValue.abs() == 0
                          ? 1
                          : kpi.targetValue.abs())) *
                  100);
        }
    }
    achievement = achievement.clamp(0, 120).toDouble();
    final status = achievement >= 105
        ? AtlasKpiStatus.excellent
        : achievement >= 95
        ? AtlasKpiStatus.onTarget
        : achievement >= 80
        ? AtlasKpiStatus.attention
        : AtlasKpiStatus.critical;
    return AtlasKpiEvaluation(
      kpi: kpi,
      status: status,
      achievement: achievement,
    );
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
