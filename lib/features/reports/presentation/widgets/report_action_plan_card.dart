import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_management_insights_card.dart';

class ReportActionPlanCard extends StatelessWidget {
  const ReportActionPlanCard({required this.insightData, super.key});

  final ReportManagementInsightData insightData;

  @override
  Widget build(BuildContext context) {
    final insights = buildManagementInsights(insightData);

    final actions = insights.map((insight) {
      return ReportActionPlanItem.fromInsight(insight);
    }).toList();

    final immediateCount = actions.where((action) {
      return action.deadline == ReportActionDeadline.immediate;
    }).length;

    final shortTermCount = actions.where((action) {
      return action.deadline == ReportActionDeadline.shortTerm;
    }).length;

    final monitoringCount = actions.where((action) {
      return action.deadline == ReportActionDeadline.monitoring;
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;

                final information = const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt_outlined,
                          color: Color(0xFF1B5E20),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Plano de ação gerencial',
                          style: TextStyle(
                            color: Color(0xFF263238),
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Ações recomendadas em ordem de prioridade.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                );

                final summary = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ReportActionSummaryChip(
                      value: immediateCount,
                      label: 'imediatas',
                      color: const Color(0xFFC62828),
                    ),
                    ReportActionSummaryChip(
                      value: shortTermCount,
                      label: 'curto prazo',
                      color: const Color(0xFFEF6C00),
                    ),
                    ReportActionSummaryChip(
                      value: monitoringCount,
                      label: 'acompanhar',
                      color: const Color(0xFF1565C0),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      information,
                      const SizedBox(height: 18),
                      summary,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.task_alt_outlined,
                                color: Color(0xFF1B5E20),
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Plano de ação gerencial',
                                style: TextStyle(
                                  color: Color(0xFF263238),
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Ações recomendadas em ordem de prioridade.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    summary,
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            if (actions.isEmpty)
              const ReportActionPlanEmptyState()
            else
              ...List.generate(actions.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == actions.length - 1 ? 0 : 14,
                  ),
                  child: ReportActionPlanTile(
                    position: index + 1,
                    action: actions[index],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class ReportActionSummaryChip extends StatelessWidget {
  const ReportActionSummaryChip({
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionPlanTile extends StatelessWidget {
  const ReportActionPlanTile({
    required this.position,
    required this.action,
    super.key,
  });

  final int position;
  final ReportActionPlanItem action;

  @override
  Widget build(BuildContext context) {
    final color = actionDeadlineColor(action.deadline);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;

          final number = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      action.title,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ReportActionDeadlineBadge(deadline: action.deadline),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                action.action,
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  ReportActionInformation(
                    icon: Icons.schedule_outlined,
                    label: 'Prazo',
                    value: action.deadlineText,
                    color: color,
                  ),
                  ReportActionInformation(
                    icon: Icons.person_outline,
                    label: 'Responsável',
                    value: action.suggestedResponsible,
                    color: const Color(0xFF1565C0),
                  ),
                  ReportActionInformation(
                    icon: Icons.flag_outlined,
                    label: 'Prioridade',
                    value: action.priorityLabel,
                    color: actionPriorityColor(action.priority),
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [number, const SizedBox(height: 13), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              number,
              const SizedBox(width: 15),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class ReportActionDeadlineBadge extends StatelessWidget {
  const ReportActionDeadlineBadge({required this.deadline, super.key});

  final ReportActionDeadline deadline;

  @override
  Widget build(BuildContext context) {
    final color = actionDeadlineColor(deadline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        actionDeadlineLabel(deadline),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ReportActionInformation extends StatelessWidget {
  const ReportActionInformation({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionPlanEmptyState extends StatelessWidget {
  const ReportActionPlanEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Nenhuma ação corretiva foi identificada para os dados selecionados.',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionPlanItem {
  const ReportActionPlanItem({
    required this.title,
    required this.action,
    required this.deadline,
    required this.deadlineText,
    required this.suggestedResponsible,
    required this.priority,
  });

  factory ReportActionPlanItem.fromInsight(ReportManagementInsight insight) {
    final deadline = deadlineFromInsight(insight);

    return ReportActionPlanItem(
      title: insight.title,
      action: insight.recommendation,
      deadline: deadline,
      deadlineText: suggestedDeadlineText(deadline),
      suggestedResponsible: suggestedResponsibleForInsight(insight),
      priority: insight.priority,
    );
  }

  final String title;
  final String action;
  final ReportActionDeadline deadline;
  final String deadlineText;
  final String suggestedResponsible;
  final int priority;

  String get priorityLabel {
    if (priority >= 85) {
      return 'Muito alta';
    }

    if (priority >= 65) {
      return 'Alta';
    }

    if (priority >= 40) {
      return 'Média';
    }

    return 'Acompanhamento';
  }
}

enum ReportActionDeadline { immediate, shortTerm, monitoring }

ReportActionDeadline deadlineFromInsight(ReportManagementInsight insight) {
  if (insight.severity == ReportInsightSeverity.critical ||
      insight.priority >= 85) {
    return ReportActionDeadline.immediate;
  }

  if (insight.severity == ReportInsightSeverity.warning ||
      insight.priority >= 60) {
    return ReportActionDeadline.shortTerm;
  }

  return ReportActionDeadline.monitoring;
}

String suggestedDeadlineText(ReportActionDeadline deadline) {
  switch (deadline) {
    case ReportActionDeadline.immediate:
      return 'Até 48 horas';

    case ReportActionDeadline.shortTerm:
      return 'Até 7 dias';

    case ReportActionDeadline.monitoring:
      return 'Próxima revisão';
  }
}

String actionDeadlineLabel(ReportActionDeadline deadline) {
  switch (deadline) {
    case ReportActionDeadline.immediate:
      return 'IMEDIATA';

    case ReportActionDeadline.shortTerm:
      return 'CURTO PRAZO';

    case ReportActionDeadline.monitoring:
      return 'ACOMPANHAR';
  }
}

Color actionDeadlineColor(ReportActionDeadline deadline) {
  switch (deadline) {
    case ReportActionDeadline.immediate:
      return const Color(0xFFC62828);

    case ReportActionDeadline.shortTerm:
      return const Color(0xFFEF6C00);

    case ReportActionDeadline.monitoring:
      return const Color(0xFF1565C0);
  }
}

Color actionPriorityColor(int priority) {
  if (priority >= 85) {
    return const Color(0xFFC62828);
  }

  if (priority >= 65) {
    return const Color(0xFFEF6C00);
  }

  if (priority >= 40) {
    return const Color(0xFF1565C0);
  }

  return const Color(0xFF1B5E20);
}

String suggestedResponsibleForInsight(ReportManagementInsight insight) {
  final title = insight.title.toLowerCase();

  if (title.contains('financeir') ||
      title.contains('despesa') ||
      title.contains('receita')) {
    return 'Gestor financeiro';
  }

  if (title.contains('estoque') || title.contains('produto')) {
    return 'Responsável pelo estoque';
  }

  if (title.contains('atividade') ||
      title.contains('tarefa') ||
      title.contains('prioridade')) {
    return 'Gerente da fazenda';
  }

  if (title.contains('propriedade')) {
    return 'Consultor e gestor';
  }

  return 'Gestor responsável';
}
