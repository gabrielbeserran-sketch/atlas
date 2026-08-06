import 'package:flutter/material.dart';

class ReportManagementInsightData {
  const ReportManagementInsightData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.previousIncome,
    required this.previousExpenses,
    required this.lowStockCount,
    required this.expiredItemsCount,
    required this.overdueTasksCount,
    required this.urgentTasksCount,
    required this.negativeFarmsCount,
    required this.totalFarmsCount,
  });

  final double totalIncome;
  final double totalExpenses;
  final double previousIncome;
  final double previousExpenses;

  final int lowStockCount;
  final int expiredItemsCount;
  final int overdueTasksCount;
  final int urgentTasksCount;
  final int negativeFarmsCount;
  final int totalFarmsCount;

  double get balance {
    return totalIncome - totalExpenses;
  }

  double get previousBalance {
    return previousIncome - previousExpenses;
  }
}

class ReportManagementInsightsCard extends StatelessWidget {
  const ReportManagementInsightsCard({required this.data, super.key});

  final ReportManagementInsightData data;

  @override
  Widget build(BuildContext context) {
    final insights = buildManagementInsights(data);

    final criticalCount = insights.where((insight) {
      return insight.severity == ReportInsightSeverity.critical;
    }).length;

    final warningCount = insights.where((insight) {
      return insight.severity == ReportInsightSeverity.warning;
    }).length;

    return Card(
      color: const Color(0xFF263238),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 650;

                final title = const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      color: Color(0xFFC8A951),
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diagnóstico gerencial Atlas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Recomendações automáticas com base nos dados filtrados.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final summary = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ReportInsightCounter(
                      value: criticalCount,
                      label: 'críticos',
                      color: const Color(0xFFEF5350),
                    ),
                    ReportInsightCounter(
                      value: warningCount,
                      label: 'atenções',
                      color: const Color(0xFFFFB74D),
                    ),
                    ReportInsightCounter(
                      value: insights.length,
                      label: 'recomendações',
                      color: const Color(0xFF81C784),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 18), summary],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: Color(0xFFC8A951),
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diagnóstico gerencial Atlas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Recomendações automáticas com base nos dados filtrados.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    summary,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ...List.generate(insights.length, (index) {
              final insight = insights[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == insights.length - 1 ? 0 : 12,
                ),
                child: ReportManagementInsightTile(
                  number: index + 1,
                  insight: insight,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ReportInsightCounter extends StatelessWidget {
  const ReportInsightCounter({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
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

class ReportManagementInsightTile extends StatelessWidget {
  const ReportManagementInsightTile({
    required this.number,
    required this.insight,
    super.key,
  });

  final int number;
  final ReportManagementInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = insightColor(insight.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(insight.icon, color: color, size: 20),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        insightSeverityLabel(insight.severity),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insight.message,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.task_alt_outlined, color: color, size: 18),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        insight.recommendation,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportManagementInsight {
  const ReportManagementInsight({
    required this.title,
    required this.message,
    required this.recommendation,
    required this.severity,
    required this.icon,
    required this.priority,
  });

  final String title;
  final String message;
  final String recommendation;
  final ReportInsightSeverity severity;
  final IconData icon;
  final int priority;
}

enum ReportInsightSeverity { normal, warning, critical }

List<ReportManagementInsight> buildManagementInsights(
  ReportManagementInsightData data,
) {
  final insights = <ReportManagementInsight>[];

  if (data.balance < 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Resultado financeiro negativo',
        message:
            'As despesas superaram as receitas em '
            '${formatInsightCurrency(data.balance.abs())}.',
        recommendation:
            'Revisar os maiores centros de custo, adiar gastos não essenciais '
            'e elaborar um plano de recuperação do caixa.',
        severity: ReportInsightSeverity.critical,
        icon: Icons.trending_down_outlined,
        priority: 100,
      ),
    );
  }

  if (data.totalIncome == 0 && data.totalExpenses > 0) {
    insights.add(
      const ReportManagementInsight(
        title: 'Ausência de receitas no período',
        message:
            'Foram registradas despesas, mas nenhuma receita foi identificada.',
        recommendation:
            'Verificar se as vendas e demais entradas foram cadastradas '
            'e revisar o planejamento comercial da propriedade.',
        severity: ReportInsightSeverity.critical,
        icon: Icons.money_off_csred_outlined,
        priority: 95,
      ),
    );
  }

  if (data.previousExpenses > 0 && data.totalExpenses > data.previousExpenses) {
    final increase =
        (data.totalExpenses - data.previousExpenses) /
        data.previousExpenses *
        100;

    if (increase >= 10) {
      insights.add(
        ReportManagementInsight(
          title: 'Crescimento das despesas',
          message:
              'As despesas aumentaram '
              '${increase.toStringAsFixed(1).replaceAll('.', ',')}% '
              'em relação ao período anterior.',
          recommendation:
              'Identificar as categorias responsáveis pelo aumento e '
              'comparar os valores com o orçamento previsto.',
          severity: increase >= 30
              ? ReportInsightSeverity.critical
              : ReportInsightSeverity.warning,
          icon: Icons.price_change_outlined,
          priority: increase >= 30 ? 90 : 70,
        ),
      );
    }
  }

  if (data.overdueTasksCount > 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Atividades atrasadas',
        message:
            '${data.overdueTasksCount} '
            '${data.overdueTasksCount == 1 ? 'atividade está' : 'atividades estão'} '
            'fora do prazo.',
        recommendation:
            'Reorganizar a agenda, definir responsáveis e concluir primeiro '
            'as tarefas com maior impacto sanitário ou produtivo.',
        severity: ReportInsightSeverity.critical,
        icon: Icons.event_busy_outlined,
        priority: 88,
      ),
    );
  }

  if (data.urgentTasksCount > 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Prioridades urgentes abertas',
        message:
            '${data.urgentTasksCount} '
            '${data.urgentTasksCount == 1 ? 'tarefa urgente permanece aberta' : 'tarefas urgentes permanecem abertas'}.',
        recommendation:
            'Confirmar imediatamente os responsáveis, materiais necessários '
            'e prazos de execução.',
        severity: ReportInsightSeverity.critical,
        icon: Icons.priority_high,
        priority: 86,
      ),
    );
  }

  if (data.expiredItemsCount > 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Produtos vencidos no estoque',
        message:
            '${data.expiredItemsCount} '
            '${data.expiredItemsCount == 1 ? 'produto vencido foi identificado' : 'produtos vencidos foram identificados'}.',
        recommendation:
            'Separar os itens, registrar a destinação correta e revisar '
            'o controle de validade e a frequência das conferências.',
        severity: ReportInsightSeverity.critical,
        icon: Icons.event_busy_outlined,
        priority: 84,
      ),
    );
  }

  if (data.lowStockCount > 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Produtos com estoque baixo',
        message:
            '${data.lowStockCount} '
            '${data.lowStockCount == 1 ? 'produto está' : 'produtos estão'} '
            'no nível mínimo ou abaixo.',
        recommendation:
            'Avaliar a reposição conforme o calendário sanitário, nutricional '
            'e operacional, evitando compras emergenciais.',
        severity: ReportInsightSeverity.warning,
        icon: Icons.inventory_2_outlined,
        priority: 65,
      ),
    );
  }

  if (data.negativeFarmsCount > 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Propriedades com resultado negativo',
        message:
            '${data.negativeFarmsCount} de ${data.totalFarmsCount} '
            '${data.negativeFarmsCount == 1 ? 'propriedade apresenta' : 'propriedades apresentam'} '
            'resultado financeiro negativo.',
        recommendation:
            'Analisar cada propriedade separadamente, comparar custos por '
            'hectare e por animal e definir um plano de ação específico.',
        severity: data.negativeFarmsCount == data.totalFarmsCount
            ? ReportInsightSeverity.critical
            : ReportInsightSeverity.warning,
        icon: Icons.home_work_outlined,
        priority: 75,
      ),
    );
  }

  if (data.balance >= 0 && data.previousBalance < 0) {
    insights.add(
      ReportManagementInsight(
        title: 'Recuperação do resultado financeiro',
        message:
            'A operação saiu de um resultado negativo de '
            '${formatInsightCurrency(data.previousBalance.abs())} '
            'para um saldo positivo de '
            '${formatInsightCurrency(data.balance)}.',
        recommendation:
            'Identificar as decisões que contribuíram para a recuperação e '
            'incorporá-las ao planejamento dos próximos períodos.',
        severity: ReportInsightSeverity.normal,
        icon: Icons.trending_up_outlined,
        priority: 55,
      ),
    );
  }

  if (insights.isEmpty) {
    insights.add(
      const ReportManagementInsight(
        title: 'Operação sem pendências críticas',
        message:
            'Os dados filtrados não apresentam alertas financeiros, '
            'operacionais ou de estoque relevantes.',
        recommendation:
            'Manter os registros atualizados e acompanhar periodicamente '
            'os indicadores para preservar o desempenho.',
        severity: ReportInsightSeverity.normal,
        icon: Icons.check_circle_outline,
        priority: 10,
      ),
    );
  }

  insights.sort((first, second) {
    return second.priority.compareTo(first.priority);
  });

  return insights.take(6).toList();
}

Color insightColor(ReportInsightSeverity severity) {
  switch (severity) {
    case ReportInsightSeverity.normal:
      return const Color(0xFF81C784);
    case ReportInsightSeverity.warning:
      return const Color(0xFFFFB74D);
    case ReportInsightSeverity.critical:
      return const Color(0xFFEF5350);
  }
}

String insightSeverityLabel(ReportInsightSeverity severity) {
  switch (severity) {
    case ReportInsightSeverity.normal:
      return 'POSITIVO';
    case ReportInsightSeverity.warning:
      return 'ATENÇÃO';
    case ReportInsightSeverity.critical:
      return 'CRÍTICO';
  }
}

String formatInsightCurrency(double value) {
  final negative = value < 0;
  final absoluteValue = value.abs();

  final parts = absoluteValue.toStringAsFixed(2).split('.');

  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final positionFromEnd = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = 'R\$ ${buffer.toString()},$decimalPart';

  return negative ? '-$formatted' : formatted;
}
