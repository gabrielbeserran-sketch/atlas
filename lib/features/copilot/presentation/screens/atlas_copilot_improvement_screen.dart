import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_feedback_analytics_service.dart';
import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_improvement_service.dart';

import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_improvement_plan.dart';

class AtlasCopilotImprovementScreen extends StatefulWidget {
  const AtlasCopilotImprovementScreen({super.key});

  @override
  State<AtlasCopilotImprovementScreen> createState() {
    return _AtlasCopilotImprovementScreenState();
  }
}

class _AtlasCopilotImprovementScreenState
    extends State<AtlasCopilotImprovementScreen> {
  final AtlasCopilotFeedbackAnalyticsService analyticsService =
      const AtlasCopilotFeedbackAnalyticsService();

  final AtlasCopilotImprovementService improvementService =
      const AtlasCopilotImprovementService();

  bool isLoading = true;
  String? errorMessage;

  AtlasCopilotImprovementPlan? plan;

  @override
  void initState() {
    super.initState();
    loadPlan();
  }

  Future<void> loadPlan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final analytics = await analyticsService.buildAnalytics();

      final result = improvementService.buildPlan(analytics: analytics);

      if (!mounted) {
        return;
      }

      setState(() {
        plan = result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Não foi possível gerar o plano de melhoria.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = plan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Plano de Melhoria do Copiloto',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar plano',
            onPressed: isLoading ? null : loadPlan,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _ImprovementErrorView(message: errorMessage!, onRetry: loadPlan)
          : data == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: loadPlan,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _ImprovementHero(plan: data),
                  const SizedBox(height: 25),
                  const _ImprovementSectionTitle(
                    title: 'Prioridades de melhoria',
                    subtitle:
                        'Pontos ordenados pela urgência e impacto estimado.',
                  ),
                  const SizedBox(height: 12),
                  _ImprovementPriorityList(priorities: data.priorities),
                  const SizedBox(height: 25),
                  const _ImprovementSectionTitle(
                    title: 'Plano de ação recomendado',
                    subtitle:
                        'Próximos passos para elevar a qualidade das respostas.',
                  ),
                  const SizedBox(height: 12),
                  _RecommendedActionList(actions: data.recommendedActions),
                  if (data.strengths.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    const _ImprovementSectionTitle(
                      title: 'Pontos fortes',
                      subtitle:
                          'Áreas com boa aceitação que devem ser preservadas.',
                    ),
                    const SizedBox(height: 12),
                    _StrengthList(strengths: data.strengths),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _ImprovementHero extends StatelessWidget {
  const _ImprovementHero({required this.plan});

  final AtlasCopilotImprovementPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = improvementLevelColor(plan.overallLevel);

    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF37474F)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    color: Color(0xFFC8A951),
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Melhoria orientada por feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.summary,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 14),
              Text(
                '${plan.priorities.length} prioridades identificadas',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          );

          final score = Container(
            width: 180,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: color.withValues(alpha: 0.42)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.overallScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasCopilotImprovementLevelLabel(plan.overallLevel),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 18), score],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 22),
              score,
            ],
          );
        },
      ),
    );
  }
}

class _ImprovementSectionTitle extends StatelessWidget {
  const _ImprovementSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _ImprovementPriorityList extends StatelessWidget {
  const _ImprovementPriorityList({required this.priorities});

  final List<AtlasCopilotImprovementPriority> priorities;

  @override
  Widget build(BuildContext context) {
    if (priorities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhuma prioridade crítica foi identificada.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Column(
      children: priorities.map((item) {
        final color = improvementLevelColor(item.level);

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${item.position}º',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.recommendation,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.score.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendedActionList extends StatelessWidget {
  const _RecommendedActionList({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List.generate(actions.length, (index) {
          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(actions[index]),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StrengthList extends StatelessWidget {
  const _StrengthList({required this.strengths});

  final List<AtlasCopilotImprovementStrength> strengths;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List.generate(strengths.length, (index) {
          final item = strengths[index];

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.verified_outlined,
                  color: Color(0xFF1B5E20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(item.description),
                trailing: Text(
                  '${item.score.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ImprovementErrorView extends StatelessWidget {
  const _ImprovementErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 54, color: Color(0xFFC62828)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

Color improvementLevelColor(AtlasCopilotImprovementLevel level) {
  switch (level) {
    case AtlasCopilotImprovementLevel.excellent:
      return const Color(0xFF1B5E20);

    case AtlasCopilotImprovementLevel.stable:
      return const Color(0xFF2E7D32);

    case AtlasCopilotImprovementLevel.attention:
      return const Color(0xFFEF6C00);

    case AtlasCopilotImprovementLevel.critical:
      return const Color(0xFFC62828);
  }
}
