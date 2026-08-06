import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/models/atlas_executive_ai_advisor_data.dart';

class AtlasExecutiveAiAdvisorScreen
    extends StatelessWidget {
  const AtlasExecutiveAiAdvisorScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasExecutiveAiAdvisorData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Executive AI Advisor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1240,
            ),
            child: data.hasData
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _AdvisorHero(data: data),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Diagnóstico executivo',
                        subtitle:
                            'Síntese consolidada de toda a operação.',
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticCard(
                        diagnostic:
                            data.diagnostic,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Prioridades da semana',
                        subtitle:
                            'Decisões que exigem ação imediata.',
                      ),
                      const SizedBox(height: 12),
                      _PriorityList(
                        items:
                            data.weeklyPriorities,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Prioridades do mês',
                        subtitle:
                            'Temas estratégicos para os próximos 30 dias.',
                      ),
                      const SizedBox(height: 12),
                      _PriorityList(
                        items:
                            data.monthlyPriorities,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Oportunidades financeiras',
                        subtitle:
                            'Intervenções com maior potencial de retorno.',
                      ),
                      const SizedBox(height: 12),
                      _FinancialOpportunityList(
                        items: data
                            .financialOpportunities,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Riscos ocultos',
                        subtitle:
                            'Problemas futuros identificados pelo cruzamento das análises.',
                      ),
                      const SizedBox(height: 12),
                      _RiskList(
                        items: data.hiddenRisks,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Gargalos operacionais',
                        subtitle:
                            'Pontos que mais limitam os resultados.',
                      ),
                      const SizedBox(height: 12),
                      _BottleneckList(
                        items: data
                            .operationalBottlenecks,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Recomendações estratégicas',
                        subtitle:
                            'Orientações consolidadas do Advisor.',
                      ),
                      const SizedBox(height: 12),
                      _RecommendationList(
                        items: data
                            .strategicRecommendations,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Plano de ação automático',
                        subtitle:
                            'Sequência recomendada para transformar análise em execução.',
                      ),
                      const SizedBox(height: 12),
                      _ActionPlanList(
                        items: data.actionPlan,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyAdvisorView(),
          ),
        ),
      ),
    );
  }
}

class _AdvisorHero extends StatelessWidget {
  const _AdvisorHero({
    required this.data,
  });

  final AtlasExecutiveAiAdvisorData data;

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B132B),
            Color(0xFF1C2541),
            Color(0xFF3A506B),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Consultor Executivo Virtual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.executiveSummary,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Semana',
                    value: data
                        .weeklyPriorities.length,
                  ),
                  _HeroMetric(
                    label: 'Mês',
                    value: data
                        .monthlyPriorities.length,
                  ),
                  _HeroMetric(
                    label: 'Riscos',
                    value:
                        data.hiddenRisks.length,
                  ),
                  _HeroMetric(
                    label: 'Ações',
                    value: data.actionPlan.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 225,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  data.advisorScore
                      .toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  atlasExecutiveAdvisorStatusLabel(
                    data.status,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    minHeight: 9,
                    value:
                        data.advisorScore / 100,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Confiança: '
                  '${data.confidencePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                information,
                const SizedBox(height: 20),
                side,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.diagnostic,
  });

  final String diagnostic;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF1C2541),
              size: 29,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                diagnostic,
                style: const TextStyle(
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveAdvisorPriority>
      items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  color.withValues(
                alpha: 0.12,
              ),
              child: Text(
                item.position.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.deadlineDays} dias\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasExecutiveAdvisorPriorityLabel(
                item.priority,
              ),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _FinancialOpportunityList
    extends StatelessWidget {
  const _FinancialOpportunityList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveAdvisorFinancialOpportunity>
      items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                item.position.toString(),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · investimento de '
              'R\$ ${item.investmentValue.toStringAsFixed(2)}\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.roiPercent.toStringAsFixed(1)}% ROI',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _RiskList extends StatelessWidget {
  const _RiskList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveAdvisorRisk> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _severityColor(item.severity);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_outlined,
              color: color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · horizonte de '
              '${item.horizonDays} dias\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.probabilityPercent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _BottleneckList
    extends StatelessWidget {
  const _BottleneckList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveAdvisorBottleneck>
      items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _severityColor(item.severity);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.crisis_alert_outlined,
              color: color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.impactScore.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationList
    extends StatelessWidget {
  const _RecommendationList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveAdvisorRecommendation>
      items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.description}\n'
              'Impacto esperado: '
              '${item.expectedImpact}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.confidencePercent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null ||
                    item.farmName == 'Operação'
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _ActionPlanList
    extends StatelessWidget {
  const _ActionPlanList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveAdvisorAction>
      items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  color.withValues(
                alpha: 0.12,
              ),
              child: Text(
                item.position.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${atlasExecutiveAdvisorActionSourceLabel(item.source)} · '
              '${item.farmName} · '
              '${item.deadlineDays} dias\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasExecutiveAdvisorPriorityLabel(
                item.priority,
              ),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Nenhum item disponível.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAdvisorView
    extends StatelessWidget {
  const _EmptyAdvisorView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum parecer executivo disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _statusColor(
  AtlasExecutiveAdvisorStatus status,
) {
  switch (status) {
    case AtlasExecutiveAdvisorStatus.excellent:
      return const Color(0xFF80CBC4);

    case AtlasExecutiveAdvisorStatus.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasExecutiveAdvisorStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasExecutiveAdvisorStatus.critical:
      return const Color(0xFFEF9A9A);
  }
}

Color _severityColor(
  AtlasExecutiveAdvisorSeverity severity,
) {
  switch (severity) {
    case AtlasExecutiveAdvisorSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveAdvisorSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveAdvisorSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveAdvisorSeverity.critical:
      return const Color(0xFFC62828);
  }
}

Color _priorityColor(
  AtlasExecutiveAdvisorPriorityLevel priority,
) {
  switch (priority) {
    case AtlasExecutiveAdvisorPriorityLevel.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveAdvisorPriorityLevel.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveAdvisorPriorityLevel.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveAdvisorPriorityLevel.critical:
      return const Color(0xFFC62828);
  }
}
