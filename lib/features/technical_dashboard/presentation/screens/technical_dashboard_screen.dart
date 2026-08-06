import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/widgets/atlas_command_center_module_card.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_analysis.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_period.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_financial_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/services/technical_dashboard_service.dart';

class TechnicalDashboardScreen extends StatefulWidget {
  const TechnicalDashboardScreen({super.key});

  @override
  State<TechnicalDashboardScreen> createState() =>
      _TechnicalDashboardScreenState();
}

class _TechnicalDashboardScreenState extends State<TechnicalDashboardScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final TechnicalDashboardService dashboardService =
      TechnicalDashboardService();

  List<FarmData> farms = const [];
  FarmData? selectedFarm;
  TechnicalDashboardAnalysis? analysis;
  TechnicalDashboardPeriod selectedPeriod = TechnicalDashboardPeriod.last30Days;
  bool isLoading = true;
  bool isRefreshingAnalysis = false;
  bool analysisReloadRequested = false;
  Timer? analysisReloadDebounce;
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;
  late final String reactiveRegistrationId;

  @override
  void initState() {
    super.initState();

    AtlasReactiveRuntime.instance.start();

    reactiveRegistrationId = reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.technicalDashboard,
      owner: 'technical_dashboard_screen',
      handler: handleReactiveUpdate,
    );

    unawaited(loadFarms());
  }

  @override
  void dispose() {
    analysisReloadDebounce?.cancel();
    reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.technicalDashboard,
      registrationId: reactiveRegistrationId,
    );
    super.dispose();
  }

  Future<void> handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.technicalDashboard)) {
      return;
    }

    final farm = selectedFarm;

    if (farm == null) {
      return;
    }

    final hasRelevantEvent = update.events.any((event) {
      final eventFarmName = event.farmName?.trim();
      return eventFarmName == null ||
          eventFarmName.isEmpty ||
          eventFarmName == farm.name;
    });

    if (!hasRelevantEvent) {
      return;
    }

    scheduleAnalysisReload();
  }

  void scheduleAnalysisReload() {
    analysisReloadDebounce?.cancel();
    analysisReloadDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(loadSummary(showLoading: false));
    });
  }

  Future<void> loadFarms() async {
    setState(() => isLoading = true);
    final loadedFarms = await farmStorage.loadFarms();
    final currentName = selectedFarm?.name;
    FarmData? nextFarm;
    for (final farm in loadedFarms) {
      if (farm.name == currentName) {
        nextFarm = farm;
        break;
      }
    }
    nextFarm ??= loadedFarms.isEmpty ? null : loadedFarms.first;
    if (!mounted) return;
    setState(() {
      farms = loadedFarms;
      selectedFarm = nextFarm;
    });
    await loadSummary();
  }

  Future<void> loadSummary({bool showLoading = true}) async {
    final farm = selectedFarm;
    if (farm == null) {
      if (!mounted) return;
      setState(() {
        analysis = null;
        isLoading = false;
      });
      return;
    }

    if (isRefreshingAnalysis) {
      analysisReloadRequested = true;
      return;
    }

    isRefreshingAnalysis = true;

    if (showLoading && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final loadedAnalysis = await dashboardService.loadAnalysis(
        farm,
        period: selectedPeriod,
      );
      if (!mounted) return;
      setState(() {
        analysis = loadedAnalysis;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar o painel: $error')),
      );
    } finally {
      isRefreshingAnalysis = false;

      if (analysisReloadRequested && mounted) {
        analysisReloadRequested = false;
        unawaited(loadSummary(showLoading: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Painel Técnico Integrado'),
        actions: [
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: isLoading ? null : loadSummary,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadFarms,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visão técnica da fazenda',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Indicadores reais de rebanho, reprodução, sanidade, nutrição, financeiro e estoque.',
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      _FarmSelector(
                        farms: farms,
                        selectedFarm: selectedFarm,
                        onChanged: isLoading
                            ? null
                            : (farm) async {
                                setState(() => selectedFarm = farm);
                                await loadSummary();
                              },
                      ),
                      const SizedBox(height: 16),
                      _PeriodSelector(
                        selectedPeriod: selectedPeriod,
                        enabled: !isLoading,
                        onSelected: (period) async {
                          if (period == selectedPeriod) return;
                          setState(() => selectedPeriod = period);
                          await loadSummary();
                        },
                      ),
                      const SizedBox(height: 18),
                      AtlasCommandCenterModuleCard(
                        module:
                            AtlasCommandCenterModule.technicalDashboard,
                        farmName: selectedFarm?.name,
                      ),
                      const SizedBox(height: 24),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (analysis == null)
                        const _EmptyDashboard()
                      else
                        _SummaryContent(analysis: analysis!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmSelector extends StatelessWidget {
  const _FarmSelector({
    required this.farms,
    required this.selectedFarm,
    required this.onChanged,
  });

  final List<FarmData> farms;
  final FarmData? selectedFarm;
  final ValueChanged<FarmData?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<FarmData>(
          initialValue: selectedFarm,
          decoration: const InputDecoration(
            labelText: 'Fazenda analisada',
            prefixIcon: Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(),
          ),
          items: farms
              .map(
                (farm) => DropdownMenuItem<FarmData>(
                  value: farm,
                  child: Text('${farm.name} • ${farm.city} - ${farm.state}'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.enabled,
    required this.onSelected,
  });

  final TechnicalDashboardPeriod selectedPeriod;
  final bool enabled;
  final ValueChanged<TechnicalDashboardPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.date_range_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Text(
                  'Período analisado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TechnicalDashboardPeriod.values.map((period) {
                return ChoiceChip(
                  label: Text(period.label),
                  selected: selectedPeriod == period,
                  onSelected: enabled ? (_) => onSelected(period) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonPanel extends StatelessWidget {
  const _ComparisonPanel({required this.analysis});

  final TechnicalDashboardAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final previous = analysis.previous;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows_outlined,
                  color: Color(0xFF1B5E20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysis.hasComparison
                        ? 'Comparação com o período anterior'
                        : 'Visão consolidada de todo o histórico',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              analysis.hasComparison
                  ? 'As variações abaixo comparam períodos de mesma duração.'
                  : 'Selecione um período para visualizar variações automáticas.',
              style: const TextStyle(color: Colors.black54),
            ),
            if (previous != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _VariationBadge(
                    label: 'Receitas',
                    value: analysis.incomeVariationPercent,
                    positiveIsGood: true,
                  ),
                  _VariationBadge(
                    label: 'Despesas',
                    value: analysis.expenseVariationPercent,
                    positiveIsGood: false,
                  ),
                  _VariationBadge(
                    label: 'Saldo',
                    value: analysis.balanceVariationPercent,
                    positiveIsGood: true,
                  ),
                  _VariationBadge(
                    label: 'Registros sanitários',
                    value: analysis.healthRecordVariationPercent,
                    positiveIsGood: null,
                  ),
                  _VariationBadge(
                    label: 'Registros reprodutivos',
                    value: analysis.reproductionRecordVariationPercent,
                    positiveIsGood: null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VariationBadge extends StatelessWidget {
  const _VariationBadge({
    required this.label,
    required this.value,
    required this.positiveIsGood,
  });

  final String label;
  final double? value;
  final bool? positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final variation = value;
    final isPositive = variation != null && variation > 0;
    final isNegative = variation != null && variation < 0;
    final icon = isPositive
        ? Icons.trending_up
        : isNegative
        ? Icons.trending_down
        : Icons.trending_flat;

    Color foreground = Colors.blueGrey.shade700;
    Color background = Colors.blueGrey.shade50;
    if (positiveIsGood != null && variation != null && variation != 0) {
      final isGood = positiveIsGood! ? isPositive : isNegative;
      foreground = isGood ? Colors.green.shade800 : Colors.red.shade800;
      background = isGood ? Colors.green.shade50 : Colors.red.shade50;
    }

    final text = variation == null
        ? 'Sem base anterior'
        : '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(1)}%';

    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: foreground),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.analysis});

  final TechnicalDashboardAnalysis analysis;

  TechnicalFarmSummary get summary => analysis.current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComparisonPanel(analysis: analysis),
        const SizedBox(height: 18),
        _FinancialEvolutionCard(points: analysis.financialSeries),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MainIndicator(
              label: 'Animais ativos',
              value: summary.activeAnimals.toString(),
              icon: Icons.pets_outlined,
            ),
            _MainIndicator(
              label: 'Saldo financeiro',
              value: _money(summary.balance),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _MainIndicator(
              label: 'Valor em estoque',
              value: _money(summary.inventoryValue),
              icon: Icons.inventory_2_outlined,
            ),
            _MainIndicator(
              label: 'Alertas técnicos',
              value: summary.totalAlerts.toString(),
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth = width >= 1000
                ? (width - 32) / 3
                : width >= 650
                ? (width - 16) / 2
                : width;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ModuleCard(
                  width: cardWidth,
                  title: 'Rebanho',
                  icon: Icons.groups_outlined,
                  metrics: [
                    ('Animais cadastrados', '${summary.totalAnimals}'),
                    ('Animais ativos', '${summary.activeAnimals}'),
                    ('Animais vendidos', '${summary.soldAnimals}'),
                    ('Lotes', '${summary.groupCount}'),
                    (
                      'Peso médio',
                      '${summary.averageWeight.toStringAsFixed(0)} kg',
                    ),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Reprodução',
                  icon: Icons.favorite_outline,
                  metrics: [
                    ('Registros', '${summary.reproductionRecords}'),
                    ('Prenhezes confirmadas', '${summary.positivePregnancies}'),
                    (
                      'Eventos pendentes',
                      '${summary.pendingReproductionEvents}',
                    ),
                    (
                      'Eventos atrasados',
                      '${summary.overdueReproductionEvents}',
                    ),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Sanidade',
                  icon: Icons.health_and_safety_outlined,
                  metrics: [
                    ('Registros sanitários', '${summary.healthRecords}'),
                    ('Retornos atrasados', '${summary.overdueHealthReturns}'),
                    ('Carências ativas', '${summary.activeWithdrawals}'),
                    ('Quarentenas', '${summary.quarantines}'),
                    ('Custo sanitário', _money(summary.healthCost)),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Nutrição',
                  icon: Icons.grass_outlined,
                  metrics: [
                    ('Dietas cadastradas', '${summary.nutritionPlans}'),
                    ('Animais atendidos', '${summary.nutritionAnimals}'),
                    (
                      'Consumo diário',
                      '${summary.dailyFeedKg.toStringAsFixed(1)} kg',
                    ),
                    ('Custo diário', _money(summary.dailyFeedCost)),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Financeiro',
                  icon: Icons.payments_outlined,
                  metrics: [
                    ('Receitas', _money(summary.income)),
                    ('Despesas', _money(summary.expenses)),
                    ('Saldo', _money(summary.balance)),
                    ('Contas vencidas', '${summary.overdueAccounts}'),
                    ('Custo por animal', _money(summary.costPerActiveAnimal)),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Estoque',
                  icon: Icons.inventory_outlined,
                  metrics: [
                    ('Produtos', '${summary.inventoryItems}'),
                    ('Valor armazenado', _money(summary.inventoryValue)),
                    ('Abaixo do mínimo', '${summary.lowStockItems}'),
                    ('Sem saldo', '${summary.outOfStockItems}'),
                    ('Movimentações', '${summary.inventoryMovements}'),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FinancialEvolutionCard extends StatelessWidget {
  const _FinancialEvolutionCard({required this.points});

  final List<TechnicalFinancialSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final hasValues = points.any(
      (point) => point.income != 0 || point.expenses != 0,
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evolução financeira mensal',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Receitas, despesas e saldo dos meses mais recentes.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _ChartLegend(label: 'Receitas', color: Color(0xFF2E7D32)),
                _ChartLegend(label: 'Despesas', color: Color(0xFFC62828)),
                _ChartLegend(label: 'Saldo', color: Color(0xFF1565C0)),
              ],
            ),
            const SizedBox(height: 18),
            if (!hasValues)
              const SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'Cadastre receitas ou despesas para gerar o gráfico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = constraints.maxWidth < 560
                        ? 560.0
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: CustomPaint(
                          painter: _FinancialChartPainter(points),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _FinancialChartPainter extends CustomPainter {
  const _FinancialChartPainter(this.points);

  final List<TechnicalFinancialSeriesPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 62.0;
    const right = 18.0;
    const top = 14.0;
    const bottom = 48.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    if (chartWidth <= 0 || chartHeight <= 0 || points.isEmpty) return;

    var maximum = 0.0;
    for (final point in points) {
      maximum = [
        maximum,
        point.income.abs(),
        point.expenses.abs(),
        point.balance.abs(),
      ].reduce((a, b) => a > b ? a : b);
    }
    if (maximum == 0) maximum = 1;
    maximum *= 1.15;

    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.2;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final value = maximum * (1 - i / 4);
      _drawText(
        canvas,
        _compactMoney(value),
        Offset(0, y - 7),
        const TextStyle(fontSize: 10, color: Colors.black54),
        maxWidth: left - 8,
        align: TextAlign.right,
      );
    }

    final zeroY = top + chartHeight;
    canvas.drawLine(
      Offset(left, zeroY),
      Offset(size.width - right, zeroY),
      axisPaint,
    );

    final groupWidth = chartWidth / points.length;
    final barWidth = (groupWidth * 0.24).clamp(8.0, 24.0).toDouble();
    final incomePaint = Paint()..color = const Color(0xFF2E7D32);
    final expensePaint = Paint()..color = const Color(0xFFC62828);
    final balancePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFF1565C0);
    final balancePath = Path();

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final centerX = left + groupWidth * (index + 0.5);
      final incomeHeight = chartHeight * point.income / maximum;
      final expenseHeight = chartHeight * point.expenses / maximum;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth - 2,
            zeroY - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(3),
        ),
        incomePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + 2,
            zeroY - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(3),
        ),
        expensePaint,
      );

      final normalizedBalance = point.balance.clamp(0, maximum).toDouble();
      final balanceY = zeroY - chartHeight * normalizedBalance / maximum;
      if (index == 0) {
        balancePath.moveTo(centerX, balanceY);
      } else {
        balancePath.lineTo(centerX, balanceY);
      }
      canvas.drawCircle(Offset(centerX, balanceY), 3.5, pointPaint);

      _drawText(
        canvas,
        point.label,
        Offset(centerX - groupWidth / 2, zeroY + 10),
        const TextStyle(fontSize: 10, color: Colors.black54),
        maxWidth: groupWidth,
        align: TextAlign.center,
      );
    }

    canvas.drawPath(balancePath, balancePaint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)} mi';
    }
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)} mil';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(covariant _FinancialChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _MainIndicator extends StatelessWidget {
  const _MainIndicator({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.metrics,
  });

  final double width;
  final String title;
  final IconData icon;
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1B5E20)),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...metrics.map(
                (metric) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          metric.$1,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        metric.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.home_work_outlined, size: 54, color: Colors.black38),
              SizedBox(height: 14),
              Text(
                'Cadastre uma fazenda para gerar o painel técnico.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(double value) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
}
