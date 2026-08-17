import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../strategic_execution_engine/presentation/screens/atlas_execution_engine_screen.dart';

import '../../data/services/atlas_investment_repository.dart';
import '../../domain/models/atlas_capital_constraint.dart';
import '../../domain/models/atlas_investment_portfolio.dart';
import '../../domain/models/atlas_investment_project.dart';
import '../../domain/services/atlas_capital_allocation_engine.dart';

class AtlasInvestmentCapitalScreen extends StatefulWidget {
  const AtlasInvestmentCapitalScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasInvestmentCapitalScreen> createState() =>
      _AtlasInvestmentCapitalScreenState();
}

class _AtlasInvestmentCapitalScreenState
    extends State<AtlasInvestmentCapitalScreen> {
  final _engine = const AtlasCapitalAllocationEngine();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _loading = true;
  List<AtlasInvestmentProject> _projects = <AtlasInvestmentProject>[];
  AtlasInvestmentPortfolio? _portfolio;
  AtlasCapitalConstraint _constraint = const AtlasCapitalConstraint(
    availableCash: 900000,
    annualBudget: 2000000,
    maximumDebt: 1100000,
    interestRate: 11.5,
    financingYears: 5,
    maximumCashCommitment: 70,
    discountRate: 12,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AtlasInvestmentRepository.instance.loadAll();
    final filtered = widget.farmId == null
        ? all
        : all
              .where(
                (item) => item.farmId.isEmpty || item.farmId == widget.farmId,
              )
              .toList();
    if (!mounted) return;
    setState(() {
      _projects = filtered;
      _portfolio = _engine.optimize(
        projects: filtered,
        constraint: _constraint,
      );
      _loading = false;
    });
  }

  void _recalculate() {
    setState(() {
      _portfolio = _engine.optimize(
        projects: _projects,
        constraint: _constraint,
      );
    });
  }

  Future<void> _editConstraints() async {
    final result = await showDialog<AtlasCapitalConstraint>(
      context: context,
      builder: (_) => _ConstraintDialog(initial: _constraint),
    );
    if (result == null) return;
    setState(() => _constraint = result);
    _recalculate();
  }

  Future<void> _createProject() async {
    final project = await showDialog<AtlasInvestmentProject>(
      context: context,
      builder: (_) => _ProjectDialog(farmId: widget.farmId ?? ''),
    );
    if (project == null) return;
    await AtlasInvestmentRepository.instance.save(project);
    await _load();
  }

  Future<void> _delete(AtlasInvestmentProject project) async {
    await AtlasInvestmentRepository.instance.delete(project.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = _portfolio;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Investment & Capital Allocation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Plano de execução',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AtlasExecutionEngineScreen(farmId: widget.farmId),
              ),
            ),
            icon: const Icon(Icons.route_outlined),
          ),
          IconButton(
            tooltip: 'Restrições financeiras',
            onPressed: _editConstraints,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Recalcular',
            onPressed: _recalculate,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: const Text('Novo investimento'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : portfolio == null
          ? const Center(child: Text('Não foi possível gerar o portfólio.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
                  children: [
                    _HeroCard(
                      portfolio: portfolio,
                      currency: _currency,
                      onConstraints: _editConstraints,
                    ),
                    const SizedBox(height: 18),
                    _MetricsGrid(portfolio: portfolio, currency: _currency),
                    const SizedBox(height: 18),
                    _FinancingCard(portfolio: portfolio, currency: _currency),
                    const SizedBox(height: 24),
                    const Text(
                      'Portfólio recomendado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (portfolio.selected.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Nenhum projeto selecionado com as restrições atuais.',
                          ),
                        ),
                      )
                    else
                      ...portfolio.selected.map(
                        (item) => _ProjectCard(
                          item: item,
                          currency: _currency,
                          selected: true,
                          onDelete: () => _delete(item.project),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Todos os projetos avaliados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...portfolio.items.map(
                      (item) => _ProjectCard(
                        item: item,
                        currency: _currency,
                        selected: portfolio.selected.any(
                          (selected) => selected.project.id == item.project.id,
                        ),
                        onDelete: () => _delete(item.project),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.portfolio,
    required this.currency,
    required this.onConstraints,
  });
  final AtlasInvestmentPortfolio portfolio;
  final NumberFormat currency;
  final VoidCallback onConstraints;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF123B36),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plano ótimo de alocação de capital',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'O Atlas combina retorno, risco, capacidade operacional, alinhamento estratégico e limites financeiros para recomendar a melhor carteira.',
                    style: TextStyle(color: Colors.white70, height: 1.45),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onConstraints,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Ajustar orçamento'),
            ),
            Text(
              '${portfolio.selected.length} projeto(s) priorizado(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.portfolio, required this.currency});
  final AtlasInvestmentPortfolio portfolio;
  final NumberFormat currency;
  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      (
        'Capital alocado',
        currency.format(portfolio.allocatedCapital),
        Icons.savings_outlined,
      ),
      (
        'Saldo disponível',
        currency.format(portfolio.remainingCapital),
        Icons.account_balance_wallet_outlined,
      ),
      (
        'VPL do portfólio',
        currency.format(portfolio.portfolioNpv),
        Icons.trending_up,
      ),
      (
        'ROI global',
        '${portfolio.portfolioRoi.toStringAsFixed(1)}%',
        Icons.percent,
      ),
      (
        'Risco médio',
        '${portfolio.averageRisk.toStringAsFixed(0)}/100',
        Icons.shield_outlined,
      ),
      (
        'Payback médio',
        '${portfolio.averagePayback.toStringAsFixed(1)} anos',
        Icons.schedule,
      ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: 195,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$3, color: const Color(0xFF00695C)),
                  const SizedBox(height: 12),
                  Text(item.$1, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FinancingCard extends StatelessWidget {
  const _FinancingCard({required this.portfolio, required this.currency});
  final AtlasInvestmentPortfolio portfolio;
  final NumberFormat currency;
  @override
  Widget build(BuildContext context) {
    final financing = portfolio.financing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estrutura de financiamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 28,
              runSpacing: 10,
              children: [
                Text(
                  'Valor financiado: ${currency.format(financing.financedAmount)}',
                ),
                Text(
                  'Parcela mensal: ${currency.format(financing.monthlyPayment)}',
                ),
                Text(
                  'Juros totais: ${currency.format(financing.totalInterest)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(portfolio.recommendation, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.item,
    required this.currency,
    required this.selected,
    required this.onDelete,
  });
  final AtlasInvestmentProjectAnalysis item;
  final NumberFormat currency;
  final bool selected;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final project = item.project;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: selected
              ? const Color(0xFFE0F2F1)
              : const Color(0xFFF1F3F4),
          child: Icon(
            selected ? Icons.check_circle_outline : Icons.analytics_outlined,
            color: selected ? const Color(0xFF00695C) : Colors.black54,
          ),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${atlasInvestmentCategoryLabel(project.category)} • ${atlasInvestmentDecisionLabel(item.decision)}',
        ),
        trailing: Text(
          '${item.priorityScore.toStringAsFixed(0)}/100',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.description),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    Text('Capital: ${currency.format(project.totalCapital)}'),
                    Text('VPL: ${currency.format(item.npv)}'),
                    Text('ROI: ${item.roi.toStringAsFixed(1)}%'),
                    Text('TIR: ${item.irr.toStringAsFixed(1)}%'),
                    Text(
                      'Payback: ${item.paybackYears.toStringAsFixed(1)} anos',
                    ),
                    Text('Risco: ${project.riskScore.toStringAsFixed(0)}/100'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item.reason, style: const TextStyle(height: 1.4)),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Excluir projeto',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstraintDialog extends StatefulWidget {
  const _ConstraintDialog({required this.initial});
  final AtlasCapitalConstraint initial;
  @override
  State<_ConstraintDialog> createState() => _ConstraintDialogState();
}

class _ConstraintDialogState extends State<_ConstraintDialog> {
  late final TextEditingController cash;
  late final TextEditingController budget;
  late final TextEditingController debt;
  late final TextEditingController rate;
  late final TextEditingController years;
  late final TextEditingController commitment;
  late final TextEditingController discount;
  @override
  void initState() {
    super.initState();
    cash = TextEditingController(
      text: widget.initial.availableCash.toStringAsFixed(0),
    );
    budget = TextEditingController(
      text: widget.initial.annualBudget.toStringAsFixed(0),
    );
    debt = TextEditingController(
      text: widget.initial.maximumDebt.toStringAsFixed(0),
    );
    rate = TextEditingController(
      text: widget.initial.interestRate.toStringAsFixed(1),
    );
    years = TextEditingController(
      text: widget.initial.financingYears.toString(),
    );
    commitment = TextEditingController(
      text: widget.initial.maximumCashCommitment.toStringAsFixed(0),
    );
    discount = TextEditingController(
      text: widget.initial.discountRate.toStringAsFixed(1),
    );
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restrições financeiras'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field(cash, 'Caixa disponível'),
              _field(budget, 'Orçamento anual'),
              _field(debt, 'Endividamento máximo'),
              _field(rate, 'Juros ao ano (%)'),
              _field(years, 'Prazo (anos)'),
              _field(commitment, 'Máximo do caixa comprometido (%)'),
              _field(discount, 'Taxa de desconto (%)'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            AtlasCapitalConstraint(
              availableCash: _number(cash),
              annualBudget: _number(budget),
              maximumDebt: _number(debt),
              interestRate: _number(rate),
              financingYears: int.tryParse(years.text) ?? 5,
              maximumCashCommitment: _number(commitment),
              discountRate: _number(discount),
            ),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) => SizedBox(
    width: 250,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({required this.farmId});
  final String farmId;
  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  final name = TextEditingController();
  final description = TextEditingController();
  final investment = TextEditingController(text: '250000');
  final workingCapital = TextEditingController(text: '50000');
  final revenue = TextEditingController(text: '180000');
  final cost = TextEditingController(text: '70000');
  final residual = TextEditingController(text: '50000');
  final years = TextEditingController(text: '5');
  AtlasInvestmentCategory category = AtlasInvestmentCategory.pasture;
  double alignment = 75;
  double capacity = 75;
  double risk = 40;
  bool mandatory = false;
  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo projeto de investimento'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AtlasInvestmentCategory>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: AtlasInvestmentCategory.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(atlasInvestmentCategoryLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _field(investment, 'Investimento inicial'),
                  _field(workingCapital, 'Capital de giro'),
                  _field(revenue, 'Receita anual incremental'),
                  _field(cost, 'Custo anual incremental'),
                  _field(residual, 'Valor residual'),
                  _field(years, 'Horizonte (anos)'),
                ],
              ),
              const SizedBox(height: 14),
              _slider(
                'Alinhamento estratégico',
                alignment,
                (value) => setState(() => alignment = value),
              ),
              _slider(
                'Capacidade operacional',
                capacity,
                (value) => setState(() => capacity = value),
              ),
              _slider('Risco', risk, (value) => setState(() => risk = value)),
              SwitchListTile(
                value: mandatory,
                onChanged: (value) => setState(() => mandatory = value),
                title: const Text('Investimento obrigatório'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  AtlasInvestmentProject(
                    id: 'investment_${DateTime.now().millisecondsSinceEpoch}',
                    farmId: widget.farmId,
                    name: name.text.trim(),
                    description: description.text.trim(),
                    category: category,
                    initialInvestment: _number(investment),
                    workingCapital: _number(workingCapital),
                    annualRevenue: _number(revenue),
                    annualOperatingCost: _number(cost),
                    residualValue: _number(residual),
                    horizonYears: int.tryParse(years.text) ?? 5,
                    strategicAlignment: alignment,
                    operationalCapacity: capacity,
                    riskScore: risk,
                    mandatory: mandatory,
                    createdAt: DateTime.now(),
                  ),
                ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) => SizedBox(
    width: 300,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  Widget _slider(String label, double value, ValueChanged<double> onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(0)}/100'),
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
