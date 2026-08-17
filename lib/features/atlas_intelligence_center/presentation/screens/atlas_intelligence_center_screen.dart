import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/data/services/atlas_intelligence_service.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/domain/models/atlas_intelligence_models.dart';

class AtlasIntelligenceCenterScreen extends StatefulWidget {
  const AtlasIntelligenceCenterScreen({super.key});

  @override
  State<AtlasIntelligenceCenterScreen> createState() =>
      _AtlasIntelligenceCenterScreenState();
}

class _AtlasIntelligenceCenterScreenState
    extends State<AtlasIntelligenceCenterScreen> {
  final _service = AtlasIntelligenceService();
  final _sale = TextEditingController();
  final _cost = TextEditingController();
  final _investment = TextEditingController();
  final _returnValue = TextEditingController();
  Map<String, dynamic>? _context;
  List<AtlasAiRecommendation> _recommendations = const [];
  AtlasAiSimulation? _simulation;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _sale.dispose();
    _cost.dispose();
    _investment.dispose();
    _returnValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AtlasSessionScope.of(context);
    final farm = session.activeFarm;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.dashboard_customize), text: 'Executivo'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Recomendações'),
            Tab(icon: Icon(Icons.hub_outlined), text: 'Agentes'),
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Simulador'),
            Tab(icon: Icon(Icons.approval_outlined), text: 'Automações'),
          ],
        ),
        body: farm == null
            ? const Center(
                child: Text(
                  'Selecione uma fazenda para usar a inteligência Atlas.',
                ),
              )
            : Stack(
                children: [
                  TabBarView(
                    children: [
                      _executive(context, farm.id),
                      _recommendationView(context, farm.id),
                      _agents(context, farm.id),
                      _simulator(context, farm.id),
                      _automations(context, farm.id),
                    ],
                  ),
                  if (_loading) const LinearProgressIndicator(),
                ],
              ),
      ),
    );
  }

  Widget _executive(BuildContext context, String farmId) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Painel executivo inteligente',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'O contexto oficial combina dados da fazenda, rebanho, reprodução, '
        'sanidade, nutrição, estoque e financeiro com qualidade e limitações.',
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => _loadContext(farmId),
        icon: const Icon(Icons.psychology_outlined),
        label: const Text('Gerar contexto oficial'),
      ),
      if (_error != null) _errorCard(),
      if (_context != null) ...[
        const SizedBox(height: 16),
        _mapCard('Qualidade dos dados', _context!['quality']),
        _mapCard('Resumo oficial', _context!['payload']),
      ],
    ],
  );

  Widget _recommendationView(
    BuildContext context,
    String farmId,
  ) => RefreshIndicator(
    onRefresh: () => _loadRecommendations(farmId),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: () => _loadRecommendations(farmId),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Gerar recomendações auditáveis'),
        ),
        if (_error != null) _errorCard(),
        if (_recommendations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Nenhuma recomendação gerada ainda.')),
          ),
        ..._recommendations.map(
          (item) => Card(
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(item.title),
              subtitle: Text(
                '${item.area} • ${item.priority} • '
                '${(item.confidence * 100).toStringAsFixed(0)}%',
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.description),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ação: ${item.action}'),
                ),
                const SizedBox(height: 8),
                if (item.evidence.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Evidências: ${item.evidence.join(' • ')}'),
                  ),
                if (item.limitations.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Limitações: ${item.limitations.join(' • ')}'),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _decide(item, 'accepted'),
                      child: const Text('Aceitar'),
                    ),
                    OutlinedButton(
                      onPressed: () => _decide(item, 'deferred'),
                      child: const Text('Adiar'),
                    ),
                    TextButton(
                      onPressed: () => _decide(item, 'rejected'),
                      child: const Text('Rejeitar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _agents(BuildContext context, String farmId) {
    const agents = [
      ('Reprodutivo', Icons.favorite_outline),
      ('Sanitário', Icons.medical_services_outlined),
      ('Nutricional', Icons.restaurant_outlined),
      ('Financeiro', Icons.account_balance_wallet_outlined),
    ];
    return GridView.extent(
      padding: const EdgeInsets.all(20),
      maxCrossAxisExtent: 320,
      childAspectRatio: 1.5,
      children: agents
          .map(
            (agent) => Card(
              child: InkWell(
                onTap: () => _loadRecommendations(farmId),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(agent.$2, size: 38),
                      const SizedBox(height: 12),
                      Text(
                        'Agente ${agent.$1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Evidências, confiança e limitações auditáveis.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _simulator(BuildContext context, String farmId) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Simulador empresarial',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      _number(_sale, 'Receita de venda'),
      _number(_cost, 'Custo adicional'),
      _number(_investment, 'Investimento'),
      _number(_returnValue, 'Retorno esperado'),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => _simulate(farmId),
        icon: const Icon(Icons.calculate),
        label: const Text('Simular cenário'),
      ),
      if (_simulation != null) ...[
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Variação projetada: R\$ ${_simulation!.projectedVariation.toStringAsFixed(2)}',
                ),
                Text(
                  'ROI: ${_simulation!.roiPercent?.toStringAsFixed(2) ?? 'não calculado'}%',
                ),
                Text(
                  'Confiança: ${(_simulation!.confidence * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  Widget _automations(BuildContext context, String farmId) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Automações supervisionadas',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Card(
        child: ListTile(
          leading: Icon(Icons.verified_user_outlined),
          title: Text('Aprovação humana obrigatória'),
          subtitle: Text(
            'Ações críticas são registradas como pending_approval e não '
            'são executadas silenciosamente.',
          ),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _recommendations.isEmpty
            ? null
            : () => _createAutomation(farmId, _recommendations.first),
        icon: const Icon(Icons.add_task),
        label: const Text('Criar ação supervisionada da primeira recomendação'),
      ),
    ],
  );

  Widget _number(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _mapCard(String title, Object? data) => Card(
    child: ExpansionTile(
      title: Text(title),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(data?.toString() ?? 'Sem dados'),
        ),
      ],
    ),
  );

  Widget _errorCard() => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(_error ?? 'Erro'),
    ),
  );

  Future<void> _loadContext(String farmId) async => _run(() async {
    _context = await _service.buildContext(farmId);
  });

  Future<void> _loadRecommendations(String farmId) async => _run(() async {
    _recommendations = await _service.recommendations(farmId);
  });

  Future<void> _decide(AtlasAiRecommendation item, String decision) async {
    await _run(() => _service.decide(item.id, decision));
    if (mounted) _message('Decisão registrada: $decision');
  }

  Future<void> _simulate(String farmId) async => _run(() async {
    double parse(TextEditingController value) =>
        double.tryParse(value.text.replaceAll(',', '.')) ?? 0;
    _simulation = await _service.simulate(
      farmId,
      saleAmount: parse(_sale),
      extraCost: parse(_cost),
      investment: parse(_investment),
      expectedReturn: parse(_returnValue),
    );
  });

  Future<void> _createAutomation(
    String farmId,
    AtlasAiRecommendation item,
  ) async {
    await _run(
      () => _service.createAutomation(
        farmId,
        recommendationId: item.id,
        actionType: 'recommendation_action',
        payload: {'title': item.title, 'action': item.action},
      ),
    );
    if (mounted) _message('Automação criada e enviada para aprovação.');
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
