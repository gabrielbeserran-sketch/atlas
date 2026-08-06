import 'package:flutter/material.dart';

import 'package:projeto_atlas/features/atlas_copilot/domain/models/atlas_copilot_data.dart';

class AtlasCopilotScreen extends StatefulWidget {
  const AtlasCopilotScreen({required this.data, this.onOpenFarm, super.key});

  final AtlasCopilotData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasCopilotScreen> createState() {
    return _AtlasCopilotScreenState();
  }
}

class _AtlasCopilotScreenState extends State<AtlasCopilotScreen> {
  late List<AtlasCopilotChecklistItem> checklist;

  @override
  void initState() {
    super.initState();
    checklist = [...widget.data.checklist];
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Copilot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: data.hasData
                ? ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _CopilotHero(data: data),
                      if (data.mainProblem != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Maior problema da operação',
                          subtitle: 'Gargalo com maior impacto estimado.',
                        ),
                        const SizedBox(height: 12),
                        _MainProblemCard(
                          issue: data.mainProblem!,
                          onOpenFarm: widget.onOpenFarm,
                        ),
                      ],
                      if (data.topPriority != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Prioridade número 1',
                          subtitle:
                              'Decisão que deve receber atenção imediata.',
                        ),
                        const SizedBox(height: 12),
                        _TopPriorityCard(
                          priority: data.topPriority!,
                          onOpenFarm: widget.onOpenFarm,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Plano de ação',
                        subtitle: 'Ações ordenadas por prioridade e prazo.',
                      ),
                      const SizedBox(height: 12),
                      _ActionList(
                        actions: data.actions,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Ranking de investimentos',
                        subtitle:
                            'Intervenções priorizadas por retorno e confiança.',
                      ),
                      const SizedBox(height: 12),
                      _InvestmentList(
                        investments: data.investments,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Alertas executivos',
                        subtitle: 'Riscos que exigem acompanhamento.',
                      ),
                      const SizedBox(height: 12),
                      _AlertList(
                        alerts: data.alerts,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Recomendações do Copilot',
                        subtitle:
                            'Sugestões consolidadas a partir das análises.',
                      ),
                      const SizedBox(height: 12),
                      _RecommendationList(
                        recommendations: data.recommendations,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Checklist inteligente',
                        subtitle:
                            'Próximas ações para transformar análise em execução.',
                      ),
                      const SizedBox(height: 12),
                      _Checklist(
                        items: checklist,
                        onChanged: (item, completed) {
                          setState(() {
                            checklist = checklist.map((current) {
                              return current.id == item.id
                                  ? current.copyWith(completed: completed)
                                  : current;
                            }).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyCopilotView(),
          ),
        ),
      ),
    );
  }
}

class _CopilotHero extends StatelessWidget {
  const _CopilotHero({required this.data});

  final AtlasCopilotData data;

  @override
  Widget build(BuildContext context) {
    final color = _maturityColor(data.maturityLevel);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1B2A), Color(0xFF23395D), Color(0xFF406E8E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Consultor Executivo Atlas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(label: 'Ações', value: data.actions.length),
                  _HeroMetric(
                    label: 'Investimentos',
                    value: data.investments.length,
                  ),
                  _HeroMetric(label: 'Alertas', value: data.alerts.length),
                  _HeroMetric(
                    label: 'Recomendações',
                    value: data.recommendations.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 225,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.maturityScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasCopilotMaturityLevelLabel(data.maturityLevel),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: data.maturityScore / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), side],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

class _MainProblemCard extends StatelessWidget {
  const _MainProblemCard({required this.issue, required this.onOpenFarm});

  final AtlasCopilotIssue issue;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(issue.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.crisis_alert_outlined, color: color, size: 30),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        issue.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  atlasCopilotSeverityLabel(issue.severity),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              issue.description,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 9),
            Text(
              'Causa provável: ${issue.cause}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 9),
            Text(
              issue.recommendation,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Impacto estimado: R\$ ${issue.financialImpactValue.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                label: const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(issue.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopPriorityCard extends StatelessWidget {
  const _TopPriorityCard({required this.priority, required this.onOpenFarm});

  final AtlasCopilotPriority priority;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: color, size: 29),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    priority.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${priority.deadlineDays} dias',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              priority.description,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Resultado esperado: ${priority.expectedResult}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(
              'Confiança: ${priority.confidencePercent.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.black54),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                label: const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(priority.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions, required this.onOpenFarm});

  final List<AtlasCopilotAction> actions;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: actions.map((action) {
        final color = _priorityColor(action.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                '${action.position}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              action.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${action.farmName} · ${action.deadlineDays} dias\n'
              '${action.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasCopilotPriorityLabel(action.priority),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(action.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _InvestmentList extends StatelessWidget {
  const _InvestmentList({required this.investments, required this.onOpenFarm});

  final List<AtlasCopilotInvestment> investments;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: investments.map((item) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${item.position}')),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
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

class _AlertList extends StatelessWidget {
  const _AlertList({required this.alerts, required this.onOpenFarm});

  final List<AtlasCopilotAlert> alerts;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: alerts.map((alert) {
        final color = _severityColor(alert.severity);

        return Card(
          child: ListTile(
            leading: Icon(Icons.notification_important_outlined, color: color),
            title: Text(
              alert.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasCopilotAlertSourceLabel(alert.source)} · '
              '${alert.farmName}\n'
              '${alert.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasCopilotSeverityLabel(alert.severity),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(alert.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({
    required this.recommendations,
    required this.onOpenFarm,
  });

  final List<AtlasCopilotRecommendation> recommendations;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: recommendations.map((item) {
        final color = _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: Icon(Icons.lightbulb_outline, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.description}\n'
              'Impacto esperado: ${item.expectedImpact}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.confidencePercent.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: onOpenFarm == null || item.farmName == 'Operação'
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

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items, required this.onChanged});

  final List<AtlasCopilotChecklistItem> items;

  final void Function(AtlasCopilotChecklistItem item, bool completed) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: items.map((item) {
          return CheckboxListTile(
            value: item.completed,
            onChanged: (value) {
              onChanged(item, value ?? false);
            },
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: item.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(item.description),
            secondary: Icon(
              Icons.task_alt_outlined,
              color: _priorityColor(item.priority),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
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
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
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
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyCopilotView extends StatelessWidget {
  const _EmptyCopilotView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma recomendação disponível.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

Color _maturityColor(AtlasCopilotMaturityLevel level) {
  switch (level) {
    case AtlasCopilotMaturityLevel.initial:
      return const Color(0xFFEF9A9A);

    case AtlasCopilotMaturityLevel.developing:
      return const Color(0xFFFFCC80);

    case AtlasCopilotMaturityLevel.structured:
      return const Color(0xFF90CAF9);

    case AtlasCopilotMaturityLevel.advanced:
      return const Color(0xFFA5D6A7);

    case AtlasCopilotMaturityLevel.excellent:
      return const Color(0xFF80CBC4);
  }
}

Color _severityColor(AtlasCopilotSeverity severity) {
  switch (severity) {
    case AtlasCopilotSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasCopilotSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasCopilotSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasCopilotSeverity.critical:
      return const Color(0xFFC62828);
  }
}

Color _priorityColor(AtlasCopilotPriorityLevel priority) {
  switch (priority) {
    case AtlasCopilotPriorityLevel.low:
      return const Color(0xFF2E7D32);

    case AtlasCopilotPriorityLevel.medium:
      return const Color(0xFF1565C0);

    case AtlasCopilotPriorityLevel.high:
      return const Color(0xFFEF6C00);

    case AtlasCopilotPriorityLevel.critical:
      return const Color(0xFFC62828);
  }
}
