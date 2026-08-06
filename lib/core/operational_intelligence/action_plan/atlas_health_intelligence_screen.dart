import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_intelligence_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_models.dart';

class AtlasHealthIntelligenceScreen
    extends StatefulWidget {
  const AtlasHealthIntelligenceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasHealthIntelligenceScreen> createState() =>
      _AtlasHealthIntelligenceScreenState();
}

class _AtlasHealthIntelligenceScreenState
    extends State<AtlasHealthIntelligenceScreen> {
  final AtlasHealthIntelligenceService service =
      AtlasHealthIntelligenceService.instance;

  List<AtlasHealthProtocol> protocols =
      <AtlasHealthProtocol>[];
  List<AtlasMedication> medications =
      <AtlasMedication>[];
  List<AtlasHealthEvent> events =
      <AtlasHealthEvent>[];
  bool isLoading = false;

  AtlasHealthSummary get summary =>
      service.buildSummary(
        events: events,
        medications: medications,
        protocols: protocols,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    protocols = await service.loadProtocols(
      farmName: widget.actionController.farmName,
    );
    medications = await service.loadMedications(
      farmName: widget.actionController.farmName,
    );
    events = await service.loadEvents(
      farmName: widget.actionController.farmName,
    );
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editEvent({
    AtlasHealthEvent? event,
    AtlasHealthEventType? initialType,
  }) async {
    final animalId = TextEditingController(
      text: event?.animalId ?? '',
    );
    final animalName = TextEditingController(
      text: event?.animalName ?? '',
    );
    final lot = TextEditingController(
      text: event?.lotName ?? '',
    );
    final paddock = TextEditingController(
      text: event?.paddockName ?? '',
    );
    final diagnosis = TextEditingController(
      text: event?.diagnosis ?? '',
    );
    final symptoms = TextEditingController(
      text: event?.symptoms ?? '',
    );
    final dose = TextEditingController(
      text: event?.dose ?? '',
    );
    final professional = TextEditingController(
      text: event?.professional ?? '',
    );
    final outcome = TextEditingController(
      text: event?.outcome ?? '',
    );
    final cost = TextEditingController(
      text: event == null
          ? ''
          : event.cost.toStringAsFixed(2),
    );
    final notes = TextEditingController(
      text: event?.notes ?? '',
    );
    var type = event?.type ??
        initialType ??
        AtlasHealthEventType.examination;
    var occurredAt = event?.occurredAt ?? DateTime.now();
    String? medicationId = event?.medicationId;

    final result = await showDialog<AtlasHealthEvent>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                event == null
                    ? 'Novo evento sanitário'
                    : 'Editar evento sanitário',
              ),
              content: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row(
                        TextField(
                          controller: animalId,
                          decoration:
                              const InputDecoration(
                            labelText: 'ID do animal',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: animalName,
                          decoration:
                              const InputDecoration(
                            labelText: 'Nome do animal',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        TextField(
                          controller: lot,
                          decoration:
                              const InputDecoration(
                            labelText: 'Lote',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: paddock,
                          decoration:
                              const InputDecoration(
                            labelText: 'Piquete/local',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<
                          AtlasHealthEventType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasHealthEventType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  atlasHealthEventTypeLabel(
                                    value,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(
                              () => type = value,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy')
                              .format(occurredAt),
                        ),
                        trailing:
                            const Icon(Icons.calendar_month),
                        onTap: () async {
                          final selected =
                              await showDatePicker(
                            context: dialogContext,
                            initialDate: occurredAt,
                            firstDate: DateTime(2010),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setDialogState(
                              () => occurredAt = selected,
                            );
                          }
                        },
                      ),
                      _row(
                        TextField(
                          controller: diagnosis,
                          decoration:
                              const InputDecoration(
                            labelText: 'Diagnóstico',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: symptoms,
                          decoration:
                              const InputDecoration(
                            labelText: 'Sintomas',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: medicationId,
                        decoration: const InputDecoration(
                          labelText: 'Medicamento',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem medicamento'),
                          ),
                          ...medications.map(
                            (item) =>
                                DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(
                            () => medicationId = value,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _row(
                        TextField(
                          controller: dose,
                          decoration:
                              const InputDecoration(
                            labelText: 'Dose',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: professional,
                          decoration:
                              const InputDecoration(
                            labelText: 'Profissional',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        TextField(
                          controller: outcome,
                          decoration:
                              const InputDecoration(
                            labelText: 'Desfecho',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: cost,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText: 'Custo',
                            prefixText: 'R\$ ',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (animalId.text.trim().isEmpty &&
                        lot.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasHealthEvent(
                        id: event?.id ??
                            'health_event_'
                                '${now.microsecondsSinceEpoch}',
                        animalId: animalId.text.trim(),
                        animalName:
                            animalName.text.trim(),
                        lotName: lot.text.trim(),
                        paddockName:
                            paddock.text.trim(),
                        type: type,
                        occurredAt: occurredAt,
                        diagnosis:
                            diagnosis.text.trim(),
                        symptoms: symptoms.text.trim(),
                        medicationId: medicationId,
                        dose: dose.text.trim(),
                        professional:
                            professional.text.trim(),
                        outcome: outcome.text.trim(),
                        cost: _money(cost.text),
                        notes: notes.text.trim(),
                        farmName:
                            widget.actionController.farmName,
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

    for (final controller in [
      animalId,
      animalName,
      lot,
      paddock,
      diagnosis,
      symptoms,
      dose,
      professional,
      outcome,
      cost,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveEvent(result);
      await _load();
    }
  }

  Future<void> _editProtocol({
    AtlasHealthProtocol? protocol,
  }) async {
    final name = TextEditingController(
      text: protocol?.name ?? '',
    );
    final description = TextEditingController(
      text: protocol?.description ?? '',
    );
    final target = TextEditingController(
      text: protocol?.targetGroup ?? '',
    );
    final frequency = TextEditingController(
      text: protocol?.frequencyDays.toString() ?? '',
    );
    var dueAt = protocol?.nextDueAt ?? DateTime.now();
    var active = protocol?.active ?? true;

    final result = await showDialog<AtlasHealthProtocol>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                protocol == null
                    ? 'Novo protocolo sanitário'
                    : 'Editar protocolo sanitário',
              ),
              content: SizedBox(
                width: 540,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: target,
                      decoration: const InputDecoration(
                        labelText: 'Grupo-alvo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: frequency,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Frequência em dias',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    ListTile(
                      title:
                          const Text('Próximo vencimento'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy')
                            .format(dueAt),
                      ),
                      trailing:
                          const Icon(Icons.calendar_month),
                      onTap: () async {
                        final selected =
                            await showDatePicker(
                          context: dialogContext,
                          initialDate: dueAt,
                          firstDate: DateTime(2010),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(
                            () => dueAt = selected,
                          );
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      value: active,
                      onChanged: (value) {
                        setDialogState(
                          () => active = value,
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasHealthProtocol(
                        id: protocol?.id ??
                            'health_protocol_'
                                '${now.microsecondsSinceEpoch}',
                        name: name.text.trim(),
                        description:
                            description.text.trim(),
                        targetGroup:
                            target.text.trim(),
                        frequencyDays: int.tryParse(
                              frequency.text,
                            ) ??
                            0,
                        nextDueAt: dueAt,
                        active: active,
                        farmName:
                            widget.actionController.farmName,
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

    name.dispose();
    description.dispose();
    target.dispose();
    frequency.dispose();

    if (result != null) {
      await service.saveProtocol(result);
      await _load();
    }
  }

  Future<void> _editMedication({
    AtlasMedication? medication,
  }) async {
    final name = TextEditingController(
      text: medication?.name ?? '',
    );
    final ingredient = TextEditingController(
      text: medication?.activeIngredient ?? '',
    );
    final batch = TextEditingController(
      text: medication?.batch ?? '',
    );
    final quantity = TextEditingController(
      text: medication?.quantity.toString() ?? '',
    );
    final unit = TextEditingController(
      text: medication?.unit ?? '',
    );
    final withdrawal = TextEditingController(
      text: medication?.withdrawalDays.toString() ?? '',
    );
    var expirationAt =
        medication?.expirationAt ?? DateTime.now();

    final result = await showDialog<AtlasMedication>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            medication == null
                ? 'Novo medicamento'
                : 'Editar medicamento',
          ),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _row(
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: ingredient,
                    decoration: const InputDecoration(
                      labelText: 'Princípio ativo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  TextField(
                    controller: batch,
                    decoration: const InputDecoration(
                      labelText: 'Lote',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: quantity,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _row(
                  TextField(
                    controller: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: withdrawal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carência em dias',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Validade'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy')
                        .format(expirationAt),
                  ),
                  trailing:
                      const Icon(Icons.calendar_month),
                  onTap: () async {
                    final selected =
                        await showDatePicker(
                      context: dialogContext,
                      initialDate: expirationAt,
                      firstDate: DateTime(2010),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) {
                      expirationAt = selected;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  return;
                }
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasMedication(
                    id: medication?.id ??
                        'medication_'
                            '${now.microsecondsSinceEpoch}',
                    name: name.text.trim(),
                    activeIngredient:
                        ingredient.text.trim(),
                    batch: batch.text.trim(),
                    expirationAt: expirationAt,
                    quantity:
                        double.tryParse(quantity.text) ?? 0,
                    unit: unit.text.trim(),
                    withdrawalDays:
                        int.tryParse(withdrawal.text) ?? 0,
                    farmName:
                        widget.actionController.farmName,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    name.dispose();
    ingredient.dispose();
    batch.dispose();
    quantity.dispose();
    unit.dispose();
    withdrawal.dispose();

    if (result != null) {
      await service.saveMedication(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = service.buildAlerts(
      events: events,
      medications: medications,
      protocols: protocols,
    );
    final epidemiology =
        service.epidemiologyByDiagnosis(events);
    final healthMap =
        service.healthMapByLocation(events);

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência sanitária'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Calendário', icon: Icon(Icons.calendar_month)),
              Tab(text: 'Protocolos', icon: Icon(Icons.vaccines_outlined)),
              Tab(text: 'Medicamentos', icon: Icon(Icons.medication_outlined)),
              Tab(text: 'Histórico clínico', icon: Icon(Icons.medical_information_outlined)),
              Tab(text: 'Indicadores', icon: Icon(Icons.analytics_outlined)),
              Tab(text: 'Alertas', icon: Icon(Icons.warning_amber)),
              Tab(text: 'Epidemiologia', icon: Icon(Icons.query_stats)),
              Tab(text: 'Mapa sanitário', icon: Icon(Icons.map_outlined)),
            ],
          ),
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: () => _editEvent(),
          icon: const Icon(Icons.add),
          label: const Text('Novo registro'),
        ),
        body: isLoading &&
                events.isEmpty &&
                protocols.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _HealthCalendarTab(
                    protocols: protocols,
                    events: events,
                  ),
                  _HealthProtocolsTab(
                    protocols: protocols,
                    onAdd: () => _editProtocol(),
                    onEdit: (item) =>
                        _editProtocol(protocol: item),
                  ),
                  _MedicationsTab(
                    items: medications,
                    onAdd: () => _editMedication(),
                    onEdit: (item) =>
                        _editMedication(medication: item),
                  ),
                  _HealthEventsTab(
                    events: events,
                    onEdit: (item) =>
                        _editEvent(event: item),
                  ),
                  _HealthSummaryTab(summary: summary),
                  _HealthAlertsTab(alerts: alerts),
                  _EpidemiologyTab(items: epidemiology),
                  _HealthMapTab(items: healthMap),
                ],
              ),
      ),
    );
  }

  static Widget _row(Widget first, Widget second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  static double _money(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _HealthCalendarTab extends StatelessWidget {
  const _HealthCalendarTab({
    required this.protocols,
    required this.events,
  });

  final List<AtlasHealthProtocol> protocols;
  final List<AtlasHealthEvent> events;

  @override
  Widget build(BuildContext context) {
    final upcoming = protocols
        .where((item) => item.active)
        .toList()
      ..sort(
        (a, b) => a.nextDueAt.compareTo(b.nextDueAt),
      );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Próximos protocolos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ...upcoming.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(item.name),
              subtitle: Text(item.targetGroup),
              trailing: Text(
                DateFormat('dd/MM/yyyy')
                    .format(item.nextDueAt),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Registros recentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ...events.take(10).map(
          (item) => Card(
            child: ListTile(
              title: Text(
                atlasHealthEventTypeLabel(item.type),
              ),
              subtitle: Text(
                '${item.animalName.isEmpty ? item.animalId : item.animalName} • '
                '${DateFormat('dd/MM/yyyy').format(item.occurredAt)}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthProtocolsTab extends StatelessWidget {
  const _HealthProtocolsTab({
    required this.protocols,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasHealthProtocol> protocols;
  final VoidCallback onAdd;
  final ValueChanged<AtlasHealthProtocol> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo protocolo'),
            ),
          ),
        ),
        Expanded(
          child: protocols.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum protocolo sanitário.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: protocols.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = protocols[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(item),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.targetGroup} • a cada '
                          '${item.frequencyDays} dia(s)',
                        ),
                        trailing: Text(
                          DateFormat('dd/MM/yyyy')
                              .format(item.nextDueAt),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MedicationsTab extends StatelessWidget {
  const _MedicationsTab({
    required this.items,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasMedication> items;
  final VoidCallback onAdd;
  final ValueChanged<AtlasMedication> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo medicamento'),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum medicamento cadastrado.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(item),
                        leading:
                            const Icon(Icons.medication),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.activeIngredient} • lote ${item.batch} • '
                          '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                        ),
                        trailing: Text(
                          DateFormat('dd/MM/yyyy')
                              .format(item.expirationAt),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HealthEventsTab extends StatelessWidget {
  const _HealthEventsTab({
    required this.events,
    required this.onEdit,
  });

  final List<AtlasHealthEvent> events;
  final ValueChanged<AtlasHealthEvent> onEdit;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text('Nenhum histórico clínico.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = events[index];
        return Card(
          child: ListTile(
            onTap: () => onEdit(item),
            leading: const CircleAvatar(
              child: Icon(Icons.health_and_safety),
            ),
            title: Text(
              '${item.animalName.isEmpty ? item.animalId : item.animalName} — '
              '${atlasHealthEventTypeLabel(item.type)}',
            ),
            subtitle: Text(
              '${item.diagnosis.isEmpty ? 'Sem diagnóstico' : item.diagnosis} • '
              '${DateFormat('dd/MM/yyyy').format(item.occurredAt)}',
            ),
            trailing: Text(
              'R\$ ${item.cost.toStringAsFixed(2)}',
            ),
          ),
        );
      },
    );
  }
}

class _HealthSummaryTab extends StatelessWidget {
  const _HealthSummaryTab({
    required this.summary,
  });

  final AtlasHealthSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HealthMetric('Eventos', summary.totalEvents.toDouble(), ''),
            _HealthMetric('Vacinações', summary.vaccinations.toDouble(), ''),
            _HealthMetric('Tratamentos', summary.treatments.toDouble(), ''),
            _HealthMetric('Morbidade', summary.morbidityCases.toDouble(), ''),
            _HealthMetric('Mortalidade', summary.mortalityCases.toDouble(), ''),
            _HealthMetric('Taxa de morbidade', summary.morbidityRatePercent, '%'),
            _HealthMetric('Taxa de mortalidade', summary.mortalityRatePercent, '%'),
            _HealthMetric('Custo sanitário', summary.totalCost, 'R\$'),
          ],
        ),
      ],
    );
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric(
    this.title,
    this.value,
    this.unit,
  );

  final String title;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                '${unit == 'R\$' ? 'R\$ ' : ''}'
                '${value.toStringAsFixed(unit.isEmpty ? 0 : 1)}'
                '${unit == '%' ? '%' : ''}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthAlertsTab extends StatelessWidget {
  const _HealthAlertsTab({
    required this.alerts,
  });

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.warning_amber),
          title: Text(alerts[index]),
        ),
      ),
    );
  }
}

class _EpidemiologyTab extends StatelessWidget {
  const _EpidemiologyTab({
    required this.items,
  });

  final Map<String, int> items;

  @override
  Widget build(BuildContext context) {
    final ordered = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isEmpty) {
      return const Center(
        child: Text('Sem dados epidemiológicos.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ordered.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = ordered[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(item.key),
            trailing: Text(
              '${item.value} caso(s)',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HealthMapTab extends StatelessWidget {
  const _HealthMapTab({
    required this.items,
  });

  final Map<String, int> items;

  @override
  Widget build(BuildContext context) {
    final ordered = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isEmpty) {
      return const Center(
        child: Text('Sem locais sanitários mapeados.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ordered.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = ordered[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(item.key),
            subtitle: const Text(
              'Concentração de eventos sanitários.',
            ),
            trailing: Text(
              '${item.value}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}
