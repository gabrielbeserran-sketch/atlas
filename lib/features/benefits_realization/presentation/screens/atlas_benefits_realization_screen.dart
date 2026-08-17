import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/value_governance/presentation/screens/atlas_value_governance_screen.dart';
import 'package:flutter/services.dart';
import 'package:projeto_atlas/features/benefits_realization/data/services/atlas_benefits_realization_repository.dart';
import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:projeto_atlas/features/benefits_realization/domain/services/atlas_benefits_realization_engine.dart';
import 'package:projeto_atlas/features/strategy_execution/data/services/atlas_strategy_execution_repository.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasBenefitsRealizationScreen extends StatefulWidget {
  const AtlasBenefitsRealizationScreen({super.key, this.farmId, this.planId});

  final String? farmId;
  final String? planId;

  @override
  State<AtlasBenefitsRealizationScreen> createState() {
    return _AtlasBenefitsRealizationScreenState();
  }
}

class _AtlasBenefitsRealizationScreenState
    extends State<AtlasBenefitsRealizationScreen> {
  bool loading = true;
  List<AtlasStrategyExecutionPlan> plans = <AtlasStrategyExecutionPlan>[];
  List<AtlasBenefitRealization> results = <AtlasBenefitRealization>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadedPlans = await AtlasStrategyExecutionRepository.instance
        .loadAll();
    final loadedResults = await AtlasBenefitsRealizationRepository.instance
        .loadAll();

    final filteredPlans = loadedPlans.where((item) {
      final farmMatches = widget.farmId == null || item.farmId == widget.farmId;
      final planMatches = widget.planId == null || item.id == widget.planId;

      return farmMatches && planMatches;
    }).toList();

    final allowedIds = filteredPlans.map((item) => item.id).toSet();

    final filteredResults = loadedResults
        .where((item) => allowedIds.contains(item.strategyPlanId))
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      plans = filteredPlans;
      results = filteredResults;
      loading = false;
    });
  }

  Future<void> _evaluate(AtlasStrategyExecutionPlan plan) async {
    final current = results
        .where((item) => item.strategyPlanId == plan.id)
        .cast<AtlasBenefitRealization?>()
        .firstWhere((item) => item != null, orElse: () => null);

    final formResult = await showDialog<_EvaluationInput>(
      context: context,
      builder: (context) {
        return _EvaluationDialog(plan: plan, current: current);
      },
    );

    if (formResult == null) {
      return;
    }

    final evaluated = const AtlasBenefitsRealizationEngine().evaluate(
      plan: plan,
      actualCost: formResult.actualCost,
      actualNetGain: formResult.actualNetGain,
      actualIndicator: formResult.actualIndicator,
    );

    await AtlasBenefitsRealizationRepository.instance.save(evaluated);

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = AtlasBenefitPortfolio(items: results);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Benefits Realization Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir governança de valor',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasValueGovernanceScreen(farmId: widget.farmId);
                  },
                ),
              );
            },
            icon: const Icon(Icons.account_balance_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
          ? const _EmptyView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _Hero(portfolio: portfolio),
                    const SizedBox(height: 22),
                    const Text(
                      'Benefícios por estratégia',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Compare o que foi prometido com o que realmente foi entregue.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    ...plans.map((plan) {
                      final result = results
                          .where((item) => item.strategyPlanId == plan.id)
                          .cast<AtlasBenefitRealization?>()
                          .firstWhere(
                            (item) => item != null,
                            orElse: () => null,
                          );

                      return _BenefitCard(
                        plan: plan,
                        result: result,
                        onEvaluate: () => _evaluate(plan),
                      );
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.portfolio});

  final AtlasBenefitPortfolio portfolio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF00695C),
            Color(0xFF2E7D32),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valor prometido × valor realizado',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Realização de benefícios estratégicos',
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
              _HeroMetric(
                label: 'Estratégias avaliadas',
                value: '${portfolio.totalStrategies}',
              ),
              _HeroMetric(
                label: 'No caminho certo',
                value: '${portfolio.onTrack}',
              ),
              _HeroMetric(label: 'Críticas', value: '${portfolio.critical}'),
              _HeroMetric(
                label: 'Ganho planejado',
                value: _currency(portfolio.plannedGain),
              ),
              _HeroMetric(
                label: 'Ganho realizado',
                value: _currency(portfolio.actualGain),
              ),
              _HeroMetric(
                label: 'Realização',
                value: '${portfolio.achievement.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.plan,
    required this.result,
    required this.onEvaluate,
  });

  final AtlasStrategyExecutionPlan plan;
  final AtlasBenefitRealization? result;
  final VoidCallback onEvaluate;

  @override
  Widget build(BuildContext context) {
    final current = result;
    final statusColor = current == null
        ? const Color(0xFF546E7A)
        : _statusColor(current.status);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(
            current == null
                ? Icons.pending_actions_outlined
                : Icons.insights_outlined,
            color: statusColor,
          ),
        ),
        title: Text(
          plan.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          current == null
              ? '${plan.farmName} · ainda não avaliado'
              : '${plan.farmName} · ${atlasBenefitRealizationStatusLabel(current.status)} · '
                    '${current.benefitAchievement.toStringAsFixed(1)}% realizado',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          if (current == null)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Registre os valores realizados para comparar com o plano estratégico.',
              ),
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Orçamento',
                  value:
                      '${_currency(current.plannedBudget)} → ${_currency(current.actualCost)}',
                ),
                _Metric(
                  label: 'Ganho líquido',
                  value:
                      '${_currency(current.plannedNetGain)} → ${_currency(current.actualNetGain)}',
                ),
                _Metric(
                  label: 'ROI',
                  value:
                      '${current.plannedRoi.toStringAsFixed(1)}% → ${current.actualRoi.toStringAsFixed(1)}%',
                ),
                _Metric(
                  label: 'Progresso',
                  value:
                      '${current.plannedProgress.toStringAsFixed(1)}% → ${current.actualProgress.toStringAsFixed(1)}%',
                ),
                _Metric(
                  label: 'Indicador',
                  value:
                      '${current.plannedIndicator.toStringAsFixed(1)} → ${current.actualIndicator.toStringAsFixed(1)}',
                ),
                _Metric(
                  label: 'Confiança original',
                  value: '${current.confidence.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ListBlock(title: 'Constatações', items: current.findings),
            _ListBlock(
              title: 'Ações corretivas',
              items: current.correctiveActions,
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onEvaluate,
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(
                current == null
                    ? 'Registrar realização'
                    : 'Atualizar realização',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationDialog extends StatefulWidget {
  const _EvaluationDialog({required this.plan, required this.current});

  final AtlasStrategyExecutionPlan plan;
  final AtlasBenefitRealization? current;

  @override
  State<_EvaluationDialog> createState() {
    return _EvaluationDialogState();
  }
}

class _EvaluationDialogState extends State<_EvaluationDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController costController;
  late final TextEditingController gainController;
  late final TextEditingController indicatorController;

  @override
  void initState() {
    super.initState();
    costController = TextEditingController(
      text:
          (widget.current?.actualCost ??
                  widget.plan.committedBudget *
                      widget.plan.progressPercent /
                      100)
              .toStringAsFixed(2),
    );
    gainController = TextEditingController(
      text: (widget.current?.actualNetGain ?? 0).toStringAsFixed(2),
    );
    indicatorController = TextEditingController(
      text: (widget.current?.actualIndicator ?? 50).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    costController.dispose();
    gainController.dispose();
    indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar valor realizado'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NumberField(
                controller: costController,
                label: 'Custo realizado',
                prefix: 'R\$ ',
              ),
              const SizedBox(height: 12),
              _NumberField(
                controller: gainController,
                label: 'Ganho líquido realizado',
                prefix: 'R\$ ',
              ),
              const SizedBox(height: 12),
              _NumberField(
                controller: indicatorController,
                label: 'Indicador atual da área',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              _EvaluationInput(
                actualCost: _parseDouble(costController.text),
                actualNetGain: _parseDouble(gainController.text),
                actualIndicator: _parseDouble(indicatorController.text),
              ),
            );
          },
          child: const Text('Salvar avaliação'),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.prefix,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
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
            Icon(Icons.insights_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Ainda não existem estratégias para avaliar.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Transforme um cenário em plano de execução antes de medir os benefícios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationInput {
  const _EvaluationInput({
    required this.actualCost,
    required this.actualNetGain,
    required this.actualIndicator,
  });

  final double actualCost;
  final double actualNetGain;
  final double actualIndicator;
}

Color _statusColor(AtlasBenefitRealizationStatus status) {
  switch (status) {
    case AtlasBenefitRealizationStatus.onTrack:
      return const Color(0xFF2E7D32);
    case AtlasBenefitRealizationStatus.attention:
      return const Color(0xFF1565C0);
    case AtlasBenefitRealizationStatus.offTrack:
      return const Color(0xFFEF6C00);
    case AtlasBenefitRealizationStatus.critical:
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

  return '${negative ? '-' : ''}R\$ '
      '${buffer.toString()},$decimal';
}
