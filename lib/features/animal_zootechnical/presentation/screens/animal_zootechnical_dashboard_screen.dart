import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_zootechnical/data/services/animal_zootechnical_dashboard_service.dart';
import 'package:projeto_atlas/features/animal_zootechnical/domain/models/animal_zootechnical_dashboard_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalZootechnicalDashboardScreen extends StatefulWidget {
  const AnimalZootechnicalDashboardScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalZootechnicalDashboardScreen> createState() =>
      _AnimalZootechnicalDashboardScreenState();
}

class _AnimalZootechnicalDashboardScreenState
    extends State<AnimalZootechnicalDashboardScreen> {
  final AnimalZootechnicalDashboardService service =
      AnimalZootechnicalDashboardService();

  AnimalZootechnicalDashboardData? data;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await service.build(
        animal: widget.animal,
        farm: widget.farm,
        group: widget.group,
      );

      if (!mounted) return;

      setState(() {
        data = result;
        isLoading = false;
      });
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Falha ao gerar painel zootécnico: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard zootécnico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: buildBody(),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: loadDashboard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final dashboard = data!;

    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _DashboardHeader(
            animal: widget.animal,
            farm: widget.farm,
            group: widget.group,
            data: dashboard,
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Indicadores individuais',
            subtitle:
                'Desempenho atual, tendência e posição dentro do lote.',
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _MetricCard(
                title: 'Peso atual',
                value: '${_weight(dashboard.currentWeight)} kg',
                subtitle: dashboard.previousWeight == null
                    ? 'Sem pesagem anterior'
                    : '${_signed(dashboard.weightVariation)} kg desde a última pesagem',
                icon: Icons.monitor_weight_outlined,
              ),
              _MetricCard(
                title: 'GMD',
                value: dashboard.averageDailyGain == null
                    ? 'Dados insuficientes'
                    : '${_signed(dashboard.averageDailyGain)} kg/dia',
                subtitle: dashboard.trend,
                icon: Icons.trending_up_outlined,
              ),
              _MetricCard(
                title: 'Ranking no lote',
                value: dashboard.rankText,
                subtitle: dashboard.percentileText,
                icon: Icons.emoji_events_outlined,
              ),
              _MetricCard(
                title: 'Média do lote',
                value: '${_weight(dashboard.groupAverageWeight)} kg',
                subtitle:
                    'Mediana: ${_weight(dashboard.groupMedianWeight)} kg',
                icon: Icons.groups_outlined,
              ),
              _MetricCard(
                title: 'Consistência',
                value:
                    '${dashboard.consistencyScore.toStringAsFixed(0)}%',
                subtitle: 'Regularidade do ganho de peso',
                icon: Icons.insights_outlined,
              ),
              _MetricCard(
                title: 'Qualidade dos dados',
                value: dashboard.dataQuality,
                subtitle:
                    '${dashboard.weightHistory.length} pesagens disponíveis',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Curva de crescimento',
            subtitle:
                'Evolução histórica do peso e leitura visual da tendência.',
          ),
          const SizedBox(height: 15),
          _WeightChartCard(weights: dashboard.weightHistory),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Projeção de peso',
            subtitle:
                'Estimativa linear baseada no ganho médio diário disponível.',
          ),
          const SizedBox(height: 15),
          _ProjectionPanel(data: dashboard),
          const SizedBox(height: 24),
          _TechnicalInterpretation(data: dashboard),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.animal,
    required this.farm,
    required this.group,
    required this.data,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AnimalZootechnicalDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 22,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor:
                  const Color(0xFF1B5E20).withValues(alpha: 0.10),
              child: const Icon(
                Icons.analytics_outlined,
                size: 35,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(
              width: 390,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.displayName,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brinco ${animal.tag} • ${farm.name} • ${group.name}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.speed_outlined, size: 18),
              label: Text(data.trend),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(0xFF1B5E20).withValues(alpha: 0.10),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
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

class _WeightChartCard extends StatelessWidget {
  const _WeightChartCard({
    required this.weights,
  });

  final List<AnimalWeightData> weights;

  @override
  Widget build(BuildContext context) {
    if (weights.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: 50,
                color: Color(0xFF1B5E20),
              ),
              SizedBox(height: 12),
              Text(
                'Cadastre pelo menos duas pesagens',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'A curva de crescimento será exibida quando houver histórico suficiente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: SizedBox(
          height: 310,
          child: CustomPaint(
            painter: _WeightChartPainter(weights),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.weights);

  final List<AnimalWeightData> weights;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 54.0;
    const right = 20.0;
    const top = 20.0;
    const bottom = 42.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final values = weights.map((item) => item.weight).toList();
    var minWeight = values.reduce(math.min);
    var maxWeight = values.reduce(math.max);

    if ((maxWeight - minWeight).abs() < 1) {
      minWeight -= 5;
      maxWeight += 5;
    } else {
      final margin = (maxWeight - minWeight) * 0.12;
      minWeight -= margin;
      maxWeight += margin;
    }

    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1.2;

    final linePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.fill;

    for (var index = 0; index <= 4; index++) {
      final y = top + chartHeight * index / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(left + chartWidth, y),
        gridPaint,
      );

      final value = maxWeight -
          (maxWeight - minWeight) * index / 4;

      _drawText(
        canvas,
        '${value.toStringAsFixed(0)} kg',
        Offset(0, y - 8),
        const TextStyle(
          fontSize: 11,
          color: Colors.black54,
        ),
      );
    }

    canvas.drawLine(
      const Offset(left, top),
      Offset(left, top + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(left + chartWidth, top + chartHeight),
      axisPaint,
    );

    final path = Path();

    for (var index = 0; index < weights.length; index++) {
      final x = weights.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (weights.length - 1);
      final normalized =
          (weights[index].weight - minWeight) /
              (maxWeight - minWeight);
      final y = top + chartHeight * (1 - normalized);

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      if (weights.length <= 8 || index.isEven || index == weights.length - 1) {
        _drawText(
          canvas,
          weights[index].date,
          Offset(x - 28, top + chartHeight + 10),
          const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        );
      }
    }

    canvas.drawPath(path, linePaint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.weights != weights;
  }
}

class _ProjectionPanel extends StatelessWidget {
  const _ProjectionPanel({
    required this.data,
  });

  final AnimalZootechnicalDashboardData data;

  @override
  Widget build(BuildContext context) {
    if (!data.hasGrowthData) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.query_stats_outlined),
          title: Text('Projeção indisponível'),
          subtitle: Text(
            'São necessárias pelo menos duas pesagens em datas diferentes.',
          ),
        ),
      );
    }

    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        _ProjectionCard(
          period: '30 dias',
          value: data.projectedWeight30Days!,
        ),
        _ProjectionCard(
          period: '60 dias',
          value: data.projectedWeight60Days!,
        ),
        _ProjectionCard(
          period: '90 dias',
          value: data.projectedWeight90Days!,
        ),
      ],
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.period,
    required this.value,
  });

  final String period;
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.auto_graph_outlined,
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(height: 8),
              Text(
                period,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Text(
                '${_weight(value)} kg',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnicalInterpretation extends StatelessWidget {
  const _TechnicalInterpretation({
    required this.data,
  });

  final AnimalZootechnicalDashboardData data;

  @override
  Widget build(BuildContext context) {
    final observations = <String>[];

    if (data.averageDailyGain == null) {
      observations.add(
        'Registre novas pesagens para calcular o ganho médio diário e as projeções.',
      );
    } else if (data.averageDailyGain! < 0) {
      observations.add(
        'Há perda de peso no período analisado. Revise sanidade, consumo, lote e manejo.',
      );
    } else if (data.averageDailyGain! < 0.10) {
      observations.add(
        'O ganho de peso é baixo. Compare dieta, disponibilidade de pasto e condição sanitária.',
      );
    } else {
      observations.add(
        'O animal apresenta tendência positiva de ganho de peso.',
      );
    }

    if (data.groupRank > 0 && data.groupSize > 1) {
      if (data.percentile >= 75) {
        observations.add(
          'O animal está entre os melhores pesos do lote.',
        );
      } else if (data.percentile <= 25) {
        observations.add(
          'O animal está entre os menores pesos do lote e merece acompanhamento.',
        );
      }
    }

    if (data.weightHistory.length < 4) {
      observations.add(
        'A confiabilidade aumentará após pelo menos quatro pesagens.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.psychology_alt_outlined,
                  color: Color(0xFF1B5E20),
                ),
                SizedBox(width: 10),
                Text(
                  'Interpretação técnica',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...observations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 17,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'As projeções são lineares e servem como apoio à decisão, não como garantia de desempenho.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _weight(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _signed(double? value) {
  if (value == null) return '0';
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(3).replaceAll('.', ',')}';
}
