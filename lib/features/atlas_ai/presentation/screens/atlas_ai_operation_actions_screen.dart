import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_operation_actions.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiOperationActionsScreen
    extends StatefulWidget {
  const AtlasAiOperationActionsScreen({
    required this.data,
    this.onOpenFarm,
    this.onOpenArea,
    super.key,
  });

  final AtlasAiOperationActions data;

  final ValueChanged<String>? onOpenFarm;

  final void Function(
    String farmName,
    AtlasFarmAnalysisArea area,
  )? onOpenArea;

  @override
  State<AtlasAiOperationActionsScreen>
      createState() {
    return _AtlasAiOperationActionsScreenState();
  }
}

class _AtlasAiOperationActionsScreenState
    extends State<AtlasAiOperationActionsScreen> {
  AtlasAiTrackedActionStatus? selectedStatus;
  String? selectedFarm;

  AtlasAiOperationActions get data =>
      widget.data;

  List<AtlasAiOperationPriorityAction>
      get filteredActions {
    return data.priorityActions.where((item) {
      final action = item.action;

      if (selectedStatus != null &&
          action.status != selectedStatus) {
        return false;
      }

      if (selectedFarm != null &&
          action.farmName != selectedFarm) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Ações da Consultoria',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1220,
            ),
            child: data.hasActions
                ? ListView(
                    padding:
                        const EdgeInsets.all(
                      22,
                    ),
                    children: [
                      _OperationActionsHero(
                        data: data,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      _FiltersBar(
                        farms: data.farms,
                        selectedFarm:
                            selectedFarm,
                        selectedStatus:
                            selectedStatus,
                        onFarmChanged: (value) {
                          setState(() {
                            selectedFarm = value;
                          });
                        },
                        onStatusChanged:
                            (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 26,
                      ),
                      const _SectionTitle(
                        title:
                            'Ranking das fazendas',
                        subtitle:
                            'Propriedades ordenadas pela necessidade de acompanhamento.',
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      _FarmProgressGrid(
                        farms: data.farms,
                        onOpenFarm:
                            widget.onOpenFarm,
                      ),
                      const SizedBox(
                        height: 26,
                      ),
                      const _SectionTitle(
                        title:
                            'Próximas ações',
                        subtitle:
                            'Ordem recomendada de execução para toda a operação.',
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      _PriorityActionList(
                        actions:
                            filteredActions,
                        onOpenFarm:
                            widget.onOpenFarm,
                        onOpenArea:
                            widget.onOpenArea,
                      ),
                      const SizedBox(
                        height: 26,
                      ),
                      const _SectionTitle(
                        title:
                            'Ações por área',
                        subtitle:
                            'Distribuição das recomendações entre os módulos.',
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      _AreaSummaryGrid(
                        areas:
                            data.areaSummaries,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                    ],
                  )
                : const _EmptyActionsView(),
          ),
        ),
      ),
    );
  }
}

class _OperationActionsHero
    extends StatelessWidget {
  const _OperationActionsHero({
    required this.data,
  });

  final AtlasAiOperationActions data;

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A43),
            Color(0xFF243B53),
            Color(0xFF334E68),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons
                        .assignment_turned_in_outlined,
                    color:
                        Color(0xFFC8A951),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Execução da consultoria',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.48,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroChip(
                    label: 'Total',
                    value: progress.total,
                  ),
                  _HeroChip(
                    label: 'Pendentes',
                    value: progress.pending,
                  ),
                  _HeroChip(
                    label: 'Em andamento',
                    value:
                        progress.inProgress,
                  ),
                  _HeroChip(
                    label: 'Atrasadas',
                    value: progress.overdue,
                  ),
                ],
              ),
            ],
          );

          final percentage = Container(
            width: 215,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progresso geral',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.completionPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color:
                        Color(0xFFC8A951),
                    fontSize: 39,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    minHeight: 10,
                    value:
                        progress.completionPercent /
                            100,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.12,
                    ),
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
                information,
                const SizedBox(height: 20),
                percentage,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: information,
              ),
              const SizedBox(width: 24),
              percentage,
            ],
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.farms,
    required this.selectedFarm,
    required this.selectedStatus,
    required this.onFarmChanged,
    required this.onStatusChanged,
  });

  final List<AtlasAiFarmActionSummary> farms;

  final String? selectedFarm;

  final AtlasAiTrackedActionStatus?
      selectedStatus;

  final ValueChanged<String?>
      onFarmChanged;

  final ValueChanged<
      AtlasAiTrackedActionStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<
                  String?>(
                initialValue: selectedFarm,
                decoration:
                    const InputDecoration(
                  labelText: 'Fazenda',
                  prefixIcon: Icon(
                    Icons.agriculture_outlined,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as fazendas',
                    ),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(
                      value: farm.farmName,
                      child: Text(
                        farm.farmName,
                      ),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<
                  AtlasAiTrackedActionStatus?>(
                initialValue:
                    selectedStatus,
                decoration:
                    const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(
                    Icons.filter_alt_outlined,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todos os status',
                    ),
                  ),
                  ...AtlasAiTrackedActionStatus
                      .values
                      .map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        atlasAiTrackedActionStatusLabel(
                          status,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged:
                    onStatusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmProgressGrid extends StatelessWidget {
  const _FarmProgressGrid({
    required this.farms,
    required this.onOpenFarm,
  });

  final List<AtlasAiFarmActionSummary> farms;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth >= 900
                ? (constraints.maxWidth -
                        14) /
                    2
                : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: farms.map((farm) {
            final color =
                farm.overdue > 0
                    ? const Color(
                        0xFFC62828,
                      )
                    : farm.completionPercent >=
                            80
                        ? const Color(
                            0xFF1B5E20,
                          )
                        : const Color(
                            0xFF1565C0,
                          );

            return SizedBox(
              width: width,
              child: Card(
                clipBehavior:
                    Clip.antiAlias,
                child: InkWell(
                  onTap: onOpenFarm == null
                      ? null
                      : () {
                          onOpenFarm!(
                            farm.farmName,
                          );
                        },
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      17,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .agriculture_outlined,
                              color: color,
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Text(
                                farm.farmName,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                            Text(
                              '${farm.completionPercent.toStringAsFixed(0)}%',
                              style:
                                  TextStyle(
                                color: color,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 11,
                        ),
                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          child:
                              LinearProgressIndicator(
                            minHeight: 8,
                            value: farm
                                    .completionPercent /
                                100,
                            backgroundColor:
                                color.withValues(
                              alpha: 0.10,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 11,
                        ),
                        Text(
                          '${farm.completed} concluídas · '
                          '${farm.inProgress} em andamento · '
                          '${farm.pending} pendentes · '
                          '${farm.overdue} atrasadas',
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        if (farm.nextActionTitle !=
                            null) ...[
                          const SizedBox(
                            height: 9,
                          ),
                          Text(
                            'Próxima: ${farm.nextActionTitle}',
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              color: color,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
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

class _PriorityActionList
    extends StatelessWidget {
  const _PriorityActionList({
    required this.actions,
    required this.onOpenFarm,
    required this.onOpenArea,
  });

  final List<AtlasAiOperationPriorityAction>
      actions;

  final ValueChanged<String>? onOpenFarm;

  final void Function(
    String farmName,
    AtlasFarmAnalysisArea area,
  )? onOpenArea;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhuma ação encontrada com os filtros atuais.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: actions.map((item) {
        final action = item.action;

        final color = action.isOverdue
            ? const Color(0xFFC62828)
            : action.status ==
                    AtlasAiTrackedActionStatus
                        .inProgress
                ? const Color(0xFF1565C0)
                : const Color(0xFFEF6C00);

        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(17),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        color.withValues(
                      alpha: 0.10,
                    ),
                    child: Text(
                      '${item.position}',
                      style: TextStyle(
                        color: color,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.farmName,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          action.title,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        Text(
                          action.description,
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          item.reason,
                          style: TextStyle(
                            color: color,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 9,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar:
                                  const Icon(
                                Icons
                                    .agriculture_outlined,
                                size: 16,
                              ),
                              label:
                                  const Text(
                                'Abrir fazenda',
                              ),
                              onPressed:
                                  onOpenFarm ==
                                          null
                                      ? null
                                      : () {
                                          onOpenFarm!(
                                            action
                                                .farmName,
                                          );
                                        },
                            ),
                            ActionChip(
                              avatar:
                                  const Icon(
                                Icons
                                    .open_in_new,
                                size: 16,
                              ),
                              label: Text(
                                atlasFarmAreaLabel(
                                  action.area,
                                ),
                              ),
                              onPressed:
                                  onOpenArea ==
                                          null
                                      ? null
                                      : () {
                                          onOpenArea!(
                                            action
                                                .farmName,
                                            action.area,
                                          );
                                        },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.priorityScore
                        .toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
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

class _AreaSummaryGrid
    extends StatelessWidget {
  const _AreaSummaryGrid({
    required this.areas,
  });

  final List<AtlasAiAreaActionSummary> areas;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: areas.map((area) {
        return SizedBox(
          width: 220,
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    area.label,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${area.total} ações',
                    style:
                        const TextStyle(
                      color:
                          Colors.black54,
                    ),
                  ),
                  Text(
                    '${area.open} abertas',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF1565C0),
                    ),
                  ),
                  Text(
                    '${area.completed} concluídas',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    '${area.overdue} atrasadas',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFFC62828),
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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

class _EmptyActionsView extends StatelessWidget {
  const _EmptyActionsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .assignment_turned_in_outlined,
              size: 58,
              color: Colors.black38,
            ),
            SizedBox(height: 14),
            Text(
              'Nenhuma ação acompanhada',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'As ações aparecerão aqui após serem geradas nas conversas do Atlas IA.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
