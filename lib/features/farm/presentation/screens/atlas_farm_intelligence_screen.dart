import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasFarmIntelligenceScreen extends StatelessWidget {
  const AtlasFarmIntelligenceScreen({
    required this.data,
    required this.onOpenCopilot,
    required this.onOpenFinance,
    required this.onOpenHerd,
    required this.onOpenPaddocks,
    required this.onOpenInventory,
    required this.onOpenAgenda,
    super.key,
  });

  final AtlasFarmIntelligenceData data;

  final VoidCallback onOpenCopilot;
  final VoidCallback onOpenFinance;
  final VoidCallback onOpenHerd;
  final VoidCallback onOpenPaddocks;
  final VoidCallback onOpenInventory;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          'Inteligência · ${data.farmName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Copiloto Atlas',
            onPressed: onOpenCopilot,
            icon: const Icon(Icons.smart_toy_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FarmIntelligenceHero(
                      data: data,
                      onOpenCopilot: onOpenCopilot,
                    ),
                    const SizedBox(height: 24),
                    _AreaScoreGrid(data: data),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Prioridade da propriedade',
                      subtitle:
                          'A primeira intervenção recomendada para proteger o resultado.',
                    ),
                    const SizedBox(height: 14),
                    _MainPriorityCard(
                      priority: data.mainPriority,
                      onOpenArea: () {
                        _openArea(data.mainPriority.area);
                      },
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Riscos identificados',
                      subtitle:
                          'Pontos que podem comprometer a operação caso não sejam tratados.',
                    ),
                    const SizedBox(height: 14),
                    _InsightGrid(insights: data.risks),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Oportunidades',
                      subtitle:
                          'Ações que podem gerar ganho ou melhorar a qualidade da gestão.',
                    ),
                    const SizedBox(height: 14),
                    _InsightGrid(insights: data.opportunities),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Pontos positivos',
                      subtitle: 'Aspectos sob controle que devem ser mantidos.',
                    ),
                    const SizedBox(height: 14),
                    _InsightGrid(insights: data.strengths),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Análise detalhada por área',
                      subtitle:
                          'Interpretação dos dados de cada módulo da fazenda.',
                    ),
                    const SizedBox(height: 14),
                    _AreaAnalysisList(
                      data: data,
                      onOpenFinance: onOpenFinance,
                      onOpenHerd: onOpenHerd,
                      onOpenPaddocks: onOpenPaddocks,
                      onOpenInventory: onOpenInventory,
                      onOpenAgenda: onOpenAgenda,
                    ),
                    const SizedBox(height: 34),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openArea(AtlasFarmAnalysisArea area) {
    switch (area) {
      case AtlasFarmAnalysisArea.finance:
        onOpenFinance();
      case AtlasFarmAnalysisArea.herd:
        onOpenHerd();
      case AtlasFarmAnalysisArea.paddock:
        onOpenPaddocks();
      case AtlasFarmAnalysisArea.inventory:
        onOpenInventory();
      case AtlasFarmAnalysisArea.agenda:
        onOpenAgenda();
      case AtlasFarmAnalysisArea.general:
        break;
    }
  }
}

class _FarmIntelligenceHero extends StatelessWidget {
  const _FarmIntelligenceHero({
    required this.data,
    required this.onOpenCopilot,
  });

  final AtlasFarmIntelligenceData data;
  final VoidCallback onOpenCopilot;

  @override
  Widget build(BuildContext context) {
    final color = farmIntelligenceColor(data.level);

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
                    width: 53,
                    height: 53,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.agriculture_outlined,
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.situationTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.farmName,
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
                data.executiveSummary,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  data.generalRecommendation,
                  style: const TextStyle(
                    color: Color(0xFFC8A951),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              FilledButton.icon(
                onPressed: onOpenCopilot,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                ),
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text(
                  'Perguntar ao Copiloto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );

          final score = _FarmScorePanel(data: data, color: color);

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

class _FarmScorePanel extends StatelessWidget {
  const _FarmScorePanel({required this.data, required this.color});

  final AtlasFarmIntelligenceData data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            atlasFarmLevelLabel(data.level),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Score da propriedade',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.score.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('/100', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: (data.score / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaScoreGrid extends StatelessWidget {
  const _AreaScoreGrid({required this.data});

  final AtlasFarmIntelligenceData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AreaScoreItem(
        title: 'Financeiro',
        score: data.finance.score,
        level: data.finance.level,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _AreaScoreItem(
        title: 'Rebanho',
        score: data.herd.score,
        level: data.herd.level,
        icon: Icons.pets_outlined,
      ),
      _AreaScoreItem(
        title: 'Piquetes',
        score: data.paddocks.score,
        level: data.paddocks.level,
        icon: Icons.grid_view_outlined,
      ),
      _AreaScoreItem(
        title: 'Estoque',
        score: data.inventory.score,
        level: data.inventory.level,
        icon: Icons.inventory_2_outlined,
      ),
      _AreaScoreItem(
        title: 'Agenda',
        score: data.agenda.score,
        level: data.agenda.level,
        icon: Icons.calendar_month_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 64) / 5
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            final color = farmIntelligenceColor(item.level);

            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: color),
                      const SizedBox(height: 12),
                      Text(
                        item.score.toStringAsFixed(0),
                        style: TextStyle(
                          color: color,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

class _AreaScoreItem {
  const _AreaScoreItem({
    required this.title,
    required this.score,
    required this.level,
    required this.icon,
  });

  final String title;
  final double score;
  final AtlasFarmIntelligenceLevel level;
  final IconData icon;
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

class _MainPriorityCard extends StatelessWidget {
  const _MainPriorityCard({required this.priority, required this.onOpenArea});

  final AtlasFarmPriority priority;
  final VoidCallback onOpenArea;

  @override
  Widget build(BuildContext context) {
    final color = farmIntelligenceColor(priority.level);

    return Card(
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            final information = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.flag_outlined, color: color),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priority.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        priority.description,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        priority.recommendation,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final button = FilledButton.icon(
              onPressed: onOpenArea,
              icon: const Icon(Icons.arrow_forward),
              label: Text('Abrir ${atlasFarmAreaLabel(priority.area)}'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [information, const SizedBox(height: 16), button],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 18),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({required this.insights});

  final List<AtlasFarmInsight> insights;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: insights.map((item) {
            return SizedBox(
              width: width,
              child: _InsightCard(insight: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AtlasFarmInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = farmIntelligenceColor(insight.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(farmAreaIcon(insight.area), color: color),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _LevelBadge(level: insight.level),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              insight.recommendation,
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
  }
}

class _AreaAnalysisList extends StatelessWidget {
  const _AreaAnalysisList({
    required this.data,
    required this.onOpenFinance,
    required this.onOpenHerd,
    required this.onOpenPaddocks,
    required this.onOpenInventory,
    required this.onOpenAgenda,
  });

  final AtlasFarmIntelligenceData data;

  final VoidCallback onOpenFinance;
  final VoidCallback onOpenHerd;
  final VoidCallback onOpenPaddocks;
  final VoidCallback onOpenInventory;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AreaAnalysisItem(
        title: 'Financeiro',
        analysis: data.finance.analysis,
        score: data.finance.score,
        level: data.finance.level,
        icon: Icons.account_balance_wallet_outlined,
        onOpen: onOpenFinance,
      ),
      _AreaAnalysisItem(
        title: 'Rebanho',
        analysis: data.herd.analysis,
        score: data.herd.score,
        level: data.herd.level,
        icon: Icons.pets_outlined,
        onOpen: onOpenHerd,
      ),
      _AreaAnalysisItem(
        title: 'Piquetes',
        analysis: data.paddocks.analysis,
        score: data.paddocks.score,
        level: data.paddocks.level,
        icon: Icons.grid_view_outlined,
        onOpen: onOpenPaddocks,
      ),
      _AreaAnalysisItem(
        title: 'Estoque',
        analysis: data.inventory.analysis,
        score: data.inventory.score,
        level: data.inventory.level,
        icon: Icons.inventory_2_outlined,
        onOpen: onOpenInventory,
      ),
      _AreaAnalysisItem(
        title: 'Agenda',
        analysis: data.agenda.analysis,
        score: data.agenda.score,
        level: data.agenda.level,
        icon: Icons.calendar_month_outlined,
        onOpen: onOpenAgenda,
      ),
    ];

    return Card(
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final color = farmIntelligenceColor(item.level);

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                onTap: item.onOpen,
                contentPadding: const EdgeInsets.all(17),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, color: color),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      item.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    item.analysis,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AreaAnalysisItem {
  const _AreaAnalysisItem({
    required this.title,
    required this.analysis,
    required this.score,
    required this.level,
    required this.icon,
    required this.onOpen,
  });

  final String title;
  final String analysis;
  final double score;
  final AtlasFarmIntelligenceLevel level;
  final IconData icon;
  final VoidCallback onOpen;
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final AtlasFarmIntelligenceLevel level;

  @override
  Widget build(BuildContext context) {
    final color = farmIntelligenceColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasFarmLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color farmIntelligenceColor(AtlasFarmIntelligenceLevel level) {
  switch (level) {
    case AtlasFarmIntelligenceLevel.excellent:
      return const Color(0xFF1B5E20);
    case AtlasFarmIntelligenceLevel.stable:
      return const Color(0xFF2E7D32);
    case AtlasFarmIntelligenceLevel.attention:
      return const Color(0xFFEF6C00);
    case AtlasFarmIntelligenceLevel.critical:
      return const Color(0xFFC62828);
  }
}

IconData farmAreaIcon(AtlasFarmAnalysisArea area) {
  switch (area) {
    case AtlasFarmAnalysisArea.general:
      return Icons.insights_outlined;
    case AtlasFarmAnalysisArea.finance:
      return Icons.account_balance_wallet_outlined;
    case AtlasFarmAnalysisArea.herd:
      return Icons.pets_outlined;
    case AtlasFarmAnalysisArea.paddock:
      return Icons.grid_view_outlined;
    case AtlasFarmAnalysisArea.inventory:
      return Icons.inventory_2_outlined;
    case AtlasFarmAnalysisArea.agenda:
      return Icons.calendar_month_outlined;
  }
}
