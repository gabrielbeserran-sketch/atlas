import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/investment_capital_allocation/presentation/screens/atlas_investment_capital_screen.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/data/services/atlas_strategic_scenario_repository.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/domain/models/atlas_scenario_analysis.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/domain/models/atlas_strategic_scenario.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/domain/services/atlas_strategic_scenario_engine.dart';

class AtlasStrategicScenarioPlanningScreen extends StatefulWidget {
  const AtlasStrategicScenarioPlanningScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasStrategicScenarioPlanningScreen> createState() {
    return _AtlasStrategicScenarioPlanningScreenState();
  }
}

class _AtlasStrategicScenarioPlanningScreenState
    extends State<AtlasStrategicScenarioPlanningScreen> {
  bool loading = true;
  List<AtlasStrategicScenario> scenarios = <AtlasStrategicScenario>[];
  AtlasScenarioPortfolioAnalysis? analysis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AtlasStrategicScenarioRepository.instance.loadAll();

    final filtered = widget.farmId == null
        ? all
        : all
              .where(
                (item) => item.farmId.isEmpty || item.farmId == widget.farmId,
              )
              .toList();

    final generated = const AtlasStrategicScenarioEngine().analyzeAll(filtered);

    if (!mounted) {
      return;
    }

    setState(() {
      scenarios = filtered;
      analysis = generated;
      loading = false;
    });
  }

  Future<void> _createScenario() async {
    final scenario = await showDialog<AtlasStrategicScenario>(
      context: context,
      builder: (context) {
        return _ScenarioEditorDialog(farmId: widget.farmId ?? '');
      },
    );

    if (scenario == null) {
      return;
    }

    await AtlasStrategicScenarioRepository.instance.save(scenario);
    await _load();
  }

  Future<void> _duplicate(AtlasStrategicScenario scenario) async {
    final duplicated = scenario.copyWith(
      id: 'scenario_${DateTime.now().millisecondsSinceEpoch}',
      title: '${scenario.title} - cópia',
      createdAt: DateTime.now(),
    );

    await AtlasStrategicScenarioRepository.instance.save(duplicated);
    await _load();
  }

  Future<void> _delete(AtlasStrategicScenario scenario) async {
    await AtlasStrategicScenarioRepository.instance.delete(scenario.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final current = analysis;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Strategic Scenario Planning',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir alocação de capital',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AtlasInvestmentCapitalScreen(farmId: widget.farmId),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar cenários',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createScenario,
        icon: const Icon(Icons.add),
        label: const Text('Novo cenário'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : current == null || current.items.isEmpty
          ? const _EmptyView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
                  children: [
                    _Hero(analysis: current),
                    const SizedBox(height: 22),
                    _ComparisonBoard(analysis: current),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Cenários analisados',
                      subtitle:
                          'Compare retorno, payback, risco, resiliência e impactos produtivos.',
                    ),
                    const SizedBox(height: 12),
                    ...current.items.map(
                      (item) => _ScenarioCard(
                        analysis: item,
                        onDuplicate: () => _duplicate(item.scenario),
                        onDelete: () => _delete(item.scenario),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.analysis});

  final AtlasScenarioPortfolioAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final best = analysis.bestBalance;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF00695C),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha o futuro antes de investir',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Simulação econômica, produtiva e de riscos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(label: 'Cenários', value: '${analysis.items.length}'),
              _HeroMetric(
                label: 'Maior VPL',
                value: _money(analysis.bestReturn?.netPresentValue ?? 0),
              ),
              _HeroMetric(
                label: 'Menor risco',
                value:
                    '${analysis.lowestRisk?.riskScore.toStringAsFixed(1) ?? '0,0'}%',
              ),
              _HeroMetric(
                label: 'Melhor equilíbrio',
                value: best?.scenario.title ?? 'Não disponível',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonBoard extends StatelessWidget {
  const _ComparisonBoard({required this.analysis});

  final AtlasScenarioPortfolioAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final bestReturn = analysis.bestReturn;
    final lowestRisk = analysis.lowestRisk;
    final bestBalance = analysis.bestBalance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _WinnerTile(
              icon: Icons.trending_up,
              label: 'Melhor retorno',
              value: bestReturn?.scenario.title ?? '-',
              detail: _money(bestReturn?.netPresentValue ?? 0),
            ),
            _WinnerTile(
              icon: Icons.shield_outlined,
              label: 'Menor risco',
              value: lowestRisk?.scenario.title ?? '-',
              detail: '${lowestRisk?.riskScore.toStringAsFixed(1) ?? '0,0'}%',
            ),
            _WinnerTile(
              icon: Icons.balance_outlined,
              label: 'Melhor equilíbrio',
              value: bestBalance?.scenario.title ?? '-',
              detail:
                  '${bestBalance?.resilienceScore.toStringAsFixed(1) ?? '0,0'} pontos',
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.analysis,
    required this.onDuplicate,
    required this.onDelete,
  });

  final AtlasScenarioAnalysis analysis;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scenario = analysis.scenario;
    final color = _classificationColor(analysis.classification);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.auto_graph_outlined, color: color),
        ),
        title: Text(
          scenario.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${atlasStrategicScenarioTypeLabel(scenario.type)} · '
          '${atlasScenarioClassificationLabel(analysis.classification)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'duplicate') {
              onDuplicate();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) {
            return const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'duplicate',
                child: Text('Duplicar'),
              ),
              PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
            ];
          },
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(scenario.description),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Investimento',
                value: _money(
                  scenario.initialInvestment + scenario.workingCapital,
                ),
              ),
              _Metric(label: 'VPL', value: _money(analysis.netPresentValue)),
              _Metric(
                label: 'TIR',
                value: '${analysis.internalRateOfReturn.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'ROI',
                value: '${analysis.roiPercent.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Payback',
                value: analysis.paybackYears.isFinite
                    ? '${analysis.paybackYears.toStringAsFixed(1)} anos'
                    : 'Não recuperado',
              ),
              _Metric(
                label: 'Risco',
                value: '${analysis.riskScore.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Resiliência',
                value: '${analysis.resilienceScore.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'VPL otimista',
                value: _money(analysis.optimisticNetPresentValue),
              ),
              _Metric(
                label: 'VPL pessimista',
                value: _money(analysis.pessimisticNetPresentValue),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Impactos produtivos estimados',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Taxa de prenhez',
                value:
                    '+${scenario.productiveImpacts.pregnancyRateChange.toStringAsFixed(1)} p.p.',
              ),
              _Metric(
                label: 'Taxa de desmame',
                value:
                    '+${scenario.productiveImpacts.weaningRateChange.toStringAsFixed(1)} p.p.',
              ),
              _Metric(
                label: 'GMD',
                value:
                    '+${scenario.productiveImpacts.dailyGainChange.toStringAsFixed(2)} kg/dia',
              ),
              _Metric(
                label: 'Lotação',
                value:
                    '+${scenario.productiveImpacts.stockingRateChange.toStringAsFixed(2)} UA/ha',
              ),
              _Metric(
                label: 'Arrobas/ano',
                value:
                    '+${scenario.productiveImpacts.arrobasPerYearChange.toStringAsFixed(0)}',
              ),
              _Metric(
                label: 'Produtividade/ha',
                value:
                    '+${scenario.productiveImpacts.productivityPerHectareChange.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recomendação:\n${analysis.recommendation}',
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioEditorDialog extends StatefulWidget {
  const _ScenarioEditorDialog({required this.farmId});

  final String farmId;

  @override
  State<_ScenarioEditorDialog> createState() {
    return _ScenarioEditorDialogState();
  }
}

class _ScenarioEditorDialogState extends State<_ScenarioEditorDialog> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final investmentController = TextEditingController(text: '250000');
  final workingCapitalController = TextEditingController(text: '50000');
  final revenueController = TextEditingController(text: '160000');
  final costController = TextEditingController(text: '65000');

  AtlasStrategicScenarioType type =
      AtlasStrategicScenarioType.pastureIntensification;
  double risk = 50;
  int horizon = 5;

  @override
  void dispose() {
    titleController.dispose();
    investmentController.dispose();
    workingCapitalController.dispose();
    revenueController.dispose();
    costController.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) {
    return double.tryParse(
          controller.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
  }

  void _save() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      AtlasStrategicScenario(
        id: 'scenario_${DateTime.now().millisecondsSinceEpoch}',
        farmId: widget.farmId,
        farmName: widget.farmId.isEmpty
            ? 'Todas as fazendas'
            : 'Fazenda selecionada',
        title: titleController.text.trim(),
        description:
            'Cenário criado para comparação estratégica e validação executiva.',
        type: type,
        createdAt: DateTime.now(),
        horizonYears: horizon,
        initialInvestment: _number(investmentController),
        workingCapital: _number(workingCapitalController),
        annualAdditionalRevenue: _number(revenueController),
        annualAdditionalCost: _number(costController),
        residualValue: _number(investmentController) * 0.20,
        discountRatePercent: 12,
        priceSensitivityPercent: 12,
        costSensitivityPercent: 15,
        productiveImpacts: _impacts(type),
        risks: AtlasScenarioRisks(
          climate: risk,
          sanitary: risk * 0.85,
          financial: risk,
          operational: (risk * 1.05).clamp(0.0, 100.0),
          market: (risk * 1.10).clamp(0.0, 100.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo cenário estratégico'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cenário',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do cenário.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AtlasStrategicScenarioType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: AtlasStrategicScenarioType.values
                      .map(
                        (item) => DropdownMenuItem<AtlasStrategicScenarioType>(
                          value: item,
                          child: Text(atlasStrategicScenarioTypeLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        type = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MoneyField(
                      controller: investmentController,
                      label: 'Investimento inicial',
                    ),
                    _MoneyField(
                      controller: workingCapitalController,
                      label: 'Capital de giro',
                    ),
                    _MoneyField(
                      controller: revenueController,
                      label: 'Receita adicional anual',
                    ),
                    _MoneyField(
                      controller: costController,
                      label: 'Custo adicional anual',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Horizonte: $horizon anos',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: horizon.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  label: '$horizon anos',
                  onChanged: (value) {
                    setState(() {
                      horizon = value.round();
                    });
                  },
                ),
                Text(
                  'Risco-base: ${risk.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: risk,
                  min: 10,
                  max: 90,
                  divisions: 16,
                  label: '${risk.toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      risk = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Criar e simular'),
        ),
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'R\$ ',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

AtlasProductiveImpacts _impacts(AtlasStrategicScenarioType type) {
  switch (type) {
    case AtlasStrategicScenarioType.iatf:
    case AtlasStrategicScenarioType.geneticImprovement:
      return const AtlasProductiveImpacts(
        pregnancyRateChange: 9,
        weaningRateChange: 7,
        dailyGainChange: 0.05,
        stockingRateChange: 0.1,
        arrobasPerYearChange: 280,
        productivityPerHectareChange: 8,
        mortalityReduction: 0.3,
      );
    case AtlasStrategicScenarioType.feedlot:
    case AtlasStrategicScenarioType.semiFeedlot:
      return const AtlasProductiveImpacts(
        pregnancyRateChange: 0,
        weaningRateChange: 0,
        dailyGainChange: 0.62,
        stockingRateChange: 1.1,
        arrobasPerYearChange: 1800,
        productivityPerHectareChange: 62,
        mortalityReduction: 0.2,
      );
    case AtlasStrategicScenarioType.pastureIntensification:
    case AtlasStrategicScenarioType.cropLivestockIntegration:
      return const AtlasProductiveImpacts(
        pregnancyRateChange: 3,
        weaningRateChange: 4,
        dailyGainChange: 0.15,
        stockingRateChange: 0.9,
        arrobasPerYearChange: 900,
        productivityPerHectareChange: 35,
        mortalityReduction: 0.4,
      );
    default:
      return const AtlasProductiveImpacts(
        pregnancyRateChange: 2,
        weaningRateChange: 2,
        dailyGainChange: 0.08,
        stockingRateChange: 0.3,
        arrobasPerYearChange: 350,
        productivityPerHectareChange: 12,
        mortalityReduction: 0.3,
      );
  }
}

class _WinnerTile extends StatelessWidget {
  const _WinnerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 250),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_graph_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Ainda não existem cenários estratégicos.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Crie um cenário para comparar investimentos, retorno e riscos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color _classificationColor(AtlasScenarioClassification classification) {
  switch (classification) {
    case AtlasScenarioClassification.recommended:
      return const Color(0xFF2E7D32);
    case AtlasScenarioClassification.recommendedInPhases:
      return const Color(0xFF1565C0);
    case AtlasScenarioClassification.review:
      return const Color(0xFFEF6C00);
    case AtlasScenarioClassification.notRecommended:
      return const Color(0xFFC62828);
  }
}

String _money(double value) {
  final negative = value < 0;
  final absolute = value.abs();
  final fixed = absolute.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final groups = <String>[];

  for (var end = digits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, end);
    groups.insert(0, digits.substring(start, end));
  }

  return '${negative ? '-' : ''}R\$ '
      '${groups.join('.')},${parts.last}';
}
