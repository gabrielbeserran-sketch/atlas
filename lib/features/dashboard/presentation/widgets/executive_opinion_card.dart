import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/data/services/executive_opinion_pdf_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/executive_opinion_service.dart';

class ExecutiveOpinionCard extends StatefulWidget {
  const ExecutiveOpinionCard({required this.opinion, super.key});

  final ExecutiveOpinionData opinion;

  @override
  State<ExecutiveOpinionCard> createState() {
    return _ExecutiveOpinionCardState();
  }
}

class _ExecutiveOpinionCardState extends State<ExecutiveOpinionCard> {
  final ExecutiveOpinionPdfService pdfService = ExecutiveOpinionPdfService();

  bool isExportingPdf = false;

  ExecutiveOpinionData get opinion {
    return widget.opinion;
  }

  Future<void> exportPdf() async {
    if (isExportingPdf) {
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      await pdfService.printOpinion(opinion: opinion);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classificationColor = executiveOpinionClassificationColor(
      opinion.classification,
    );

    final mainRecommendation = opinion.recommendations.isEmpty
        ? null
        : opinion.recommendations.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF263238), Color(0xFF37474F)],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;

                final information = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.psychology_alt_outlined,
                          color: Colors.white,
                          size: 29,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Parecer Executivo Inteligente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      opinion.scopeLabel,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      opinion.diagnosis,
                      maxLines: compact ? 7 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ],
                );

                final score = ExecutiveOpinionScorePanel(
                  opinion: opinion,
                  color: classificationColor,
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [information, const SizedBox(height: 20), score],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: information),
                    const SizedBox(width: 24),
                    score,
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 780
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: width,
                          child: ExecutiveOpinionPreviewSection(
                            title: 'Riscos e gargalos',
                            icon: Icons.warning_amber_outlined,
                            color: const Color(0xFFC62828),
                            items: [
                              ...opinion.risks,
                              ...opinion.bottlenecks,
                            ].take(4).toList(),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: ExecutiveOpinionPriorityPreview(
                            priorities: opinion.priorities.take(4).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (mainRecommendation != null) ...[
                  const SizedBox(height: 18),
                  ExecutiveOpinionMainRecommendation(
                    recommendation: mainRecommendation,
                  ),
                ],
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;

                    final date = Text(
                      'Gerado em ${opinion.generatedAt}',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    );

                    final pdfButton = OutlinedButton.icon(
                      onPressed: isExportingPdf ? null : exportPdf,
                      icon: isExportingPdf
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        isExportingPdf ? 'Gerando PDF...' : 'Exportar PDF',
                      ),
                    );

                    final viewButton = FilledButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) {
                            return ExecutiveOpinionDialog(opinion: opinion);
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                      ),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Ver parecer completo'),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          date,
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: pdfButton),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: viewButton),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: date),
                        pdfButton,
                        const SizedBox(width: 10),
                        viewButton,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExecutiveOpinionScorePanel extends StatelessWidget {
  const ExecutiveOpinionScorePanel({
    required this.opinion,
    required this.color,
    super.key,
  });

  final ExecutiveOpinionData opinion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            executiveClassificationLabel(opinion.classification),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Classificação geral',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                opinion.performanceIndex.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '/100',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (opinion.performanceIndex / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Confiança: ${formatOpinionPercentage(opinion.confidence)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class ExecutiveOpinionPreviewSection extends StatelessWidget {
  const ExecutiveOpinionPreviewSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<ExecutiveOpinionItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Nenhum ponto crítico identificado.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 11,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: executiveOpinionImpactColor(item.impact),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ExecutiveOpinionPriorityPreview extends StatelessWidget {
  const ExecutiveOpinionPriorityPreview({required this.priorities, super.key});

  final List<ExecutiveOpinionPriorityItem> priorities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_list_numbered_outlined,
                color: Color(0xFF1565C0),
              ),
              SizedBox(width: 8),
              Text(
                'Prioridades imediatas',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(priorities.length, (index) {
            final item = priorities[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == priorities.length - 1 ? 0 : 11,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        item.position.toString(),
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.deadline} · ${item.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ExecutiveOpinionMainRecommendation extends StatelessWidget {
  const ExecutiveOpinionMainRecommendation({
    required this.recommendation,
    super.key,
  });

  final ExecutiveOpinionRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = executiveOpinionPriorityColor(recommendation.priority);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.explanation,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 7),
                Text(
                  recommendation.action,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExecutiveOpinionDialog extends StatefulWidget {
  const ExecutiveOpinionDialog({required this.opinion, super.key});

  final ExecutiveOpinionData opinion;

  @override
  State<ExecutiveOpinionDialog> createState() {
    return _ExecutiveOpinionDialogState();
  }
}

class _ExecutiveOpinionDialogState extends State<ExecutiveOpinionDialog> {
  final ExecutiveOpinionPdfService pdfService = ExecutiveOpinionPdfService();

  bool isExportingPdf = false;

  ExecutiveOpinionData get opinion {
    return widget.opinion;
  }

  Future<void> exportPdf() async {
    if (isExportingPdf) {
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      await pdfService.printOpinion(opinion: opinion);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = executiveOpinionClassificationColor(opinion.classification);

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF263238), Color(0xFF37474F)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.psychology_alt_outlined,
                      color: color,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parecer Executivo Completo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opinion.scopeLabel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  ExecutiveOpinionDialogSummary(opinion: opinion),
                  const SizedBox(height: 20),
                  ExecutiveOpinionDialogSection(
                    title: 'Diagnóstico geral',
                    icon: Icons.analytics_outlined,
                    color: const Color(0xFF1565C0),
                    child: Text(
                      opinion.diagnosis,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionItemListSection(
                    title: 'Pontos fortes',
                    icon: Icons.trending_up_outlined,
                    color: const Color(0xFF1B5E20),
                    items: opinion.strengths,
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionItemListSection(
                    title: 'Gargalos',
                    icon: Icons.block_outlined,
                    color: const Color(0xFFEF6C00),
                    items: opinion.bottlenecks,
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionItemListSection(
                    title: 'Riscos',
                    icon: Icons.warning_amber_outlined,
                    color: const Color(0xFFC62828),
                    items: opinion.risks,
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionItemListSection(
                    title: 'Oportunidades',
                    icon: Icons.lightbulb_outline,
                    color: const Color(0xFF00838F),
                    items: opinion.opportunities,
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionPriorityListSection(
                    priorities: opinion.priorities,
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionRecommendationListSection(
                    recommendations: opinion.recommendations,
                  ),
                  const SizedBox(height: 16),
                  ExecutiveOpinionDialogSection(
                    title: 'Resumo executivo',
                    icon: Icons.description_outlined,
                    color: const Color(0xFF6A1B9A),
                    child: SelectableText(
                      opinion.executiveSummary,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;

                  final confidence = Text(
                    'Confiança do parecer: ${formatOpinionPercentage(opinion.confidence)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  );

                  final exportButton = OutlinedButton.icon(
                    onPressed: isExportingPdf ? null : exportPdf,
                    icon: isExportingPdf
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      isExportingPdf ? 'Gerando PDF...' : 'Exportar PDF',
                    ),
                  );

                  final closeButton = FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                    ),
                    child: const Text('Fechar'),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        confidence,
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: exportButton),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: closeButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: confidence),
                      exportButton,
                      const SizedBox(width: 10),
                      closeButton,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExecutiveOpinionDialogSummary extends StatelessWidget {
  const ExecutiveOpinionDialogSummary({required this.opinion, super.key});

  final ExecutiveOpinionData opinion;

  @override
  Widget build(BuildContext context) {
    final color = executiveOpinionClassificationColor(opinion.classification);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 14,
        children: [
          ExecutiveOpinionDialogMetric(
            label: 'Classificação',
            value: executiveClassificationLabel(opinion.classification),
            color: color,
          ),
          ExecutiveOpinionDialogMetric(
            label: 'Índice geral',
            value: '${opinion.performanceIndex.toStringAsFixed(0)}/100',
            color: color,
          ),
          ExecutiveOpinionDialogMetric(
            label: 'Confiança',
            value: formatOpinionPercentage(opinion.confidence),
            color: const Color(0xFF1565C0),
          ),
          ExecutiveOpinionDialogMetric(
            label: 'Riscos',
            value: opinion.risks.length.toString(),
            color: const Color(0xFFC62828),
          ),
          ExecutiveOpinionDialogMetric(
            label: 'Prioridades',
            value: opinion.priorities.length.toString(),
            color: const Color(0xFFEF6C00),
          ),
        ],
      ),
    );
  }
}

class ExecutiveOpinionDialogMetric extends StatelessWidget {
  const ExecutiveOpinionDialogMetric({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class ExecutiveOpinionDialogSection extends StatelessWidget {
  const ExecutiveOpinionDialogSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class ExecutiveOpinionItemListSection extends StatelessWidget {
  const ExecutiveOpinionItemListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<ExecutiveOpinionItem> items;

  @override
  Widget build(BuildContext context) {
    return ExecutiveOpinionDialogSection(
      title: title,
      icon: icon,
      color: color,
      child: items.isEmpty
          ? const Text(
              'Nenhum item identificado.',
              style: TextStyle(color: Colors.black54),
            )
          : Column(
              children: List.generate(items.length, (index) {
                final item = items[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 13,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: executiveOpinionImpactColor(item.impact),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.category,
                              style: TextStyle(
                                color: executiveOpinionImpactColor(item.impact),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

class ExecutiveOpinionPriorityListSection extends StatelessWidget {
  const ExecutiveOpinionPriorityListSection({
    required this.priorities,
    super.key,
  });

  final List<ExecutiveOpinionPriorityItem> priorities;

  @override
  Widget build(BuildContext context) {
    return ExecutiveOpinionDialogSection(
      title: 'Plano de prioridades',
      icon: Icons.format_list_numbered_outlined,
      color: const Color(0xFFEF6C00),
      child: Column(
        children: List.generate(priorities.length, (index) {
          final item = priorities[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == priorities.length - 1 ? 0 : 14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF6C00).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.position.toString(),
                      style: const TextStyle(
                        color: Color(0xFFEF6C00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Prazo: ${item.deadline}',
                        style: const TextStyle(
                          color: Color(0xFFEF6C00),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Resultado esperado: ${item.expectedResult}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ExecutiveOpinionRecommendationListSection extends StatelessWidget {
  const ExecutiveOpinionRecommendationListSection({
    required this.recommendations,
    super.key,
  });

  final List<ExecutiveOpinionRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return ExecutiveOpinionDialogSection(
      title: 'Recomendações',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFF1565C0),
      child: Column(
        children: List.generate(recommendations.length, (index) {
          final item = recommendations[index];

          final color = executiveOpinionPriorityColor(item.priority);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == recommendations.length - 1 ? 0 : 14,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${formatOpinionPercentage(item.confidence)} de confiança',
                        style: TextStyle(color: color, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.explanation,
                    style: const TextStyle(color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.action,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

Color executiveOpinionClassificationColor(
  ExecutiveOperationClassification classification,
) {
  switch (classification) {
    case ExecutiveOperationClassification.excellent:
      return const Color(0xFF1B5E20);

    case ExecutiveOperationClassification.good:
      return const Color(0xFF2E7D32);

    case ExecutiveOperationClassification.attention:
      return const Color(0xFFEF6C00);

    case ExecutiveOperationClassification.critical:
      return const Color(0xFFC62828);

    case ExecutiveOperationClassification.severe:
      return const Color(0xFF8E0000);
  }
}

Color executiveOpinionImpactColor(ExecutiveOpinionImpact impact) {
  switch (impact) {
    case ExecutiveOpinionImpact.low:
      return const Color(0xFF1B5E20);

    case ExecutiveOpinionImpact.medium:
      return const Color(0xFF1565C0);

    case ExecutiveOpinionImpact.high:
      return const Color(0xFFEF6C00);

    case ExecutiveOpinionImpact.critical:
      return const Color(0xFFC62828);
  }
}

Color executiveOpinionPriorityColor(String priority) {
  switch (priority) {
    case 'critical':
      return const Color(0xFFC62828);

    case 'high':
      return const Color(0xFFEF6C00);

    case 'medium':
      return const Color(0xFF1565C0);

    case 'low':
      return const Color(0xFF1B5E20);

    default:
      return const Color(0xFF607D8B);
  }
}
