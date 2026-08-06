import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/predictive_ai/presentation/screens/atlas_predictive_ai_screen.dart';
import '../../data/services/atlas_performance_repository.dart';
import '../../domain/models/atlas_performance_analysis.dart';
import '../../domain/models/atlas_performance_kpi.dart';
import '../../domain/services/atlas_performance_engine.dart';

class AtlasPerformanceDashboardScreen extends StatefulWidget {
  const AtlasPerformanceDashboardScreen({super.key, this.farmId});
  final String? farmId;

  @override
  State<AtlasPerformanceDashboardScreen> createState() => _AtlasPerformanceDashboardScreenState();
}

class _AtlasPerformanceDashboardScreenState extends State<AtlasPerformanceDashboardScreen> {
  final _engine = const AtlasPerformanceEngine();
  final AtlasReactiveIntelligenceCoordinator _reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  bool _loading = true;
  bool _refreshing = false;
  bool _refreshRequested = false;
  late final String _reactiveRegistrationId;
  List<AtlasPerformanceKpi> _kpis = const [];
  AtlasKpiCategory? _filter;

  @override
  void initState() {
    super.initState();
    AtlasReactiveRuntime.instance.start();
    _reactiveRegistrationId = _reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.performanceIntelligence,
      owner: 'atlas_performance_dashboard_screen',
      handler: _handleReactiveUpdate,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.performanceIntelligence,
      registrationId: _reactiveRegistrationId,
    );
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.performanceIntelligence)) {
      return;
    }

    final farmId = widget.farmId;
    final hasRelevantEvent = farmId == null ||
        update.events.any((event) {
          final eventFarmId = event.farmId?.trim();
          return eventFarmId == null ||
              eventFarmId.isEmpty ||
              eventFarmId == farmId;
        });

    if (!hasRelevantEvent) {
      return;
    }

    await _load(showLoading: false);
  }

  Future<void> _load({bool showLoading = true}) async {
    if (_refreshing) {
      _refreshRequested = true;
      return;
    }

    _refreshing = true;

    if (showLoading && mounted) {
      setState(() => _loading = true);
    }

    try {
      final all = await AtlasPerformanceRepository.instance.loadAll();
    final filtered = widget.farmId == null ? all : all.where((e) => e.farmId.isEmpty || e.farmId == widget.farmId).toList();
      if (!mounted) return;
      setState(() { _kpis = filtered; _loading = false; });
    } finally {
      _refreshing = false;

      if (_refreshRequested && mounted) {
        _refreshRequested = false;
        unawaited(_load(showLoading: false));
      }
    }
  }

  Future<void> _edit([AtlasPerformanceKpi? initial]) async {
    final result = await showDialog<AtlasPerformanceKpi>(
      context: context,
      builder: (_) => _KpiDialog(initial: initial, farmId: widget.farmId ?? initial?.farmId ?? ''),
    );
    if (result == null) return;
    await AtlasPerformanceRepository.instance.save(result);
    await _load();
  }

  Future<void> _delete(AtlasPerformanceKpi kpi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir indicador?'),
        content: Text('O indicador “${kpi.name}” será removido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    await AtlasPerformanceRepository.instance.delete(kpi.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter == null ? _kpis : _kpis.where((e) => e.category == _filter).toList();
    final analysis = _engine.analyze(_kpis);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Performance Intelligence & KPI', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AtlasPredictiveAiScreen(farmId: widget.farmId))), tooltip: 'Abrir análise preditiva', icon: const Icon(Icons.psychology_alt_outlined)), IconButton(onPressed: _load, tooltip: 'Atualizar', icon: const Icon(Icons.refresh)), const SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add_chart), label: const Text('Novo KPI')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
            children: [
              const _Hero(),
              const SizedBox(height: 18),
              _ScoreGrid(scorecard: analysis),
              const SizedBox(height: 18),
              _Alerts(alerts: analysis.alerts),
              const SizedBox(height: 22),
              _Filters(selected: _filter, onChanged: (value) => setState(() => _filter = value)),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                const _EmptyState()
              else
                ...visible.map((kpi) {
                  final evaluation = analysis.evaluations.firstWhere((e) => e.kpi.id == kpi.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _KpiCard(evaluation: evaluation, onEdit: () => _edit(kpi), onDelete: () => _delete(kpi)),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF123B36),
    child: const Padding(
      padding: EdgeInsets.all(24),
      child: Row(children: [
        Icon(Icons.insights_outlined, size: 42, color: Colors.white),
        SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Inteligência de desempenho', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 7),
          Text('Consolide indicadores produtivos, financeiros, operacionais e estratégicos. Compare meta, resultado, tendência e nível de atenção.', style: TextStyle(color: Colors.white70, height: 1.4)),
        ])),
      ]),
    ),
  );
}

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.scorecard});
  final AtlasPerformanceScorecard scorecard;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final width = constraints.maxWidth >= 1000 ? (constraints.maxWidth - 48) / 5 : constraints.maxWidth >= 620 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
    final items = <({String label, double value, IconData icon})>[
      (label: 'Índice geral', value: scorecard.overallScore, icon: Icons.speed_outlined),
      (label: 'Produtivo', value: scorecard.productiveScore, icon: Icons.agriculture_outlined),
      (label: 'Financeiro', value: scorecard.financialScore, icon: Icons.account_balance_wallet_outlined),
      (label: 'Operacional', value: scorecard.operationalScore, icon: Icons.precision_manufacturing_outlined),
      (label: 'Estratégico', value: scorecard.strategicScore, icon: Icons.flag_outlined),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: items.map((item) => SizedBox(width: width, child: _ScoreCard(label: item.label, value: item.value, icon: item.icon))).toList());
  });
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.value, required this.icon});
  final String label;
  final double value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final color = value >= 95 ? const Color(0xFF17735F) : value >= 80 ? const Color(0xFFB7791F) : const Color(0xFFB42318);
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
      CircleAvatar(backgroundColor: color.withValues(alpha: .10), child: Icon(icon, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 5), Text('${value.toStringAsFixed(0)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))])),
    ])));
  }
}

class _Alerts extends StatelessWidget {
  const _Alerts({required this.alerts});
  final List<AtlasPerformanceAlert> alerts;
  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const Card(child: ListTile(leading: Icon(Icons.verified_outlined, color: Color(0xFF17735F)), title: Text('Nenhum alerta relevante'), subtitle: Text('Os indicadores estão dentro da faixa esperada.')));
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Alertas inteligentes', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ...alerts.take(6).map((alert) {
        final critical = alert.severity == AtlasPerformanceAlertSeverity.critical;
        return ListTile(contentPadding: EdgeInsets.zero, leading: Icon(critical ? Icons.error_outline : Icons.warning_amber_rounded, color: critical ? const Color(0xFFB42318) : const Color(0xFFB7791F)), title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(alert.message));
      }),
    ])));
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onChanged});
  final AtlasKpiCategory? selected;
  final ValueChanged<AtlasKpiCategory?> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
    ChoiceChip(label: const Text('Todos'), selected: selected == null, onSelected: (_) => onChanged(null)),
    ...AtlasKpiCategory.values.map((category) => ChoiceChip(label: Text(_categoryLabel(category)), selected: selected == category, onSelected: (_) => onChanged(category))),
  ]);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.evaluation, required this.onEdit, required this.onDelete});
  final AtlasKpiEvaluation evaluation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final kpi = evaluation.kpi;
    final color = _statusColor(evaluation.status);
    final trendPositive = kpi.direction == AtlasKpiDirection.lowerIsBetter ? kpi.variation <= 0 : kpi.variation >= 0;
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 8, height: 58, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kpi.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_categoryLabel(kpi.category)} • Atualizado em ${DateFormat('dd/MM/yyyy').format(kpi.updatedAt)}', style: const TextStyle(color: Colors.black54)),
        ])),
        PopupMenuButton<String>(onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))]),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _Metric(label: 'Resultado atual', value: '${_number(kpi.currentValue)} ${kpi.unit}')),
        Expanded(child: _Metric(label: 'Meta', value: '${_number(kpi.targetValue)} ${kpi.unit}')),
        Expanded(child: _Metric(label: 'Atingimento', value: '${evaluation.achievement.toStringAsFixed(0)}%')),
        Expanded(child: _Metric(label: 'Tendência', value: '${kpi.variation >= 0 ? '+' : ''}${kpi.variation.toStringAsFixed(1)}%', icon: trendPositive ? Icons.trending_up : Icons.trending_down, valueColor: trendPositive ? const Color(0xFF17735F) : const Color(0xFFB42318))),
      ]),
      const SizedBox(height: 14),
      LinearProgressIndicator(value: (evaluation.achievement / 100).clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(8), color: color),
    ])));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.icon, this.valueColor});
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 4), Row(children: [if (icon != null) ...[Icon(icon, size: 17, color: valueColor), const SizedBox(width: 4)], Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)))] )]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(36), child: Center(child: Text('Nenhum indicador nesta categoria.'))));
}

class _KpiDialog extends StatefulWidget {
  const _KpiDialog({required this.farmId, this.initial});
  final String farmId;
  final AtlasPerformanceKpi? initial;
  @override
  State<_KpiDialog> createState() => _KpiDialogState();
}

class _KpiDialogState extends State<_KpiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _current;
  late final TextEditingController _target;
  late final TextEditingController _previous;
  late final TextEditingController _notes;
  late AtlasKpiCategory _category;
  late AtlasKpiDirection _direction;

  @override
  void initState() {
    super.initState();
    final kpi = widget.initial;
    _name = TextEditingController(text: kpi?.name ?? '');
    _unit = TextEditingController(text: kpi?.unit ?? '%');
    _current = TextEditingController(text: kpi?.currentValue.toString() ?? '0');
    _target = TextEditingController(text: kpi?.targetValue.toString() ?? '0');
    _previous = TextEditingController(text: kpi?.previousValue.toString() ?? '0');
    _notes = TextEditingController(text: kpi?.notes ?? '');
    _category = kpi?.category ?? AtlasKpiCategory.productive;
    _direction = kpi?.direction ?? AtlasKpiDirection.higherIsBetter;
  }

  double _parse(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(context, AtlasPerformanceKpi(
      id: widget.initial?.id ?? 'performance_${now.microsecondsSinceEpoch}',
      farmId: widget.farmId,
      name: _name.text.trim(), category: _category, unit: _unit.text.trim(),
      currentValue: _parse(_current.text), targetValue: _parse(_target.text),
      previousValue: _parse(_previous.text), direction: _direction,
      updatedAt: now, notes: _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Novo indicador' : 'Editar indicador'),
    content: SizedBox(width: 620, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nome do KPI'), validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<AtlasKpiCategory>(initialValue: _category, decoration: const InputDecoration(labelText: 'Categoria'), items: AtlasKpiCategory.values.map((e) => DropdownMenuItem(value: e, child: Text(_categoryLabel(e)))).toList(), onChanged: (v) => setState(() => _category = v!)),
      const SizedBox(height: 12),
      DropdownButtonFormField<AtlasKpiDirection>(initialValue: _direction, decoration: const InputDecoration(labelText: 'Regra de desempenho'), items: AtlasKpiDirection.values.map((e) => DropdownMenuItem(value: e, child: Text(_directionLabel(e)))).toList(), onChanged: (v) => setState(() => _direction = v!)),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Unidade'))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _current, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor atual')))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: TextFormField(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Meta'))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _previous, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Período anterior')))]),
      const SizedBox(height: 12),
      TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observações')),
    ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: _save, child: const Text('Salvar'))],
  );
}

String _categoryLabel(AtlasKpiCategory category) => switch (category) {
  AtlasKpiCategory.productive => 'Produtivo',
  AtlasKpiCategory.financial => 'Financeiro',
  AtlasKpiCategory.operational => 'Operacional',
  AtlasKpiCategory.strategic => 'Estratégico',
};

String _directionLabel(AtlasKpiDirection direction) => switch (direction) {
  AtlasKpiDirection.higherIsBetter => 'Quanto maior, melhor',
  AtlasKpiDirection.lowerIsBetter => 'Quanto menor, melhor',
  AtlasKpiDirection.targetRange => 'Faixa-alvo',
};

Color _statusColor(AtlasKpiStatus status) => switch (status) {
  AtlasKpiStatus.excellent => const Color(0xFF0F766E),
  AtlasKpiStatus.onTarget => const Color(0xFF17735F),
  AtlasKpiStatus.attention => const Color(0xFFB7791F),
  AtlasKpiStatus.critical => const Color(0xFFB42318),
};

String _number(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
