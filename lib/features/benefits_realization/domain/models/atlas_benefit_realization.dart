import 'package:projeto_atlas/features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasBenefitRealization {
  const AtlasBenefitRealization({
    required this.id,
    required this.strategyPlanId,
    required this.farmId,
    required this.farmName,
    required this.strategyTitle,
    required this.area,
    required this.measuredAt,
    required this.plannedBudget,
    required this.actualCost,
    required this.plannedNetGain,
    required this.actualNetGain,
    required this.plannedRoi,
    required this.actualRoi,
    required this.plannedProgress,
    required this.actualProgress,
    required this.plannedIndicator,
    required this.actualIndicator,
    required this.confidence,
    required this.risk,
    required this.status,
    required this.findings,
    required this.correctiveActions,
  });

  final String id;
  final String strategyPlanId;
  final String farmId;
  final String farmName;
  final String strategyTitle;
  final AtlasFarmAuditArea area;
  final DateTime measuredAt;
  final double plannedBudget;
  final double actualCost;
  final double plannedNetGain;
  final double actualNetGain;
  final double plannedRoi;
  final double actualRoi;
  final double plannedProgress;
  final double actualProgress;
  final double plannedIndicator;
  final double actualIndicator;
  final double confidence;
  final AtlasDecisionRisk risk;
  final AtlasBenefitRealizationStatus status;
  final List<String> findings;
  final List<String> correctiveActions;

  double get budgetVariance {
    return actualCost - plannedBudget;
  }

  double get gainVariance {
    return actualNetGain - plannedNetGain;
  }

  double get roiVariance {
    return actualRoi - plannedRoi;
  }

  double get progressVariance {
    return actualProgress - plannedProgress;
  }

  double get indicatorVariance {
    return actualIndicator - plannedIndicator;
  }

  double get benefitAchievement {
    if (plannedNetGain <= 0) {
      return actualNetGain > 0 ? 100 : 0;
    }

    return (actualNetGain / plannedNetGain * 100)
        .clamp(-100.0, 200.0)
        .toDouble();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'strategyPlanId': strategyPlanId,
      'farmId': farmId,
      'farmName': farmName,
      'strategyTitle': strategyTitle,
      'area': area.name,
      'measuredAt': measuredAt.toIso8601String(),
      'plannedBudget': plannedBudget,
      'actualCost': actualCost,
      'plannedNetGain': plannedNetGain,
      'actualNetGain': actualNetGain,
      'plannedRoi': plannedRoi,
      'actualRoi': actualRoi,
      'plannedProgress': plannedProgress,
      'actualProgress': actualProgress,
      'plannedIndicator': plannedIndicator,
      'actualIndicator': actualIndicator,
      'confidence': confidence,
      'risk': risk.name,
      'status': status.name,
      'findings': findings,
      'correctiveActions': correctiveActions,
    };
  }

  factory AtlasBenefitRealization.fromJson(Map<String, dynamic> json) {
    return AtlasBenefitRealization(
      id: json['id'] as String? ?? '',
      strategyPlanId: json['strategyPlanId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Fazenda',
      strategyTitle: json['strategyTitle'] as String? ?? 'Estratégia',
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      measuredAt:
          DateTime.tryParse(json['measuredAt'] as String? ?? '') ??
          DateTime.now(),
      plannedBudget: (json['plannedBudget'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actualCost'] as num?)?.toDouble() ?? 0,
      plannedNetGain: (json['plannedNetGain'] as num?)?.toDouble() ?? 0,
      actualNetGain: (json['actualNetGain'] as num?)?.toDouble() ?? 0,
      plannedRoi: (json['plannedRoi'] as num?)?.toDouble() ?? 0,
      actualRoi: (json['actualRoi'] as num?)?.toDouble() ?? 0,
      plannedProgress: (json['plannedProgress'] as num?)?.toDouble() ?? 0,
      actualProgress: (json['actualProgress'] as num?)?.toDouble() ?? 0,
      plannedIndicator: (json['plannedIndicator'] as num?)?.toDouble() ?? 0,
      actualIndicator: (json['actualIndicator'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      risk: AtlasDecisionRisk.values.firstWhere(
        (item) => item.name == json['risk'],
        orElse: () => AtlasDecisionRisk.moderate,
      ),
      status: AtlasBenefitRealizationStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => AtlasBenefitRealizationStatus.attention,
      ),
      findings: (json['findings'] as List? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      correctiveActions:
          (json['correctiveActions'] as List? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
    );
  }
}

class AtlasBenefitPortfolio {
  const AtlasBenefitPortfolio({required this.items});

  final List<AtlasBenefitRealization> items;

  int get totalStrategies => items.length;

  int get onTrack {
    return items
        .where((item) => item.status == AtlasBenefitRealizationStatus.onTrack)
        .length;
  }

  int get critical {
    return items
        .where((item) => item.status == AtlasBenefitRealizationStatus.critical)
        .length;
  }

  double get plannedGain {
    return items.fold<double>(0, (sum, item) => sum + item.plannedNetGain);
  }

  double get actualGain {
    return items.fold<double>(0, (sum, item) => sum + item.actualNetGain);
  }

  double get achievement {
    if (plannedGain <= 0) {
      return actualGain > 0 ? 100 : 0;
    }

    return (actualGain / plannedGain * 100).clamp(-100.0, 200.0).toDouble();
  }
}

enum AtlasBenefitRealizationStatus { onTrack, attention, offTrack, critical }

String atlasBenefitRealizationStatusLabel(
  AtlasBenefitRealizationStatus status,
) {
  switch (status) {
    case AtlasBenefitRealizationStatus.onTrack:
      return 'No caminho certo';
    case AtlasBenefitRealizationStatus.attention:
      return 'Atenção';
    case AtlasBenefitRealizationStatus.offTrack:
      return 'Fora da rota';
    case AtlasBenefitRealizationStatus.critical:
      return 'Crítico';
  }
}
