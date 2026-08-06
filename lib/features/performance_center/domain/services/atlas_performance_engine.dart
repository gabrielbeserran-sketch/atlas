import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/performance_center/domain/models/atlas_performance_snapshot.dart';

class AtlasPerformanceEngine {
  const AtlasPerformanceEngine();

  AtlasPerformanceSnapshot generate({
    required AtlasActionPlan plan,
    required AtlasFarmAudit currentAudit,
    AtlasFarmAudit? previousAudit,
  }) {
    final completed = plan.missions.where((mission) => mission.status == AtlasMissionStatus.completed).toList();
    final completedOnTime = completed.where((mission) {
      final completedAt = mission.completedAt;
      return completedAt != null && !completedAt.isAfter(mission.dueDate);
    }).length;

    final onTimeRate = completed.isEmpty ? 0.0 : completedOnTime / completed.length * 100;
    final planProgress = plan.progressPercent;
    final auditEvolution = previousAudit == null ? 0.0 : currentAudit.overallIndex - previousAudit.overallIndex;
    final overduePenalty = plan.totalMissions == 0 ? 0.0 : plan.overdueMissions / plan.totalMissions * 25;
    final impactRate = plan.expectedImpact <= 0 ? 0.0 : (plan.realizedImpact / plan.expectedImpact * 100).clamp(0.0, 100.0).toDouble();

    final executionScore = (
      planProgress * 0.45 +
      onTimeRate * 0.20 +
      impactRate * 0.20 +
      (50 + auditEvolution * 5).clamp(0.0, 100.0) * 0.15 -
      overduePenalty
    ).clamp(0.0, 100.0).toDouble();

    final kpis = currentAudit.areaResults.map((area) {
      final previous = previousAudit?.areaResults.where((item) => item.area == area.area).firstOrNull;
      final before = previous?.score ?? (area.score - _missionGain(plan, area.area)).clamp(0.0, 100.0).toDouble();
      final variation = area.score - before;
      final trend = variation > 1.5
          ? AtlasPerformanceTrend.improving
          : variation < -1.5
              ? AtlasPerformanceTrend.worsening
              : AtlasPerformanceTrend.stable;
      return AtlasPerformanceKpi(
        id: 'performance_${area.area.name}',
        title: atlasFarmAuditAreaLabel(area.area),
        area: area.area,
        unit: 'pontos',
        beforeValue: before,
        currentValue: area.score,
        targetValue: 85,
        trend: trend,
        interpretation: _interpretation(area.area, trend, variation),
      );
    }).toList()
      ..sort((a, b) => a.currentValue.compareTo(b.currentValue));

    final alerts = <AtlasPerformanceAlert>[];
    if (plan.overdueMissions > 0) {
      alerts.add(AtlasPerformanceAlert(
        id: 'overdue_missions',
        title: 'Missões atrasadas',
        message: '${plan.overdueMissions} missão(ões) ultrapassaram o prazo e precisam de revisão imediata.',
        severity: plan.overdueMissions >= 3 ? AtlasPerformanceAlertSeverity.critical : AtlasPerformanceAlertSeverity.high,
        area: AtlasFarmAuditArea.operational,
      ));
    }
    for (final kpi in kpis.where((item) => item.trend == AtlasPerformanceTrend.worsening || item.currentValue < 55).take(5)) {
      alerts.add(AtlasPerformanceAlert(
        id: 'kpi_${kpi.area.name}',
        title: 'Atenção em ${kpi.title}',
        message: '${kpi.title} está em ${kpi.currentValue.toStringAsFixed(1)} pontos e apresenta tendência ${atlasPerformanceTrendLabel(kpi.trend).toLowerCase()}.',
        severity: kpi.currentValue < 45 ? AtlasPerformanceAlertSeverity.critical : AtlasPerformanceAlertSeverity.high,
        area: kpi.area,
      ));
    }
    if (auditEvolution < -2) {
      alerts.add(AtlasPerformanceAlert(
        id: 'audit_regression',
        title: 'Redução do índice da fazenda',
        message: 'O Atlas Farm Audit Index caiu ${auditEvolution.abs().toStringAsFixed(1)} pontos desde a auditoria anterior.',
        severity: AtlasPerformanceAlertSeverity.critical,
        area: AtlasFarmAuditArea.operational,
      ));
    }
    if (alerts.isEmpty) {
      alerts.add(const AtlasPerformanceAlert(
        id: 'stable_operation',
        title: 'Operação sob controle',
        message: 'Nenhum alerta crítico foi identificado no ciclo atual de execução.',
        severity: AtlasPerformanceAlertSeverity.information,
        area: AtlasFarmAuditArea.operational,
      ));
    }

    return AtlasPerformanceSnapshot(
      farmId: plan.farmId,
      farmName: plan.farmName,
      generatedAt: DateTime.now(),
      executionScore: executionScore,
      planProgress: planProgress,
      onTimeRate: onTimeRate,
      realizedImpact: plan.realizedImpact,
      expectedImpact: plan.expectedImpact,
      kpis: kpis,
      alerts: alerts,
    );
  }

  double _missionGain(AtlasActionPlan plan, AtlasFarmAuditArea area) {
    final related = plan.missions.where((mission) => mission.area == area);
    return related.fold<double>(0, (sum, mission) {
      switch (mission.status) {
        case AtlasMissionStatus.completed:
          return sum + 5;
        case AtlasMissionStatus.inProgress:
          return sum + 2;
        case AtlasMissionStatus.pending:
        case AtlasMissionStatus.cancelled:
          return sum;
      }
    });
  }

  String _interpretation(AtlasFarmAuditArea area, AtlasPerformanceTrend trend, double variation) {
    final label = atlasFarmAuditAreaLabel(area);
    switch (trend) {
      case AtlasPerformanceTrend.improving:
        return '$label avançou ${variation.abs().toStringAsFixed(1)} pontos em relação à referência anterior.';
      case AtlasPerformanceTrend.stable:
        return '$label permaneceu estável, sem variação relevante no período.';
      case AtlasPerformanceTrend.worsening:
        return '$label recuou ${variation.abs().toStringAsFixed(1)} pontos e deve ser reavaliado.';
    }
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
