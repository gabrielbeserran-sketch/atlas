import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/predictive/domain/models/atlas_predictive_scenario.dart';
import 'package:projeto_atlas/features/predictive/data/services/atlas_predictive_scenario_storage_service.dart';
import 'package:projeto_atlas/features/predictive/domain/services/atlas_predictive_service.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasPredictiveScreen extends StatefulWidget {
  const AtlasPredictiveScreen({
    required this.diagnostic,
    required this.farmIntelligence,
    this.onOpenArea,
    super.key,
  });

  final AtlasDiagnosticData diagnostic;
  final AtlasFarmIntelligenceData farmIntelligence;

  final ValueChanged<AtlasFarmAnalysisArea>? onOpenArea;

  @override
  State<AtlasPredictiveScreen> createState() {
    return _AtlasPredictiveScreenState();
  }
}

class _AtlasPredictiveScreenState extends State<AtlasPredictiveScreen> {
  final AtlasPredictiveService service = const AtlasPredictiveService();

  final AtlasPredictiveScenarioStorageService storage =
      const AtlasPredictiveScenarioStorageService();

  bool isLoadingScenarios = true;

  late List<AtlasPredictiveScenarioRequest> requests;

  final List<AtlasPredictiveScenarioRequest> customRequests = [];

  late AtlasPredictiveScenarioRanking ranking;

  AtlasPredictiveScenarioResult? selectedResult;

  @override
  void initState() {
    super.initState();
    _initializeScenarios();
  }

  Future<void> _initializeScenarios() async {
    final saved = await storage.load(farmName: widget.diagnostic.scopeLabel);

    if (!mounted) {
      return;
    }

    customRequests
      ..clear()
      ..addAll(saved);

    _generateScenarios();

    setState(() {
      isLoadingScenarios = false;
    });
  }

  Future<void> _saveCustomScenarios() {
    return storage.save(
      farmName: widget.diagnostic.scopeLabel,
      scenarios: customRequests,
    );
  }

  void _generateScenarios() {
    requests = [
      ...service.buildRecommendedScenarios(
        diagnostic: widget.diagnostic,
        farm: widget.farmIntelligence,
      ),
      ...customRequests,
    ];

    ranking = service.compareScenarios(
      diagnostic: widget.diagnostic,
      farm: widget.farmIntelligence,
      requests: requests,
    );

    selectedResult = ranking.bestScenario;
  }

  void _selectScenario(AtlasPredictiveScenarioResult result) {
    setState(() {
      selectedResult = result;
    });
  }

  void _openArea(AtlasFarmAnalysisArea area) {
    final callback = widget.onOpenArea;

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A área "${atlasFarmAreaLabel(area)}" ainda não foi conectada.',
          ),
        ),
      );
      return;
    }

    callback(area);
  }

  Future<void> _openCustomScenarioDialog() async {
    final request = await showDialog<AtlasPredictiveScenarioRequest>(
      context: context,
      builder: (dialogContext) {
        return const _CustomScenarioDialog();
      },
    );

    if (request == null) {
      return;
    }

    setState(() {
      customRequests.add(request);
      _generateScenarios();

      final generated = ranking.results.where((result) {
        return result.request == request ||
            (result.request.title == request.title &&
                result.request.type == request.type);
      }).toList();

      if (generated.isNotEmpty) {
        selectedResult = generated.first;
      }
    });

    await _saveCustomScenarios();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cenário personalizado criado e comparado.'),
        ),
      );
  }

  Future<void> _removeCustomScenario(
    AtlasPredictiveScenarioResult result,
  ) async {
    final index = customRequests.indexWhere((request) {
      return request.title == result.request.title &&
          request.type == result.request.type &&
          request.changePercent == result.request.changePercent &&
          request.investmentValue == result.request.investmentValue &&
          request.executionDays == result.request.executionDays;
    });

    if (index < 0) {
      return;
    }

    setState(() {
      customRequests.removeAt(index);
      _generateScenarios();
    });

    await _saveCustomScenarios();
  }

  bool _isCustomScenario(AtlasPredictiveScenarioResult result) {
    return customRequests.any((request) {
      return request.title == result.request.title &&
          request.type == result.request.type &&
          request.changePercent == result.request.changePercent &&
          request.investmentValue == result.request.investmentValue &&
          request.executionDays == result.request.executionDays;
    });
  }

  Future<void> _clearCustomScenarios() async {
    if (customRequests.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar cenários personalizados?'),
          content: const Text(
            'Todos os cenários personalizados desta fazenda serão removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    customRequests.clear();

    await storage.clear(farmName: widget.diagnostic.scopeLabel);

    if (!mounted) {
      return;
    }

    setState(_generateScenarios);
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedResult;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inteligência Preditiva',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              widget.diagnostic.scopeLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Novo cenário',
            onPressed: _openCustomScenarioDialog,
            icon: const Icon(Icons.add_chart_outlined),
          ),
          IconButton(
            tooltip: 'Apagar cenários personalizados',
            onPressed: customRequests.isEmpty ? null : _clearCustomScenarios,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(
            tooltip: 'Recalcular cenários',
            onPressed: isLoadingScenarios
                ? null
                : () {
                    setState(_generateScenarios);
                  },
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const Material(
            color: Color(0xFFFFF7E6),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Avançado em validação: cenários personalizados ainda são salvos somente neste dispositivo e não alteram os cadastros oficiais da fazenda.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoadingScenarios
          ? const _PredictiveLoadingView()
          : requests.isEmpty
          ? const _EmptyPredictiveView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _PredictiveHero(ranking: ranking),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Cenários recomendados',
                        subtitle:
                            'Selecione um cenário para analisar as projeções.',
                      ),
                      const SizedBox(height: 14),
                      _ScenarioSelector(
                        results: ranking.results,
                        selected: selected,
                        onSelected: _selectScenario,
                        isCustom: _isCustomScenario,
                        onRemoveCustom: _removeCustomScenario,
                        onCreateCustom: _openCustomScenarioDialog,
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 28),
                        _ScenarioSummaryCard(result: selected),
                        const SizedBox(height: 28),
                        const _SectionTitle(
                          title: 'Projeções',
                          subtitle:
                              'Comparação entre cenário conservador, provável e otimista.',
                        ),
                        const SizedBox(height: 14),
                        _ProjectionGrid(projections: selected.projections),
                        const SizedBox(height: 28),
                        const _SectionTitle(
                          title: 'Impacto financeiro',
                          subtitle:
                              'Estimativa de retorno e investimento do cenário.',
                        ),
                        const SizedBox(height: 14),
                        _FinancialImpactCard(impact: selected.financialImpact),
                        const SizedBox(height: 28),
                        const _SectionTitle(
                          title: 'Plano de execução',
                          subtitle:
                              'Etapas recomendadas para colocar o cenário em prática.',
                        ),
                        const SizedBox(height: 14),
                        _PredictiveActionList(
                          actions: selected.actions,
                          onOpenArea: _openArea,
                        ),
                        const SizedBox(height: 34),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictiveHero extends StatelessWidget {
  const _PredictiveHero({required this.ranking});

  final AtlasPredictiveScenarioRanking ranking;

  @override
  Widget build(BuildContext context) {
    final best = ranking.bestScenario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A43), Color(0xFF243B53), Color(0xFF334E68)],
        ),
        borderRadius: BorderRadius.circular(26),
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
                    Icons.auto_graph_outlined,
                    color: Color(0xFFC8A951),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Simulação de decisões',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                ranking.summary,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              if (best != null) ...[
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Melhor decisão: ${best.request.title}',
                    style: const TextStyle(
                      color: Color(0xFFC8A951),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          );

          final score = best == null
              ? const SizedBox.shrink()
              : Container(
                  width: 220,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFC8A951).withValues(alpha: 0.42),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Impacto × esforço',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        best.impactEffortScore.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Color(0xFFC8A951),
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${best.scoreVariation >= 0 ? '+' : ''}'
                        '${best.scoreVariation.toStringAsFixed(1)} pontos no score',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                information,
                if (best != null) ...[const SizedBox(height: 20), score],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              if (best != null) ...[const SizedBox(width: 25), score],
            ],
          );
        },
      ),
    );
  }
}

class _ScenarioSelector extends StatelessWidget {
  const _ScenarioSelector({
    required this.results,
    required this.selected,
    required this.onSelected,
    required this.isCustom,
    required this.onRemoveCustom,
    required this.onCreateCustom,
  });

  final List<AtlasPredictiveScenarioResult> results;

  final AtlasPredictiveScenarioResult? selected;

  final ValueChanged<AtlasPredictiveScenarioResult> onSelected;

  final bool Function(AtlasPredictiveScenarioResult result) isCustom;

  final ValueChanged<AtlasPredictiveScenarioResult> onRemoveCustom;

  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        final cards = results.map((result) {
          final isSelected = selected?.request.title == result.request.title;

          final custom = isCustom(result);

          final color = predictiveResultColor(result);

          return SizedBox(
            width: width,
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: isSelected ? 4 : 1,
              child: InkWell(
                onTap: () {
                  onSelected(result);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            predictiveScenarioIcon(result.request.type),
                            color: color,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              result.request.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (custom)
                            IconButton(
                              tooltip: 'Excluir cenário',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                onRemoveCustom(result);
                              },
                              icon: const Icon(Icons.delete_outline, size: 19),
                            )
                          else if (isSelected)
                            Icon(Icons.check_circle, color: color),
                        ],
                      ),
                      if (custom) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'Cenário personalizado',
                          style: TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 11),
                      Text(
                        result.request.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SmallMetricChip(
                            label: 'Score',
                            value:
                                '${result.scoreVariation >= 0 ? '+' : ''}'
                                '${result.scoreVariation.toStringAsFixed(1)}',
                            color: color,
                          ),
                          _SmallMetricChip(
                            label: 'Risco',
                            value:
                                '-${result.riskReductionPercent.toStringAsFixed(0)}%',
                            color: const Color(0xFF1565C0),
                          ),
                          _SmallMetricChip(
                            label: 'Esforço',
                            value: atlasPredictiveEffortLabel(result.effort),
                            color: const Color(0xFF6A1B9A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList();

        cards.add(
          SizedBox(
            width: width,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onCreateCustom,
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_chart_outlined,
                          size: 34,
                          color: Color(0xFF1565C0),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Criar cenário personalizado',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Defina mudança, investimento e prazo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Wrap(spacing: 16, runSpacing: 16, children: cards);
      },
    );
  }
}

class _ScenarioSummaryCard extends StatelessWidget {
  const _ScenarioSummaryCard({required this.result});

  final AtlasPredictiveScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final color = predictiveResultColor(result);

    return Card(
      color: color.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      predictiveScenarioIcon(result.request.type),
                      color: color,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.request.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  result.mainEvidence,
                  style: const TextStyle(color: Colors.black54, height: 1.45),
                ),
                const SizedBox(height: 12),
                Text(
                  result.recommendation,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            );

            final metrics = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _LargeMetric(
                  label: 'Score projetado',
                  value: result.projectedScore.toStringAsFixed(0),
                  color: color,
                ),
                _LargeMetric(
                  label: 'Redução de risco',
                  value: '${result.riskReductionPercent.toStringAsFixed(0)}%',
                  color: const Color(0xFF1565C0),
                ),
                _LargeMetric(
                  label: 'Confiança',
                  value: '${result.confidence.toStringAsFixed(0)}%',
                  color: const Color(0xFF6A1B9A),
                ),
                _LargeMetric(
                  label: 'Esforço',
                  value: atlasPredictiveEffortLabel(result.effort),
                  color: const Color(0xFFEF6C00),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [information, const SizedBox(height: 18), metrics],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: information),
                const SizedBox(width: 22),
                SizedBox(width: 420, child: metrics),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProjectionGrid extends StatelessWidget {
  const _ProjectionGrid({required this.projections});

  final List<AtlasPredictiveProjection> projections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 28) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: projections.map((item) {
            final color = projectionColor(item.kind);

            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(projectionIcon(item.kind), color: color),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _ProjectionMetric(
                        label: 'Score',
                        value: item.projectedScore.toStringAsFixed(0),
                        color: color,
                      ),
                      const SizedBox(height: 10),
                      _ProjectionMetric(
                        label: 'Impacto financeiro',
                        value: _currency(item.financialImpact),
                        color: color,
                      ),
                      const SizedBox(height: 10),
                      _ProjectionMetric(
                        label: 'Redução de risco',
                        value:
                            '${item.riskReductionPercent.toStringAsFixed(0)}%',
                        color: color,
                      ),
                      const SizedBox(height: 10),
                      _ProjectionMetric(
                        label: 'Confiança',
                        value: '${item.confidence.toStringAsFixed(0)}%',
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FinancialImpactCard extends StatelessWidget {
  const _FinancialImpactCard({required this.impact});

  final AtlasPredictiveFinancialImpact impact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FinancialMetricCard(
                  width: width,
                  label: 'Impacto provável',
                  value: _currency(impact.probableValue),
                  icon: Icons.trending_up,
                  color: const Color(0xFF1B5E20),
                ),
                _FinancialMetricCard(
                  width: width,
                  label: 'Investimento',
                  value: _currency(impact.investmentValue),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF1565C0),
                ),
                _FinancialMetricCard(
                  width: width,
                  label: 'ROI',
                  value:
                      '${impact.returnOnInvestmentPercent.toStringAsFixed(0)}%',
                  icon: Icons.show_chart,
                  color: const Color(0xFF6A1B9A),
                ),
                _FinancialMetricCard(
                  width: width,
                  label: 'Payback',
                  value: impact.paybackDays == null
                      ? 'Não aplicável'
                      : '${impact.paybackDays} dias',
                  icon: Icons.schedule,
                  color: const Color(0xFFEF6C00),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PredictiveActionList extends StatelessWidget {
  const _PredictiveActionList({
    required this.actions,
    required this.onOpenArea,
  });

  final List<AtlasPredictiveAction> actions;

  final ValueChanged<AtlasFarmAnalysisArea> onOpenArea;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                onOpenArea(action.area);
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      child: Text(
                        '${action.position}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            action.description,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Resultado esperado: ${action.expectedResult}',
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${atlasFarmAreaLabel(action.area)} · prazo: ${action.deadlineDays} dias',
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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

class _SmallMetricChip extends StatelessWidget {
  const _SmallMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LargeMetric extends StatelessWidget {
  const _LargeMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 195,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black45, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ProjectionMetric extends StatelessWidget {
  const _ProjectionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _FinancialMetricCard extends StatelessWidget {
  const _FinancialMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black45, fontSize: 10),
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

class _CustomScenarioDialog extends StatefulWidget {
  const _CustomScenarioDialog();

  @override
  State<_CustomScenarioDialog> createState() {
    return _CustomScenarioDialogState();
  }
}

class _CustomScenarioDialogState extends State<_CustomScenarioDialog> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();

  final descriptionController = TextEditingController();

  final changeController = TextEditingController(text: '10');

  final investmentController = TextEditingController(text: '0');

  final daysController = TextEditingController(text: '30');

  AtlasPredictiveScenarioType selectedType = AtlasPredictiveScenarioType.custom;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    changeController.dispose();
    investmentController.dispose();
    daysController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final change = _parseNumber(changeController.text);

    final investment = _parseNumber(investmentController.text);

    final days = int.tryParse(daysController.text.trim()) ?? 30;

    Navigator.of(context).pop(
      AtlasPredictiveScenarioRequest(
        type: selectedType,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? 'Cenário personalizado criado para simular uma decisão da propriedade.'
            : descriptionController.text.trim(),
        changePercent: change.clamp(0.1, 100.0),
        investmentValue: investment.clamp(0.0, double.infinity),
        executionDays: days.clamp(1, 3650),
      ),
    );
  }

  double _parseNumber(String value) {
    var normalized = value.trim().replaceAll('R\$', '');

    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo cenário'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AtlasPredictiveScenarioType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de decisão',
                    prefixIcon: Icon(Icons.tune_outlined),
                  ),
                  items: AtlasPredictiveScenarioType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(atlasPredictiveScenarioTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título do cenário',
                    hintText: 'Ex.: Reduzir custo de suplementação',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe um título.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Explique a mudança que deseja simular.',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: changeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Mudança (%)',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        validator: (value) {
                          final number = _parseNumber(value ?? '');

                          if (number <= 0 || number > 100) {
                            return 'Use valor entre 0 e 100.';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prazo (dias)',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        validator: (value) {
                          final days = int.tryParse(value?.trim() ?? '');

                          if (days == null || days <= 0) {
                            return 'Prazo inválido.';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: investmentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Investimento previsto',
                    hintText: '0,00',
                    prefixText: 'R\$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final number = _parseNumber(value ?? '');

                    if (number < 0) {
                      return 'O investimento não pode ser negativo.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'A simulação é uma estimativa gerencial baseada nos dados cadastrados e não substitui avaliação técnica ou financeira específica.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: submit,
          icon: const Icon(Icons.auto_graph_outlined),
          label: const Text('Simular'),
        ),
      ],
    );
  }
}

class _PredictiveLoadingView extends StatelessWidget {
  const _PredictiveLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              'Carregando cenários salvos...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPredictiveView extends StatelessWidget {
  const _EmptyPredictiveView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_graph_outlined, size: 56, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Nenhum cenário disponível',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Cadastre mais dados financeiros, operacionais, zootécnicos ou de estoque para gerar simulações.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color predictiveResultColor(AtlasPredictiveScenarioResult result) {
  if (result.confidence >= 80 && result.scoreVariation >= 8) {
    return const Color(0xFF1B5E20);
  }

  if (result.scoreVariation >= 4) {
    return const Color(0xFF2E7D32);
  }

  if (result.scoreVariation > 0) {
    return const Color(0xFFEF6C00);
  }

  return const Color(0xFFC62828);
}

Color projectionColor(AtlasPredictiveProjectionKind kind) {
  switch (kind) {
    case AtlasPredictiveProjectionKind.conservative:
      return const Color(0xFF1565C0);

    case AtlasPredictiveProjectionKind.probable:
      return const Color(0xFF1B5E20);

    case AtlasPredictiveProjectionKind.optimistic:
      return const Color(0xFF6A1B9A);
  }
}

IconData projectionIcon(AtlasPredictiveProjectionKind kind) {
  switch (kind) {
    case AtlasPredictiveProjectionKind.conservative:
      return Icons.shield_outlined;

    case AtlasPredictiveProjectionKind.probable:
      return Icons.balance_outlined;

    case AtlasPredictiveProjectionKind.optimistic:
      return Icons.rocket_launch_outlined;
  }
}

IconData predictiveScenarioIcon(AtlasPredictiveScenarioType type) {
  switch (type) {
    case AtlasPredictiveScenarioType.reduceCosts:
      return Icons.savings_outlined;

    case AtlasPredictiveScenarioType.increaseRevenue:
      return Icons.trending_up;

    case AtlasPredictiveScenarioType.reduceOverdueTasks:
      return Icons.task_alt_outlined;

    case AtlasPredictiveScenarioType.reduceInventoryLosses:
      return Icons.inventory_2_outlined;

    case AtlasPredictiveScenarioType.improveHerdRecords:
      return AtlasLivestockIcons.cow;

    case AtlasPredictiveScenarioType.improvePaddockUse:
      return Icons.grid_view_outlined;

    case AtlasPredictiveScenarioType.custom:
      return Icons.tune_outlined;
  }
}

String _currency(double value) {
  final fixed = value.abs().toStringAsFixed(2);

  final parts = fixed.split('.');

  final integer = parts.first;
  final decimal = parts.last;

  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;

    buffer.write(integer[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  final sign = value < 0 ? '-' : '';

  return '${sign}R\$ ${buffer.toString()},$decimal';
}
