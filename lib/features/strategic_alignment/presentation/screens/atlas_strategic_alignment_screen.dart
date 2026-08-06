import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/presentation/screens/atlas_strategic_scenario_planning_screen.dart';
import 'package:projeto_atlas/features/strategic_alignment/domain/models/atlas_strategic_alignment.dart';
import 'package:projeto_atlas/features/strategic_alignment/domain/services/atlas_strategic_alignment_engine.dart';
import 'package:projeto_atlas/features/strategy_execution/data/services/atlas_strategy_execution_repository.dart';

class AtlasStrategicAlignmentScreen extends StatefulWidget {
  const AtlasStrategicAlignmentScreen({
    super.key,
    this.farmId,
  });

  final String? farmId;

  @override
  State<AtlasStrategicAlignmentScreen> createState() {
    return _AtlasStrategicAlignmentScreenState();
  }
}

class _AtlasStrategicAlignmentScreenState
    extends State<AtlasStrategicAlignmentScreen> {
  bool loading = true;
  AtlasStrategicAlignmentAssessment? assessment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans =
        await AtlasStrategyExecutionRepository.instance
            .loadAll();

    final filtered = widget.farmId == null
        ? plans
        : plans
            .where(
              (item) => item.farmId == widget.farmId,
            )
            .toList();

    final generated =
        const AtlasStrategicAlignmentEngine().assess(
      plans: filtered,
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
          'Strategic Alignment & OKR',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir planejamento de cenários',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasStrategicScenarioPlanningScreen(
                      farmId: widget.farmId,
                    );
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.auto_graph_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Atualizar alinhamento',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : current == null ||
                  current.items.isEmpty
              ? const _EmptyView()
              : Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 1240),
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _Hero(assessment: current),
                        const SizedBox(height: 22),
                        const _SectionTitle(
                          title: 'Objetivos estratégicos',
                          subtitle:
                              'OKRs consolidados da propriedade e progresso dos resultados-chave.',
                        ),
                        const SizedBox(height: 12),
                        ...current.objectives.map(
                          (objective) => _ObjectiveCard(
                            objective: objective,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(
                          title:
                              'Alinhamento das estratégias',
                          subtitle:
                              'Contribuição de cada plano para os objetivos prioritários da fazenda.',
                        ),
                        const SizedBox(height: 12),
                        ...current.items.map(
                          (item) => _AlignmentCard(
                            item: item,
                          ),
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
  const _Hero({
    required this.assessment,
  });

  final AtlasStrategicAlignmentAssessment assessment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF283593),
            Color(0xFF00695C),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Estratégia conectada à execução',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Objetivos, resultados-chave e contribuição',
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
                label: 'Alinhamento geral',
                value:
                    '${assessment.overallAlignment.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                label: 'Progresso dos objetivos',
                value:
                    '${assessment.objectiveProgress.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                label: 'Objetivos',
                value:
                    '${assessment.objectives.length}',
              ),
              _HeroMetric(
                label: 'Estratégias sem alinhamento',
                value:
                    '${assessment.unalignedStrategies}',
              ),
              _HeroMetric(
                label: 'Alinhamento fraco',
                value:
                    '${assessment.weakStrategies}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.objective,
  });

  final AtlasStrategicObjective objective;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(Icons.flag_outlined),
        ),
        title: Text(
          objective.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${atlasStrategicHorizonLabel(objective.horizon)} · '
          'peso ${objective.weightPercent.toStringAsFixed(0)}% · '
          'progresso ${objective.progressPercent.toStringAsFixed(1)}%',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(objective.description),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (objective.progressPercent / 100)
                .clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          ...objective.keyResults.map(
            (result) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.track_changes_outlined,
              ),
              title: Text(result.title),
              subtitle: Text(
                '${result.currentValue.toStringAsFixed(1)} '
                '${result.unit} de '
                '${result.targetValue.toStringAsFixed(1)} '
                '${result.unit}',
              ),
              trailing: Text(
                '${result.progressPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignmentCard extends StatelessWidget {
  const _AlignmentCard({
    required this.item,
  });

  final AtlasStrategyAlignmentItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withValues(alpha: 0.12),
          child: Icon(
            Icons.align_horizontal_left_outlined,
            color: color,
          ),
        ),
        title: Text(
          item.plan.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${atlasAlignmentStatusLabel(item.status)} · '
          '${item.alignmentScore.toStringAsFixed(1)}% · '
          '${item.objective?.title ?? 'Sem objetivo'}',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Alinhamento',
                value:
                    '${item.alignmentScore.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Contribuição',
                value:
                    '${item.contributionScore.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Confiança de execução',
                value:
                    '${item.executionConfidence.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Progresso do plano',
                value:
                    '${item.plan.progressPercent.toStringAsFixed(1)}%',
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minWidth: 165),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
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
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
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
            Icon(
              Icons.flag_outlined,
              size: 58,
              color: Colors.black26,
            ),
            SizedBox(height: 12),
            Text(
              'Ainda não existem estratégias para alinhar.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Crie planos de execução antes de avaliar objetivos e OKRs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(
  AtlasAlignmentStatus status,
) {
  switch (status) {
    case AtlasAlignmentStatus.strong:
      return const Color(0xFF2E7D32);
    case AtlasAlignmentStatus.acceptable:
      return const Color(0xFF1565C0);
    case AtlasAlignmentStatus.weak:
      return const Color(0xFFEF6C00);
    case AtlasAlignmentStatus.unaligned:
      return const Color(0xFFC62828);
  }
}
