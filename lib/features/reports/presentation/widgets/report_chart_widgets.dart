import 'dart:math' as math;

import 'package:flutter/material.dart';

class ReportMonthlyPoint {
  const ReportMonthlyPoint({
    required this.label,
    required this.income,
    required this.expenses,
  });

  final String label;
  final double income;
  final double expenses;

  double get balance => income - expenses;
}

class ReportCategoryPoint {
  const ReportCategoryPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class ReportFarmComparisonPoint {
  const ReportFarmComparisonPoint({
    required this.farmName,
    required this.income,
    required this.expenses,
  });

  final String farmName;
  final double income;
  final double expenses;

  double get balance => income - expenses;
}

class ReportFinancialEvolutionCard extends StatelessWidget {
  const ReportFinancialEvolutionCard({required this.points, super.key});

  final List<ReportMonthlyPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const ReportChartEmptyState(
        icon: Icons.show_chart_outlined,
        title: 'Sem dados para evolução mensal',
        message:
            'Cadastre receitas e despesas com datas válidas para visualizar o histórico.',
      );
    }

    return ReportChartContainer(
      title: 'Evolução financeira',
      subtitle: 'Receitas, despesas e resultado ao longo do período.',
      child: Column(
        children: [
          const ReportChartLegend(
            items: [
              ReportChartLegendItem(
                label: 'Receitas',
                color: Color(0xFF1B5E20),
              ),
              ReportChartLegendItem(
                label: 'Despesas',
                color: Color(0xFFC62828),
              ),
              ReportChartLegendItem(
                label: 'Resultado',
                color: Color(0xFF1565C0),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: CustomPaint(
              painter: _FinancialEvolutionPainter(points: points),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportExpenseCategoryChart extends StatelessWidget {
  const ReportExpenseCategoryChart({required this.categories, super.key});

  final List<ReportCategoryPoint> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const ReportChartEmptyState(
        icon: Icons.pie_chart_outline,
        title: 'Sem despesas por categoria',
        message:
            'As categorias aparecerão aqui quando houver despesas no período.',
      );
    }

    final visibleCategories = categories.take(6).toList();

    final total = visibleCategories.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );

    return ReportChartContainer(
      title: 'Participação das despesas',
      subtitle: 'Distribuição das principais categorias no período.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final chart = SizedBox(
            width: compact ? double.infinity : 300,
            height: 280,
            child: CustomPaint(
              painter: _ExpenseDonutPainter(
                categories: visibleCategories,
                total: total,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatReportCurrency(total),
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          final legendContent = Column(
            children: List.generate(visibleCategories.length, (index) {
              final category = visibleCategories[index];
              final percentage = total == 0 ? 0 : category.value / total * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color:
                            reportChartColors[index % reportChartColors.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatReportCurrency(category.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1).replaceAll('.', ',')}%',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [chart, const SizedBox(height: 20), legendContent],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              chart,
              const SizedBox(width: 28),
              Expanded(child: legendContent),
            ],
          );
        },
      ),
    );
  }
}

class ReportFarmComparisonChart extends StatelessWidget {
  const ReportFarmComparisonChart({required this.farms, super.key});

  final List<ReportFarmComparisonPoint> farms;

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) {
      return const ReportChartEmptyState(
        icon: Icons.compare_arrows_outlined,
        title: 'Sem propriedades para comparar',
        message:
            'Selecione todas as propriedades ou cadastre dados financeiros.',
      );
    }

    final visibleFarms = farms.take(8).toList();

    return ReportChartContainer(
      title: 'Comparativo entre propriedades',
      subtitle: 'Receitas, despesas e resultado por fazenda.',
      child: Column(
        children: [
          const ReportChartLegend(
            items: [
              ReportChartLegendItem(
                label: 'Receitas',
                color: Color(0xFF1B5E20),
              ),
              ReportChartLegendItem(
                label: 'Despesas',
                color: Color(0xFFC62828),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: CustomPaint(
              painter: _FarmComparisonPainter(farms: visibleFarms),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportBalanceTrendCard extends StatelessWidget {
  const ReportBalanceTrendCard({required this.points, super.key});

  final List<ReportMonthlyPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const ReportChartEmptyState(
        icon: Icons.timeline_outlined,
        title: 'Sem histórico de resultado',
        message:
            'O resultado acumulado será exibido quando houver lançamentos.',
      );
    }

    double accumulated = 0;

    final accumulatedPoints = points.map((point) {
      accumulated += point.balance;

      return _AccumulatedPoint(label: point.label, value: accumulated);
    }).toList();

    return ReportChartContainer(
      title: 'Resultado acumulado',
      subtitle: 'Evolução do saldo ao longo do período.',
      child: SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _AccumulatedBalancePainter(points: accumulatedPoints),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class ReportChartContainer extends StatelessWidget {
  const ReportChartContainer({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}

class ReportChartLegend extends StatelessWidget {
  const ReportChartLegend({required this.items, super.key});

  final List<ReportChartLegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              item.label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ReportChartLegendItem {
  const ReportChartLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class ReportChartEmptyState extends StatelessWidget {
  const ReportChartEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 30),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(message, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Color> reportChartColors = [
  Color(0xFF1B5E20),
  Color(0xFF1565C0),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFC62828),
];

class _FinancialEvolutionPainter extends CustomPainter {
  const _FinancialEvolutionPainter({required this.points});

  final List<ReportMonthlyPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(58, 12, size.width - 76, size.height - 48);

    final values = <double>[
      ...points.map((point) => point.income),
      ...points.map((point) => point.expenses),
      ...points.map((point) => point.balance),
    ];

    var maxValue = values.fold<double>(
      0,
      (largest, value) => value.abs() > largest ? value.abs() : largest,
    );

    if (maxValue == 0) {
      maxValue = 1;
    }

    _drawGrid(canvas: canvas, rect: chartRect, maxValue: maxValue);

    final xStep = points.length <= 1
        ? chartRect.width
        : chartRect.width / (points.length - 1);

    final zeroY = chartRect.center.dy;

    Offset pointOffset(int index, double value) {
      final normalized = value / maxValue;

      return Offset(
        chartRect.left + index * xStep,
        zeroY - normalized * chartRect.height / 2,
      );
    }

    _drawLineSeries(
      canvas: canvas,
      points: List.generate(
        points.length,
        (index) => pointOffset(index, points[index].income),
      ),
      color: const Color(0xFF1B5E20),
    );

    _drawLineSeries(
      canvas: canvas,
      points: List.generate(
        points.length,
        (index) => pointOffset(index, points[index].expenses),
      ),
      color: const Color(0xFFC62828),
    );

    _drawLineSeries(
      canvas: canvas,
      points: List.generate(
        points.length,
        (index) => pointOffset(index, points[index].balance),
      ),
      color: const Color(0xFF1565C0),
    );

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index < points.length; index++) {
      final shouldDraw =
          points.length <= 8 ||
          index == 0 ||
          index == points.length - 1 ||
          index.isEven;

      if (!shouldDraw) {
        continue;
      }

      labelPainter.text = TextSpan(
        text: points[index].label,
        style: const TextStyle(color: Colors.black54, fontSize: 10),
      );

      labelPainter.layout(maxWidth: 70);

      labelPainter.paint(
        canvas,
        Offset(
          chartRect.left + index * xStep - labelPainter.width / 2,
          chartRect.bottom + 10,
        ),
      );
    }
  }

  void _drawGrid({
    required Canvas canvas,
    required Rect rect,
    required double maxValue,
  }) {
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.2;

    for (var index = 0; index <= 4; index++) {
      final y = rect.top + rect.height / 4 * index;

      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      axisPaint,
    );

    final labels = <double>[
      maxValue,
      maxValue / 2,
      0.0,
      -maxValue / 2,
      -maxValue,
    ];

    final painter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index < labels.length; index++) {
      painter.text = TextSpan(
        text: formatReportCompactCurrency(labels[index]),
        style: const TextStyle(color: Colors.black45, fontSize: 9),
      );

      painter.layout(maxWidth: 52);

      painter.paint(
        canvas,
        Offset(
          rect.left - painter.width - 8,
          rect.top + rect.height / 4 * index - painter.height / 2,
        ),
      );
    }
  }

  void _drawLineSeries({
    required Canvas canvas,
    required List<Offset> points,
    required Color color,
  }) {
    if (points.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialEvolutionPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _ExpenseDonutPainter extends CustomPainter {
  const _ExpenseDonutPainter({required this.categories, required this.total});

  final List<ReportCategoryPoint> categories;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final radius = math.min(size.width, size.height) * 0.34;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.38;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (total <= 0) {
      return;
    }

    var startAngle = -math.pi / 2;

    for (var index = 0; index < categories.length; index++) {
      final sweepAngle = categories[index].value / total * math.pi * 2;

      final paint = Paint()
        ..color = reportChartColors[index % reportChartColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.38
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ExpenseDonutPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.total != total;
  }
}

class _FarmComparisonPainter extends CustomPainter {
  const _FarmComparisonPainter({required this.farms});

  final List<ReportFarmComparisonPoint> farms;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(58, 12, size.width - 76, size.height - 66);

    var maxValue = farms.fold<double>(0, (largest, farm) {
      final farmLargest = math.max(farm.income, farm.expenses);

      return farmLargest > largest ? farmLargest : largest;
    });

    if (maxValue == 0) {
      maxValue = 1;
    }

    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final y = chartRect.top + chartRect.height / 4 * index;

      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final groupWidth = chartRect.width / farms.length;

    final barWidth = math.min(26.0, groupWidth * 0.26);

    final incomePaint = Paint()..color = const Color(0xFF1B5E20);

    final expensePaint = Paint()..color = const Color(0xFFC62828);

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var index = 0; index < farms.length; index++) {
      final farm = farms[index];

      final centerX = chartRect.left + groupWidth * index + groupWidth / 2;

      final incomeHeight = farm.income / maxValue * chartRect.height;

      final expenseHeight = farm.expenses / maxValue * chartRect.height;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth - 2,
            chartRect.bottom - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(4),
        ),
        incomePaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + 2,
            chartRect.bottom - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(4),
        ),
        expensePaint,
      );

      labelPainter.text = TextSpan(
        text: farm.farmName,
        style: const TextStyle(color: Colors.black54, fontSize: 9),
      );

      labelPainter.layout(maxWidth: groupWidth - 8);

      labelPainter.paint(
        canvas,
        Offset(centerX - labelPainter.width / 2, chartRect.bottom + 10),
      );
    }

    final valuePainter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index <= 4; index++) {
      final value = maxValue - maxValue / 4 * index;

      valuePainter.text = TextSpan(
        text: formatReportCompactCurrency(value),
        style: const TextStyle(color: Colors.black45, fontSize: 9),
      );

      valuePainter.layout(maxWidth: 52);

      valuePainter.paint(
        canvas,
        Offset(
          chartRect.left - valuePainter.width - 8,
          chartRect.top +
              chartRect.height / 4 * index -
              valuePainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FarmComparisonPainter oldDelegate) {
    return oldDelegate.farms != farms;
  }
}

class _AccumulatedPoint {
  const _AccumulatedPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _AccumulatedBalancePainter extends CustomPainter {
  const _AccumulatedBalancePainter({required this.points});

  final List<_AccumulatedPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(58, 12, size.width - 76, size.height - 48);

    var maxValue = points.fold<double>(
      0,
      (largest, point) =>
          point.value.abs() > largest ? point.value.abs() : largest,
    );

    if (maxValue == 0) {
      maxValue = 1;
    }

    final zeroY = chartRect.center.dy;

    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final y = chartRect.top + chartRect.height / 4 * index;

      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(chartRect.left, zeroY),
      Offset(chartRect.right, zeroY),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1.2,
    );

    final xStep = points.length <= 1
        ? chartRect.width
        : chartRect.width / (points.length - 1);

    final offsets = List.generate(points.length, (index) {
      final normalized = points[index].value / maxValue;

      return Offset(
        chartRect.left + xStep * index,
        zeroY - normalized * chartRect.height / 2,
      );
    });

    if (offsets.isNotEmpty) {
      final areaPath = Path()
        ..moveTo(offsets.first.dx, zeroY)
        ..lineTo(offsets.first.dx, offsets.first.dy);

      for (final point in offsets.skip(1)) {
        areaPath.lineTo(point.dx, point.dy);
      }

      areaPath
        ..lineTo(offsets.last.dx, zeroY)
        ..close();

      canvas.drawPath(
        areaPath,
        Paint()
          ..color = const Color(0xFF1565C0).withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );

      final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);

      for (final point in offsets.skip(1)) {
        linePath.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(
        linePath,
        Paint()
          ..color = const Color(0xFF1565C0)
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      for (final point in offsets) {
        canvas.drawCircle(point, 3.5, Paint()..color = const Color(0xFF1565C0));
      }
    }

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index < points.length; index++) {
      final shouldDraw =
          points.length <= 8 ||
          index == 0 ||
          index == points.length - 1 ||
          index.isEven;

      if (!shouldDraw) {
        continue;
      }

      labelPainter.text = TextSpan(
        text: points[index].label,
        style: const TextStyle(color: Colors.black54, fontSize: 10),
      );

      labelPainter.layout(maxWidth: 70);

      labelPainter.paint(
        canvas,
        Offset(
          chartRect.left + xStep * index - labelPainter.width / 2,
          chartRect.bottom + 10,
        ),
      );
    }

    final valuePainter = TextPainter(textDirection: TextDirection.ltr);

    final labels = <double>[
      maxValue,
      maxValue / 2,
      0.0,
      -maxValue / 2,
      -maxValue,
    ];

    for (var index = 0; index < labels.length; index++) {
      valuePainter.text = TextSpan(
        text: formatReportCompactCurrency(labels[index]),
        style: const TextStyle(color: Colors.black45, fontSize: 9),
      );

      valuePainter.layout(maxWidth: 52);

      valuePainter.paint(
        canvas,
        Offset(
          chartRect.left - valuePainter.width - 8,
          chartRect.top +
              chartRect.height / 4 * index -
              valuePainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AccumulatedBalancePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

String formatReportCurrency(double value) {
  final negative = value < 0;
  final absolute = value.abs();

  final parts = absolute.toStringAsFixed(2).split('.');

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

String formatReportCompactCurrency(double value) {
  final negative = value < 0;
  final absolute = value.abs();

  String formatted;

  if (absolute >= 1000000) {
    formatted =
        'R\$ ${(absolute / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
  } else if (absolute >= 1000) {
    formatted =
        'R\$ ${(absolute / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  } else {
    formatted = 'R\$ ${absolute.toStringAsFixed(0)}';
  }

  return negative ? '-$formatted' : formatted;
}
