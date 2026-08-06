import 'package:flutter/material.dart';

class ReportPeriodComparisonData {
  const ReportPeriodComparisonData({
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpenses,
    required this.previousExpenses,
  });

  final double currentIncome;
  final double previousIncome;
  final double currentExpenses;
  final double previousExpenses;

  double get currentBalance {
    return currentIncome - currentExpenses;
  }

  double get previousBalance {
    return previousIncome - previousExpenses;
  }
}

class ReportPeriodComparisonCard extends StatelessWidget {
  const ReportPeriodComparisonCard({
    required this.data,
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
    super.key,
  });

  final ReportPeriodComparisonData data;
  final String currentPeriodLabel;
  final String previousPeriodLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Text(
                  'Comparação entre períodos',
                  style: TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$currentPeriodLabel comparado com $previousPeriodLabel.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 900
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth >= 580
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ReportComparisonMetric(
                      width: cardWidth,
                      title: 'Receitas',
                      currentValue: data.currentIncome,
                      previousValue: data.previousIncome,
                      favorableWhenHigher: true,
                      icon: Icons.trending_up_outlined,
                    ),
                    ReportComparisonMetric(
                      width: cardWidth,
                      title: 'Despesas',
                      currentValue: data.currentExpenses,
                      previousValue: data.previousExpenses,
                      favorableWhenHigher: false,
                      icon: Icons.trending_down_outlined,
                    ),
                    ReportComparisonMetric(
                      width: cardWidth,
                      title: 'Resultado',
                      currentValue: data.currentBalance,
                      previousValue: data.previousBalance,
                      favorableWhenHigher: true,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
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

class ReportComparisonMetric extends StatelessWidget {
  const ReportComparisonMetric({
    required this.width,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.favorableWhenHigher,
    required this.icon,
    super.key,
  });

  final double width;
  final String title;
  final double currentValue;
  final double previousValue;
  final bool favorableWhenHigher;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final difference = currentValue - previousValue;

    final percentage = calculateReportVariation(
      currentValue: currentValue,
      previousValue: previousValue,
    );

    final improved = difference == 0
        ? null
        : favorableWhenHigher
        ? difference > 0
        : difference < 0;

    final statusColor = improved == null
        ? const Color(0xFF607D8B)
        : improved
        ? const Color(0xFF1B5E20)
        : const Color(0xFFC62828);

    final statusIcon = improved == null
        ? Icons.remove
        : difference > 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    final statusLabel = improved == null
        ? 'Sem alteração'
        : improved
        ? 'Melhora'
        : 'Piora';

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Período atual',
              style: TextStyle(color: Colors.black54, fontSize: 11),
            ),
            const SizedBox(height: 3),
            Text(
              formatComparisonCurrency(currentValue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: currentValue < 0
                    ? const Color(0xFFC62828)
                    : const Color(0xFF263238),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Período anterior',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatComparisonCurrency(previousValue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 15, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        formatComparisonPercentage(percentage),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  improved == null
                      ? Icons.horizontal_rule
                      : improved
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  size: 17,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double? calculateReportVariation({
  required double currentValue,
  required double previousValue,
}) {
  if (previousValue == 0) {
    if (currentValue == 0) {
      return 0;
    }

    return null;
  }

  return (currentValue - previousValue) / previousValue.abs() * 100;
}

String formatComparisonPercentage(double? value) {
  if (value == null) {
    return 'Novo';
  }

  final prefix = value > 0 ? '+' : '';

  return '$prefix${value.toStringAsFixed(1).replaceAll('.', ',')}%';
}

String formatComparisonCurrency(double value) {
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
