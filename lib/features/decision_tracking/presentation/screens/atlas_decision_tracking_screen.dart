import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/decision_tracking/domain/models/atlas_decision_tracking_data.dart';
import 'package:projeto_atlas/features/decision_tracking/domain/services/atlas_decision_tracking_service.dart';

class AtlasDecisionTrackingScreen
    extends StatefulWidget {
  const AtlasDecisionTrackingScreen({
    required this.executions,
    this.onExecutionsChanged,
    this.onOpenFarm,
    super.key,
  });

  final List<AtlasDecisionExecution> executions;

  final ValueChanged<List<AtlasDecisionExecution>>?
      onExecutionsChanged;

  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasDecisionTrackingScreen> createState() {
    return _AtlasDecisionTrackingScreenState();
  }
}

class _AtlasDecisionTrackingScreenState
    extends State<AtlasDecisionTrackingScreen> {
  final AtlasDecisionTrackingService service =
      const AtlasDecisionTrackingService();

  late List<AtlasDecisionExecution> executions;

  AtlasDecisionExecutionStatus? selectedStatus;
  String? selectedFarm;

  @override
  void initState() {
    super.initState();
    executions = [...widget.executions];
  }

  AtlasDecisionTrackingData get summary {
    return service.buildSummary(
      executions: executions,
    );
  }

  List<String> get farms {
    final result = executions
        .map((item) => item.farmName)
        .toSet()
        .toList()
      ..sort();

    return result;
  }

  List<AtlasDecisionExecution>
      get filteredExecutions {
    return summary.executions.where((item) {
      if (selectedFarm != null &&
          item.farmName != selectedFarm) {
        return false;
      }

      if (selectedStatus != null &&
          item.status != selectedStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  void _updateExecution(
    AtlasDecisionExecution updated,
  ) {
    setState(() {
      executions = executions.map((item) {
        return item.id == updated.id
            ? updated
            : item;
      }).toList();
    });

    widget.onExecutionsChanged?.call(
      executions,
    );
  }

  Future<void> _registerResult(
    AtlasDecisionExecution execution,
  ) async {
    final controller = TextEditingController(
      text: execution.realizedFinancialImpact
          .toStringAsFixed(2),
    );

    final summaryController =
        TextEditingController(
      text: execution.resultSummary,
    );

    final result = await showDialog<
        _ExecutionResultInput>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Registrar resultado',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Impacto realizado (R\$)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller:
                      summaryController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Resumo do resultado',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = controller.text
                    .replaceAll('.', '')
                    .replaceAll(',', '.');

                final value =
                    double.tryParse(normalized);

                if (value == null) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _ExecutionResultInput(
                    value: value,
                    summary:
                        summaryController.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    summaryController.dispose();

    if (result == null || !mounted) {
      return;
    }

    final updated = service.registerResult(
      execution: execution,
      realizedFinancialImpact: result.value,
      resultSummary: result.summary,
    );

    _updateExecution(updated);
  }

  @override
  Widget build(BuildContext context) {
    final data = summary;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Acompanhamento de Decisões',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1240,
            ),
            child: data.hasData
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _TrackingHero(data: data),
                      const SizedBox(height: 22),
                      _TrackingFilters(
                        farms: farms,
                        selectedFarm:
                            selectedFarm,
                        selectedStatus:
                            selectedStatus,
                        onFarmChanged: (value) {
                          setState(() {
                            selectedFarm = value;
                          });
                        },
                        onStatusChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Decisões em acompanhamento',
                        subtitle:
                            'Execução, progresso, resultado e impacto financeiro.',
                      ),
                      const SizedBox(height: 13),
                      if (filteredExecutions.isEmpty)
                        const _EmptyFilteredView()
                      else
                        ...filteredExecutions.map(
                          (execution) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child:
                                  _ExecutionCard(
                                execution:
                                    execution,
                                onStart: () {
                                  _updateExecution(
                                    service.start(
                                      execution:
                                          execution,
                                    ),
                                  );
                                },
                                onToggleStep:
                                    (position) {
                                  _updateExecution(
                                    service.toggleStep(
                                      execution:
                                          execution,
                                      position:
                                          position,
                                    ),
                                  );
                                },
                                onRegisterResult:
                                    () {
                                  _registerResult(
                                    execution,
                                  );
                                },
                                onOpenFarm:
                                    widget.onOpenFarm,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyTrackingView(),
          ),
        ),
      ),
    );
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({
    required this.data,
  });

  final AtlasDecisionTrackingData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A43),
            Color(0xFF243B53),
            Color(0xFF486581),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.track_changes_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Execução das Decisões',
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
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Ativas',
                    value:
                        data.activeExecutions.length,
                  ),
                  _HeroMetric(
                    label: 'Concluídas',
                    value: data
                        .completedExecutions.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 235,
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
                Text(
                  '${data.executionRatePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFFB3E5FC),
                    fontSize: 38,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const Text(
                  'Taxa de execução',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'R\$ ${data.totalRealizedImpact.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFA5D6A7),
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const Text(
                  'Impacto realizado',
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
                information,
                const SizedBox(height: 20),
                side,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _TrackingFilters
    extends StatelessWidget {
  const _TrackingFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedStatus,
    required this.onFarmChanged,
    required this.onStatusChanged,
  });

  final List<String> farms;
  final String? selectedFarm;

  final AtlasDecisionExecutionStatus?
      selectedStatus;

  final ValueChanged<String?>
      onFarmChanged;

  final ValueChanged<
          AtlasDecisionExecutionStatus?>
      onStatusChanged;

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
              width: 260,
              child: DropdownButtonFormField<
                  String?>(
                initialValue: selectedFarm,
                decoration:
                    const InputDecoration(
                  labelText: 'Fazenda',
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
                      value: farm,
                      child: Text(farm),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<
                  AtlasDecisionExecutionStatus?>(
                initialValue: selectedStatus,
                decoration:
                    const InputDecoration(
                  labelText: 'Situação',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as situações',
                    ),
                  ),
                  ...AtlasDecisionExecutionStatus
                      .values
                      .map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        atlasDecisionExecutionStatusLabel(
                          status,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecutionCard extends StatelessWidget {
  const _ExecutionCard({
    required this.execution,
    required this.onStart,
    required this.onToggleStep,
    required this.onRegisterResult,
    required this.onOpenFarm,
  });

  final AtlasDecisionExecution execution;

  final VoidCallback onStart;
  final ValueChanged<int> onToggleStep;
  final VoidCallback onRegisterResult;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(execution.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.task_alt_outlined,
                  color: color,
                  size: 29,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        execution.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        execution.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  atlasDecisionExecutionStatusLabel(
                    execution.status,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              execution.description,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 9,
                value:
                    execution.progressPercent / 100,
                backgroundColor:
                    color.withValues(
                  alpha: 0.10,
                ),
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  color,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${execution.progressPercent.toStringAsFixed(0)}% concluído · '
              'prazo ${_date(execution.deadline)}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            ...execution.steps.map((step) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: step.completed,
                onChanged:
                    execution.status ==
                            AtlasDecisionExecutionStatus
                                .cancelled
                        ? null
                        : (_) {
                            onToggleStep(
                              step.position,
                            );
                          },
                title: Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: step.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  step.description,
                ),
                secondary: CircleAvatar(
                  radius: 14,
                  child: Text(
                    step.position.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (execution.status ==
                    AtlasDecisionExecutionStatus
                        .approved)
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(
                      Icons.play_arrow,
                    ),
                    label:
                        const Text('Iniciar'),
                  ),
                if (execution.status !=
                        AtlasDecisionExecutionStatus
                            .cancelled &&
                    execution.status !=
                        AtlasDecisionExecutionStatus
                            .completed)
                  OutlinedButton.icon(
                    onPressed:
                        onRegisterResult,
                    icon: const Icon(
                      Icons.payments_outlined,
                    ),
                    label: const Text(
                      'Registrar resultado',
                    ),
                  ),
                if (onOpenFarm != null)
                  ActionChip(
                    avatar: const Icon(
                      Icons.agriculture_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Abrir fazenda',
                    ),
                    onPressed: () {
                      onOpenFarm!(
                        execution.farmName,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Impacto esperado: '
              'R\$ ${execution.expectedFinancialImpact.toStringAsFixed(2)} · '
              'realizado: '
              'R\$ ${execution.realizedFinancialImpact.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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

class _EmptyFilteredView
    extends StatelessWidget {
  const _EmptyFilteredView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Nenhuma decisão encontrada com os filtros atuais.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTrackingView
    extends StatelessWidget {
  const _EmptyTrackingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma decisão aprovada para acompanhamento.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _ExecutionResultInput {
  const _ExecutionResultInput({
    required this.value,
    required this.summary,
  });

  final double value;
  final String summary;
}

Color _statusColor(
  AtlasDecisionExecutionStatus status,
) {
  switch (status) {
    case AtlasDecisionExecutionStatus.approved:
      return const Color(0xFF1565C0);

    case AtlasDecisionExecutionStatus.inProgress:
      return const Color(0xFFEF6C00);

    case AtlasDecisionExecutionStatus.delayed:
      return const Color(0xFFC62828);

    case AtlasDecisionExecutionStatus.completed:
      return const Color(0xFF1B5E20);

    case AtlasDecisionExecutionStatus.cancelled:
      return const Color(0xFF616161);
  }
}

String _date(
  DateTime date,
) {
  final day =
      date.day.toString().padLeft(2, '0');

  final month =
      date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
