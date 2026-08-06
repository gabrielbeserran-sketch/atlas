import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ReportActionAnalyticsCard extends StatelessWidget {
  const ReportActionAnalyticsCard({
    required this.actions,
    required this.historyByActionId,
    super.key,
  });

  final List<ReportActionItemData> actions;

  final Map<String, List<ReportActionHistoryData>> historyByActionId;

  @override
  Widget build(BuildContext context) {
    final analytics = ReportActionAnalytics.fromData(
      actions: actions,
      historyByActionId: historyByActionId,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF1B5E20),
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Análise gerencial das ações',
                    style: TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Indicadores de execução, atraso e responsabilidade.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 900
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth >= 580
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ReportActionAnalyticsMetric(
                      width: width,
                      title: 'Taxa de conclusão',
                      value: formatAnalyticsPercentage(
                        analytics.completionRate,
                      ),
                      subtitle:
                          '${analytics.completedCount} de ${analytics.consideredCount} ações consideradas',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF1B5E20),
                    ),
                    ReportActionAnalyticsMetric(
                      width: width,
                      title: 'Taxa de atraso',
                      value: formatAnalyticsPercentage(analytics.overdueRate),
                      subtitle: '${analytics.overdueCount} ações atrasadas',
                      icon: Icons.event_busy_outlined,
                      color: analytics.overdueCount > 0
                          ? const Color(0xFFC62828)
                          : const Color(0xFF1B5E20),
                    ),
                    ReportActionAnalyticsMetric(
                      width: width,
                      title: 'Prazo médio de conclusão',
                      value: analytics.averageCompletionDaysLabel,
                      subtitle: 'Tempo entre criação e conclusão',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF1565C0),
                    ),
                    ReportActionAnalyticsMetric(
                      width: width,
                      title: 'Mais ações abertas',
                      value: analytics.topResponsible,
                      subtitle:
                          '${analytics.topResponsibleOpenCount} ações abertas',
                      icon: Icons.person_outline,
                      color: const Color(0xFF6A1B9A),
                    ),
                    ReportActionAnalyticsMetric(
                      width: width,
                      title: 'Prioridade predominante',
                      value: analytics.mainPriority,
                      subtitle:
                          '${analytics.mainPriorityCount} ações nessa prioridade',
                      icon: Icons.flag_outlined,
                      color: analyticsPriorityColor(analytics.mainPriority),
                    ),
                    ReportActionAnalyticsMetric(
                      width: width,
                      title: 'Ações sem responsável',
                      value: analytics.withoutResponsibleCount.toString(),
                      subtitle: 'Pendências abertas sem responsável definido',
                      icon: Icons.person_off_outlined,
                      color: analytics.withoutResponsibleCount > 0
                          ? const Color(0xFFEF6C00)
                          : const Color(0xFF1B5E20),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow = constraints.maxWidth >= 820;

                final responsibility = ReportActionResponsibilityCard(
                  items: analytics.responsibilityItems,
                );

                final recommendation = ReportActionAnalyticsRecommendation(
                  analytics: analytics,
                );

                if (!useRow) {
                  return Column(
                    children: [
                      responsibility,
                      const SizedBox(height: 16),
                      recommendation,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: responsibility),
                    const SizedBox(width: 16),
                    Expanded(child: recommendation),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ReportActionAnalyticsMetric extends StatelessWidget {
  const ReportActionAnalyticsMetric({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    super.key,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
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

class ReportActionResponsibilityCard extends StatelessWidget {
  const ReportActionResponsibilityCard({required this.items, super.key});

  final List<ReportActionResponsibilityItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_outlined, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text(
                'Distribuição por responsável',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Text(
              'Nenhuma ação com responsável definido.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 14,
                ),
                child: ReportActionResponsibilityRow(item: item),
              );
            }),
        ],
      ),
    );
  }
}

class ReportActionResponsibilityRow extends StatelessWidget {
  const ReportActionResponsibilityRow({required this.item, super.key});

  final ReportActionResponsibilityItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.responsible,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.openCount} abertas',
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.completedCount} concluídas',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: item.completionRate.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
          ),
        ),
      ],
    );
  }
}

class ReportActionAnalyticsRecommendation extends StatelessWidget {
  const ReportActionAnalyticsRecommendation({
    required this.analytics,
    super.key,
  });

  final ReportActionAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final recommendation = buildAnalyticsRecommendation(analytics);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: recommendation.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: recommendation.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(recommendation.icon, color: recommendation.color),
              const SizedBox(width: 8),
              Text(
                recommendation.title,
                style: TextStyle(
                  color: recommendation.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.message,
            style: const TextStyle(color: Color(0xFF263238), height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.task_alt_outlined,
                color: recommendation.color,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  recommendation.action,
                  style: TextStyle(
                    color: recommendation.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportActionAnalytics {
  const ReportActionAnalytics({
    required this.totalCount,
    required this.consideredCount,
    required this.completedCount,
    required this.overdueCount,
    required this.completionRate,
    required this.overdueRate,
    required this.averageCompletionDays,
    required this.topResponsible,
    required this.topResponsibleOpenCount,
    required this.mainPriority,
    required this.mainPriorityCount,
    required this.withoutResponsibleCount,
    required this.responsibilityItems,
  });

  factory ReportActionAnalytics.fromData({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
  }) {
    final considered = actions.where((action) {
      return !action.isCancelled;
    }).toList();

    final completed = considered.where((action) {
      return action.isCompleted;
    }).toList();

    final overdue = considered.where((action) {
      return action.isOverdue;
    }).toList();

    final openByResponsible = <String, int>{};
    final completedByResponsible = <String, int>{};
    final totalByResponsible = <String, int>{};

    var withoutResponsible = 0;

    for (final action in actions) {
      final responsible = action.responsible.trim();

      if (responsible.isEmpty) {
        if (action.isOpen) {
          withoutResponsible++;
        }

        continue;
      }

      totalByResponsible.update(
        responsible,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      if (action.isOpen) {
        openByResponsible.update(
          responsible,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      if (action.isCompleted) {
        completedByResponsible.update(
          responsible,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    String topResponsible = 'Não definido';
    var topResponsibleCount = 0;

    for (final entry in openByResponsible.entries) {
      if (entry.value > topResponsibleCount) {
        topResponsible = entry.key;
        topResponsibleCount = entry.value;
      }
    }

    final priorities = <String, int>{};

    for (final action in actions) {
      priorities.update(
        action.priority,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String mainPriority = 'Não definida';
    var mainPriorityCount = 0;

    for (final entry in priorities.entries) {
      if (entry.value > mainPriorityCount) {
        mainPriority = entry.key;
        mainPriorityCount = entry.value;
      }
    }

    final completionDays = <int>[];

    for (final action in completed) {
      final createdAt = tryParseAnalyticsDate(action.createdAt);

      final completedAt = tryParseAnalyticsDate(action.completedAt);

      if (createdAt != null && completedAt != null) {
        completionDays.add(completedAt.difference(createdAt).inDays.abs());
        continue;
      }

      final history = historyByActionId[action.id] ?? const [];

      final creationHistory = history.where((item) {
        return item.isCreation;
      }).toList()..sort(compareReportActionHistory);

      final completionHistory = history.where((item) {
        return item.isCompletion;
      }).toList()..sort(compareReportActionHistory);

      if (creationHistory.isNotEmpty && completionHistory.isNotEmpty) {
        final createdHistoryDate = tryParseReportActionHistoryDateTime(
          creationHistory.last.createdAt,
        );

        final completedHistoryDate = tryParseReportActionHistoryDateTime(
          completionHistory.first.createdAt,
        );

        if (createdHistoryDate != null && completedHistoryDate != null) {
          completionDays.add(
            completedHistoryDate.difference(createdHistoryDate).inDays.abs(),
          );
        }
      }
    }

    final averageDays = completionDays.isEmpty
        ? null
        : completionDays.reduce((first, second) => first + second) /
              completionDays.length;

    final responsibilityItems =
        totalByResponsible.entries.map((entry) {
          final total = entry.value;
          final completedCount = completedByResponsible[entry.key] ?? 0;
          final openCount = openByResponsible[entry.key] ?? 0;

          return ReportActionResponsibilityItem(
            responsible: entry.key,
            totalCount: total,
            openCount: openCount,
            completedCount: completedCount,
          );
        }).toList()..sort((first, second) {
          return second.openCount.compareTo(first.openCount);
        });

    return ReportActionAnalytics(
      totalCount: actions.length,
      consideredCount: considered.length,
      completedCount: completed.length,
      overdueCount: overdue.length,
      completionRate: considered.isEmpty
          ? 0
          : completed.length / considered.length,
      overdueRate: considered.isEmpty ? 0 : overdue.length / considered.length,
      averageCompletionDays: averageDays,
      topResponsible: topResponsible,
      topResponsibleOpenCount: topResponsibleCount,
      mainPriority: mainPriority,
      mainPriorityCount: mainPriorityCount,
      withoutResponsibleCount: withoutResponsible,
      responsibilityItems: responsibilityItems.take(6).toList(),
    );
  }

  final int totalCount;
  final int consideredCount;
  final int completedCount;
  final int overdueCount;

  final double completionRate;
  final double overdueRate;
  final double? averageCompletionDays;

  final String topResponsible;
  final int topResponsibleOpenCount;

  final String mainPriority;
  final int mainPriorityCount;

  final int withoutResponsibleCount;

  final List<ReportActionResponsibilityItem> responsibilityItems;

  String get averageCompletionDaysLabel {
    final value = averageCompletionDays;

    if (value == null) {
      return 'Sem dados';
    }

    if (value < 1) {
      return 'Menos de 1 dia';
    }

    if (value == 1) {
      return '1 dia';
    }

    return '${value.toStringAsFixed(1).replaceAll('.', ',')} dias';
  }
}

class ReportActionResponsibilityItem {
  const ReportActionResponsibilityItem({
    required this.responsible,
    required this.totalCount,
    required this.openCount,
    required this.completedCount,
  });

  final String responsible;
  final int totalCount;
  final int openCount;
  final int completedCount;

  double get completionRate {
    if (totalCount == 0) {
      return 0;
    }

    return completedCount / totalCount;
  }
}

class ReportActionAnalyticsRecommendationData {
  const ReportActionAnalyticsRecommendationData({
    required this.title,
    required this.message,
    required this.action,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final String action;
  final IconData icon;
  final Color color;
}

ReportActionAnalyticsRecommendationData buildAnalyticsRecommendation(
  ReportActionAnalytics analytics,
) {
  if (analytics.overdueRate >= 0.25) {
    return const ReportActionAnalyticsRecommendationData(
      title: 'Risco elevado de atraso',
      message: 'Uma parcela relevante das ações está fora do prazo.',
      action:
          'Revisar prazos, redistribuir responsabilidades e priorizar as ações vencidas.',
      icon: Icons.warning_amber_outlined,
      color: Color(0xFFC62828),
    );
  }

  if (analytics.withoutResponsibleCount > 0) {
    return ReportActionAnalyticsRecommendationData(
      title: 'Responsabilidades incompletas',
      message:
          '${analytics.withoutResponsibleCount} '
          '${analytics.withoutResponsibleCount == 1 ? 'ação aberta está' : 'ações abertas estão'} '
          'sem responsável definido.',
      action: 'Definir um responsável e confirmar o prazo de cada pendência.',
      icon: Icons.person_off_outlined,
      color: const Color(0xFFEF6C00),
    );
  }

  if (analytics.completionRate >= 0.75) {
    return const ReportActionAnalyticsRecommendationData(
      title: 'Boa execução do plano',
      message: 'A taxa de conclusão indica avanço consistente das ações.',
      action:
          'Manter o acompanhamento das pendências restantes e registrar os resultados alcançados.',
      icon: Icons.trending_up_outlined,
      color: Color(0xFF1B5E20),
    );
  }

  if (analytics.topResponsibleOpenCount >= 5) {
    return ReportActionAnalyticsRecommendationData(
      title: 'Possível sobrecarga',
      message:
          '${analytics.topResponsible} concentra '
          '${analytics.topResponsibleOpenCount} ações abertas.',
      action:
          'Avaliar a redistribuição das atividades para reduzir risco de atraso.',
      icon: Icons.groups_outlined,
      color: const Color(0xFF6A1B9A),
    );
  }

  return const ReportActionAnalyticsRecommendationData(
    title: 'Plano em evolução',
    message:
        'A execução está em andamento e ainda há espaço para acelerar as conclusões.',
    action:
        'Revisar semanalmente o Kanban e atualizar responsáveis, prazos e status.',
    icon: Icons.insights_outlined,
    color: Color(0xFF1565C0),
  );
}

DateTime? tryParseAnalyticsDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

String formatAnalyticsPercentage(double value) {
  return '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
}

Color analyticsPriorityColor(String priority) {
  switch (priority) {
    case 'Muito alta':
    case 'Urgente':
      return const Color(0xFFC62828);
    case 'Alta':
      return const Color(0xFFEF6C00);
    case 'Média':
    case 'Normal':
      return const Color(0xFF1565C0);
    default:
      return const Color(0xFF1B5E20);
  }
}
