import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';
import 'package:projeto_atlas/features/executive_alerts/data/services/atlas_executive_alert_state_storage_service.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert_state.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/services/atlas_executive_alert_treatment_service.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasExecutiveAlertsScreen extends StatefulWidget {
  const AtlasExecutiveAlertsScreen({
    required this.data,
    this.onOpenFarm,
    this.onOpenArea,
    super.key,
  });

  final AtlasExecutiveAlertSummary data;

  final ValueChanged<String>? onOpenFarm;

  final void Function(String farmName, AtlasFarmAnalysisArea area)? onOpenArea;

  @override
  State<AtlasExecutiveAlertsScreen> createState() {
    return _AtlasExecutiveAlertsScreenState();
  }
}

class _AtlasExecutiveAlertsScreenState
    extends State<AtlasExecutiveAlertsScreen> {
  final AtlasExecutiveAlertStateStorageService stateStorage =
      const AtlasExecutiveAlertStateStorageService();

  final AtlasExecutiveAlertTreatmentService treatmentService =
      const AtlasExecutiveAlertTreatmentService();

  AtlasExecutiveAlertSeverity? selectedSeverity;

  AtlasExecutiveAlertTreatmentStatus? selectedTreatmentStatus;

  String? selectedFarm;

  bool isLoadingTreatment = true;

  List<AtlasExecutiveAlertTreatmentItem> treatmentItems = [];

  AtlasExecutiveAlertSummary get data => widget.data;

  @override
  void initState() {
    super.initState();
    _loadTreatmentStates();
  }

  Future<void> _loadTreatmentStates() async {
    final farmNames = data.farms.map((item) => item.farmName).toSet().toList();

    final stateLists = await Future.wait(
      farmNames.map((farmName) {
        return stateStorage.load(farmName: farmName);
      }),
    );

    final states = stateLists.expand((items) => items).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      treatmentItems = treatmentService.merge(
        alerts: data.alerts,
        states: states,
      );
      isLoadingTreatment = false;
    });

    await _persistAllStates();
  }

  Future<void> _persistAllStates() async {
    final grouped = <String, List<AtlasExecutiveAlertState>>{};

    for (final item in treatmentItems) {
      grouped.putIfAbsent(item.alert.farmName, () => []);

      grouped[item.alert.farmName]!.add(item.state);
    }

    await Future.wait(
      grouped.entries.map((entry) {
        return stateStorage.save(farmName: entry.key, states: entry.value);
      }),
    );
  }

  AtlasExecutiveAlertTreatmentProgress get treatmentProgress {
    return treatmentService.calculateProgress(treatmentItems);
  }

  List<AtlasExecutiveAlertTreatmentItem> get filteredTreatmentItems {
    return treatmentItems.where((item) {
      final alert = item.alert;

      if (selectedSeverity != null && alert.severity != selectedSeverity) {
        return false;
      }

      if (selectedFarm != null && alert.farmName != selectedFarm) {
        return false;
      }

      if (selectedTreatmentStatus != null &&
          item.state.status != selectedTreatmentStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _updateTreatmentItem(
    AtlasExecutiveAlertTreatmentItem item,
    AtlasExecutiveAlertState newState,
  ) async {
    final index = treatmentItems.indexWhere(
      (current) => current.alert.id == item.alert.id,
    );

    if (index < 0) {
      return;
    }

    setState(() {
      treatmentItems[index] = AtlasExecutiveAlertTreatmentItem(
        alert: item.alert,
        state: newState,
      );
    });

    await stateStorage.save(
      farmName: item.alert.farmName,
      states: treatmentItems
          .where((current) {
            return current.alert.farmName == item.alert.farmName;
          })
          .map((current) => current.state)
          .toList(),
    );
  }

  Future<void> _changeStatus(
    AtlasExecutiveAlertTreatmentItem item,
    AtlasExecutiveAlertTreatmentStatus status,
  ) async {
    final updated = treatmentService.updateStatus(
      state: item.state,
      status: status,
    );

    await _updateTreatmentItem(item, updated);
  }

  Future<void> _editTreatmentDetails(
    AtlasExecutiveAlertTreatmentItem item,
  ) async {
    final responsibleController = TextEditingController(
      text: item.state.responsibleName,
    );

    final notesController = TextEditingController(text: item.state.notes);

    DateTime? selectedDeadline = item.state.customDeadline;

    final result = await showDialog<_TreatmentEditResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tratamento do alerta'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: responsibleController,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: notesController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          hintText:
                              'Registre análise, providências ou impedimentos.',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 13),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Prazo do tratamento'),
                        subtitle: Text(
                          selectedDeadline == null
                              ? 'Sem prazo definido'
                              : _formatDate(selectedDeadline!),
                        ),
                        trailing: Wrap(
                          spacing: 5,
                          children: [
                            if (selectedDeadline != null)
                              IconButton(
                                tooltip: 'Remover prazo',
                                onPressed: () {
                                  setDialogState(() {
                                    selectedDeadline = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            IconButton(
                              tooltip: 'Escolher prazo',
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate:
                                      selectedDeadline ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 365),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDeadline = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.edit_calendar),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                    Navigator.of(dialogContext).pop(
                      _TreatmentEditResult(
                        responsibleName: responsibleController.text.trim(),
                        notes: notesController.text.trim(),
                        deadline: selectedDeadline,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    responsibleController.dispose();
    notesController.dispose();

    if (result == null) {
      return;
    }

    var updated = treatmentService.updateResponsible(
      state: item.state,
      responsibleName: result.responsibleName,
    );

    updated = treatmentService.updateNotes(state: updated, notes: result.notes);

    updated = treatmentService.updateDeadline(
      state: updated,
      deadline: result.deadline,
    );

    await _updateTreatmentItem(item, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Alertas Inteligentes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoadingTreatment
          ? const _TreatmentLoadingView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: data.hasAlerts
                      ? ListView(
                          padding: const EdgeInsets.all(22),
                          children: [
                            _AlertHero(
                              data: data,
                              treatmentProgress: treatmentProgress,
                            ),
                            const SizedBox(height: 24),
                            _AlertFilters(
                              farms: data.farms,
                              selectedFarm: selectedFarm,
                              selectedSeverity: selectedSeverity,
                              selectedTreatmentStatus: selectedTreatmentStatus,
                              onFarmChanged: (value) {
                                setState(() {
                                  selectedFarm = value;
                                });
                              },
                              onSeverityChanged: (value) {
                                setState(() {
                                  selectedSeverity = value;
                                });
                              },
                              onTreatmentStatusChanged: (value) {
                                setState(() {
                                  selectedTreatmentStatus = value;
                                });
                              },
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle(
                              title: 'Fazendas por criticidade',
                              subtitle:
                                  'Propriedades ordenadas pela necessidade de resposta.',
                            ),
                            const SizedBox(height: 13),
                            _FarmAlertGrid(
                              farms: data.farms,
                              onOpenFarm: widget.onOpenFarm,
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle(
                              title: 'Alertas prioritários',
                              subtitle:
                                  'Ordenados por severidade, impacto e prazo de resposta.',
                            ),
                            const SizedBox(height: 13),
                            _TreatmentAlertList(
                              items: filteredTreatmentItems,
                              onOpenFarm: widget.onOpenFarm,
                              onOpenArea: widget.onOpenArea,
                              onChangeStatus: _changeStatus,
                              onEditTreatment: _editTreatmentDetails,
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle(
                              title: 'Distribuição por área',
                              subtitle:
                                  'Módulos com maior concentração de alertas.',
                            ),
                            const SizedBox(height: 13),
                            _AreaAlertGrid(areas: data.areas),
                            const SizedBox(height: 32),
                          ],
                        )
                      : const _EmptyAlertsView(),
                ),
              ),
            ),
    );
  }
}

class _AlertHero extends StatelessWidget {
  const _AlertHero({required this.data, required this.treatmentProgress});

  final AtlasExecutiveAlertSummary data;

  final AtlasExecutiveAlertTreatmentProgress treatmentProgress;

  @override
  Widget build(BuildContext context) {
    final main = data.mainAlert;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E0A0A), Color(0xFF6A1515), Color(0xFF8E2424)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notification_important_outlined,
                    color: Color(0xFFFFCC80),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Central de Alertas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.48),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Total',
                    value: data.total,
                    color: Colors.white70,
                  ),
                  _HeroMetric(
                    label: 'Críticos',
                    value: data.critical,
                    color: const Color(0xFFEF5350),
                  ),
                  _HeroMetric(
                    label: 'Altos',
                    value: data.high,
                    color: const Color(0xFFFF8A65),
                  ),
                  _HeroMetric(
                    label: 'Atenção',
                    value: data.attention,
                    color: const Color(0xFFFFCC80),
                  ),
                  _HeroMetric(
                    label: 'Em tratamento',
                    value: treatmentProgress.inTreatment,
                    color: const Color(0xFF64B5F6),
                  ),
                  _HeroMetric(
                    label: 'Resolvidos',
                    value: treatmentProgress.resolved,
                    color: const Color(0xFF81C784),
                  ),
                ],
              ),
            ],
          );

          final priority = main == null
              ? const SizedBox.shrink()
              : Container(
                  width: 250,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alerta prioritário',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        main.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFCC80),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        main.farmName,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Responder em até '
                        '${main.responseDeadlineDays} '
                        '${main.responseDeadlineDays == 1 ? 'dia' : 'dias'}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                information,
                if (main != null) ...[const SizedBox(height: 20), priority],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              if (main != null) ...[const SizedBox(width: 24), priority],
            ],
          );
        },
      ),
    );
  }
}

class _AlertFilters extends StatelessWidget {
  const _AlertFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedSeverity,
    required this.selectedTreatmentStatus,
    required this.onFarmChanged,
    required this.onSeverityChanged,
    required this.onTreatmentStatusChanged,
  });

  final List<AtlasExecutiveFarmAlertSummary> farms;

  final String? selectedFarm;

  final AtlasExecutiveAlertSeverity? selectedSeverity;

  final AtlasExecutiveAlertTreatmentStatus? selectedTreatmentStatus;

  final ValueChanged<String?> onFarmChanged;

  final ValueChanged<AtlasExecutiveAlertSeverity?> onSeverityChanged;

  final ValueChanged<AtlasExecutiveAlertTreatmentStatus?>
  onTreatmentStatusChanged;

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
              child: DropdownButtonFormField<String?>(
                initialValue: selectedFarm,
                decoration: const InputDecoration(
                  labelText: 'Fazenda',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as fazendas'),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(
                      value: farm.farmName,
                      child: Text(farm.farmName),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<AtlasExecutiveAlertSeverity?>(
                initialValue: selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severidade',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as severidades'),
                  ),
                  ...AtlasExecutiveAlertSeverity.values.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(atlasExecutiveAlertSeverityLabel(severity)),
                    );
                  }),
                ],
                onChanged: onSeverityChanged,
              ),
            ),
            SizedBox(
              width: 250,
              child:
                  DropdownButtonFormField<AtlasExecutiveAlertTreatmentStatus?>(
                    initialValue: selectedTreatmentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Tratamento',
                      prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos os status'),
                      ),
                      ...AtlasExecutiveAlertTreatmentStatus.values.map((
                        status,
                      ) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            atlasExecutiveAlertTreatmentStatusLabel(status),
                          ),
                        );
                      }),
                    ],
                    onChanged: onTreatmentStatusChanged,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmAlertGrid extends StatelessWidget {
  const _FarmAlertGrid({required this.farms, required this.onOpenFarm});

  final List<AtlasExecutiveFarmAlertSummary> farms;

  final ValueChanged<String>? onOpenFarm;

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
          children: farms.map((farm) {
            final color = farm.critical > 0
                ? const Color(0xFFC62828)
                : farm.high > 0
                ? const Color(0xFFEF6C00)
                : const Color(0xFFF9A825);

            return SizedBox(
              width: width,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onOpenFarm == null
                      ? null
                      : () {
                          onOpenFarm!(farm.farmName);
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.agriculture_outlined, color: color),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                farm.farmName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              farm.priorityScore.toStringAsFixed(0),
                              style: TextStyle(
                                color: color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${farm.total} alertas · '
                          '${farm.critical} críticos · '
                          '${farm.high} altos · '
                          '${farm.attention} atenção',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        if (farm.mainAlertTitle != null) ...[
                          const SizedBox(height: 9),
                          Text(
                            farm.mainAlertTitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
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

class _TreatmentAlertList extends StatelessWidget {
  const _TreatmentAlertList({
    required this.items,
    required this.onOpenFarm,
    required this.onOpenArea,
    required this.onChangeStatus,
    required this.onEditTreatment,
  });

  final List<AtlasExecutiveAlertTreatmentItem> items;

  final ValueChanged<String>? onOpenFarm;

  final void Function(String farmName, AtlasFarmAnalysisArea area)? onOpenArea;

  final void Function(
    AtlasExecutiveAlertTreatmentItem item,
    AtlasExecutiveAlertTreatmentStatus status,
  )
  onChangeStatus;

  final ValueChanged<AtlasExecutiveAlertTreatmentItem> onEditTreatment;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhum alerta encontrado com os filtros atuais.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final alert = item.alert;
        final state = item.state;

        final color = item.isOverdue
            ? const Color(0xFFC62828)
            : _severityColor(alert.severity);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
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
                    child: Icon(
                      item.isOverdue
                          ? Icons.timer_off_outlined
                          : _severityIcon(alert.severity),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _TreatmentStatusBadge(
                              status: state.status,
                              overdue: item.isOverdue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          alert.farmName,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          alert.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.recommendation,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TreatmentInfoChip(
                              label: atlasExecutiveAlertSeverityLabel(
                                alert.severity,
                              ),
                              color: color,
                            ),
                            if (state.responsibleName.isNotEmpty)
                              _TreatmentInfoChip(
                                label: 'Responsável: ${state.responsibleName}',
                                color: const Color(0xFF1565C0),
                              ),
                            if (state.customDeadline != null)
                              _TreatmentInfoChip(
                                label:
                                    'Prazo: ${_formatDate(state.customDeadline!)}',
                                color: item.isOverdue
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF6A1B9A),
                              ),
                          ],
                        ),
                        if (state.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Observações: ${state.notes}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PopupMenuButton<AtlasExecutiveAlertTreatmentStatus>(
                              tooltip: 'Alterar status',
                              onSelected: (status) {
                                onChangeStatus(item, status);
                              },
                              itemBuilder: (context) {
                                return AtlasExecutiveAlertTreatmentStatus.values
                                    .map((status) {
                                      return PopupMenuItem(
                                        value: status,
                                        child: Text(
                                          atlasExecutiveAlertTreatmentStatusLabel(
                                            status,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList();
                              },
                              child: const ActionChip(
                                avatar: Icon(Icons.sync_alt_outlined, size: 16),
                                label: Text('Alterar status'),
                              ),
                            ),
                            ActionChip(
                              avatar: const Icon(
                                Icons.edit_note_outlined,
                                size: 16,
                              ),
                              label: const Text('Tratamento'),
                              onPressed: () {
                                onEditTreatment(item);
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(
                                Icons.agriculture_outlined,
                                size: 16,
                              ),
                              label: const Text('Abrir fazenda'),
                              onPressed: onOpenFarm == null
                                  ? null
                                  : () {
                                      onOpenFarm!(alert.farmName);
                                    },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.open_in_new, size: 16),
                              label: Text(atlasFarmAreaLabel(alert.area)),
                              onPressed: onOpenArea == null
                                  ? null
                                  : () {
                                      onOpenArea!(alert.farmName, alert.area);
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    alert.priorityScore.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 21,
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

class _TreatmentStatusBadge extends StatelessWidget {
  const _TreatmentStatusBadge({required this.status, required this.overdue});

  final AtlasExecutiveAlertTreatmentStatus status;

  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final color = overdue
        ? const Color(0xFFC62828)
        : _treatmentStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        overdue
            ? 'Tratamento atrasado'
            : atlasExecutiveAlertTreatmentStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TreatmentInfoChip extends StatelessWidget {
  const _TreatmentInfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AreaAlertGrid extends StatelessWidget {
  const _AreaAlertGrid({required this.areas});

  final List<AtlasExecutiveAreaAlertSummary> areas;

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
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${area.total} alertas',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    '${area.critical} críticos',
                    style: const TextStyle(color: Color(0xFFC62828)),
                  ),
                  Text(
                    '${area.high} altos',
                    style: const TextStyle(color: Color(0xFFEF6C00)),
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
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

class _EmptyAlertsView extends StatelessWidget {
  const _EmptyAlertsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 58,
              color: Colors.black38,
            ),
            SizedBox(height: 14),
            Text(
              'Nenhum alerta identificado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'A operação não possui alertas executivos nos dados atuais.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentLoadingView extends StatelessWidget {
  const _TreatmentLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              'Carregando tratamento dos alertas...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentEditResult {
  const _TreatmentEditResult({
    required this.responsibleName,
    required this.notes,
    required this.deadline,
  });

  final String responsibleName;
  final String notes;
  final DateTime? deadline;
}

Color _treatmentStatusColor(AtlasExecutiveAlertTreatmentStatus status) {
  switch (status) {
    case AtlasExecutiveAlertTreatmentStatus.newAlert:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveAlertTreatmentStatus.acknowledged:
      return const Color(0xFFF9A825);

    case AtlasExecutiveAlertTreatmentStatus.inTreatment:
      return const Color(0xFF1565C0);

    case AtlasExecutiveAlertTreatmentStatus.resolved:
      return const Color(0xFF1B5E20);

    case AtlasExecutiveAlertTreatmentStatus.discarded:
      return const Color(0xFF616161);
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

Color _severityColor(AtlasExecutiveAlertSeverity severity) {
  switch (severity) {
    case AtlasExecutiveAlertSeverity.informational:
      return const Color(0xFF1565C0);

    case AtlasExecutiveAlertSeverity.attention:
      return const Color(0xFFF9A825);

    case AtlasExecutiveAlertSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveAlertSeverity.critical:
      return const Color(0xFFC62828);
  }
}

IconData _severityIcon(AtlasExecutiveAlertSeverity severity) {
  switch (severity) {
    case AtlasExecutiveAlertSeverity.informational:
      return Icons.info_outline;

    case AtlasExecutiveAlertSeverity.attention:
      return Icons.notification_important_outlined;

    case AtlasExecutiveAlertSeverity.high:
      return Icons.warning_amber_outlined;

    case AtlasExecutiveAlertSeverity.critical:
      return Icons.error_outline;
  }
}
