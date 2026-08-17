import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_cycle_report.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_cycle_report_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_recommendation_effectiveness.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_recommendation_effectiveness_service.dart';

class AtlasResultsIntelligenceScreen extends StatefulWidget {
  const AtlasResultsIntelligenceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasResultsIntelligenceScreen> createState() =>
      _AtlasResultsIntelligenceScreenState();
}

class _AtlasResultsIntelligenceScreenState
    extends State<AtlasResultsIntelligenceScreen> {
  final AtlasActionOutcomeService outcomeService =
      AtlasActionOutcomeService.instance;
  final AtlasExecutionCycleReportService reportService =
      AtlasExecutionCycleReportService.instance;
  final AtlasRecommendationEffectivenessService effectivenessService =
      const AtlasRecommendationEffectivenessService();

  List<AtlasActionOutcome> outcomes = <AtlasActionOutcome>[];
  List<AtlasExecutionCycleReport> reports = <AtlasExecutionCycleReport>[];
  bool isLoading = false;
  bool isGeneratingReport = false;

  Map<String, AtlasActionOutcome> get outcomesByAction => {
    for (final outcome in outcomes) outcome.actionId: outcome,
  };

  List<AtlasRecommendationEffectiveness> get effectivenessRanking =>
      effectivenessService.build(
        actions: widget.actionController.actions,
        outcomes: outcomes,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    await widget.actionController.load();
    outcomes = await outcomeService.load(
      farmName: widget.actionController.farmName,
    );
    reports = await reportService.load(
      farmName: widget.actionController.farmName,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editOutcome(AtlasCommandCenterAction action) async {
    final existing = outcomesByAction[action.id];
    final technical = TextEditingController(
      text: existing?.technicalResult ?? '',
    );
    final lessons = TextEditingController(text: existing?.lessonsLearned ?? '');
    final evidence = TextEditingController(text: existing?.evidence ?? '');
    final realizedImpact = TextEditingController(
      text: existing == null || existing.realizedFinancialImpact == 0
          ? ''
          : existing.realizedFinancialImpact.toStringAsFixed(2),
    );
    final cost = TextEditingController(
      text: existing == null || existing.executionCost == 0
          ? ''
          : existing.executionCost.toStringAsFixed(2),
    );
    final revenue = TextEditingController(
      text: existing == null || existing.revenueGenerated == 0
          ? ''
          : existing.revenueGenerated.toStringAsFixed(2),
    );
    final savings = TextEditingController(
      text: existing == null || existing.savingsGenerated == 0
          ? ''
          : existing.savingsGenerated.toStringAsFixed(2),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Resultado — ${action.title}'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: technical,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Resultado técnico obtido',
                      hintText: 'Descreva o que mudou após a execução.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lessons,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Aprendizado registrado',
                      hintText: 'O que deve ser repetido ou evitado?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: evidence,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Evidências',
                      hintText: 'Indicadores, documentos ou observações.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Impacto esperado: '
                      'R\$ ${action.expectedFinancialImpact.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MoneyField(
                    controller: realizedImpact,
                    label: 'Impacto financeiro realizado',
                  ),
                  const SizedBox(height: 10),
                  _MoneyField(controller: cost, label: 'Custo da execução'),
                  const SizedBox(height: 10),
                  _MoneyField(controller: revenue, label: 'Receita gerada'),
                  const SizedBox(height: 10),
                  _MoneyField(controller: savings, label: 'Economia gerada'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Salvar resultado'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await outcomeService.save(
        action: action,
        technicalResult: technical.text,
        lessonsLearned: lessons.text,
        evidence: evidence.text,
        realizedFinancialImpact: _parseMoney(realizedImpact.text),
        executionCost: _parseMoney(cost.text),
        revenueGenerated: _parseMoney(revenue.text),
        savingsGenerated: _parseMoney(savings.text),
      );
      await _load();
    }

    technical.dispose();
    lessons.dispose();
    evidence.dispose();
    realizedImpact.dispose();
    cost.dispose();
    revenue.dispose();
    savings.dispose();
  }

  Future<void> _generateReport() async {
    setState(() => isGeneratingReport = true);

    try {
      final report = await reportService.generate(
        actions: widget.actionController.actions,
        outcomes: outcomes,
        farmName: widget.actionController.farmName,
      );

      await _load();

      if (!mounted) {
        return;
      }

      await _openReport(report);
    } finally {
      if (mounted) {
        setState(() => isGeneratingReport = false);
      }
    }
  }

  Future<void> _openReport(AtlasExecutionCycleReport report) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Relatório de '
            '${DateFormat('dd/MM/yyyy').format(report.generatedAt)}',
          ),
          content: SizedBox(
            width: 760,
            height: 600,
            child: ListView(
              children: [
                Text(
                  report.executiveSummary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${report.totalActions} ações')),
                    Chip(label: Text('${report.completedActions} concluídas')),
                    Chip(label: Text('${report.overdueActions} atrasadas')),
                    Chip(
                      label: Text('${report.actionsWithOutcome} com resultado'),
                    ),
                    Chip(
                      label: Text(
                        'ROI médio '
                        '${report.averageRoiPercent.toStringAsFixed(1)}%',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Líquido R\$ '
                        '${report.totalNetFinancialResult.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ReportSection(
                  title: 'Destaques',
                  icon: Icons.star_outline,
                  items: report.highlights,
                ),
                const SizedBox(height: 12),
                _ReportSection(
                  title: 'Pontos de atenção',
                  icon: Icons.warning_amber_rounded,
                  items: report.attentionPoints,
                ),
                const SizedBox(height: 12),
                _ReportSection(
                  title: 'Aprendizados',
                  icon: Icons.psychology_outlined,
                  items: report.lessonsLearned,
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultados e inteligência financeira'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Resultados'),
              Tab(icon: Icon(Icons.attach_money), text: 'Financeiro'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Ranking'),
              Tab(icon: Icon(Icons.description_outlined), text: 'Relatórios'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: isGeneratingReport ? null : _generateReport,
          icon: isGeneratingReport
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: const Text('Gerar relatório'),
        ),
        body: isLoading && widget.actionController.actions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _ResultsTab(
                    actions: widget.actionController.actions,
                    outcomesByAction: outcomesByAction,
                    onEdit: _editOutcome,
                  ),
                  _FinancialTab(
                    actions: widget.actionController.actions,
                    outcomes: outcomes,
                  ),
                  _RankingTab(items: effectivenessRanking),
                  _ReportsTab(
                    reports: reports,
                    onOpen: _openReport,
                    onDelete: (report) async {
                      await reportService.delete(report.id);
                      await _load();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  static double _parseMoney(String value) {
    var normalized = value.trim();

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({
    required this.actions,
    required this.outcomesByAction,
    required this.onEdit,
  });

  final List<AtlasCommandCenterAction> actions;
  final Map<String, AtlasActionOutcome> outcomesByAction;
  final ValueChanged<AtlasCommandCenterAction> onEdit;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Center(child: Text('Nenhuma ação disponível.'));
    }

    final ordered = List<AtlasCommandCenterAction>.from(actions)
      ..sort((first, second) {
        if (first.isCompleted != second.isCompleted) {
          return first.isCompleted ? -1 : 1;
        }

        return second.updatedAt.compareTo(first.updatedAt);
      });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: ordered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final action = ordered[index];
        final outcome = outcomesByAction[action.id];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      outcome == null
                          ? Icons.pending_actions
                          : Icons.fact_check_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        outcome == null
                            ? 'Sem resultado'
                            : 'Resultado registrado',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Responsável: '
                  '${action.responsibleName.trim().isEmpty ? 'Não definido' : action.responsibleName}',
                ),
                Text('Progresso: ${action.progressPercent}%'),
                if (outcome != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    outcome.technicalResult.trim().isEmpty
                        ? 'Resultado técnico não informado.'
                        : outcome.technicalResult,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esperado: R\$ '
                    '${outcome.expectedFinancialImpact.toStringAsFixed(2)} • '
                    'Realizado: R\$ '
                    '${outcome.realizedFinancialImpact.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => onEdit(action),
                    icon: const Icon(Icons.edit_note),
                    label: Text(
                      outcome == null
                          ? 'Registrar resultado'
                          : 'Editar resultado',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FinancialTab extends StatelessWidget {
  const _FinancialTab({required this.actions, required this.outcomes});

  final List<AtlasCommandCenterAction> actions;
  final List<AtlasActionOutcome> outcomes;

  @override
  Widget build(BuildContext context) {
    final expected = actions.fold<double>(
      0,
      (total, action) => total + action.expectedFinancialImpact,
    );
    final realized = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.realizedFinancialImpact,
    );
    final cost = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.executionCost,
    );
    final revenue = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.revenueGenerated,
    );
    final savings = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.savingsGenerated,
    );
    final net = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.netFinancialResult,
    );
    final roi = cost <= 0 ? (net > 0 ? 100.0 : 0.0) : net / cost * 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FinancialMetric(title: 'Impacto esperado', value: expected),
            _FinancialMetric(title: 'Impacto realizado', value: realized),
            _FinancialMetric(title: 'Custo de execução', value: cost),
            _FinancialMetric(title: 'Receita gerada', value: revenue),
            _FinancialMetric(title: 'Economia gerada', value: savings),
            _FinancialMetric(title: 'Resultado líquido', value: net),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.trending_up)),
            title: const Text('Retorno sobre o investimento'),
            subtitle: const Text(
              'Resultado líquido dividido pelo custo '
              'total da execução.',
            ),
            trailing: Text(
              '${roi.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...outcomes.map(
          (outcome) => Card(
            child: ListTile(
              title: Text('Ação ${outcome.actionId}'),
              subtitle: Text(
                'Líquido R\$ '
                '${outcome.netFinancialResult.toStringAsFixed(2)}',
              ),
              trailing: Text(
                'ROI ${outcome.roiPercent.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({required this.title, required this.value});

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                'R\$ ${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  const _RankingTab({required this.items});

  final List<AtlasRecommendationEffectiveness> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Não há dados suficientes para o ranking.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text('${index + 1}')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.sourceModule,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${item.effectivenessScore.toStringAsFixed(0)} pontos',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: item.effectivenessScore / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${item.actionCount} ações')),
                    Chip(label: Text('${item.completedCount} concluídas')),
                    Chip(label: Text('${item.outcomeCount} com resultado')),
                    Chip(
                      label: Text(
                        'ROI médio '
                        '${item.averageRoiPercent.toStringAsFixed(1)}%',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Líquido R\$ '
                        '${item.totalNetFinancialResult.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({
    required this.reports,
    required this.onOpen,
    required this.onDelete,
  });

  final List<AtlasExecutionCycleReport> reports;
  final ValueChanged<AtlasExecutionCycleReport> onOpen;
  final ValueChanged<AtlasExecutionCycleReport> onDelete;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum relatório executivo foi gerado.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];

        return Card(
          child: ListTile(
            onTap: () => onOpen(report),
            leading: const CircleAvatar(
              child: Icon(Icons.description_outlined),
            ),
            title: Text(
              'Ciclo de '
              '${DateFormat('dd/MM').format(report.periodStart)} '
              'a ${DateFormat('dd/MM/yyyy').format(report.periodEnd)}',
            ),
            subtitle: Text(
              '${report.completedActions} concluídas • '
              '${report.overdueActions} atrasadas • '
              'R\$ ${report.totalNetFinancialResult.toStringAsFixed(2)} líquido',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'open') {
                  onOpen(report);
                } else if (value == 'delete') {
                  onDelete(report);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('Abrir')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, size: 7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
