import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/knowledge_learning/presentation/screens/atlas_knowledge_learning_screen.dart';
import '../../data/services/atlas_prediction_repository.dart';
import '../../domain/models/atlas_predictive_scenario.dart';
import '../../domain/services/atlas_prediction_engine.dart';

class AtlasPredictiveAiScreen extends StatefulWidget {
  const AtlasPredictiveAiScreen({super.key, this.farmId});
  final String? farmId;

  @override
  State<AtlasPredictiveAiScreen> createState() =>
      _AtlasPredictiveAiScreenState();
}

class _AtlasPredictiveAiScreenState extends State<AtlasPredictiveAiScreen> {
  final _engine = const AtlasPredictionEngine();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _loading = true;
  List<AtlasPredictiveScenario> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AtlasPredictionRepository.instance.loadAll();
    final filtered = widget.farmId == null
        ? all
        : all
              .where((e) => e.farmId.isEmpty || e.farmId == widget.farmId)
              .toList();
    if (!mounted) return;
    setState(() {
      _items = filtered;
      _loading = false;
    });
  }

  Future<void> _edit([AtlasPredictiveScenario? initial]) async {
    final result = await showDialog<AtlasPredictiveScenario>(
      context: context,
      builder: (_) => _ScenarioDialog(
        initial: initial,
        farmId: widget.farmId ?? initial?.farmId ?? '',
      ),
    );
    if (result == null) return;
    await AtlasPredictionRepository.instance.save(result);
    await _load();
  }

  Future<void> _delete(AtlasPredictiveScenario item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cenário?'),
        content: Text('“${item.title}” será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AtlasPredictionRepository.instance.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6F8),
    appBar: AppBar(
      title: const Text(
        'Predictive Analytics & AI',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Conhecimento & aprendizado',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  AtlasKnowledgeLearningScreen(farmId: widget.farmId),
            ),
          ),
          icon: const Icon(Icons.school_outlined),
        ),
        IconButton(
          onPressed: _load,
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.auto_graph),
      label: const Text('Novo cenário'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
                children: [
                  Card(
                    color: const Color(0xFF173E55),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_alt_outlined,
                            size: 44,
                            color: Colors.white,
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Antecipe resultados antes de decidir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Simule mudanças produtivas, operacionais e financeiras, veja nível de confiança, risco, retorno e recomendação prática.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text('Nenhum cenário preditivo cadastrado.'),
                        ),
                      ),
                    )
                  else
                    ..._items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ScenarioCard(
                          result: _engine.analyze(item),
                          currency: _currency,
                          onEdit: () => _edit(item),
                          onDelete: () => _delete(item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
  );
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.result,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });
  final AtlasPredictionResult result;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final r = result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.scenario.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        r.scenario.description,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  'Receita projetada',
                  currency.format(r.projectedRevenue),
                ),
                _Metric('Custo projetado', currency.format(r.projectedCost)),
                _Metric('Lucro projetado', currency.format(r.projectedProfit)),
                _Metric('ROI anualizado', '${r.roi.toStringAsFixed(1)}%'),
                _Metric(
                  'Payback',
                  r.paybackMonths >= 999
                      ? 'Não recupera'
                      : '${r.paybackMonths.toStringAsFixed(1)} meses',
                ),
                _Metric('Confiança', '${r.confidence.toStringAsFixed(0)}%'),
                _Metric(
                  'Risco',
                  '${r.riskProbability.toStringAsFixed(0)}% • ${_risk(r.riskLevel)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              r.recommendation,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.drivers.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static String _risk(AtlasRiskLevel v) => switch (v) {
    AtlasRiskLevel.low => 'Baixo',
    AtlasRiskLevel.moderate => 'Moderado',
    AtlasRiskLevel.high => 'Alto',
    AtlasRiskLevel.critical => 'Crítico',
  };
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _ScenarioDialog extends StatefulWidget {
  const _ScenarioDialog({required this.farmId, this.initial});
  final String farmId;
  final AtlasPredictiveScenario? initial;
  @override
  State<_ScenarioDialog> createState() => _ScenarioDialogState();
}

class _ScenarioDialogState extends State<_ScenarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController title,
      description,
      investment,
      revenue,
      cost,
      productivity,
      costChange,
      revenueChange,
      capacity,
      horizon;
  late AtlasPredictionArea area;
  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    title = TextEditingController(text: i?.title ?? '');
    description = TextEditingController(text: i?.description ?? '');
    investment = TextEditingController(
      text: i?.investment.toStringAsFixed(0) ?? '0',
    );
    revenue = TextEditingController(
      text: i?.currentRevenue.toStringAsFixed(0) ?? '0',
    );
    cost = TextEditingController(
      text: i?.currentCost.toStringAsFixed(0) ?? '0',
    );
    productivity = TextEditingController(
      text: i?.productivityChange.toStringAsFixed(1) ?? '0',
    );
    costChange = TextEditingController(
      text: i?.costChange.toStringAsFixed(1) ?? '0',
    );
    revenueChange = TextEditingController(
      text: i?.revenueChange.toStringAsFixed(1) ?? '0',
    );
    capacity = TextEditingController(
      text: i?.capacityChange.toStringAsFixed(1) ?? '0',
    );
    horizon = TextEditingController(text: i?.horizonMonths.toString() ?? '12');
    area = i?.area ?? AtlasPredictionArea.production;
  }

  double _d(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initial == null
          ? 'Novo cenário preditivo'
          : 'Editar cenário preditivo',
    ),
    content: SizedBox(
      width: 720,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 2,
              ),
              DropdownButtonFormField<AtlasPredictionArea>(
                initialValue: area,
                decoration: const InputDecoration(labelText: 'Área'),
                items: AtlasPredictionArea.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(_area(e))),
                    )
                    .toList(),
                onChanged: (v) => setState(() => area = v ?? area),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _field(investment, 'Investimento (R\$)'),
                  _field(revenue, 'Receita mensal atual (R\$)'),
                  _field(cost, 'Custo mensal atual (R\$)'),
                  _field(productivity, 'Variação produtividade (%)'),
                  _field(costChange, 'Variação custos (%)'),
                  _field(revenueChange, 'Variação receita (%)'),
                  _field(capacity, 'Variação capacidade (%)'),
                  _field(horizon, 'Horizonte (meses)', integer: true),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Salvar e simular')),
    ],
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool integer = false,
  }) => SizedBox(
    width: 215,
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    ),
  );
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AtlasPredictiveScenario(
        id:
            widget.initial?.id ??
            'pred_${DateTime.now().microsecondsSinceEpoch}',
        farmId: widget.farmId,
        title: title.text.trim(),
        description: description.text.trim(),
        area: area,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        investment: _d(investment),
        currentRevenue: _d(revenue),
        currentCost: _d(cost),
        productivityChange: _d(productivity),
        costChange: _d(costChange),
        revenueChange: _d(revenueChange),
        capacityChange: _d(capacity),
        horizonMonths: int.tryParse(horizon.text) ?? 12,
      ),
    );
  }

  static String _area(AtlasPredictionArea v) => switch (v) {
    AtlasPredictionArea.reproduction => 'Reprodução',
    AtlasPredictionArea.production => 'Produção',
    AtlasPredictionArea.financial => 'Financeiro',
    AtlasPredictionArea.operational => 'Operacional',
  };
}
