import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasDiagnosticScreen extends StatefulWidget {
  const AtlasDiagnosticScreen({
    required this.data,
    this.onOpenArea,
    this.onExportExecutivePdf,
    this.onExportTechnicalPdf,
    this.onExportProducerReport,
    super.key,
  });

  final AtlasDiagnosticData data;

  final ValueChanged<AtlasFarmAnalysisArea>? onOpenArea;

  final VoidCallback? onExportExecutivePdf;
  final VoidCallback? onExportTechnicalPdf;
  final VoidCallback? onExportProducerReport;

  @override
  State<AtlasDiagnosticScreen> createState() {
    return _AtlasDiagnosticScreenState();
  }
}

class _AtlasDiagnosticScreenState extends State<AtlasDiagnosticScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  AtlasDiagnosticData get data => widget.data;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void openArea(AtlasFarmAnalysisArea area) {
    final callback = widget.onOpenArea;

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O acesso à área "${atlasFarmAreaLabel(area)}" ainda não foi conectado.',
          ),
        ),
      );
      return;
    }

    callback(area);
  }

  void showExportUnavailable(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label ainda não foi conectado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnóstico Inteligente',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              data.scopeLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<_DiagnosticExportType>(
            tooltip: 'Exportar diagnóstico',
            icon: const Icon(Icons.file_download_outlined),
            onSelected: (type) {
              switch (type) {
                case _DiagnosticExportType.executive:
                  final callback = widget.onExportExecutivePdf;

                  if (callback == null) {
                    showExportUnavailable('PDF Executivo');
                  } else {
                    callback();
                  }

                  break;

                case _DiagnosticExportType.technical:
                  final callback = widget.onExportTechnicalPdf;

                  if (callback == null) {
                    showExportUnavailable('PDF Técnico');
                  } else {
                    callback();
                  }

                  break;

                case _DiagnosticExportType.producer:
                  final callback = widget.onExportProducerReport;

                  if (callback == null) {
                    showExportUnavailable('Relatório do produtor');
                  } else {
                    callback();
                  }

                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _DiagnosticExportType.executive,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.assessment_outlined),
                    title: Text('PDF Executivo'),
                  ),
                ),
                PopupMenuItem(
                  value: _DiagnosticExportType.technical,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.science_outlined),
                    title: Text('PDF Técnico'),
                  ),
                ),
                PopupMenuItem(
                  value: _DiagnosticExportType.producer,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.agriculture_outlined),
                    title: Text('Relatório do produtor'),
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _DiagnosticHero(data: data),
                const SizedBox(height: 24),
                _MainDiagnosisCard(
                  data: data,
                  onOpenArea: () {
                    openArea(data.mainPriority.area);
                  },
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Diagnóstico por área',
                  subtitle: 'Áreas ordenadas do menor para o maior score.',
                ),
                const SizedBox(height: 14),
                _DiagnosticAreaGrid(areas: data.areas, onOpenArea: openArea),
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Riscos',
                  subtitle:
                      'Pontos que podem comprometer o resultado da propriedade.',
                ),
                const SizedBox(height: 14),
                _InsightGrid(
                  items: data.risks,
                  emptyMessage: 'Nenhum risco relevante foi identificado.',
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Gargalos',
                  subtitle: 'Áreas que limitam o desempenho geral.',
                ),
                const SizedBox(height: 14),
                _InsightGrid(
                  items: data.bottlenecks,
                  emptyMessage: 'Nenhum gargalo relevante foi identificado.',
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Oportunidades',
                  subtitle:
                      'Ações que podem gerar ganho operacional ou financeiro.',
                ),
                const SizedBox(height: 14),
                _InsightGrid(
                  items: data.opportunities,
                  emptyMessage: 'Nenhuma oportunidade foi identificada.',
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Plano de ação',
                  subtitle: 'Ações organizadas por horizonte de execução.',
                ),
                const SizedBox(height: 14),
                _ActionPlanPanel(
                  tabController: tabController,
                  plan7Days: data.plan7Days,
                  plan30Days: data.plan30Days,
                  plan90Days: data.plan90Days,
                  onOpenArea: openArea,
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Pontos fortes',
                  subtitle: 'Práticas positivas que devem ser preservadas.',
                ),
                const SizedBox(height: 14),
                _InsightGrid(
                  items: data.strengths,
                  emptyMessage:
                      'Ainda não existem pontos fortes suficientes para destacar.',
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

class _DiagnosticHero extends StatelessWidget {
  const _DiagnosticHero({required this.data});

  final AtlasDiagnosticData data;

  @override
  Widget build(BuildContext context) {
    final color = diagnosticLevelColor(data.level);

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
                      Icons.health_and_safety_outlined,
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
                          data.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.scopeLabel,
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
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  data.mainDiagnosis,
                  style: const TextStyle(
                    color: Color(0xFFC8A951),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 13),
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
                  atlasDiagnosticLevelLabel(data.level),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Score diagnóstico',
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
                    value: (data.score / 100).clamp(0.0, 1.0),
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

class _MainDiagnosisCard extends StatelessWidget {
  const _MainDiagnosisCard({required this.data, required this.onOpenArea});

  final AtlasDiagnosticData data;
  final VoidCallback onOpenArea;

  @override
  Widget build(BuildContext context) {
    final priority = data.mainPriority;

    final color = diagnosticLevelColor(priority.level);

    return Card(
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            final information = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                      const Text(
                        'Prioridade número 1',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
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

class _DiagnosticAreaGrid extends StatelessWidget {
  const _DiagnosticAreaGrid({required this.areas, required this.onOpenArea});

  final List<AtlasDiagnosticArea> areas;

  final ValueChanged<AtlasFarmAnalysisArea> onOpenArea;

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
            final color = diagnosticLevelColor(area.level);

            return SizedBox(
              width: width,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    onOpenArea(area.sourceArea);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              diagnosticAreaIcon(area.sourceArea),
                              color: color,
                            ),
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
                              area.score.toStringAsFixed(0),
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
                            value: (area.score / 100).clamp(0.0, 1.0),
                            backgroundColor: color.withValues(alpha: 0.10),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          area.analysis,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          area.recommendation,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({required this.items, required this.emptyMessage});

  final List<AtlasDiagnosticInsight> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
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
          children: items.map((item) {
            final color = diagnosticLevelColor(item.level);

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
                          Icon(diagnosticAreaIcon(item.area), color: color),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _LevelBadge(level: item.level),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Impacto',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.impactScore.toStringAsFixed(0),
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
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ActionPlanPanel extends StatelessWidget {
  const _ActionPlanPanel({
    required this.tabController,
    required this.plan7Days,
    required this.plan30Days,
    required this.plan90Days,
    required this.onOpenArea,
  });

  final TabController tabController;

  final List<AtlasDiagnosticAction> plan7Days;

  final List<AtlasDiagnosticAction> plan30Days;

  final List<AtlasDiagnosticAction> plan90Days;

  final ValueChanged<AtlasFarmAnalysisArea> onOpenArea;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: const Color(0xFFF0F3F2),
            child: TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: '7 dias'),
                Tab(text: '30 dias'),
                Tab(text: '90 dias'),
              ],
            ),
          ),
          SizedBox(
            height: 520,
            child: TabBarView(
              controller: tabController,
              children: [
                _ActionList(actions: plan7Days, onOpenArea: onOpenArea),
                _ActionList(actions: plan30Days, onOpenArea: onOpenArea),
                _ActionList(actions: plan90Days, onOpenArea: onOpenArea),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions, required this.onOpenArea});

  final List<AtlasDiagnosticAction> actions;

  final ValueChanged<AtlasFarmAnalysisArea> onOpenArea;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Center(child: Text('Nenhuma ação foi definida.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 11);
      },
      itemBuilder: (context, index) {
        final action = actions[index];

        final color = diagnosticLevelColor(action.level);

        return Card(
          color: color.withValues(alpha: 0.04),
          child: InkWell(
            onTap: () {
              onOpenArea(action.area);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(17),
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
                    child: Center(
                      child: Text(
                        '${action.position}º',
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
                          action.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Resultado esperado: '
                          '${action.expectedResult}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${atlasFarmAreaLabel(action.area)} · '
                          '${atlasDiagnosticHorizonLabel(action.horizon)}',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          ),
        );
      },
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

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final AtlasDiagnosticLevel level;

  @override
  Widget build(BuildContext context) {
    final color = diagnosticLevelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasDiagnosticLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color diagnosticLevelColor(AtlasDiagnosticLevel level) {
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

IconData diagnosticAreaIcon(AtlasFarmAnalysisArea area) {
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

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/${date.year} '
      '$hour:$minute';
}

enum _DiagnosticExportType { executive, technical, producer }
