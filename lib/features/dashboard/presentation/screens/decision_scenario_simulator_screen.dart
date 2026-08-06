import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_scenario_simulator.dart';

class DecisionScenarioSimulatorScreen extends StatefulWidget {
  const DecisionScenarioSimulatorScreen({
    required this.data,
    required this.onOpenActions,
    super.key,
  });

  final ExecutiveDecisionData data;
  final VoidCallback onOpenActions;

  @override
  State<DecisionScenarioSimulatorScreen> createState() {
    return _DecisionScenarioSimulatorScreenState();
  }
}

class _DecisionScenarioSimulatorScreenState
    extends State<DecisionScenarioSimulatorScreen> {
  final DecisionScenarioSimulator simulator = const DecisionScenarioSimulator();

  final Set<String> selectedActionIds = <String>{};

  late DecisionScenarioResult result;
  late List<DecisionScenarioCombination> bestCombinations;

  @override
  void initState() {
    super.initState();

    result = simulator.simulate(
      currentData: widget.data,
      completedActionIds: selectedActionIds,
    );

    bestCombinations = simulator.findBestCombinations(
      currentData: widget.data,
      maximumActions: 5,
      resultLimit: 8,
    );
  }

  void updateScenario() {
    setState(() {
      result = simulator.simulate(
        currentData: widget.data,
        completedActionIds: selectedActionIds,
      );
    });
  }

  void toggleAction(ExecutivePriorityAction action, bool selected) {
    if (selected) {
      selectedActionIds.add(action.actionId);
    } else {
      selectedActionIds.remove(action.actionId);
    }

    updateScenario();
  }

  void clearSelection() {
    selectedActionIds.clear();
    updateScenario();
  }

  void selectTopActions(int count) {
    selectedActionIds
      ..clear()
      ..addAll(
        widget.data.priorityActions
            .take(count)
            .map((action) => action.actionId),
      );

    updateScenario();
  }

  void applyCombination(DecisionScenarioCombination combination) {
    selectedActionIds
      ..clear()
      ..addAll(combination.actionIds);

    updateScenario();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Combinação aplicada ao simulador.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Simulador de Cenários',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Limpar seleção',
            onPressed: selectedActionIds.isEmpty ? null : clearSelection,
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: 'Abrir ações gerenciais',
            onPressed: widget.onOpenActions,
            icon: const Icon(Icons.assignment_turned_in_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScenarioSimulatorHero(
                      result: result,
                      selectedCount: selectedActionIds.length,
                      onSelectTopThree: () {
                        selectTopActions(3);
                      },
                      onSelectTopFive: () {
                        selectTopActions(5);
                      },
                      onClear: clearSelection,
                    ),
                    const SizedBox(height: 24),
                    ScenarioComparisonGrid(result: result),
                    const SizedBox(height: 28),
                    const ScenarioSectionTitle(
                      title: 'Selecione as ações',
                      subtitle:
                          'Marque as ações que deseja considerar como concluídas no cenário simulado.',
                    ),
                    const SizedBox(height: 14),
                    ScenarioActionSelectionCard(
                      actions: widget.data.priorityActions,
                      selectedActionIds: selectedActionIds,
                      onChanged: toggleAction,
                    ),
                    const SizedBox(height: 28),
                    const ScenarioSectionTitle(
                      title: 'Resultado da simulação',
                      subtitle:
                          'Projeção calculada sem alterar os dados reais do aplicativo.',
                    ),
                    const SizedBox(height: 14),
                    ScenarioResultCard(result: result),
                    const SizedBox(height: 28),
                    const ScenarioSectionTitle(
                      title: 'Melhores combinações',
                      subtitle:
                          'Combinações com maior ganho estimado em relação ao número de ações.',
                    ),
                    const SizedBox(height: 14),
                    ScenarioCombinationList(
                      combinations: bestCombinations,
                      onApply: applyCombination,
                    ),
                    const SizedBox(height: 34),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScenarioSimulatorHero extends StatelessWidget {
  const ScenarioSimulatorHero({
    required this.result,
    required this.selectedCount,
    required this.onSelectTopThree,
    required this.onSelectTopFive,
    required this.onClear,
    super.key,
  });

  final DecisionScenarioResult result;
  final int selectedCount;
  final VoidCallback onSelectTopThree;
  final VoidCallback onSelectTopFive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = scenarioLevelColor(result.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF455A64)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, color: Colors.white, size: 31),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Simule antes de decidir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const Text(
                'Selecione ações e visualize como a operação pode mudar antes de alterar qualquer dado real.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  ScenarioHeroChip(
                    label: 'Selecionadas',
                    value: selectedCount.toString(),
                    color: color,
                  ),
                  ScenarioHeroChip(
                    label: 'Ganho no índice',
                    value:
                        '+${formatScenarioNumber(result.performanceIndexGain)}',
                    color: const Color(0xFFC8A951),
                  ),
                  ScenarioHeroChip(
                    label: 'Redução de risco',
                    value: formatScenarioNumber(result.riskReduction),
                    color: const Color(0xFF81C784),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onSelectTopThree,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: const Icon(Icons.filter_3_outlined),
                    label: const Text('Simular 3 principais'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSelectTopFive,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: const Icon(Icons.filter_5_outlined),
                    label: const Text('Simular 5 principais'),
                  ),
                  TextButton.icon(
                    onPressed: selectedCount == 0 ? null : onClear,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Limpar'),
                  ),
                ],
              ),
            ],
          );

          final scorePanel = ScenarioProjectedScorePanel(
            result: result,
            color: color,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 22), scorePanel],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 26),
              scorePanel,
            ],
          );
        },
      ),
    );
  }
}

class ScenarioHeroChip extends StatelessWidget {
  const ScenarioHeroChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ScenarioProjectedScorePanel extends StatelessWidget {
  const ScenarioProjectedScorePanel({
    required this.result,
    required this.color,
    super.key,
  });

  final DecisionScenarioResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score projetado',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.projectedConsultantScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 37,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '/100',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (result.projectedConsultantScore / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '+${formatScenarioNumber(result.consultantScoreGain)} pontos no score',
            style: const TextStyle(
              color: Color(0xFFC8A951),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ScenarioComparisonGrid extends StatelessWidget {
  const ScenarioComparisonGrid({required this.result, super.key});

  final DecisionScenarioResult result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ScenarioComparisonCard(
              width: width,
              title: 'Score do consultor',
              current: result.currentConsultantScore,
              projected: result.projectedConsultantScore,
              suffix: '',
              icon: Icons.person_search_outlined,
            ),
            ScenarioComparisonCard(
              width: width,
              title: 'Índice de desempenho',
              current: result.currentPerformanceIndex,
              projected: result.projectedPerformanceIndex,
              suffix: '',
              icon: Icons.insights_outlined,
            ),
            ScenarioComparisonCard(
              width: width,
              title: 'Risco médio',
              current: result.currentAverageRisk,
              projected: result.projectedAverageRisk,
              suffix: '',
              lowerIsBetter: true,
              icon: Icons.shield_outlined,
            ),
            ScenarioComparisonCard(
              width: width,
              title: 'Prioridades críticas',
              current: result.currentCriticalCount.toDouble(),
              projected: result.projectedCriticalCount.toDouble(),
              suffix: '',
              lowerIsBetter: true,
              decimals: 0,
              icon: Icons.priority_high,
            ),
          ],
        );
      },
    );
  }
}

class ScenarioComparisonCard extends StatelessWidget {
  const ScenarioComparisonCard({
    required this.width,
    required this.title,
    required this.current,
    required this.projected,
    required this.suffix,
    required this.icon,
    this.lowerIsBetter = false,
    this.decimals = 1,
    super.key,
  });

  final double width;
  final String title;
  final double current;
  final double projected;
  final String suffix;
  final IconData icon;
  final bool lowerIsBetter;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final difference = projected - current;

    final improved = lowerIsBetter ? difference < 0 : difference > 0;

    final color = difference == 0
        ? const Color(0xFF1565C0)
        : improved
        ? const Color(0xFF1B5E20)
        : const Color(0xFFC62828);

    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ScenarioMetricValue(
                      label: 'Atual',
                      value:
                          '${current.toStringAsFixed(decimals).replaceAll('.', ',')}$suffix',
                      color: Colors.black54,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.black38,
                    size: 20,
                  ),
                  Expanded(
                    child: ScenarioMetricValue(
                      label: 'Projetado',
                      value:
                          '${projected.toStringAsFixed(decimals).replaceAll('.', ',')}$suffix',
                      color: color,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScenarioMetricValue extends StatelessWidget {
  const ScenarioMetricValue({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black45, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ScenarioSectionTitle extends StatelessWidget {
  const ScenarioSectionTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class ScenarioActionSelectionCard extends StatelessWidget {
  const ScenarioActionSelectionCard({
    required this.actions,
    required this.selectedActionIds,
    required this.onChanged,
    super.key,
  });

  final List<ExecutivePriorityAction> actions;
  final Set<String> selectedActionIds;

  final void Function(ExecutivePriorityAction action, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text('Nenhuma ação está disponível para simulação.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: List.generate(actions.length, (index) {
          final action = actions[index];
          final selected = selectedActionIds.contains(action.actionId);

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              CheckboxListTile(
                value: selected,
                onChanged: (value) {
                  onChanged(action, value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 7,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ScenarioLevelBadge(level: action.priorityLevel),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${action.farmName} · '
                    '${action.responsible} · '
                    'Impacto ${formatScenarioNumber(action.estimatedImpact)}',
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class ScenarioResultCard extends StatelessWidget {
  const ScenarioResultCard({required this.result, super.key});

  final DecisionScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final color = scenarioLevelColor(result.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: color, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Recomendação do cenário',
                    style: TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ScenarioLevelBadge(level: result.level),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              result.recommendation,
              style: const TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ScenarioResultChip(
                  label: 'Críticas removidas',
                  value: result.removedCriticalCount.toString(),
                  color: const Color(0xFFC62828),
                ),
                ScenarioResultChip(
                  label: 'Atrasos evitados',
                  value: result.removedPredictedDelayCount.toString(),
                  color: const Color(0xFFEF6C00),
                ),
                ScenarioResultChip(
                  label: 'Impacto capturado',
                  value: formatScenarioNumber(result.capturedImpact),
                  color: const Color(0xFF1B5E20),
                ),
                ScenarioResultChip(
                  label: 'Oportunidade capturada',
                  value: formatScenarioNumber(result.capturedOpportunity),
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScenarioResultChip extends StatelessWidget {
  const ScenarioResultChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ScenarioCombinationList extends StatelessWidget {
  const ScenarioCombinationList({
    required this.combinations,
    required this.onApply,
    super.key,
  });

  final List<DecisionScenarioCombination> combinations;

  final void Function(DecisionScenarioCombination combination) onApply;

  @override
  Widget build(BuildContext context) {
    if (combinations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text('Não há combinações suficientes para análise.'),
        ),
      );
    }

    return Column(
      children: List.generate(combinations.length, (index) {
        final item = combinations[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == combinations.length - 1 ? 0 : 12,
          ),
          child: ScenarioCombinationCard(
            position: index + 1,
            combination: item,
            onApply: () {
              onApply(item);
            },
          ),
        );
      }),
    );
  }
}

class ScenarioCombinationCard extends StatelessWidget {
  const ScenarioCombinationCard({
    required this.position,
    required this.combination,
    required this.onApply,
    super.key,
  });

  final int position;
  final DecisionScenarioCombination combination;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final color = combination.efficiencyScore >= 70
        ? const Color(0xFF1B5E20)
        : combination.efficiencyScore >= 45
        ? const Color(0xFF1565C0)
        : const Color(0xFFEF6C00);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            final information = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$positionº',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        combination.actionTitles.join(' + '),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ScenarioResultChip(
                            label: 'Eficiência',
                            value:
                                '${formatScenarioNumber(combination.efficiencyScore)}%',
                            color: color,
                          ),
                          ScenarioResultChip(
                            label: 'Ganho no índice',
                            value:
                                '+${formatScenarioNumber(combination.performanceIndexGain)}',
                            color: const Color(0xFF1B5E20),
                          ),
                          ScenarioResultChip(
                            label: 'Redução de risco',
                            value: formatScenarioNumber(
                              combination.riskReduction,
                            ),
                            color: const Color(0xFF1565C0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final button = FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Simular combinação'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [information, const SizedBox(height: 15), button],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 18),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class ScenarioLevelBadge extends StatelessWidget {
  const ScenarioLevelBadge({required this.level, super.key});

  final ExecutiveDecisionLevel level;

  @override
  Widget build(BuildContext context) {
    final color = scenarioLevelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        scenarioLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color scenarioLevelColor(ExecutiveDecisionLevel level) {
  switch (level) {
    case ExecutiveDecisionLevel.excellent:
      return const Color(0xFF1B5E20);
    case ExecutiveDecisionLevel.good:
      return const Color(0xFF2E7D32);
    case ExecutiveDecisionLevel.normal:
      return const Color(0xFF1565C0);
    case ExecutiveDecisionLevel.attention:
      return const Color(0xFFEF6C00);
    case ExecutiveDecisionLevel.critical:
      return const Color(0xFFC62828);
  }
}

String scenarioLevelLabel(ExecutiveDecisionLevel level) {
  switch (level) {
    case ExecutiveDecisionLevel.excellent:
      return 'Excelente';
    case ExecutiveDecisionLevel.good:
      return 'Bom';
    case ExecutiveDecisionLevel.normal:
      return 'Normal';
    case ExecutiveDecisionLevel.attention:
      return 'Atenção';
    case ExecutiveDecisionLevel.critical:
      return 'Crítico';
  }
}

String formatScenarioNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
