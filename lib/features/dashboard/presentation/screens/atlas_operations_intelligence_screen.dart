import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_operations_intelligence_service.dart';

class AtlasOperationsIntelligenceScreen extends StatelessWidget {
  const AtlasOperationsIntelligenceScreen({
    required this.brief,
    required this.onOpenCopilot,
    required this.onOpenDecisionCenter,
    required this.onOpenActions,
    super.key,
  });

  final AtlasIntelligenceBrief brief;
  final VoidCallback onOpenCopilot;
  final VoidCallback onOpenDecisionCenter;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Central de Inteligência Atlas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Copiloto Atlas',
            onPressed: onOpenCopilot,
            icon: const Icon(Icons.smart_toy_outlined),
          ),
          IconButton(
            tooltip: 'Central de Decisão',
            onPressed: onOpenDecisionCenter,
            icon: const Icon(Icons.psychology_outlined),
          ),
          IconButton(
            tooltip: 'Ações Gerenciais',
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
                    AtlasIntelligenceHero(
                      brief: brief,
                      onOpenCopilot: onOpenCopilot,
                      onOpenDecisionCenter: onOpenDecisionCenter,
                      onOpenActions: onOpenActions,
                    ),
                    const SizedBox(height: 24),
                    AtlasCopilotIntelligenceCard(
                      brief: brief,
                      onOpen: onOpenCopilot,
                    ),
                    const SizedBox(height: 24),
                    AtlasSituationSummaryGrid(brief: brief),
                    const SizedBox(height: 28),
                    const AtlasSectionTitle(
                      title: 'O que fazer hoje',
                      subtitle:
                          'Orientação objetiva baseada nas prioridades, riscos e previsões atuais.',
                    ),
                    const SizedBox(height: 14),
                    AtlasTodayGuidanceCard(
                      brief: brief,
                      onOpenActions: onOpenActions,
                    ),
                    const SizedBox(height: 28),
                    const AtlasSectionTitle(
                      title: 'Principais prioridades',
                      subtitle:
                          'As cinco ações mais importantes para proteger o resultado da operação.',
                    ),
                    const SizedBox(height: 14),
                    AtlasPriorityList(
                      priorities: brief.topPriorities,
                      onOpenActions: onOpenActions,
                    ),
                    const SizedBox(height: 28),
                    const AtlasSectionTitle(
                      title: 'Riscos identificados',
                      subtitle:
                          'Situações que podem comprometer prazos, desempenho ou execução.',
                    ),
                    const SizedBox(height: 14),
                    AtlasInsightGrid(insights: brief.risks),
                    const SizedBox(height: 28),
                    const AtlasSectionTitle(
                      title: 'Oportunidades',
                      subtitle:
                          'Pontos em que uma decisão bem executada pode gerar ganho operacional.',
                    ),
                    const SizedBox(height: 14),
                    AtlasInsightGrid(insights: brief.opportunities),
                    const SizedBox(height: 28),
                    const AtlasSectionTitle(
                      title: 'Pontos positivos',
                      subtitle:
                          'Aspectos da operação que estão sob controle e devem ser preservados.',
                    ),
                    const SizedBox(height: 14),
                    AtlasInsightGrid(insights: brief.strengths),
                    const SizedBox(height: 28),
                    const AtlasSectionTitle(
                      title: 'Análises por grupo',
                      subtitle:
                          'Interpretação do risco e da oportunidade por fazenda, responsável e categoria.',
                    ),
                    const SizedBox(height: 14),
                    AtlasGroupAnalysisTabs(
                      farmAnalyses: brief.farmAnalyses,
                      responsibleAnalyses: brief.responsibleAnalyses,
                      categoryAnalyses: brief.categoryAnalyses,
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

class AtlasCopilotIntelligenceCard extends StatelessWidget {
  const AtlasCopilotIntelligenceCard({
    required this.brief,
    required this.onOpen,
    super.key,
  });

  final AtlasIntelligenceBrief brief;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final priority = brief.mainPriority;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;

              final information = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 51,
                    height: 51,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Color(0xFF1B5E20),
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pergunte ao Copiloto Atlas',
                          style: TextStyle(
                            color: Color(0xFF263238),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          priority == null
                              ? 'Converse com os dados e peça uma análise da situação atual.'
                              : 'Experimente perguntar por que “${priority.title}” é a prioridade número 1.',
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'O Copiloto usa o contexto desta Central de Inteligência para responder.',
                          style: TextStyle(color: Colors.black45, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final button = FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Abrir conversa'),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 16), button],
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
      ),
    );
  }
}

class AtlasIntelligenceHero extends StatelessWidget {
  const AtlasIntelligenceHero({
    required this.brief,
    required this.onOpenCopilot,
    required this.onOpenDecisionCenter,
    required this.onOpenActions,
    super.key,
  });

  final AtlasIntelligenceBrief brief;
  final VoidCallback onOpenCopilot;
  final VoidCallback onOpenDecisionCenter;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final color = atlasIntelligenceColor(brief.operationLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2F24), Color(0xFF174B37), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brief.greeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          brief.situationTitle,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                brief.situationDescription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  brief.executiveSummary,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onOpenCopilot,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B5E20),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text(
                      'Perguntar ao Copiloto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onOpenDecisionCenter,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC8A951),
                      foregroundColor: const Color(0xFF263238),
                    ),
                    icon: const Icon(Icons.psychology_outlined),
                    label: const Text(
                      'Central de Decisão',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenActions,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Ações Gerenciais'),
                  ),
                ],
              ),
            ],
          );

          final scorePanel = AtlasOperationScorePanel(
            brief: brief,
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
              const SizedBox(width: 28),
              scorePanel,
            ],
          );
        },
      ),
    );
  }
}

class AtlasOperationScorePanel extends StatelessWidget {
  const AtlasOperationScorePanel({
    required this.brief,
    required this.color,
    super.key,
  });

  final AtlasIntelligenceBrief brief;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
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
            atlasIntelligenceLevelLabel(brief.operationLevel),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Score geral da operação',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                brief.operationScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
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
              value: (brief.operationScore / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Ganho estimado',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            '+${formatAtlasNumber(brief.estimatedGain)} pontos',
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

class AtlasSituationSummaryGrid extends StatelessWidget {
  const AtlasSituationSummaryGrid({required this.brief, super.key});

  final AtlasIntelligenceBrief brief;

  @override
  Widget build(BuildContext context) {
    final criticalRisks = brief.risks.where((item) {
      return item.level == AtlasIntelligenceLevel.critical;
    }).length;

    final highOpportunity = brief.opportunities.where((item) {
      return item.level == AtlasIntelligenceLevel.excellent ||
          item.level == AtlasIntelligenceLevel.stable;
    }).length;

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
            AtlasSummaryCard(
              width: width,
              title: 'Prioridades',
              value: brief.topPriorities.length.toString(),
              icon: Icons.flag_outlined,
              color: const Color(0xFF1565C0),
            ),
            AtlasSummaryCard(
              width: width,
              title: 'Riscos críticos',
              value: criticalRisks.toString(),
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFFC62828),
            ),
            AtlasSummaryCard(
              width: width,
              title: 'Oportunidades',
              value: highOpportunity.toString(),
              icon: Icons.trending_up_outlined,
              color: const Color(0xFF1B5E20),
            ),
            AtlasSummaryCard(
              width: width,
              title: 'Pontos positivos',
              value: brief.strengths.length.toString(),
              icon: Icons.verified_outlined,
              color: const Color(0xFF2E7D32),
            ),
          ],
        );
      },
    );
  }
}

class AtlasSummaryCard extends StatelessWidget {
  const AtlasSummaryCard({
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

class AtlasSectionTitle extends StatelessWidget {
  const AtlasSectionTitle({
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

class AtlasTodayGuidanceCard extends StatelessWidget {
  const AtlasTodayGuidanceCard({
    required this.brief,
    required this.onOpenActions,
    super.key,
  });

  final AtlasIntelligenceBrief brief;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final priority = brief.mainPriority;

    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final information = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8A951).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.today_outlined,
                    color: Color(0xFF80681F),
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Orientação para hoje',
                        style: TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        brief.todayGuidance,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      if (priority != null) ...[
                        const SizedBox(height: 13),
                        Text(
                          'Prioridade nº 1: ${priority.title}',
                          style: const TextStyle(
                            color: Color(0xFF80681F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final button = FilledButton.icon(
              onPressed: onOpenActions,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC8A951),
                foregroundColor: const Color(0xFF263238),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Executar agora',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [information, const SizedBox(height: 17), button],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class AtlasPriorityList extends StatelessWidget {
  const AtlasPriorityList({
    required this.priorities,
    required this.onOpenActions,
    super.key,
  });

  final List<ExecutivePriorityAction> priorities;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    if (priorities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text('Nenhuma prioridade foi identificada.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: List.generate(priorities.length, (index) {
          final item = priorities[index];

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                onTap: onOpenActions,
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: atlasDecisionColor(
                      item.priorityLevel,
                    ).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: atlasDecisionColor(item.priorityLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${item.farmName} · '
                    '${item.responsible} · '
                    '${item.deadline}',
                  ),
                ),
                trailing: AtlasDecisionBadge(level: item.priorityLevel),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class AtlasInsightGrid extends StatelessWidget {
  const AtlasInsightGrid({required this.insights, super.key});

  final List<AtlasIntelligenceInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text('Nenhuma análise disponível.'),
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
          children: insights.map((item) {
            return SizedBox(
              width: width,
              child: AtlasInsightCard(insight: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class AtlasInsightCard extends StatelessWidget {
  const AtlasInsightCard({required this.insight, super.key});

  final AtlasIntelligenceInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = atlasIntelligenceColor(insight.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(atlasInsightIcon(insight.iconType), color: color),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        insight.targetLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AtlasIntelligenceBadge(level: insight.level),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              insight.description,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 11),
            Text(
              insight.recommendation,
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

class AtlasGroupAnalysisTabs extends StatelessWidget {
  const AtlasGroupAnalysisTabs({
    required this.farmAnalyses,
    required this.responsibleAnalyses,
    required this.categoryAnalyses,
    super.key,
  });

  final List<AtlasGroupAnalysis> farmAnalyses;
  final List<AtlasGroupAnalysis> responsibleAnalyses;
  final List<AtlasGroupAnalysis> categoryAnalyses;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.home_work_outlined), text: 'Fazendas'),
                  Tab(icon: Icon(Icons.groups_outlined), text: 'Responsáveis'),
                  Tab(icon: Icon(Icons.category_outlined), text: 'Categorias'),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 460,
                child: TabBarView(
                  children: [
                    AtlasGroupAnalysisList(analyses: farmAnalyses),
                    AtlasGroupAnalysisList(analyses: responsibleAnalyses),
                    AtlasGroupAnalysisList(analyses: categoryAnalyses),
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

class AtlasGroupAnalysisList extends StatelessWidget {
  const AtlasGroupAnalysisList({required this.analyses, super.key});

  final List<AtlasGroupAnalysis> analyses;

  @override
  Widget build(BuildContext context) {
    if (analyses.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados suficientes para esta análise.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      itemCount: analyses.length,
      separatorBuilder: (_, __) {
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        final item = analyses[index];
        final color = atlasIntelligenceColor(item.level);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 34,
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  AtlasIntelligenceBadge(level: item.level),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AtlasSmallMetric(
                    label: 'Risco',
                    value: formatAtlasNumber(item.score),
                    color: color,
                  ),
                  AtlasSmallMetric(
                    label: 'Oportunidade',
                    value: formatAtlasNumber(item.opportunityScore),
                    color: const Color(0xFF1565C0),
                  ),
                  AtlasSmallMetric(
                    label: 'Abertas',
                    value: item.openCount.toString(),
                    color: const Color(0xFF616161),
                  ),
                  AtlasSmallMetric(
                    label: 'Atrasadas',
                    value: item.overdueCount.toString(),
                    color: const Color(0xFFC62828),
                  ),
                  AtlasSmallMetric(
                    label: 'Urgentes',
                    value: item.urgentCount.toString(),
                    color: const Color(0xFFEF6C00),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                item.analysis,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 7),
              Text(
                item.recommendation,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AtlasSmallMetric extends StatelessWidget {
  const AtlasSmallMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
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

class AtlasIntelligenceBadge extends StatelessWidget {
  const AtlasIntelligenceBadge({required this.level, super.key});

  final AtlasIntelligenceLevel level;

  @override
  Widget build(BuildContext context) {
    final color = atlasIntelligenceColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasIntelligenceLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AtlasDecisionBadge extends StatelessWidget {
  const AtlasDecisionBadge({required this.level, super.key});

  final ExecutiveDecisionLevel level;

  @override
  Widget build(BuildContext context) {
    final color = atlasDecisionColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasDecisionLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color atlasIntelligenceColor(AtlasIntelligenceLevel level) {
  switch (level) {
    case AtlasIntelligenceLevel.excellent:
      return const Color(0xFF1B5E20);

    case AtlasIntelligenceLevel.stable:
      return const Color(0xFF2E7D32);

    case AtlasIntelligenceLevel.attention:
      return const Color(0xFFEF6C00);

    case AtlasIntelligenceLevel.critical:
      return const Color(0xFFC62828);
  }
}

Color atlasDecisionColor(ExecutiveDecisionLevel level) {
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

String atlasDecisionLevelLabel(ExecutiveDecisionLevel level) {
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

IconData atlasInsightIcon(AtlasInsightIconType type) {
  switch (type) {
    case AtlasInsightIconType.positive:
      return Icons.verified_outlined;

    case AtlasInsightIconType.warning:
      return Icons.warning_amber_outlined;

    case AtlasInsightIconType.risk:
      return Icons.shield_outlined;

    case AtlasInsightIconType.priority:
      return Icons.flag_outlined;

    case AtlasInsightIconType.opportunity:
      return Icons.trending_up_outlined;

    case AtlasInsightIconType.farm:
      return Icons.home_work_outlined;

    case AtlasInsightIconType.responsible:
      return Icons.person_outline;

    case AtlasInsightIconType.category:
      return Icons.category_outlined;
  }
}
