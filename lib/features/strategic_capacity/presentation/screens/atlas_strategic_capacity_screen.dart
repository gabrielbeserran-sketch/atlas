import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/strategic_alignment/presentation/screens/atlas_strategic_alignment_screen.dart';
import 'package:projeto_atlas/features/strategic_capacity/domain/models/atlas_capacity_dependency.dart';
import 'package:projeto_atlas/features/strategic_capacity/domain/services/atlas_capacity_dependency_engine.dart';
import 'package:projeto_atlas/features/strategy_execution/data/services/atlas_strategy_execution_repository.dart';

class AtlasStrategicCapacityScreen extends StatefulWidget {
  const AtlasStrategicCapacityScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasStrategicCapacityScreen> createState() {
    return _AtlasStrategicCapacityScreenState();
  }
}

class _AtlasStrategicCapacityScreenState
    extends State<AtlasStrategicCapacityScreen> {
  bool loading = true;
  double availableWeeklyHours = 160;
  AtlasCapacityAssessment? assessment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await AtlasStrategyExecutionRepository.instance.loadAll();

    final filtered = widget.farmId == null
        ? plans
        : plans.where((item) => item.farmId == widget.farmId).toList();

    final generated = const AtlasCapacityDependencyEngine().assess(
      plans: filtered,
      availableWeeklyHours: availableWeeklyHours,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      assessment = generated;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = assessment;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Strategic Capacity & Dependency',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir alinhamento estratégico',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasStrategicAlignmentScreen(farmId: widget.farmId);
                  },
                ),
              );
            },
            icon: const Icon(Icons.flag_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar capacidade',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : current == null || current.items.isEmpty
          ? const _EmptyView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _Hero(assessment: current),
                    const SizedBox(height: 22),
                    _CapacityConfig(
                      value: availableWeeklyHours,
                      onChanged: (value) {
                        setState(() {
                          availableWeeklyHours = value;
                        });
                      },
                      onApply: _load,
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Carga por estratégia',
                      subtitle:
                          'Capacidade estimada, marcos restantes, prazo e recomendação operacional.',
                    ),
                    const SizedBox(height: 12),
                    ...current.items.map((item) => _CapacityCard(item: item)),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Dependências',
                      subtitle:
                          'Relações entre estratégias que podem bloquear ou atrasar a execução.',
                    ),
                    const SizedBox(height: 12),
                    if (current.dependencies.isEmpty)
                      const _EmptyCard(
                        text: 'Nenhuma dependência relevante foi detectada.',
                      )
                    else
                      ...current.dependencies.map(
                        (item) => _DependencyCard(dependency: item),
                      ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Conflitos de capacidade',
                      subtitle:
                          'Sobrecarga, concorrência por capital e responsáveis compartilhados.',
                    ),
                    const SizedBox(height: 12),
                    if (current.conflicts.isEmpty)
                      const _EmptyCard(
                        text: 'Nenhum conflito importante foi detectado.',
                      )
                    else
                      ...current.conflicts.map(
                        (item) => _ConflictCard(conflict: item),
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
  const _Hero({required this.assessment});

  final AtlasCapacityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF4527A0),
            Color(0xFF006064),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capacidade real de execução do portfólio',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Recursos, dependências e gargalos',
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
                label: 'Demanda semanal',
                value: '${assessment.totalCapacityDemand.toStringAsFixed(0)} h',
              ),
              _HeroMetric(
                label: 'Capacidade disponível',
                value: '${assessment.availableCapacity.toStringAsFixed(0)} h',
              ),
              _HeroMetric(
                label: 'Utilização',
                value: '${assessment.utilizationPercent.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                label: 'Estratégias sobrecarregadas',
                value: '${assessment.overloadedStrategies}',
              ),
              _HeroMetric(
                label: 'Conflitos críticos',
                value: '${assessment.criticalConflicts}',
              ),
              _HeroMetric(
                label: 'Dependências bloqueadas',
                value: '${assessment.blockedDependencies}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapacityConfig extends StatelessWidget {
  const _CapacityConfig({
    required this.value,
    required this.onChanged,
    required this.onApply,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capacidade semanal disponível: '
              '${value.toStringAsFixed(0)} horas',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: value,
              min: 40,
              max: 400,
              divisions: 36,
              label: '${value.toStringAsFixed(0)} h',
              onChanged: onChanged,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Recalcular capacidade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.item});

  final AtlasCapacityItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.overloaded
        ? const Color(0xFFC62828)
        : const Color(0xFF2E7D32);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            item.overloaded
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            color: color,
          ),
        ),
        title: Text(
          item.plan.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.requiredHours.toStringAsFixed(0)} h estimadas · '
          '${item.teamLoadPercent.toStringAsFixed(1)}% da capacidade',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Marcos restantes',
                value: '${item.remainingMilestones}',
              ),
              _Metric(label: 'Dias restantes', value: '${item.remainingDays}'),
              _Metric(
                label: 'Carga estimada',
                value: '${item.requiredHours.toStringAsFixed(0)} h',
              ),
              _Metric(
                label: 'Uso da capacidade',
                value: '${item.teamLoadPercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recomendação:\n${item.recommendation}',
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DependencyCard extends StatelessWidget {
  const _DependencyCard({required this.dependency});

  final AtlasStrategyDependency dependency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(
          '${dependency.predecessorTitle} → '
          '${dependency.successorTitle}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dependency.reason}\n'
          'Status: '
          '${atlasDependencyStatusLabel(dependency.status)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict});

  final AtlasCapacityConflict conflict;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.report_problem_outlined),
        title: Text(
          conflict.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Severidade '
          '${atlasCapacityConflictSeverityLabel(conflict.severity)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${conflict.description}\n\n'
              'Recomendação:\n'
              '${conflict.recommendation}',
              style: const TextStyle(height: 1.4),
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
      constraints: const BoxConstraints(minWidth: 155),
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
      constraints: const BoxConstraints(minWidth: 155),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(text, textAlign: TextAlign.center),
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
            Icon(Icons.hub_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Ainda não existem estratégias para avaliar.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Crie planos de execução antes de analisar capacidade e dependências.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
