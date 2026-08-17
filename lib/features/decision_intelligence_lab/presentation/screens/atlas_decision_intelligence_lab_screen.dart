import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/strategy_execution/presentation/screens/atlas_strategy_execution_screen.dart';
import 'package:flutter/services.dart';
import 'package:projeto_atlas/features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart';
import 'package:projeto_atlas/features/decision_intelligence_lab/domain/services/atlas_decision_intelligence_engine.dart';
import 'package:projeto_atlas/features/farm_audit/data/services/atlas_farm_audit_history_service.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/knowledge_learning/data/services/atlas_knowledge_repository.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/domain/models/atlas_intelligent_recommendation.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/domain/services/atlas_recommendation_intelligence_engine.dart';

class AtlasDecisionIntelligenceLabScreen extends StatefulWidget {
  const AtlasDecisionIntelligenceLabScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasDecisionIntelligenceLabScreen> createState() {
    return _AtlasDecisionIntelligenceLabScreenState();
  }
}

class _AtlasDecisionIntelligenceLabScreenState
    extends State<AtlasDecisionIntelligenceLabScreen> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController(
    text: 'Novo cenário estratégico',
  );
  final descriptionController = TextEditingController();
  final investmentController = TextEditingController(text: '50000');
  final revenueController = TextEditingController(text: '10000');
  final costController = TextEditingController(text: '2500');

  bool loading = true;
  AtlasFarmAudit? audit;
  AtlasRecommendationPortfolio? recommendations;
  AtlasFarmAuditArea selectedArea = AtlasFarmAuditArea.reproduction;
  int horizonMonths = 12;
  double complexity = 45;
  double readiness = 70;
  final List<AtlasDecisionScenarioInput> scenarios =
      <AtlasDecisionScenarioInput>[];
  AtlasDecisionComparison? comparison;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    investmentController.dispose();
    revenueController.dispose();
    costController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final audits = await AtlasFarmAuditHistoryService.instance.loadAll();

    final filtered = widget.farmId == null
        ? audits
        : audits.where((item) => item.farmId == widget.farmId).toList();

    if (filtered.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      return;
    }

    final currentAudit = filtered.first;
    final cases = await AtlasKnowledgeRepository.instance.loadCases();

    final portfolio = const AtlasRecommendationIntelligenceEngine().generate(
      audit: currentAudit,
      knowledgeCases: cases,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      audit = currentAudit;
      recommendations = portfolio;
      selectedArea = portfolio.recommendations.isEmpty
          ? AtlasFarmAuditArea.reproduction
          : portfolio.recommendations.first.area;
      loading = false;
    });

    _addTemplates();
  }

  void _addTemplates() {
    if (scenarios.isNotEmpty) {
      return;
    }

    final templates = <AtlasDecisionScenarioInput>[
      AtlasDecisionScenarioInput(
        id: 'template_reproduction',
        title: 'Novo protocolo reprodutivo',
        description:
            'Revisão do manejo e implantação de protocolo reprodutivo estruturado.',
        area: AtlasFarmAuditArea.reproduction,
        investment: 45000,
        monthlyRevenueGain: 12000,
        monthlyCostChange: 3000,
        horizonMonths: 12,
        operationalComplexity: 55,
        executionReadiness: 75,
      ),
      AtlasDecisionScenarioInput(
        id: 'template_pasture',
        title: 'Reforma estratégica de pastagens',
        description:
            'Recuperação de áreas prioritárias para elevar suporte e desempenho.',
        area: AtlasFarmAuditArea.pastures,
        investment: 120000,
        monthlyRevenueGain: 22000,
        monthlyCostChange: 6500,
        horizonMonths: 18,
        operationalComplexity: 65,
        executionReadiness: 68,
      ),
      AtlasDecisionScenarioInput(
        id: 'template_sanitary',
        title: 'Intensificação do controle sanitário',
        description:
            'Fortalecimento de prevenção, monitoramento e biossegurança.',
        area: AtlasFarmAuditArea.sanitary,
        investment: 30000,
        monthlyRevenueGain: 7500,
        monthlyCostChange: 1800,
        horizonMonths: 12,
        operationalComplexity: 35,
        executionReadiness: 82,
      ),
    ];

    setState(() {
      scenarios.addAll(templates);
      _compare();
    });
  }

  void _addScenario() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final scenario = AtlasDecisionScenarioInput(
      id: 'scenario_${DateTime.now().microsecondsSinceEpoch}',
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      area: selectedArea,
      investment: _parseDouble(investmentController.text),
      monthlyRevenueGain: _parseDouble(revenueController.text),
      monthlyCostChange: _parseDouble(costController.text),
      horizonMonths: horizonMonths,
      operationalComplexity: complexity,
      executionReadiness: readiness,
    );

    setState(() {
      scenarios.add(scenario);
      _compare();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cenário adicionado à comparação.')),
    );
  }

  void _removeScenario(String id) {
    setState(() {
      scenarios.removeWhere((item) => item.id == id);
      _compare();
    });
  }

  void _compare() {
    final currentAudit = audit;
    final currentRecommendations = recommendations;

    if (currentAudit == null ||
        currentRecommendations == null ||
        scenarios.isEmpty) {
      comparison = null;
      return;
    }

    comparison = const AtlasDecisionIntelligenceEngine().compare(
      audit: currentAudit,
      recommendations: currentRecommendations,
      scenarios: scenarios,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAudit = audit;
    final currentComparison = comparison;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Decision Intelligence Lab',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Recalcular cenários',
            onPressed: scenarios.isEmpty
                ? null
                : () {
                    setState(_compare);
                  },
            icon: const Icon(Icons.calculate_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : currentAudit == null
          ? const _EmptyView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _Hero(
                      farmName: currentAudit.farmName,
                      comparison: currentComparison,
                    ),
                    const SizedBox(height: 20),
                    _ScenarioForm(
                      formKey: formKey,
                      titleController: titleController,
                      descriptionController: descriptionController,
                      investmentController: investmentController,
                      revenueController: revenueController,
                      costController: costController,
                      selectedArea: selectedArea,
                      horizonMonths: horizonMonths,
                      complexity: complexity,
                      readiness: readiness,
                      onAreaChanged: (value) {
                        setState(() {
                          selectedArea = value;
                        });
                      },
                      onHorizonChanged: (value) {
                        setState(() {
                          horizonMonths = value;
                        });
                      },
                      onComplexityChanged: (value) {
                        setState(() {
                          complexity = value;
                        });
                      },
                      onReadinessChanged: (value) {
                        setState(() {
                          readiness = value;
                        });
                      },
                      onAdd: _addScenario,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'Comparação de cenários',
                      subtitle:
                          'Ordenação por retorno, prazo, probabilidade, confiança e risco.',
                    ),
                    const SizedBox(height: 12),
                    if (currentComparison == null)
                      const _NoScenarios()
                    else
                      ..._ordered(
                        currentComparison.results,
                      ).asMap().entries.map(
                        (entry) => _ScenarioResultCard(
                          position: entry.key + 1,
                          result: entry.value,
                          recommended:
                              currentComparison.recommended?.id ==
                              entry.value.id,
                          onExecute: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) {
                                  return AtlasStrategyExecutionScreen(
                                    scenario: entry.value,
                                    farmId: entry.value.farmId,
                                  );
                                },
                              ),
                            );
                          },
                          onRemove: () => _removeScenario(entry.value.input.id),
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.farmName, required this.comparison});

  final String farmName;
  final AtlasDecisionComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final recommended = comparison?.recommended;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF4A148C),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laboratório virtual de decisões',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            farmName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recommended == null
                ? 'Adicione cenários para comparar alternativas.'
                : 'Melhor alternativa atual: ${recommended.input.title}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (recommended != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HeroMetric(
                  label: 'Score estratégico',
                  value: recommended.score.toStringAsFixed(1),
                ),
                _HeroMetric(
                  label: 'ROI esperado',
                  value: '${recommended.roiPercent.toStringAsFixed(1)}%',
                ),
                _HeroMetric(
                  label: 'Risco',
                  value: atlasDecisionRiskLabel(recommended.risk),
                ),
                _HeroMetric(
                  label: 'Confiança',
                  value: '${recommended.confidence.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScenarioForm extends StatelessWidget {
  const _ScenarioForm({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.investmentController,
    required this.revenueController,
    required this.costController,
    required this.selectedArea,
    required this.horizonMonths,
    required this.complexity,
    required this.readiness,
    required this.onAreaChanged,
    required this.onHorizonChanged,
    required this.onComplexityChanged,
    required this.onReadinessChanged,
    required this.onAdd,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController investmentController;
  final TextEditingController revenueController;
  final TextEditingController costController;
  final AtlasFarmAuditArea selectedArea;
  final int horizonMonths;
  final double complexity;
  final double readiness;
  final ValueChanged<AtlasFarmAuditArea> onAreaChanged;
  final ValueChanged<int> onHorizonChanged;
  final ValueChanged<double> onComplexityChanged;
  final ValueChanged<double> onReadinessChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Criar novo cenário',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AtlasFarmAuditArea>(
                initialValue: selectedArea,
                decoration: const InputDecoration(
                  labelText: 'Área principal',
                  border: OutlineInputBorder(),
                ),
                items: AtlasFarmAuditArea.values
                    .map(
                      (area) => DropdownMenuItem(
                        value: area,
                        child: Text(atlasFarmAuditAreaLabel(area)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onAreaChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = <Widget>[
                    _MoneyField(
                      controller: investmentController,
                      label: 'Investimento inicial',
                    ),
                    _MoneyField(
                      controller: revenueController,
                      label: 'Receita mensal adicional',
                    ),
                    _MoneyField(
                      controller: costController,
                      label: 'Custo mensal adicional',
                    ),
                  ];

                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: fields
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: item,
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[1]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[2]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: horizonMonths,
                decoration: const InputDecoration(
                  labelText: 'Horizonte da simulação',
                  border: OutlineInputBorder(),
                ),
                items: const <int>[6, 12, 18, 24, 36]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value meses'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onHorizonChanged(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _SliderField(
                label:
                    'Complexidade operacional: ${complexity.toStringAsFixed(0)}%',
                value: complexity,
                onChanged: onComplexityChanged,
              ),
              _SliderField(
                label:
                    'Prontidão para executar: ${readiness.toStringAsFixed(0)}%',
                value: readiness,
                onChanged: onReadinessChanged,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar à comparação'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]'))],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe o valor.';
        }

        return null;
      },
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ScenarioResultCard extends StatelessWidget {
  const _ScenarioResultCard({
    required this.position,
    required this.result,
    required this.recommended,
    required this.onExecute,
    required this.onRemove,
  });

  final int position;
  final AtlasDecisionScenarioResult result;
  final bool recommended;
  final VoidCallback onExecute;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(result.risk);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            '$position',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                result.input.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (recommended)
              const Chip(
                avatar: Icon(Icons.emoji_events_outlined, size: 18),
                label: Text('Recomendado'),
              ),
          ],
        ),
        subtitle: Text(
          '${atlasFarmAuditAreaLabel(result.input.area)} · '
          'score ${result.score.toStringAsFixed(1)} · '
          'risco ${atlasDecisionRiskLabel(result.risk)}',
        ),
        trailing: IconButton(
          tooltip: 'Remover cenário',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              result.explanation,
              style: const TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Investimento',
                value: _currency(result.input.investment),
              ),
              _Metric(
                label: 'Ganho líquido projetado',
                value: _currency(result.expectedNetGain),
              ),
              _Metric(
                label: 'ROI',
                value: '${result.roiPercent.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Payback',
                value: result.paybackMonths >= 999
                    ? 'Não alcançado'
                    : '${result.paybackMonths.toStringAsFixed(1)} meses',
              ),
              _Metric(
                label: 'Sucesso',
                value: '${result.successProbability.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Confiança',
                value: '${result.confidence.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Indicador',
                value:
                    '${result.currentAreaScore.toStringAsFixed(1)} → ${result.projectedAreaScore.toStringAsFixed(1)}',
              ),
              _Metric(
                label: 'Resultado esperado',
                value: '${result.expectedResultMonths} meses',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ListBlock(title: 'Principais vantagens', items: result.advantages),
          _ListBlock(title: 'Principais riscos', items: result.risks),
          _ListBlock(
            title: 'Plano de implementação',
            items: result.implementationPlan,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onExecute,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Transformar em plano de execução'),
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
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(14),
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
      constraints: const BoxConstraints(minWidth: 150),
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

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $item'),
              ),
            ),
          ],
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Gere uma auditoria antes de utilizar o laboratório de decisões.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoScenarios extends StatelessWidget {
  const _NoScenarios();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nenhum cenário disponível para comparação.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

List<AtlasDecisionScenarioResult> _ordered(
  List<AtlasDecisionScenarioResult> results,
) {
  return List<AtlasDecisionScenarioResult>.from(results)
    ..sort((first, second) => second.score.compareTo(first.score));
}

Color _riskColor(AtlasDecisionRisk risk) {
  switch (risk) {
    case AtlasDecisionRisk.low:
      return const Color(0xFF2E7D32);
    case AtlasDecisionRisk.moderate:
      return const Color(0xFF1565C0);
    case AtlasDecisionRisk.high:
      return const Color(0xFFEF6C00);
    case AtlasDecisionRisk.critical:
      return const Color(0xFFC62828);
  }
}

double _parseDouble(String value) {
  final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');

  return double.tryParse(normalized) ?? 0;
}

String _currency(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final pieces = fixed.split('.');
  final integer = pieces.first;
  final decimal = pieces.last;
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;
    buffer.write(integer[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${negative ? '-' : ''}R\$ '
      '${buffer.toString()},$decimal';
}
