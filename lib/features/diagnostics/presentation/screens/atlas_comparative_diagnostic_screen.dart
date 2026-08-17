import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_comparative_diagnostic_data.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasComparativeDiagnosticScreen extends StatelessWidget {
  const AtlasComparativeDiagnosticScreen({
    required this.data,
    this.onOpenFarm,
    this.onOpenArea,
    super.key,
  });

  final AtlasComparativeDiagnosticData data;

  final ValueChanged<String>? onOpenFarm;

  final void Function(String farmName, AtlasFarmAnalysisArea area)? onOpenArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Diagnóstico Comparativo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: data.ranking.isEmpty
                ? const _EmptyComparisonView()
                : ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _ComparisonHero(data: data),
                      const SizedBox(height: 24),
                      _TopFarmSummary(data: data, onOpenFarm: onOpenFarm),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        title: 'Ranking das fazendas',
                        subtitle:
                            'Propriedades ordenadas pelo score diagnóstico.',
                      ),
                      const SizedBox(height: 14),
                      _FarmRankingList(
                        ranking: data.ranking,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        title: 'Comparação por área',
                        subtitle:
                            'Média, melhor resultado, pior resultado e diferença entre as propriedades.',
                      ),
                      const SizedBox(height: 14),
                      _AreaComparisonGrid(
                        areas: data.areaComparisons,
                        onOpenArea: onOpenArea,
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        title: 'Destaques da operação',
                        subtitle:
                            'Lideranças, alertas, desequilíbrios e oportunidades.',
                      ),
                      const SizedBox(height: 14),
                      _HighlightGrid(
                        highlights: data.highlights,
                        onOpenFarm: onOpenFarm,
                        onOpenArea: onOpenArea,
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        title: 'Prioridades de intervenção',
                        subtitle: 'Ordem recomendada de atuação do consultor.',
                      ),
                      const SizedBox(height: 14),
                      _PriorityList(
                        priorities: data.priorities,
                        onOpenFarm: onOpenFarm,
                        onOpenArea: onOpenArea,
                      ),
                      const SizedBox(height: 34),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonHero extends StatelessWidget {
  const _ComparisonHero({required this.data});

  final AtlasComparativeDiagnosticData data;

  @override
  Widget build(BuildContext context) {
    final color = comparativeLevelColor(data.operationLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2F24), Color(0xFF174B37), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.compare_arrows_outlined,
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visão comparativa da operação',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.farmCount} '
                          '${data.farmCount == 1 ? 'fazenda analisada' : 'fazendas analisadas'}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 14),
              Text(
                'Gerado em ${_formatDateTime(data.generatedAt)}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          );

          final score = Container(
            width: 220,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.42)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atlasDiagnosticLevelLabel(data.operationLevel),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Média da operação',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 17),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.operationAverageScore.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/100',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 11,
                    value: (data.operationAverageScore / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 22), score],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 27),
              score,
            ],
          );
        },
      ),
    );
  }
}

class _TopFarmSummary extends StatelessWidget {
  const _TopFarmSummary({required this.data, required this.onOpenFarm});

  final AtlasComparativeDiagnosticData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final best = data.bestFarm;
    final critical = data.mostCriticalFarm;

    if (best == null || critical == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final bestCard = _FarmSummaryCard(
          title: 'Fazenda líder',
          farm: best,
          icon: Icons.emoji_events_outlined,
          color: const Color(0xFF1B5E20),
          onOpen: onOpenFarm == null
              ? null
              : () {
                  onOpenFarm!(best.farmName);
                },
        );

        final criticalCard = _FarmSummaryCard(
          title: 'Maior necessidade de atenção',
          farm: critical,
          icon: Icons.warning_amber_outlined,
          color: comparativeLevelColor(critical.level),
          onOpen: onOpenFarm == null
              ? null
              : () {
                  onOpenFarm!(critical.farmName);
                },
        );

        if (compact) {
          return Column(
            children: [bestCard, const SizedBox(height: 14), criticalCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: bestCard),
            const SizedBox(width: 14),
            Expanded(child: criticalCard),
          ],
        );
      },
    );
  }
}

class _FarmSummaryCard extends StatelessWidget {
  const _FarmSummaryCard({
    required this.title,
    required this.farm,
    required this.icon,
    required this.color,
    required this.onOpen,
  });

  final String title;
  final AtlasComparativeFarmRanking farm;
  final IconData icon;
  final Color color;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farm.farmName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Prioridade: ${farm.mainPriority}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetricChip(
                          label: 'Score',
                          value: farm.score.toStringAsFixed(0),
                          color: color,
                        ),
                        _MetricChip(
                          label: 'Riscos',
                          value: farm.criticalRiskCount.toString(),
                          color: const Color(0xFFC62828),
                        ),
                        _MetricChip(
                          label: 'Gargalos',
                          value: farm.bottleneckCount.toString(),
                          color: const Color(0xFFEF6C00),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOpen != null)
                const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmRankingList extends StatelessWidget {
  const _FarmRankingList({required this.ranking, required this.onOpenFarm});

  final List<AtlasComparativeFarmRanking> ranking;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(ranking.length, (index) {
          final farm = ranking[index];
          final color = comparativeLevelColor(farm.level);

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              InkWell(
                onTap: onOpenFarm == null
                    ? null
                    : () {
                        onOpenFarm!(farm.farmName);
                      },
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.10),
                        child: Text(
                          '${farm.position}º',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farm.farmName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              farm.mainPriority,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      minHeight: 7,
                                      value: (farm.score / 100).clamp(0.0, 1.0),
                                      backgroundColor: color.withValues(
                                        alpha: 0.10,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  farm.score.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _differenceText(farm.differenceFromAverage),
                            style: TextStyle(
                              color: farm.differenceFromAverage >= 0
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFFC62828),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'da média',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      if (onOpenFarm != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.black38,
                          ),
                        ),
                    ],
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

class _AreaComparisonGrid extends StatelessWidget {
  const _AreaComparisonGrid({required this.areas, required this.onOpenArea});

  final List<AtlasComparativeAreaData> areas;

  final void Function(String farmName, AtlasFarmAnalysisArea area)? onOpenArea;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: areas.map((area) {
            final color = comparativeLevelColor(area.level);

            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(comparativeAreaIcon(area.area), color: color),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              area.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            area.averageScore.toStringAsFixed(0),
                            style: TextStyle(
                              color: color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (area.averageScore / 100).clamp(0.0, 1.0),
                          backgroundColor: color.withValues(alpha: 0.10),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FarmAreaResult(
                        label: 'Melhor',
                        farmName: area.bestFarmName,
                        score: area.bestScore,
                        color: const Color(0xFF1B5E20),
                        onTap: onOpenArea == null
                            ? null
                            : () {
                                onOpenArea!(area.bestFarmName, area.area);
                              },
                      ),
                      const SizedBox(height: 9),
                      _FarmAreaResult(
                        label: 'Pior',
                        farmName: area.worstFarmName,
                        score: area.worstScore,
                        color: const Color(0xFFC62828),
                        onTap: onOpenArea == null
                            ? null
                            : () {
                                onOpenArea!(area.worstFarmName, area.area);
                              },
                      ),
                      const SizedBox(height: 11),
                      Text(
                        'Diferença entre propriedades: '
                        '${area.amplitude.toStringAsFixed(0)} pontos',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
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

class _FarmAreaResult extends StatelessWidget {
  const _FarmAreaResult({
    required this.label,
    required this.farmName,
    required this.score,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String farmName;
  final double score;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              '$label:',
              style: const TextStyle(color: Colors.black45, fontSize: 10),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                farmName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightGrid extends StatelessWidget {
  const _HighlightGrid({
    required this.highlights,
    required this.onOpenFarm,
    required this.onOpenArea,
  });

  final List<AtlasComparativeHighlight> highlights;

  final ValueChanged<String>? onOpenFarm;

  final void Function(String farmName, AtlasFarmAnalysisArea area)? onOpenArea;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return const _EmptyCard(
        message: 'Nenhum destaque comparativo foi identificado.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: highlights.map((item) {
            final color = comparativeHighlightColor(item.type);

            return SizedBox(
              width: width,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final farmName = item.farmName;

                    final area = item.area;

                    if (farmName != null &&
                        area != null &&
                        onOpenArea != null) {
                      onOpenArea!(farmName, area);

                      return;
                    }

                    if (farmName != null && onOpenFarm != null) {
                      onOpenFarm!(farmName);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              comparativeHighlightIcon(item.type),
                              color: color,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _TypeBadge(type: item.type),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({
    required this.priorities,
    required this.onOpenFarm,
    required this.onOpenArea,
  });

  final List<AtlasComparativePriority> priorities;

  final ValueChanged<String>? onOpenFarm;

  final void Function(String farmName, AtlasFarmAnalysisArea area)? onOpenArea;

  @override
  Widget build(BuildContext context) {
    if (priorities.isEmpty) {
      return const _EmptyCard(
        message: 'Nenhuma prioridade comparativa foi identificada.',
      );
    }

    return Column(
      children: priorities.map((item) {
        final color = comparativeLevelColor(item.level);

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (onOpenArea != null) {
                  onOpenArea!(item.farmName, item.area);

                  return;
                }

                if (onOpenFarm != null) {
                  onOpenFarm!(item.farmName);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
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
                            item.farmName,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 8),
                          Text(
                            atlasFarmAreaLabel(item.area),
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.priorityScore.toStringAsFixed(0),
                          style: TextStyle(
                            color: color,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Prioridade',
                          style: TextStyle(color: Colors.black38, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final AtlasComparativeHighlightType type;

  @override
  Widget build(BuildContext context) {
    final color = comparativeHighlightColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasComparativeHighlightTypeLabel(type),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }
}

class _EmptyComparisonView extends StatelessWidget {
  const _EmptyComparisonView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_outlined,
              size: 56,
              color: Colors.black38,
            ),
            SizedBox(height: 14),
            Text(
              'Sem dados para comparação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Gere diagnósticos para pelo menos uma fazenda antes de abrir esta tela.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color comparativeLevelColor(AtlasDiagnosticLevel level) {
  switch (level) {
    case AtlasDiagnosticLevel.excellent:
      return const Color(0xFF1B5E20);

    case AtlasDiagnosticLevel.stable:
      return const Color(0xFF2E7D32);

    case AtlasDiagnosticLevel.attention:
      return const Color(0xFFEF6C00);

    case AtlasDiagnosticLevel.critical:
      return const Color(0xFFC62828);
  }
}

Color comparativeHighlightColor(AtlasComparativeHighlightType type) {
  switch (type) {
    case AtlasComparativeHighlightType.leader:
      return const Color(0xFF1B5E20);

    case AtlasComparativeHighlightType.warning:
      return const Color(0xFFC62828);

    case AtlasComparativeHighlightType.opportunity:
      return const Color(0xFF1565C0);

    case AtlasComparativeHighlightType.imbalance:
      return const Color(0xFFEF6C00);
  }
}

IconData comparativeHighlightIcon(AtlasComparativeHighlightType type) {
  switch (type) {
    case AtlasComparativeHighlightType.leader:
      return Icons.emoji_events_outlined;

    case AtlasComparativeHighlightType.warning:
      return Icons.warning_amber_outlined;

    case AtlasComparativeHighlightType.opportunity:
      return Icons.lightbulb_outline;

    case AtlasComparativeHighlightType.imbalance:
      return Icons.compare_arrows_outlined;
  }
}

IconData comparativeAreaIcon(AtlasFarmAnalysisArea area) {
  switch (area) {
    case AtlasFarmAnalysisArea.general:
      return Icons.insights_outlined;

    case AtlasFarmAnalysisArea.finance:
      return Icons.account_balance_wallet_outlined;

    case AtlasFarmAnalysisArea.herd:
      return AtlasLivestockIcons.cow;

    case AtlasFarmAnalysisArea.paddock:
      return Icons.grid_view_outlined;

    case AtlasFarmAnalysisArea.inventory:
      return Icons.inventory_2_outlined;

    case AtlasFarmAnalysisArea.agenda:
      return Icons.calendar_month_outlined;
  }
}

String _differenceText(double value) {
  final sign = value >= 0 ? '+' : '-';

  return '$sign${value.abs().toStringAsFixed(0)}';
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/${date.year} '
      '$hour:$minute';
}
