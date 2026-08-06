import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/decision_scenario_simulator_screen.dart';

class ExecutiveDecisionCenterScreen extends StatelessWidget {
  const ExecutiveDecisionCenterScreen({
    required this.data,
    required this.onOpenActions,
    super.key,
  });

  final ExecutiveDecisionData data;
  final VoidCallback onOpenActions;

  void openScenarioSimulator(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return DecisionScenarioSimulatorScreen(
            data: data,
            onOpenActions: onOpenActions,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Central de Decisão Inteligente',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Simulador de Cenários',
            onPressed: () {
              openScenarioSimulator(context);
            },
            icon: const Icon(Icons.science_outlined),
          ),
          IconButton(
            tooltip: 'Abrir ações gerenciais',
            onPressed: onOpenActions,
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
                    DecisionAssistantHero(
                      message: data.executiveAssistant,
                      consultantScore: data.consultantScore,
                      onOpenActions: onOpenActions,
                    ),
                    const SizedBox(height: 24),
                    DecisionSummaryGrid(summary: data.summary),
                    const SizedBox(height: 24),
                    DecisionScenarioAccessCard(
                      data: data,
                      onOpen: () {
                        openScenarioSimulator(context);
                      },
                    ),
                    const SizedBox(height: 28),
                    const DecisionSectionTitle(
                      title: 'Prioridades do dia',
                      subtitle:
                          'Ações ordenadas por risco, urgência, oportunidade e impacto esperado.',
                    ),
                    const SizedBox(height: 14),
                    DecisionPriorityList(
                      actions: data.priorityActions.take(5).toList(),
                      onOpenActions: onOpenActions,
                    ),
                    const SizedBox(height: 28),
                    const DecisionSectionTitle(
                      title: 'Previsões inteligentes',
                      subtitle:
                          'Situações que podem ocorrer nos próximos dias com base nos sinais atuais.',
                    ),
                    const SizedBox(height: 14),
                    DecisionPredictionGrid(
                      predictions: data.predictions.take(8).toList(),
                    ),
                    const SizedBox(height: 28),
                    const DecisionSectionTitle(
                      title: 'Mapa de calor da operação',
                      subtitle:
                          'Visão consolidada de fazendas, responsáveis e categorias.',
                    ),
                    const SizedBox(height: 14),
                    DecisionHeatMapGrid(items: data.heatMapItems),
                    const SizedBox(height: 28),
                    const DecisionSectionTitle(
                      title: 'Rankings de risco',
                      subtitle:
                          'Grupos que concentram maior risco e oportunidade de melhoria.',
                    ),
                    const SizedBox(height: 14),
                    DecisionRankingGrid(
                      farmRanking: data.farmRiskRanking,
                      responsibleRanking: data.responsibleRiskRanking,
                      categoryRanking: data.categoryRiskRanking,
                    ),
                    const SizedBox(height: 28),
                    DecisionConsultantScoreDetails(score: data.consultantScore),
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

class DecisionScenarioAccessCard extends StatelessWidget {
  const DecisionScenarioAccessCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final ExecutiveDecisionData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final topActions = data.priorityActions.take(3).toList();

    final potentialGain = data.executiveAssistant.estimatedGain;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(21),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 29,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Simulador de Cenários',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teste o impacto da conclusão das ações antes de alterar os dados reais.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _DecisionScenarioChip(
                        text:
                            '${data.priorityActions.length} ações disponíveis',
                      ),
                      _DecisionScenarioChip(
                        text: '${data.summary.criticalActionCount} críticas',
                      ),
                      _DecisionScenarioChip(
                        text:
                            'Ganho potencial de ${potentialGain.toStringAsFixed(1).replaceAll('.', ',')} pontos',
                      ),
                    ],
                  ),
                  if (topActions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Primeiras ações: ${topActions.map((item) => item.title).join(' · ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              );

              final button = FilledButton.icon(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D47A1),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Abrir simulador',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), button],
                );
              }

              return Row(
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 22),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DecisionScenarioChip extends StatelessWidget {
  const _DecisionScenarioChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DecisionAssistantHero extends StatelessWidget {
  const DecisionAssistantHero({
    required this.message,
    required this.consultantScore,
    required this.onOpenActions,
    super.key,
  });

  final ExecutiveAssistantMessage message;
  final ExecutiveDecisionScore consultantScore;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(consultantScore.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF455A64)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 800;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.psychology_alt_outlined,
                      color: color,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.greeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message.headline,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              Text(
                message.message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              DecisionAssistantPriorityBox(
                title: 'Prioridade principal',
                text: message.mainPriority,
                color: const Color(0xFFC8A951),
              ),
              if (message.secondaryPriority.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                DecisionAssistantPriorityBox(
                  title: 'Prioridade secundária',
                  text: message.secondaryPriority,
                  color: Colors.white70,
                ),
              ],
              const SizedBox(height: 17),
              Text(
                message.callToAction,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpenActions,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC8A951),
                  foregroundColor: const Color(0xFF263238),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text(
                  'Abrir ações gerenciais',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );

          final scorePanel = DecisionConsultantScorePanel(
            score: consultantScore,
            estimatedGain: message.estimatedGain,
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
              const SizedBox(width: 28),
              scorePanel,
            ],
          );
        },
      ),
    );
  }
}

class DecisionAssistantPriorityBox extends StatelessWidget {
  const DecisionAssistantPriorityBox({
    required this.title,
    required this.text,
    required this.color,
    super.key,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class DecisionConsultantScorePanel extends StatelessWidget {
  const DecisionConsultantScorePanel({
    required this.score,
    required this.estimatedGain,
    super.key,
  });

  final ExecutiveDecisionScore score;
  final double estimatedGain;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(score.level);

    return Container(
      width: 225,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score.label,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Score do consultor',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.value.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
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
              minHeight: 11,
              value: (score.value / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Ganho estimado',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            '+${estimatedGain.toStringAsFixed(1).replaceAll('.', ',')} pontos',
            style: const TextStyle(
              color: Color(0xFFC8A951),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DecisionSummaryGrid extends StatelessWidget {
  const DecisionSummaryGrid({required this.summary, super.key});

  final ExecutiveDecisionSummary summary;

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
            DecisionSummaryCard(
              width: width,
              title: 'Ações críticas',
              value: summary.criticalActionCount.toString(),
              icon: Icons.priority_high,
              color: const Color(0xFFC62828),
            ),
            DecisionSummaryCard(
              width: width,
              title: 'Fazendas em risco',
              value: summary.highRiskFarmCount.toString(),
              icon: Icons.home_work_outlined,
              color: const Color(0xFFEF6C00),
            ),
            DecisionSummaryCard(
              width: width,
              title: 'Atrasos previstos',
              value: summary.predictedDelayCount.toString(),
              icon: Icons.schedule_outlined,
              color: const Color(0xFF6A1B9A),
            ),
            DecisionSummaryCard(
              width: width,
              title: 'Risco médio',
              value: summary.averageRiskScore
                  .toStringAsFixed(1)
                  .replaceAll('.', ','),
              icon: Icons.shield_outlined,
              color: const Color(0xFF1565C0),
            ),
          ],
        );
      },
    );
  }
}

class DecisionSummaryCard extends StatelessWidget {
  const DecisionSummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DecisionSectionTitle extends StatelessWidget {
  const DecisionSectionTitle({
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

class DecisionPriorityList extends StatelessWidget {
  const DecisionPriorityList({
    required this.actions,
    required this.onOpenActions,
    super.key,
  });

  final List<ExecutivePriorityAction> actions;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text(
            'Nenhuma prioridade foi identificada.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ...List.generate(actions.length, (index) {
            final item = actions[index];

            return Column(
              children: [
                if (index > 0) const Divider(height: 1),
                DecisionPriorityTile(item: item, onTap: onOpenActions),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class DecisionPriorityTile extends StatelessWidget {
  const DecisionPriorityTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final ExecutivePriorityAction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(item.priorityLevel);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  item.position.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF263238),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      DecisionLevelBadge(level: item.priorityLevel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      item.farmName,
                      item.responsible,
                      item.category,
                      item.deadline,
                    ].join(' · '),
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DecisionMetricChip(
                        label: 'Prioridade',
                        value: item.priorityScore
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
                        color: color,
                      ),
                      DecisionMetricChip(
                        label: 'Risco',
                        value: item.riskScore
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
                        color: const Color(0xFFC62828),
                      ),
                      DecisionMetricChip(
                        label: 'Oportunidade',
                        value: item.opportunityScore
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
                        color: const Color(0xFF1B5E20),
                      ),
                      DecisionMetricChip(
                        label: 'Chance de atraso',
                        value:
                            '${(item.delayProbability * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                        color: const Color(0xFFEF6C00),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    item.recommendedAction,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DecisionMetricChip extends StatelessWidget {
  const DecisionMetricChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DecisionPredictionGrid extends StatelessWidget {
  const DecisionPredictionGrid({required this.predictions, super.key});

  final List<ExecutivePredictionData> predictions;

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text(
            'Nenhuma previsão crítica foi identificada.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: predictions.map((item) {
            return SizedBox(
              width: width,
              child: DecisionPredictionCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class DecisionPredictionCard extends StatelessWidget {
  const DecisionPredictionCard({required this.item, super.key});

  final ExecutivePredictionData item;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(item.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    decisionPredictionIcon(item.targetType),
                    color: color,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.targetLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(item.probability * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              item.description,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 11),
            Text(
              'Horizonte: ${item.horizonDays} ${item.horizonDays == 1 ? 'dia' : 'dias'}',
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
            const SizedBox(height: 11),
            Text(
              item.recommendedAction,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DecisionHeatMapGrid extends StatelessWidget {
  const DecisionHeatMapGrid({required this.items, super.key});

  final List<ExecutiveHeatMapItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text('Sem dados suficientes para o mapa de calor.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: DecisionHeatMapCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class DecisionHeatMapCard extends StatelessWidget {
  const DecisionHeatMapCard({required this.item, super.key});

  final ExecutiveHeatMapItem item;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(item.level);

    return Card(
      color: color.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  item.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.group,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (item.score / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DecisionMiniStat(
                  label: 'Abertas',
                  value: item.openCount.toString(),
                ),
                DecisionMiniStat(
                  label: 'Atrasadas',
                  value: item.overdueCount.toString(),
                ),
                DecisionMiniStat(
                  label: 'Urgentes',
                  value: item.urgentCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              item.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DecisionMiniStat extends StatelessWidget {
  const DecisionMiniStat({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DecisionRankingGrid extends StatelessWidget {
  const DecisionRankingGrid({
    required this.farmRanking,
    required this.responsibleRanking,
    required this.categoryRanking,
    super.key,
  });

  final List<ExecutiveDecisionRankingItem> farmRanking;

  final List<ExecutiveDecisionRankingItem> responsibleRanking;

  final List<ExecutiveDecisionRankingItem> categoryRanking;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 28) / 3
            : constraints.maxWidth;

        final cards = [
          DecisionRankingCard(
            title: 'Fazendas',
            icon: Icons.home_work_outlined,
            items: farmRanking,
          ),
          DecisionRankingCard(
            title: 'Responsáveis',
            icon: Icons.groups_outlined,
            items: responsibleRanking,
          ),
          DecisionRankingCard(
            title: 'Categorias',
            icon: Icons.category_outlined,
            items: categoryRanking,
          ),
        ];

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards.map((card) {
            return SizedBox(width: width, child: card);
          }).toList(),
        );
      },
    );
  }
}

class DecisionRankingCard extends StatelessWidget {
  const DecisionRankingCard({
    required this.title,
    required this.icon,
    required this.items,
    super.key,
  });

  final String title;
  final IconData icon;

  final List<ExecutiveDecisionRankingItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (items.isEmpty)
              const Text('Sem dados.', style: TextStyle(color: Colors.black54))
            else
              ...List.generate(items.take(6).length, (index) {
                final item = items[index];
                final color = decisionLevelColor(item.level);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == 5 || index == items.length - 1 ? 0 : 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 25,
                        child: Text(
                          '${item.position}º',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.riskScore.toStringAsFixed(0),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class DecisionConsultantScoreDetails extends StatelessWidget {
  const DecisionConsultantScoreDetails({required this.score, super.key});

  final ExecutiveDecisionScore score;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(score.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_search_outlined, color: color, size: 27),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Composição do score do consultor',
                    style: TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${score.value.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              score.explanation,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 18),
            ...List.generate(score.components.length, (index) {
              final component = score.components[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == score.components.length - 1 ? 0 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            component.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          component.value
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (component.value / 100).clamp(0.0, 1.0),
                        backgroundColor: color.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      component.description,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class DecisionLevelBadge extends StatelessWidget {
  const DecisionLevelBadge({required this.level, super.key});

  final ExecutiveDecisionLevel level;

  @override
  Widget build(BuildContext context) {
    final color = decisionLevelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        decisionLevelLabelUi(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color decisionLevelColor(ExecutiveDecisionLevel level) {
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

String decisionLevelLabelUi(ExecutiveDecisionLevel level) {
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

IconData decisionPredictionIcon(ExecutivePredictionTargetType type) {
  switch (type) {
    case ExecutivePredictionTargetType.action:
      return Icons.assignment_late_outlined;

    case ExecutivePredictionTargetType.farm:
      return Icons.home_work_outlined;

    case ExecutivePredictionTargetType.responsible:
      return Icons.person_outlined;

    case ExecutivePredictionTargetType.category:
      return Icons.category_outlined;

    case ExecutivePredictionTargetType.indicator:
      return Icons.insights_outlined;
  }
}
