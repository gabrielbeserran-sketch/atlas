import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/executive_alerts/data/services/atlas_executive_alert_loader_service.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';

class AtlasExecutiveKpiLoaderService {
  AtlasExecutiveKpiLoaderService({
    AtlasExecutiveAlertLoaderService? farmDataLoader,
  }) : farmDataLoader = farmDataLoader ?? AtlasExecutiveAlertLoaderService();

  final AtlasExecutiveAlertLoaderService farmDataLoader;

  Future<AtlasExecutiveKpiLoadResult> load() async {
    final loaded = await farmDataLoader.load();

    final farms = loaded.inputs.map((input) {
      final intelligence = input.intelligence;

      final diagnostic = input.diagnostic;

      final trackedActions = input.trackedActions;

      final actionProgress = _actionProgress(trackedActions);

      return AtlasExecutiveFarmKpiInput(
        farmName: input.farmName,
        kpis: [
          AtlasExecutiveKpiInput(
            id: 'farm_score',
            title: 'Score geral da fazenda',
            description: 'Desempenho consolidado da propriedade.',
            category: AtlasExecutiveKpiCategory.intelligence,
            value: intelligence.score,
            unit: 'pontos',
            targetValue: 85,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.5,
            sourceLabel: 'Inteligência da Fazenda',
          ),
          AtlasExecutiveKpiInput(
            id: 'diagnostic_score',
            title: 'Score do diagnóstico',
            description: 'Pontuação calculada pelo Diagnóstico Inteligente.',
            category: AtlasExecutiveKpiCategory.intelligence,
            value: diagnostic.score,
            unit: 'pontos',
            targetValue: 85,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.5,
            sourceLabel: 'Diagnóstico Inteligente',
          ),
          AtlasExecutiveKpiInput(
            id: 'finance_score',
            title: 'Qualidade financeira',
            description: intelligence.finance.analysis,
            category: AtlasExecutiveKpiCategory.finance,
            value: intelligence.finance.score,
            unit: 'pontos',
            targetValue: 85,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.4,
            sourceLabel: 'Financeiro',
          ),
          AtlasExecutiveKpiInput(
            id: 'finance_margin',
            title: 'Margem financeira',
            description: 'Percentual das receitas preservado após as despesas.',
            category: AtlasExecutiveKpiCategory.finance,
            value: intelligence.finance.margin,
            unit: '%',
            targetValue: 20,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.3,
            sourceLabel: 'Financeiro',
          ),
          AtlasExecutiveKpiInput(
            id: 'herd_score',
            title: 'Qualidade do rebanho',
            description: intelligence.herd.analysis,
            category: AtlasExecutiveKpiCategory.production,
            value: intelligence.herd.score,
            unit: 'pontos',
            targetValue: 85,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.2,
            sourceLabel: 'Rebanho',
          ),
          AtlasExecutiveKpiInput(
            id: 'average_weight',
            title: 'Peso médio do rebanho',
            description: 'Peso médio dos animais cadastrados na propriedade.',
            category: AtlasExecutiveKpiCategory.production,
            value: intelligence.herd.averageWeight,
            unit: 'kg',
            targetValue: 450,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1,
            sourceLabel: 'Rebanho',
          ),
          AtlasExecutiveKpiInput(
            id: 'registration_coverage',
            title: 'Cobertura cadastral',
            description:
                'Percentual do rebanho declarado que está corretamente cadastrado.',
            category: AtlasExecutiveKpiCategory.management,
            value: intelligence.herd.registrationCoverage,
            unit: '%',
            targetValue: 95,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.2,
            sourceLabel: 'Rebanho',
          ),
          AtlasExecutiveKpiInput(
            id: 'paddock_score',
            title: 'Desempenho dos piquetes',
            description: intelligence.paddocks.analysis,
            category: AtlasExecutiveKpiCategory.production,
            value: intelligence.paddocks.score,
            unit: 'pontos',
            targetValue: 85,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.1,
            sourceLabel: 'Piquetes',
          ),
          AtlasExecutiveKpiInput(
            id: 'inventory_score',
            title: 'Controle do estoque',
            description: intelligence.inventory.analysis,
            category: AtlasExecutiveKpiCategory.health,
            value: intelligence.inventory.score,
            unit: 'pontos',
            targetValue: 90,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.1,
            sourceLabel: 'Estoque',
          ),
          AtlasExecutiveKpiInput(
            id: 'inventory_alert_rate',
            title: 'Taxa de alertas do estoque',
            description:
                'Percentual de itens com estoque baixo, vencido ou próximo do vencimento.',
            category: AtlasExecutiveKpiCategory.health,
            value: intelligence.inventory.alertRate,
            unit: '%',
            targetValue: 5,
            direction: AtlasExecutiveKpiDirection.lowerIsBetter,
            weight: 1.2,
            sourceLabel: 'Estoque',
          ),
          AtlasExecutiveKpiInput(
            id: 'agenda_completion_rate',
            title: 'Execução da agenda',
            description: 'Percentual de tarefas concluídas na propriedade.',
            category: AtlasExecutiveKpiCategory.management,
            value: intelligence.agenda.completionRate,
            unit: '%',
            targetValue: 90,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.2,
            sourceLabel: 'Agenda',
          ),
          AtlasExecutiveKpiInput(
            id: 'agenda_overdue_rate',
            title: 'Taxa de tarefas atrasadas',
            description:
                'Percentual de atividades da agenda que ultrapassaram o prazo.',
            category: AtlasExecutiveKpiCategory.management,
            value: intelligence.agenda.overdueRate,
            unit: '%',
            targetValue: 5,
            direction: AtlasExecutiveKpiDirection.lowerIsBetter,
            weight: 1.3,
            sourceLabel: 'Agenda',
          ),
          AtlasExecutiveKpiInput(
            id: 'consulting_execution',
            title: 'Execução das ações da consultoria',
            description:
                'Percentual das recomendações acompanhadas que foram concluídas.',
            category: AtlasExecutiveKpiCategory.management,
            value: actionProgress.completionPercent,
            unit: '%',
            targetValue: 90,
            direction: AtlasExecutiveKpiDirection.higherIsBetter,
            weight: 1.4,
            sourceLabel: 'Ações da Consultoria',
          ),
          AtlasExecutiveKpiInput(
            id: 'consulting_overdue_actions',
            title: 'Ações atrasadas da consultoria',
            description:
                'Quantidade de recomendações abertas com prazo vencido.',
            category: AtlasExecutiveKpiCategory.management,
            value: actionProgress.overdue.toDouble(),
            unit: 'ações',
            targetValue: 1,
            direction: AtlasExecutiveKpiDirection.lowerIsBetter,
            weight: 1.4,
            sourceLabel: 'Ações da Consultoria',
          ),
          AtlasExecutiveKpiInput(
            id: 'critical_risks',
            title: 'Riscos críticos',
            description:
                'Quantidade de riscos críticos identificados pelo diagnóstico.',
            category: AtlasExecutiveKpiCategory.intelligence,
            value: diagnostic.risks
                .where((item) {
                  return item.level.name == 'critical';
                })
                .length
                .toDouble(),
            unit: 'riscos',
            targetValue: 1,
            direction: AtlasExecutiveKpiDirection.lowerIsBetter,
            weight: 1.5,
            sourceLabel: 'Diagnóstico Inteligente',
          ),
        ],
      );
    }).toList();

    return AtlasExecutiveKpiLoadResult(farms: farms);
  }

  _KpiActionProgress _actionProgress(List<AtlasAiTrackedAction> actions) {
    final cancelled = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.cancelled;
    }).length;

    final completed = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.completed;
    }).length;

    final overdue = actions.where((item) {
      return item.isOverdue;
    }).length;

    final validTotal = actions.length - cancelled;

    final completionPercent = validTotal <= 0
        ? 0.0
        : completed / validTotal * 100;

    return _KpiActionProgress(
      completionPercent: completionPercent.clamp(0.0, 100.0).toDouble(),
      overdue: overdue,
    );
  }
}

class AtlasExecutiveKpiLoadResult {
  const AtlasExecutiveKpiLoadResult({required this.farms});

  final List<AtlasExecutiveFarmKpiInput> farms;
}

class _KpiActionProgress {
  const _KpiActionProgress({
    required this.completionPercent,
    required this.overdue,
  });

  final double completionPercent;
  final int overdue;
}
