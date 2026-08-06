import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_feedback_analytics_service.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_feedback_analytics.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/copilot/presentation/screens/atlas_copilot_improvement_screen.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class AtlasCopilotFeedbackAnalyticsScreen
    extends StatefulWidget {
  const AtlasCopilotFeedbackAnalyticsScreen({
    super.key,
  });

  @override
  State<AtlasCopilotFeedbackAnalyticsScreen>
      createState() {
    return _AtlasCopilotFeedbackAnalyticsScreenState();
  }
}

class _AtlasCopilotFeedbackAnalyticsScreenState
    extends State<AtlasCopilotFeedbackAnalyticsScreen> {
  final AtlasCopilotFeedbackAnalyticsService
      service =
      const AtlasCopilotFeedbackAnalyticsService();

  bool isLoading = true;
  String? errorMessage;

  AtlasCopilotFeedbackAnalytics? analytics;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await service.buildAnalytics();

      if (!mounted) {
        return;
      }

      setState(() {
        analytics = result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Não foi possível carregar os dados de qualidade.';
        isLoading = false;
      });
    }
  }

  Future<void> openImprovementPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasCopilotImprovementScreen();
        },
      ),
    );

    await loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final data = analytics;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Qualidade do Copiloto',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Plano de melhoria',
            onPressed:
                isLoading || data == null
                    ? null
                    : openImprovementPlan,
            icon: const Icon(
              Icons.build_circle_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
                isLoading ? null : loadAnalytics,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? _ErrorView(
                  message: errorMessage!,
                  onRetry: loadAnalytics,
                )
              : data == null || !data.hasFeedback
                  ? const _EmptyFeedbackView()
                  : RefreshIndicator(
                      onRefresh: loadAnalytics,
                      child: ListView(
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),
                        children: [
                          _QualityHero(
                            analytics: data,
                            onOpenImprovement:
                                openImprovementPlan,
                          ),
                          const SizedBox(
                            height: 18,
                          ),
                          _SummaryGrid(
                            analytics: data,
                          ),
                          const SizedBox(
                            height: 26,
                          ),
                          const _SectionTitle(
                            title:
                                'Desempenho por assunto',
                            subtitle:
                                'Assuntos com maior índice de respostas não úteis aparecem primeiro.',
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _IntentMetricsCard(
                            metrics:
                                data.intentMetrics,
                          ),
                          const SizedBox(
                            height: 26,
                          ),
                          const _SectionTitle(
                            title:
                                'Desempenho por contexto',
                            subtitle:
                                'Comparação entre operação consolidada e fazendas.',
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _ContextMetricsCard(
                            metrics:
                                data.contextMetrics,
                          ),
                          const SizedBox(
                            height: 26,
                          ),
                          const _SectionTitle(
                            title:
                                'Avaliações recentes',
                            subtitle:
                                'Respostas avaliadas mais recentemente.',
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _RecentFeedbackList(
                            items:
                                data.recentFeedback,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _QualityHero extends StatelessWidget {
  const _QualityHero({
    required this.analytics,
    required this.onOpenImprovement,
  });

  final AtlasCopilotFeedbackAnalytics analytics;
  final VoidCallback onOpenImprovement;

  @override
  Widget build(BuildContext context) {
    final color = _qualityColor(
      analytics.approvalRate,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF263238),
            Color(0xFF37474F),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 700;

          final text = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFFC8A951),
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Qualidade das respostas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _qualityMessage(
                  analytics.approvalRate,
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: onOpenImprovement,
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC8A951),
                  foregroundColor:
                      const Color(0xFF263238),
                ),
                icon: const Icon(
                  Icons.build_outlined,
                ),
                label: const Text(
                  'Abrir plano de melhoria',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          );

          final score = Container(
            width: 180,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.42,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${analytics.approvalRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const Text(
                  'Taxa de aprovação',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 18),
                score,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 22),
              score,
            ],
          );
        },
      ),
    );
  }

  static String _qualityMessage(
    double rate,
  ) {
    if (rate >= 85) {
      return 'O Copiloto apresenta excelente aceitação. Mantenha as regras atuais e continue coletando feedback.';
    }

    if (rate >= 70) {
      return 'A qualidade geral está boa, mas alguns assuntos ainda podem ser aprimorados.';
    }

    if (rate >= 50) {
      return 'A qualidade exige atenção. Revise primeiro os assuntos com menor aprovação.';
    }

    return 'A taxa de aprovação está baixa. As respostas e regras locais precisam de revisão prioritária.';
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.analytics,
  });

  final AtlasCopilotFeedbackAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Avaliadas',
        value:
            analytics.evaluatedResponses,
        icon:
            Icons.fact_check_outlined,
        color:
            const Color(0xFF1565C0),
      ),
      _SummaryItem(
        label: 'Úteis',
        value: analytics.usefulResponses,
        icon:
            Icons.thumb_up_outlined,
        color:
            const Color(0xFF1B5E20),
      ),
      _SummaryItem(
        label: 'Não úteis',
        value:
            analytics.notUsefulResponses,
        icon:
            Icons.thumb_down_outlined,
        color:
            const Color(0xFFC62828),
      ),
      _SummaryItem(
        label: 'Conversas',
        value:
            analytics.totalConversations,
        icon:
            Icons.forum_outlined,
        color:
            const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth >= 760
                ? (constraints.maxWidth -
                        36) /
                    4
                : (constraints.maxWidth -
                        12) /
                    2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: item.color,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              item.value
                                  .toString(),
                              style: TextStyle(
                                color:
                                    item.color,
                                fontSize: 21,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            Text(
                              item.label,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
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
            fontSize: 20,
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

class _IntentMetricsCard
    extends StatelessWidget {
  const _IntentMetricsCard({
    required this.metrics,
  });

  final List<AtlasCopilotIntentFeedbackMetric>
      metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _NoDataCard();
    }

    return Card(
      child: Column(
        children: List.generate(
          metrics.length,
          (index) {
            final item = metrics[index];

            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1),
                _MetricTile(
                  title:
                      atlasCopilotIntentLabel(
                    item.intent,
                  ),
                  subtitle:
                      '${item.total} avaliações · '
                      '${item.useful} úteis · '
                      '${item.notUseful} não úteis',
                  approvalRate:
                      item.approvalRate,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContextMetricsCard
    extends StatelessWidget {
  const _ContextMetricsCard({
    required this.metrics,
  });

  final List<AtlasCopilotContextFeedbackMetric>
      metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _NoDataCard();
    }

    return Card(
      child: Column(
        children: List.generate(
          metrics.length,
          (index) {
            final item = metrics[index];

            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1),
                _MetricTile(
                  title: item.contextLabel,
                  subtitle:
                      '${item.total} avaliações · '
                      '${item.useful} úteis · '
                      '${item.notUseful} não úteis',
                  approvalRate:
                      item.approvalRate,
                  icon: item.isFarmContext
                      ? Icons
                          .agriculture_outlined
                      : Icons
                          .business_outlined,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.subtitle,
    required this.approvalRate,
    this.icon,
  });

  final String title;
  final String subtitle;
  final double approvalRate;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color =
        _qualityColor(approvalRate);

    return Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${approvalRate.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFeedbackList
    extends StatelessWidget {
  const _RecentFeedbackList({
    required this.items,
  });

  final List<AtlasCopilotRecentFeedbackItem>
      items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _NoDataCard();
    }

    return Card(
      child: Column(
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            final useful = item.feedback ==
                AtlasCopilotMessageFeedback.useful;

            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    useful
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    color: useful
                        ? const Color(
                            0xFF1B5E20,
                          )
                        : const Color(
                            0xFFC62828,
                          ),
                  ),
                  title: Text(
                    item.messageText,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.contextLabel} · '
                    '${item.intent == null ? 'Sem assunto' : atlasCopilotIntentLabel(item.intent!)}',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoDataCard extends StatelessWidget {
  const _NoDataCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Ainda não há dados suficientes.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFeedbackView
    extends StatelessWidget {
  const _EmptyFeedbackView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma resposta avaliada.',
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(
          Icons.refresh,
        ),
        label: Text(message),
      ),
    );
  }
}

Color _qualityColor(
  double rate,
) {
  if (rate >= 85) {
    return const Color(0xFF1B5E20);
  }

  if (rate >= 70) {
    return const Color(0xFF2E7D32);
  }

  if (rate >= 50) {
    return const Color(0xFFEF6C00);
  }

  return const Color(0xFFC62828);
}
