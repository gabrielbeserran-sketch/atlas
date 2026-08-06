import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasBenefitsRealizationEngine {
  const AtlasBenefitsRealizationEngine();

  AtlasBenefitRealization evaluate({
    required AtlasStrategyExecutionPlan plan,
    required double actualCost,
    required double actualNetGain,
    required double actualIndicator,
  }) {
    final elapsedDays = DateTime.now()
        .difference(plan.startDate)
        .inDays
        .clamp(0, 100000);

    final totalDays = plan.targetDate
        .difference(plan.startDate)
        .inDays
        .clamp(1, 100000);

    final plannedProgress =
        (elapsedDays / totalDays * 100)
            .clamp(0.0, 100.0)
            .toDouble();

    final actualProgress = plan.progressPercent;

    final actualRoi = actualCost <= 0
        ? actualNetGain > 0
            ? 100.0
            : 0.0
        : actualNetGain / actualCost * 100;

    final plannedIndicator = 85.0;

    final status = _status(
      plannedBudget: plan.budget,
      actualCost: actualCost,
      plannedNetGain: plan.expectedNetGain,
      actualNetGain: actualNetGain,
      plannedProgress: plannedProgress,
      actualProgress: actualProgress,
      plannedIndicator: plannedIndicator,
      actualIndicator: actualIndicator,
    );

    final findings = _findings(
      plan: plan,
      actualCost: actualCost,
      actualNetGain: actualNetGain,
      actualRoi: actualRoi,
      plannedProgress: plannedProgress,
      actualIndicator: actualIndicator,
    );

    final correctiveActions = _actions(
      status: status,
      actualCost: actualCost,
      plannedBudget: plan.budget,
      actualProgress: actualProgress,
      plannedProgress: plannedProgress,
      actualNetGain: actualNetGain,
      plannedNetGain: plan.expectedNetGain,
    );

    return AtlasBenefitRealization(
      id: 'benefit_${plan.id}',
      strategyPlanId: plan.id,
      farmId: plan.farmId,
      farmName: plan.farmName,
      strategyTitle: plan.title,
      area: plan.area,
      measuredAt: DateTime.now(),
      plannedBudget: plan.budget,
      actualCost: actualCost,
      plannedNetGain: plan.expectedNetGain,
      actualNetGain: actualNetGain,
      plannedRoi: plan.expectedRoi,
      actualRoi: actualRoi,
      plannedProgress: plannedProgress,
      actualProgress: actualProgress,
      plannedIndicator: plannedIndicator,
      actualIndicator: actualIndicator,
      confidence: plan.confidence,
      risk: plan.risk,
      status: status,
      findings: findings,
      correctiveActions: correctiveActions,
    );
  }

  AtlasBenefitRealizationStatus _status({
    required double plannedBudget,
    required double actualCost,
    required double plannedNetGain,
    required double actualNetGain,
    required double plannedProgress,
    required double actualProgress,
    required double plannedIndicator,
    required double actualIndicator,
  }) {
    final budgetRatio = plannedBudget <= 0
        ? 1.0
        : actualCost / plannedBudget;

    final gainRatio = plannedNetGain <= 0
        ? actualNetGain > 0
            ? 1.0
            : 0.0
        : actualNetGain / plannedNetGain;

    final progressGap = plannedProgress - actualProgress;
    final indicatorGap = plannedIndicator - actualIndicator;

    if (budgetRatio > 1.30 ||
        gainRatio < 0.30 ||
        progressGap > 35 ||
        indicatorGap > 35) {
      return AtlasBenefitRealizationStatus.critical;
    }

    if (budgetRatio > 1.15 ||
        gainRatio < 0.60 ||
        progressGap > 20 ||
        indicatorGap > 20) {
      return AtlasBenefitRealizationStatus.offTrack;
    }

    if (budgetRatio > 1.05 ||
        gainRatio < 0.85 ||
        progressGap > 10 ||
        indicatorGap > 10) {
      return AtlasBenefitRealizationStatus.attention;
    }

    return AtlasBenefitRealizationStatus.onTrack;
  }

  List<String> _findings({
    required AtlasStrategyExecutionPlan plan,
    required double actualCost,
    required double actualNetGain,
    required double actualRoi,
    required double plannedProgress,
    required double actualIndicator,
  }) {
    return <String>[
      if (actualCost > plan.budget)
        'O custo realizado ultrapassou o orçamento planejado.',
      if (actualCost <= plan.budget)
        'O custo permanece dentro do orçamento aprovado.',
      if (actualNetGain < plan.expectedNetGain)
        'O benefício econômico realizado ainda está abaixo da meta.',
      if (actualNetGain >= plan.expectedNetGain)
        'O benefício econômico atingiu ou superou a meta planejada.',
      if (plan.progressPercent < plannedProgress)
        'A execução está atrasada em relação ao cronograma.',
      if (plan.progressPercent >= plannedProgress)
        'O progresso está compatível com o cronograma.',
      'ROI realizado: ${actualRoi.toStringAsFixed(1)}%.',
      'Indicador atual informado: ${actualIndicator.toStringAsFixed(1)}.',
    ];
  }

  List<String> _actions({
    required AtlasBenefitRealizationStatus status,
    required double actualCost,
    required double plannedBudget,
    required double actualProgress,
    required double plannedProgress,
    required double actualNetGain,
    required double plannedNetGain,
  }) {
    final actions = <String>[];

    if (actualCost > plannedBudget) {
      actions.add(
        'Revisar imediatamente os itens que excederam o orçamento.',
      );
    }

    if (actualProgress < plannedProgress) {
      actions.add(
        'Reprogramar marcos atrasados e redefinir responsáveis.',
      );
    }

    if (actualNetGain < plannedNetGain) {
      actions.add(
        'Revalidar premissas de ganho, adesão ao protocolo e qualidade da execução.',
      );
    }

    switch (status) {
      case AtlasBenefitRealizationStatus.onTrack:
        actions.add(
          'Manter a execução e confirmar os resultados na próxima revisão.',
        );
      case AtlasBenefitRealizationStatus.attention:
        actions.add(
          'Executar uma revisão gerencial em até 15 dias.',
        );
      case AtlasBenefitRealizationStatus.offTrack:
        actions.add(
          'Abrir plano corretivo e revisar o próximo gate de decisão.',
        );
      case AtlasBenefitRealizationStatus.critical:
        actions.add(
          'Suspender novas expansões até concluir análise de causa e recuperação.',
        );
    }

    return actions;
  }
}
