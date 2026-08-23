import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_role_card.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_workspace_guide.dart';
import 'package:projeto_atlas/core/navigation/atlas_product_surface_policy.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/data/services/atlas_intelligence_service.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/domain/models/atlas_intelligence_models.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/reports_screen.dart';

class AtlasIntelligenceCenterScreen extends StatefulWidget {
  const AtlasIntelligenceCenterScreen({
    this.onNavigateModule,
    this.initialTab = 0,
    super.key,
  });

  final ValueChanged<String>? onNavigateModule;
  final int initialTab;

  @override
  State<AtlasIntelligenceCenterScreen> createState() =>
      _AtlasIntelligenceCenterScreenState();
}

class _AtlasIntelligenceCenterScreenState
    extends State<AtlasIntelligenceCenterScreen> {
  final AtlasIntelligenceService service = AtlasIntelligenceService();
  final TextEditingController saleController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController investmentController = TextEditingController();
  final TextEditingController returnController = TextEditingController();

  Map<String, dynamic>? officialContext;
  List<AtlasAiRecommendation> recommendations = const [];
  AtlasAiSimulation? simulation;
  bool loading = false;
  String? errorMessage;

  static const List<_AnalysisArea> areas = [
    _AnalysisArea(
      title: 'Rebanho',
      moduleLabel: 'Rebanho',
      aliases: ['rebanho', 'animal', 'zootec'],
      icon: Icons.pets_outlined,
      description: 'Desempenho, evolução do rebanho e qualidade dos dados.',
    ),
    _AnalysisArea(
      title: 'Sanidade',
      moduleLabel: 'Sanidade',
      aliases: ['sanidade', 'sanit', 'health', 'clínic', 'clinic'],
      icon: Icons.medical_services_outlined,
      description: 'Ocorrências, atrasos, risco sanitário e prioridades.',
    ),
    _AnalysisArea(
      title: 'Reprodução',
      moduleLabel: 'Reprodução',
      aliases: ['reprodução', 'reproduc', 'reprodut', 'prenhez'],
      icon: Icons.favorite_outline,
      description: 'Prenhez, concepção, serviços e ações reprodutivas.',
    ),
    _AnalysisArea(
      title: 'Nutrição',
      moduleLabel: 'Nutrição',
      aliases: ['nutrição', 'nutric', 'nutrition', 'dieta'],
      icon: Icons.restaurant_outlined,
      description: 'Planos, consumo, desempenho e integração com estoque.',
    ),
    _AnalysisArea(
      title: 'Estoque',
      moduleLabel: 'Estoque',
      aliases: ['estoque', 'inventory', 'insumo', 'suprimento'],
      icon: Icons.inventory_2_outlined,
      description: 'Ruptura, validade, reposição e risco de falta de insumos.',
    ),
    _AnalysisArea(
      title: 'Financeiro',
      moduleLabel: 'Financeiro',
      aliases: ['finance', 'financeiro', 'custo', 'caixa', 'receita'],
      icon: Icons.account_balance_wallet_outlined,
      description: 'Resultado, compromissos e leitura do ciclo pecuário.',
    ),
    _AnalysisArea(
      title: 'Campo',
      moduleLabel: 'Campo',
      aliases: ['campo', 'piquete', 'pastagem', 'operação', 'operacao'],
      icon: Icons.agriculture_outlined,
      description: 'Piquetes, operações, equipe e execução de campo.',
    ),
  ];

  @override
  void dispose() {
    saleController.dispose();
    costController.dispose();
    investmentController.dispose();
    returnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AtlasSessionScope.of(context);
    final farm = session.activeFarm;
    final initialIndex = widget.initialTab.clamp(0, 4);

    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumo'),
            Tab(icon: Icon(Icons.task_alt_outlined), text: 'O que fazer'),
            Tab(icon: Icon(Icons.grid_view_outlined), text: 'Por área'),
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Simular'),
            Tab(icon: Icon(Icons.rule_outlined), text: 'Decisões'),
          ],
        ),
        body: farm == null
            ? const Center(
                child: Text('Escolha uma fazenda para abrir as análises.'),
              )
            : Stack(
                children: [
                  TabBarView(
                    children: [
                      buildSummary(context, farm.id),
                      buildRecommendations(context, farm.id),
                      buildAreas(context, farm.id),
                      buildSimulator(context, farm.id),
                      buildDecisions(context, farm.id),
                    ],
                  ),
                  if (loading) const LinearProgressIndicator(),
                ],
              ),
      ),
    );
  }

  Widget buildSummary(BuildContext context, String farmId) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Análises da fazenda',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Veja a situação geral e depois entre apenas na área que precisa de '
          'atenção. Os dados vêm dos módulos oficiais do Atlas.',
        ),
        const SizedBox(height: 16),
        AtlasModuleWorkspaceGuide(
          moduleLabel: 'Análises',
          workflows:
              AtlasProductSurfacePolicy.moduleWorkflows['Análises'] ??
                  const <String>[],
          specializedFamilies:
              AtlasProductSurfacePolicy
                      .specializedCapabilityCountByOwner['Análises'] ??
                  0,
        ),
        const SizedBox(height: 16),
        AtlasModuleRoleCard(
          title: 'Análises transforma dados em decisão',
          responsibility:
              AtlasProductSurfacePolicy.moduleResponsibility['Análises']!,
          doesNotReplace:
              AtlasProductSurfacePolicy.moduleDoesNotReplace['Análises']!,
          icon: Icons.insights_outlined,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => loadContext(farmId),
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Atualizar resumo'),
            ),
            OutlinedButton.icon(
              onPressed: openReports,
              icon: const Icon(Icons.bar_chart_outlined),
              label: const Text('Abrir relatórios'),
            ),
          ],
        ),
        if (errorMessage != null) errorCard(),
        if (officialContext == null)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Resumo ainda não atualizado'),
                subtitle: Text(
                  'Toque em Atualizar resumo para combinar os dados oficiais '
                  'da fazenda, rebanho, sanidade, reprodução, nutrição, estoque '
                  'e financeiro.',
                ),
              ),
            ),
          ),
        if (officialContext != null) ...[
          const SizedBox(height: 16),
          mapCard('Qualidade dos dados', officialContext!['quality']),
          mapCard('Situação consolidada', officialContext!['payload']),
        ],
      ],
    );
  }

  Widget buildRecommendations(BuildContext context, String farmId) {
    return RefreshIndicator(
      onRefresh: () => loadRecommendations(farmId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'O que fazer agora',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Prioridades explicadas com evidências, confiança e limitações. '
            'Nenhuma ação crítica é executada sem confirmação.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => loadRecommendations(farmId),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Atualizar prioridades'),
          ),
          if (errorMessage != null) errorCard(),
          if (recommendations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Nenhuma prioridade calculada ainda.'),
              ),
            ),
          ...recommendations.map(buildRecommendationCard),
        ],
      ),
    );
  }

  Widget buildAreas(BuildContext context, String farmId) {
    return RefreshIndicator(
      onRefresh: () => loadRecommendations(farmId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Análises por área',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cada assunto fica no módulo que é dono do dado. Aqui você vê o '
            'resumo e abre diretamente a área certa, sem telas intermediárias.',
          ),
          const SizedBox(height: 14),
          if (recommendations.isEmpty)
            OutlinedButton.icon(
              onPressed: () => loadRecommendations(farmId),
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Atualizar análises por área'),
            ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: areas
                    .map(
                      (area) => SizedBox(
                        width: width,
                        child: buildAreaCard(area),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildSimulator(BuildContext context, String farmId) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Simular uma decisão',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Compare receita, custo, investimento e retorno antes de tomar uma '
          'decisão. A simulação não altera nenhum dado da fazenda.',
        ),
        const SizedBox(height: 16),
        numberField(saleController, 'Receita de venda'),
        numberField(costController, 'Custo adicional'),
        numberField(investmentController, 'Investimento'),
        numberField(returnController, 'Retorno esperado'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => simulate(farmId),
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Calcular cenário'),
        ),
        if (simulation != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variação projetada: R\$ ${simulation!.projectedVariation.toStringAsFixed(2)}',
                  ),
                  Text(
                    'ROI: ${simulation!.roiPercent?.toStringAsFixed(2) ?? 'não calculado'}%',
                  ),
                  Text(
                    'Confiança: ${(simulation!.confidence * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildDecisions(BuildContext context, String farmId) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Decisões e confirmações',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Você continua no controle'),
            subtitle: Text(
              'O Atlas pode recomendar e preparar ações, mas ações críticas '
              'ficam pendentes até uma pessoa confirmar.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: recommendations.isEmpty
              ? null
              : () => createSupervisedAction(farmId, recommendations.first),
          icon: const Icon(Icons.add_task_outlined),
          label: const Text('Preparar ação da primeira prioridade'),
        ),
        if (recommendations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Atualize O que fazer primeiro para ter uma prioridade disponível.',
            ),
          ),
      ],
    );
  }

  Widget buildRecommendationCard(AtlasAiRecommendation item) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.lightbulb_outline),
        title: Text(item.title),
        subtitle: Text(
          '${simpleArea(item.area)} • ${simplePriority(item.priority)} • '
          '${(item.confidence * 100).toStringAsFixed(0)}% de confiança',
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
            child: Text('Sugestão: ${item.action}'),
          ),
          if (item.evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Por quê: ${item.evidence.join(' • ')}'),
            ),
          ],
          if (item.limitations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Atenção: ${item.limitations.join(' • ')}'),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => decide(item, 'accepted'),
                child: const Text('Concordo'),
              ),
              OutlinedButton(
                onPressed: () => decide(item, 'deferred'),
                child: const Text('Ver depois'),
              ),
              TextButton(
                onPressed: () => decide(item, 'rejected'),
                child: const Text('Não seguir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAreaCard(_AnalysisArea area) {
    final matches = recommendations.where((item) {
      final haystack = '${item.area} ${item.title} ${item.description}'
          .toLowerCase();
      return area.aliases.any((alias) => haystack.contains(alias));
    }).toList(growable: false);

    final top = matches.isEmpty ? null : matches.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(area.icon)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    area.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (matches.isNotEmpty)
                  Chip(label: Text('${matches.length} ponto(s)')),
              ],
            ),
            const SizedBox(height: 10),
            Text(area.description),
            const SizedBox(height: 10),
            ...(
              AtlasProductSurfacePolicy.moduleWorkflows[area.title] ??
                  const <String>[]
            ).map(
              (workflow) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        workflow,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if ((AtlasProductSurfacePolicy
                        .specializedCapabilityCountByOwner[area.title] ??
                    0) >
                0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${AtlasProductSurfacePolicy.specializedCapabilityCountByOwner[area.title]} '
                  'família(s) especializada(s) já organizada(s) nesta área.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (top != null) ...[
              const SizedBox(height: 10),
              Text(
                top.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onNavigateModule == null
                    ? null
                    : () => widget.onNavigateModule!(area.moduleLabel),
                icon: const Icon(Icons.arrow_forward_outlined),
                label: Text('Abrir ${area.title}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget mapCard(String title, Object? data) {
    return Card(
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
  }

  Widget errorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(errorMessage ?? 'Não foi possível atualizar.'),
      ),
    );
  }

  void openReports() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  Future<void> loadContext(String farmId) async {
    await runRequest(() async {
      officialContext = await service.buildContext(farmId);
    });
  }

  Future<void> loadRecommendations(String farmId) async {
    await runRequest(() async {
      recommendations = await service.recommendations(farmId);
    });
  }

  Future<void> decide(AtlasAiRecommendation item, String decision) async {
    await runRequest(() => service.decide(item.id, decision));
    if (mounted) showMessage('Decisão registrada.');
  }

  Future<void> simulate(String farmId) async {
    await runRequest(() async {
      double parse(TextEditingController controller) {
        return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
      }

      simulation = await service.simulate(
        farmId,
        saleAmount: parse(saleController),
        extraCost: parse(costController),
        investment: parse(investmentController),
        expectedReturn: parse(returnController),
      );
    });
  }

  Future<void> createSupervisedAction(
    String farmId,
    AtlasAiRecommendation item,
  ) async {
    await runRequest(
      () => service.createAutomation(
        farmId,
        recommendationId: item.id,
        actionType: 'recommendation_action',
        payload: {'title': item.title, 'action': item.action},
      ),
    );
    if (mounted) showMessage('Ação preparada e enviada para confirmação.');
  }

  Future<void> runRequest(Future<void> Function() action) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String simpleArea(String value) {
    final normalized = value.toLowerCase();
    for (final area in areas) {
      if (area.aliases.any(normalized.contains)) return area.title;
    }
    return value.trim().isEmpty ? 'Geral' : value;
  }

  String simplePriority(String value) {
    return switch (value.toLowerCase()) {
      'critical' || 'critico' || 'crítico' => 'Urgente',
      'high' || 'alto' || 'alta' => 'Alta',
      'medium' || 'medio' || 'médio' || 'media' || 'média' => 'Média',
      'low' || 'baixo' || 'baixa' => 'Baixa',
      _ => value,
    };
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AnalysisArea {
  const _AnalysisArea({
    required this.title,
    required this.moduleLabel,
    required this.aliases,
    required this.icon,
    required this.description,
  });

  final String title;
  final String moduleLabel;
  final List<String> aliases;
  final IconData icon;
  final String description;
}
