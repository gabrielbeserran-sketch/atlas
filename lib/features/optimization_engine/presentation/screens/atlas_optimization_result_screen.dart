import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_result.dart';
import 'package:projeto_atlas/features/scenario_simulator/presentation/screens/atlas_scenario_result_screen.dart';

class AtlasOptimizationResultScreen extends StatelessWidget {
  const AtlasOptimizationResultScreen({required this.result, super.key});

  final AtlasOptimizationResult result;

  @override
  Widget build(BuildContext context) {
    final best = result.bestCandidate;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Resultado da Otimização',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _BestCandidateHero(candidate: best),
                const SizedBox(height: 20),
                _SummaryCard(result: result),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Por que esta estratégia venceu?',
                  subtitle: 'Critérios utilizados pelo motor de otimização.',
                ),
                const SizedBox(height: 12),
                _ReasonList(reasons: result.selectionReasons),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Ranking dos cenários',
                  subtitle:
                      'Alternativas geradas automaticamente e ordenadas pela aderência ao objetivo.',
                ),
                const SizedBox(height: 12),
                _CandidateList(candidates: result.candidates),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BestCandidateHero extends StatelessWidget {
  const _BestCandidateHero({required this.candidate});

  final AtlasOptimizationCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF17384D), Color(0xFF236075)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: Color(0xFFFFE082),
            size: 48,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estratégia recomendada',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  candidate.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${candidate.optimizationScore.toStringAsFixed(1)} pontos de otimização · '
                  '${candidate.isEligible ? 'Dentro das restrições' : 'Com restrições pendentes'}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasScenarioResultScreen(result: candidate.result);
                  },
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Ver detalhes'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});

  final AtlasOptimizationResult result;

  @override
  Widget build(BuildContext context) {
    final best = result.bestCandidate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.summary,
              style: const TextStyle(
                height: 1.5,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Objetivo',
                  value: best.objectiveScore.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'Financeiro',
                  value: best.financialScore.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'Segurança',
                  value: best.riskScore.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'Equilíbrio',
                  value: best.balanceScore.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.insights_outlined, size: 18),
      label: Text('$label: $value'),
    );
  }
}

class _ReasonList extends StatelessWidget {
  const _ReasonList({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: reasons.map((reason) {
          return ListTile(
            leading: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2E7D32),
            ),
            title: Text(reason),
          );
        }).toList(),
      ),
    );
  }
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({required this.candidates});

  final List<AtlasOptimizationCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: candidates.map((candidate) {
        final color = candidate.isEligible
            ? const Color(0xFF2E7D32)
            : const Color(0xFFEF6C00);

        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                candidate.position.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              candidate.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${candidate.optimizationScore.toStringAsFixed(1)} pontos · '
              '${candidate.isEligible ? 'Elegível' : 'Fora de uma ou mais restrições'}',
            ),
            trailing: Icon(
              candidate.isEligible
                  ? Icons.verified_outlined
                  : Icons.warning_amber_outlined,
              color: color,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              _ScoreLine(label: 'Objetivo', value: candidate.objectiveScore),
              _ScoreLine(label: 'Financeiro', value: candidate.financialScore),
              _ScoreLine(label: 'Segurança', value: candidate.riskScore),
              _ScoreLine(label: 'Equilíbrio', value: candidate.balanceScore),
              if (candidate.constraintNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...candidate.constraintNotes.map(
                  (note) => Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        '• $note',
                        style: const TextStyle(color: Color(0xFFC62828)),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return AtlasScenarioResultScreen(
                            result: candidate.result,
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Abrir cenário'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(value: value / 100, minHeight: 8),
          ),
          const SizedBox(width: 10),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
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
