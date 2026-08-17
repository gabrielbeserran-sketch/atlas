import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/action_plan/data/services/atlas_action_plan_storage_service.dart';
import 'package:projeto_atlas/features/continuous_improvement/data/services/atlas_improvement_history_service.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/knowledge_learning/data/services/atlas_knowledge_repository.dart';
import 'package:projeto_atlas/features/knowledge_learning/domain/models/atlas_knowledge_case.dart';
import 'package:projeto_atlas/features/knowledge_learning/domain/services/atlas_knowledge_learning_engine.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/presentation/screens/atlas_recommendation_intelligence_screen.dart';

class AtlasKnowledgeLearningScreen extends StatefulWidget {
  const AtlasKnowledgeLearningScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasKnowledgeLearningScreen> createState() =>
      _AtlasKnowledgeLearningScreenState();
}

class _AtlasKnowledgeLearningScreenState
    extends State<AtlasKnowledgeLearningScreen> {
  final _engine = const AtlasKnowledgeLearningEngine();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool loading = true;
  bool learning = false;
  AtlasFarmAuditArea? areaFilter;
  AtlasKnowledgeStatus? statusFilter;
  AtlasKnowledgeOverview overview = const AtlasKnowledgeOverview(
    cases: <AtlasKnowledgeCase>[],
    protocols: <AtlasKnowledgeProtocol>[],
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cases = await AtlasKnowledgeRepository.instance.loadCases();
    final filtered = widget.farmId == null
        ? cases
        : cases
              .where(
                (item) => item.farmId.isEmpty || item.farmId == widget.farmId,
              )
              .toList();
    if (!mounted) return;
    setState(() {
      overview = _engine.buildOverview(filtered);
      loading = false;
    });
  }

  Future<void> _learn() async {
    if (learning) return;
    setState(() => learning = true);
    try {
      final cycles = await AtlasImprovementHistoryService.instance.loadAll();
      final selected = widget.farmId == null
          ? cycles
          : cycles.where((item) => item.farmId == widget.farmId).toList();
      final learned = <AtlasKnowledgeCase>[];
      for (final cycle in selected.take(20)) {
        final plan = await AtlasActionPlanStorageService.instance.latestForFarm(
          cycle.farmId,
        );
        if (plan == null) continue;
        learned.addAll(_engine.learn(cycle: cycle, plan: plan));
      }
      await AtlasKnowledgeRepository.instance.addCases(learned);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              learned.isEmpty
                  ? 'Nenhum novo caso concluído foi encontrado.'
                  : '${learned.length} caso(s) incorporado(s) à memória técnica.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => learning = false);
    }
  }

  Future<void> _edit([AtlasKnowledgeCase? initial]) async {
    final result = await showDialog<AtlasKnowledgeCase>(
      context: context,
      builder: (_) => _KnowledgeDialog(
        initial: initial,
        farmId: widget.farmId ?? initial?.farmId ?? '',
      ),
    );
    if (result == null) return;
    await AtlasKnowledgeRepository.instance.save(result);
    await _load();
  }

  Future<void> _delete(AtlasKnowledgeCase item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir caso?'),
        content: Text('“${item.problem}” será removido da memória técnica.'),
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
    if (confirmed != true) return;
    await AtlasKnowledgeRepository.instance.delete(item.id);
    await _load();
  }

  Future<void> _toggleBestPractice(AtlasKnowledgeCase item) async {
    final next = item.status == AtlasKnowledgeStatus.bestPractice
        ? AtlasKnowledgeStatus.validated
        : AtlasKnowledgeStatus.bestPractice;
    await AtlasKnowledgeRepository.instance.save(item.copyWith(status: next));
    await _load();
  }

  List<AtlasKnowledgeCase> get _visibleCases => overview.cases.where((item) {
    final areaOk = areaFilter == null || item.area == areaFilter;
    final statusOk = statusFilter == null || item.status == statusFilter;
    return areaOk && statusOk;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Knowledge & Learning Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Recomendações inteligentes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AtlasRecommendationIntelligenceScreen(
                  farmId: widget.farmId,
                ),
              ),
            ),
            icon: const Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            tooltip: 'Aprender com ciclos concluídos',
            onPressed: learning ? null : _learn,
            icon: learning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar aprendizado'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
                  children: [
                    _Hero(overview: overview, currency: _currency),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Biblioteca de protocolos',
                      subtitle:
                          'Boas práticas consolidadas por área, confiança, casos e taxa de sucesso.',
                    ),
                    const SizedBox(height: 12),
                    if (overview.protocols.isEmpty)
                      const _EmptyCard(
                        text:
                            'Ainda não existem protocolos consolidados. Registre casos ou aprenda com ciclos concluídos.',
                      )
                    else
                      ...overview.protocols.map(
                        (item) =>
                            _ProtocolCard(protocol: item, currency: _currency),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(
                            title: 'Casos, decisões e lições aprendidas',
                            subtitle:
                                'Compare previsão e resultado real, valide práticas e preserve a memória da fazenda.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 190,
                          child: DropdownButtonFormField<AtlasFarmAuditArea?>(
                            initialValue: areaFilter,
                            decoration: const InputDecoration(
                              labelText: 'Área',
                            ),
                            items: [
                              const DropdownMenuItem<AtlasFarmAuditArea?>(
                                value: null,
                                child: Text('Todas'),
                              ),
                              ...AtlasFarmAuditArea.values.map(
                                (item) => DropdownMenuItem<AtlasFarmAuditArea?>(
                                  value: item,
                                  child: Text(atlasFarmAuditAreaLabel(item)),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => areaFilter = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<AtlasKnowledgeStatus?>(
                            initialValue: statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: [
                              const DropdownMenuItem<AtlasKnowledgeStatus?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...AtlasKnowledgeStatus.values.map(
                                (item) =>
                                    DropdownMenuItem<AtlasKnowledgeStatus?>(
                                      value: item,
                                      child: Text(_statusLabel(item)),
                                    ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => statusFilter = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_visibleCases.isEmpty)
                      const _EmptyCard(
                        text:
                            'Nenhum caso corresponde aos filtros selecionados.',
                      )
                    else
                      ..._visibleCases.map(
                        (item) => _CaseCard(
                          item: item,
                          currency: _currency,
                          onEdit: () => _edit(item),
                          onDelete: () => _delete(item),
                          onBestPractice: () => _toggleBestPractice(item),
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
  const _Hero({required this.overview, required this.currency});
  final AtlasKnowledgeOverview overview;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF283593), Color(0xFF5E35B1)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Memória técnica do Atlas',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Conhecimento que melhora cada nova decisão',
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
              _HeroMetric('Casos aprendidos', '${overview.learnedCases}'),
              _HeroMetric('Protocolos ativos', '${overview.activeProtocols}'),
              _HeroMetric('Boas práticas', '${overview.bestPractices}'),
              _HeroMetric(
                'Sucesso',
                '${overview.successRate.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                'Aderência',
                '${overview.implementationRate.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                'Precisão preditiva',
                '${overview.averagePredictionAccuracy.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                'Ganho médio',
                currency.format(overview.averageEconomicGain),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.protocol, required this.currency});
  final AtlasKnowledgeProtocol protocol;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
        title: Text(
          protocol.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${protocol.caseCount} casos · ${protocol.successRate.toStringAsFixed(1)}% de sucesso · confiança ${protocol.confidence.toStringAsFixed(1)}%',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(protocol.description),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _Metric(
                'Resposta média',
                '${protocol.averageResponseDays.toStringAsFixed(0)} dias',
              ),
              _Metric(
                'Ganho médio',
                currency.format(protocol.averageEconomicGain),
              ),
              _Metric(
                'Confiança',
                '${protocol.confidence.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
    required this.onBestPractice,
  });

  final AtlasKnowledgeCase item;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBestPractice;

  @override
  Widget build(BuildContext context) {
    final accuracy = item.predictionAccuracy;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              (item.success ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00))
                  .withValues(alpha: 0.12),
          child: Icon(
            item.success
                ? Icons.verified_outlined
                : Icons.warning_amber_outlined,
            color: item.success
                ? const Color(0xFF2E7D32)
                : const Color(0xFFEF6C00),
          ),
        ),
        title: Text(
          item.problem,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${atlasFarmAuditAreaLabel(item.area)} · ${item.farmName} · ${_statusLabel(item.status)}',
        ),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: item.status == AtlasKnowledgeStatus.bestPractice
                  ? 'Remover de boas práticas'
                  : 'Marcar como boa prática',
              onPressed: onBestPractice,
              icon: Icon(
                item.status == AtlasKnowledgeStatus.bestPractice
                    ? Icons.star
                    : Icons.star_border,
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
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _TextBlock('Intervenção', item.intervention),
          _TextBlock('Resultado real', item.outcome),
          _TextBlock('Lições aprendidas', '• ${item.lessons.join('\n• ')}'),
          if (item.notes.isNotEmpty) _TextBlock('Observações', item.notes),
          const SizedBox(height: 10),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _Metric('Antes', item.beforeValue.toStringAsFixed(1)),
              if (item.predictedValue != null)
                _Metric('Previsto', item.predictedValue!.toStringAsFixed(1)),
              _Metric('Realizado', item.afterValue.toStringAsFixed(1)),
              if (accuracy != null)
                _Metric('Precisão', '${accuracy.toStringAsFixed(1)}%'),
              _Metric('Resposta', '${item.responseDays} dias'),
              _Metric('Ganho econômico', currency.format(item.economicGain)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KnowledgeDialog extends StatefulWidget {
  const _KnowledgeDialog({required this.farmId, this.initial});
  final String farmId;
  final AtlasKnowledgeCase? initial;

  @override
  State<_KnowledgeDialog> createState() => _KnowledgeDialogState();
}

class _KnowledgeDialogState extends State<_KnowledgeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController farmName;
  late final TextEditingController problem;
  late final TextEditingController intervention;
  late final TextEditingController outcome;
  late final TextEditingController before;
  late final TextEditingController predicted;
  late final TextEditingController after;
  late final TextEditingController days;
  late final TextEditingController predictedGain;
  late final TextEditingController economicGain;
  late final TextEditingController lessons;
  late final TextEditingController notes;
  late AtlasFarmAuditArea area;
  late AtlasKnowledgeStatus status;
  late bool success;
  late bool implemented;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    farmName = TextEditingController(text: item?.farmName ?? 'Fazenda');
    problem = TextEditingController(text: item?.problem ?? '');
    intervention = TextEditingController(text: item?.intervention ?? '');
    outcome = TextEditingController(text: item?.outcome ?? '');
    before = TextEditingController(text: item?.beforeValue.toString() ?? '0');
    predicted = TextEditingController(
      text: item?.predictedValue?.toString() ?? '',
    );
    after = TextEditingController(text: item?.afterValue.toString() ?? '0');
    days = TextEditingController(text: item?.responseDays.toString() ?? '0');
    predictedGain = TextEditingController(
      text: item?.predictedEconomicGain?.toString() ?? '',
    );
    economicGain = TextEditingController(
      text: item?.economicGain.toString() ?? '0',
    );
    lessons = TextEditingController(text: item?.lessons.join('\n') ?? '');
    notes = TextEditingController(text: item?.notes ?? '');
    area = item?.area ?? AtlasFarmAuditArea.operational;
    status = item?.status ?? AtlasKnowledgeStatus.validated;
    success = item?.success ?? true;
    implemented = item?.recommendationImplemented ?? true;
  }

  double _double(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  double? _nullableDouble(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Registrar aprendizado' : 'Editar aprendizado',
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: problem,
                  decoration: const InputDecoration(
                    labelText: 'Problema ou decisão analisada',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o problema ou decisão'
                      : null,
                ),
                TextFormField(
                  controller: farmName,
                  decoration: const InputDecoration(labelText: 'Fazenda'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AtlasFarmAuditArea>(
                        initialValue: area,
                        decoration: const InputDecoration(labelText: 'Área'),
                        items: AtlasFarmAuditArea.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(atlasFarmAuditAreaLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => area = value ?? area),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<AtlasKnowledgeStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: AtlasKnowledgeStatus.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(_statusLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => status = value ?? status),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: intervention,
                  decoration: const InputDecoration(labelText: 'Intervenção'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: outcome,
                  decoration: const InputDecoration(
                    labelText: 'Resultado real',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _number(before, 'Valor antes'),
                    _number(predicted, 'Valor previsto'),
                    _number(after, 'Valor realizado'),
                    _number(days, 'Resposta (dias)'),
                    _number(predictedGain, 'Ganho previsto (R\$)'),
                    _number(economicGain, 'Ganho realizado (R\$)'),
                  ],
                ),
                TextFormField(
                  controller: lessons,
                  decoration: const InputDecoration(
                    labelText: 'Lições aprendidas (uma por linha)',
                  ),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Observações'),
                  maxLines: 2,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: implemented,
                  onChanged: (value) => setState(() => implemented = value),
                  title: const Text('Recomendação implementada'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: success,
                  onChanged: (value) => setState(() => success = value),
                  title: const Text('Resultado considerado bem-sucedido'),
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
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }

  Widget _number(TextEditingController controller, String label) => SizedBox(
    width: 220,
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AtlasKnowledgeCase(
        id:
            widget.initial?.id ??
            'knowledge_${DateTime.now().microsecondsSinceEpoch}',
        farmId: widget.farmId,
        farmName: farmName.text.trim().isEmpty
            ? 'Fazenda'
            : farmName.text.trim(),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        area: area,
        problem: problem.text.trim(),
        intervention: intervention.text.trim(),
        outcome: outcome.text.trim(),
        beforeValue: _double(before),
        predictedValue: _nullableDouble(predicted),
        afterValue: _double(after),
        responseDays: int.tryParse(days.text) ?? 0,
        predictedEconomicGain: _nullableDouble(predictedGain),
        economicGain: _double(economicGain),
        success: success,
        lessons: lessons.text
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        source: widget.initial?.source ?? AtlasKnowledgeSource.manual,
        status: status,
        recommendationImplemented: implemented,
        notes: notes.text.trim(),
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock(this.label, this.text);
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text('$label:\n$text', style: const TextStyle(height: 1.4)),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 145),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

String _statusLabel(AtlasKnowledgeStatus value) => switch (value) {
  AtlasKnowledgeStatus.draft => 'Rascunho',
  AtlasKnowledgeStatus.validated => 'Validado',
  AtlasKnowledgeStatus.bestPractice => 'Boa prática',
  AtlasKnowledgeStatus.needsReview => 'Requer revisão',
};
