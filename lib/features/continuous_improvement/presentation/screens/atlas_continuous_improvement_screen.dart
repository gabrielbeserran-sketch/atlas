import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/knowledge_learning/presentation/screens/atlas_knowledge_learning_screen.dart';
import 'package:projeto_atlas/features/action_plan/data/services/atlas_action_plan_storage_service.dart';
import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/continuous_improvement/data/services/atlas_improvement_history_service.dart';
import 'package:projeto_atlas/features/continuous_improvement/domain/models/atlas_improvement_cycle.dart';
import 'package:projeto_atlas/features/continuous_improvement/domain/services/atlas_continuous_improvement_engine.dart';
import 'package:projeto_atlas/features/farm_audit/data/services/atlas_farm_audit_history_service.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/performance_center/domain/models/atlas_performance_snapshot.dart';
import 'package:projeto_atlas/features/performance_center/domain/services/atlas_performance_engine.dart';

class AtlasContinuousImprovementScreen extends StatefulWidget {
  const AtlasContinuousImprovementScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasContinuousImprovementScreen> createState() {
    return _AtlasContinuousImprovementScreenState();
  }
}

class _AtlasContinuousImprovementScreenState
    extends State<AtlasContinuousImprovementScreen> {
  bool loading = true;
  bool generating = false;
  AtlasImprovementCycle? cycle;
  List<AtlasImprovementCycle> history = <AtlasImprovementCycle>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
    });

    final allCycles = await AtlasImprovementHistoryService.instance.loadAll();

    final filtered = widget.farmId == null
        ? allCycles
        : allCycles.where((item) => item.farmId == widget.farmId).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      history = filtered;
      cycle = filtered.isEmpty ? null : filtered.first;
      loading = false;
    });

    if (cycle == null) {
      await _generate();
    }
  }

  Future<void> _generate() async {
    if (generating) {
      return;
    }

    setState(() {
      generating = true;
    });

    try {
      final audits = await AtlasFarmAuditHistoryService.instance.loadAll();

      final filteredAudits = widget.farmId == null
          ? audits
          : audits.where((item) => item.farmId == widget.farmId).toList();

      if (filteredAudits.isEmpty) {
        return;
      }

      final AtlasFarmAudit currentAudit = filteredAudits.first;

      final AtlasFarmAudit? previousAudit = filteredAudits.length > 1
          ? filteredAudits[1]
          : null;

      final AtlasActionPlan? plan = await AtlasActionPlanStorageService.instance
          .latestForFarm(currentAudit.farmId);

      if (plan == null) {
        return;
      }

      final AtlasPerformanceSnapshot performance =
          const AtlasPerformanceEngine().generate(
            plan: plan,
            currentAudit: currentAudit,
            previousAudit: previousAudit,
          );

      final generated = const AtlasContinuousImprovementEngine().generate(
        performance: performance,
        audit: currentAudit,
        plan: plan,
      );

      await AtlasImprovementHistoryService.instance.save(generated);

      final updatedHistory = await AtlasImprovementHistoryService.instance
          .byFarmId(currentAudit.farmId);

      if (!mounted) {
        return;
      }

      setState(() {
        cycle = generated;
        history = updatedHistory;
      });
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Melhoria Contínua',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir conhecimento e aprendizado',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasKnowledgeLearningScreen(farmId: widget.farmId);
                  },
                ),
              );
            },
            icon: const Icon(Icons.psychology_outlined),
          ),
          IconButton(
            tooltip: 'Gerar novo ciclo',
            onPressed: generating ? null : _generate,
            icon: const Icon(Icons.autorenew),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cycle == null
          ? const _EmptyView()
          : _CycleBody(cycle: cycle!, history: history),
    );
  }
}

class _CycleBody extends StatelessWidget {
  const _CycleBody({required this.cycle, required this.history});

  final AtlasImprovementCycle cycle;
  final List<AtlasImprovementCycle> history;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _Hero(cycle: cycle),
            const SizedBox(height: 18),
            _SummaryCard(cycle: cycle),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Decisões do novo ciclo',
              subtitle:
                  'Ações que devem ser mantidas, monitoradas, corrigidas ou recalibradas.',
            ),
            const SizedBox(height: 12),
            ...cycle.decisions.map((item) => _DecisionCard(decision: item)),
            if (history.length > 1) ...[
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Histórico de ciclos',
                subtitle:
                    'Registro das recalibrações realizadas para a fazenda.',
              ),
              const SizedBox(height: 12),
              _HistoryCard(history: history),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.cycle});

  final AtlasImprovementCycle cycle;

  @override
  Widget build(BuildContext context) {
    final color = _classificationColor(cycle.classification);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF17384D),
            Color(0xFF236075),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(Icons.autorenew, size: 42, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atlas Continuous Improvement Engine',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  cycle.farmName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${atlasImprovementCycleClassificationLabel(cycle.classification)} · '
                  '${cycle.recalibrationDecisions} recalibrações · '
                  '${cycle.correctionDecisions} correções',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cycle});

  final AtlasImprovementCycle cycle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Síntese executiva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(cycle.summary, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Execution Score',
                  value: cycle.executionScore.toStringAsFixed(1),
                ),
                _Metric(
                  label: 'Farm Audit Index',
                  value: cycle.auditIndex.toStringAsFixed(1),
                ),
                _Metric(
                  label: 'Próxima revisão',
                  value: _formatDate(cycle.nextReviewDate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.decision});

  final AtlasImprovementDecision decision;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(decision.priority);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_decisionIcon(decision.type), color: color),
        ),
        title: Text(
          decision.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${atlasFarmAuditAreaLabel(decision.area)} · '
          '${atlasFarmAuditPriorityLabel(decision.priority)} · '
          'prazo de ${decision.deadlineDays} dias',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              decision.explanation,
              style: const TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Atual',
                  value: decision.currentValue.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Meta',
                  value: decision.targetValue.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Ganho esperado',
                  value: '+${decision.expectedGain.toStringAsFixed(1)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final List<AtlasImprovementCycle> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: history.take(8).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: Text(_formatDate(item.generatedAt))),
                  Expanded(
                    child: Text(
                      atlasImprovementCycleClassificationLabel(
                        item.classification,
                      ),
                    ),
                  ),
                  Text(
                    '${item.recalibrationDecisions} recalibrações',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
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
      constraints: const BoxConstraints(minWidth: 150),
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
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
            Icon(Icons.autorenew, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Ainda não existem dados suficientes.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Gere uma auditoria e um plano de ação antes de iniciar o ciclo de melhoria contínua.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _decisionIcon(AtlasImprovementDecisionType type) {
  switch (type) {
    case AtlasImprovementDecisionType.maintain:
      return Icons.verified_outlined;
    case AtlasImprovementDecisionType.monitor:
      return Icons.visibility_outlined;
    case AtlasImprovementDecisionType.correct:
      return Icons.build_outlined;
    case AtlasImprovementDecisionType.recalibrate:
      return Icons.autorenew;
  }
}

Color _classificationColor(AtlasImprovementCycleClassification classification) {
  switch (classification) {
    case AtlasImprovementCycleClassification.excellent:
      return const Color(0xFF66BB6A);
    case AtlasImprovementCycleClassification.controlled:
      return const Color(0xFF42A5F5);
    case AtlasImprovementCycleClassification.attention:
      return const Color(0xFFFFB74D);
    case AtlasImprovementCycleClassification.critical:
      return const Color(0xFFEF5350);
  }
}

Color _priorityColor(AtlasFarmAuditPriority priority) {
  switch (priority) {
    case AtlasFarmAuditPriority.low:
      return const Color(0xFF2E7D32);
    case AtlasFarmAuditPriority.moderate:
      return const Color(0xFF1565C0);
    case AtlasFarmAuditPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasFarmAuditPriority.critical:
      return const Color(0xFFC62828);
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}
