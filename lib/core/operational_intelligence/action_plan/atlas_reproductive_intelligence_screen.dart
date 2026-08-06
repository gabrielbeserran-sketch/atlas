import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_service.dart';

class AtlasReproductiveIntelligenceScreen
    extends StatefulWidget {
  const AtlasReproductiveIntelligenceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasReproductiveIntelligenceScreen> createState() =>
      _AtlasReproductiveIntelligenceScreenState();
}

class _AtlasReproductiveIntelligenceScreenState
    extends State<AtlasReproductiveIntelligenceScreen> {
  final AtlasReproductiveService service =
      AtlasReproductiveService.instance;

  List<AtlasReproductiveProtocol> protocols =
      <AtlasReproductiveProtocol>[];
  List<AtlasReproductiveEvent> events =
      <AtlasReproductiveEvent>[];
  List<AtlasGeneticAnimal> genetics =
      <AtlasGeneticAnimal>[];
  bool isLoading = false;

  AtlasReproductiveSummary get summary =>
      service.buildSummary(events);

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
    events = await service.loadEvents(
      farmName: widget.actionController.farmName,
    );
    genetics = await service.loadGenetics(
      farmName: widget.actionController.farmName,
    );
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editEvent({
    AtlasReproductiveEvent? event,
    AtlasReproductiveEventType? initialType,
  }) async {
    final animalId = TextEditingController(
      text: event?.animalId ?? '',
    );
    final animalName = TextEditingController(
      text: event?.animalName ?? '',
    );
    final sire = TextEditingController(
      text: event?.sireId ?? '',
    );
    final semen = TextEditingController(
      text: event?.semenBatch ?? '',
    );
    final professional = TextEditingController(
      text: event?.professional ?? '',
    );
    final resultText = TextEditingController(
      text: event?.result ?? '',
    );
    final notes = TextEditingController(
      text: event?.notes ?? '',
    );
    var type = event?.type ??
        initialType ??
        AtlasReproductiveEventType.heat;
    var occurredAt = event?.occurredAt ?? DateTime.now();
    String? protocolId = event?.protocolId;

    final result =
        await showDialog<AtlasReproductiveEvent>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                event == null
                    ? 'Novo evento reprodutivo'
                    : 'Editar evento reprodutivo',
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: animalId,
                              decoration:
                                  const InputDecoration(
                                labelText: 'ID do animal',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: animalName,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Nome do animal',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<
                          AtlasReproductiveEventType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de evento',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasReproductiveEventType
                            .values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  atlasReproductiveEventTypeLabel(
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
                      DropdownButtonFormField<String?>(
                        initialValue: protocolId,
                        decoration: const InputDecoration(
                          labelText: 'Protocolo',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem protocolo'),
                          ),
                          ...protocols.map(
                            (protocol) =>
                                DropdownMenuItem<String?>(
                              value: protocol.id,
                              child: Text(protocol.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(
                            () => protocolId = value,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data do evento'),
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sire,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Touro/doador',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: semen,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Lote de sêmen',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: professional,
                        decoration: const InputDecoration(
                          labelText: 'Profissional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: resultText,
                        decoration: const InputDecoration(
                          labelText: 'Resultado',
                          hintText:
                              'Ex.: positivo, negativo, normal.',
                          border: OutlineInputBorder(),
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
                    if (animalId.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasReproductiveEvent(
                        id: event?.id ??
                            'reproductive_event_'
                                '${now.microsecondsSinceEpoch}',
                        animalId: animalId.text.trim(),
                        animalName:
                            animalName.text.trim(),
                        type: type,
                        occurredAt: occurredAt,
                        protocolId: protocolId,
                        sireId: sire.text.trim(),
                        semenBatch: semen.text.trim(),
                        professional:
                            professional.text.trim(),
                        result: resultText.text.trim(),
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

    animalId.dispose();
    animalName.dispose();
    sire.dispose();
    semen.dispose();
    professional.dispose();
    resultText.dispose();
    notes.dispose();

    if (result != null) {
      await service.saveEvent(result);
      await _load();
    }
  }

  Future<void> _editProtocol({
    AtlasReproductiveProtocol? protocol,
  }) async {
    final name = TextEditingController(
      text: protocol?.name ?? '',
    );
    final description = TextEditingController(
      text: protocol?.description ?? '',
    );
    final steps = TextEditingController(
      text: protocol?.steps.join('\n') ?? '',
    );
    var startAt = protocol?.startAt ?? DateTime.now();
    var endAt = protocol?.endAt ??
        DateTime.now().add(const Duration(days: 10));
    var active = protocol?.active ?? true;

    final result =
        await showDialog<AtlasReproductiveProtocol>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                protocol == null
                    ? 'Novo protocolo'
                    : 'Editar protocolo',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
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
                        controller: steps,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText:
                              'Etapas — uma por linha',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: const Text('Período'),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(startAt)} '
                          'a ${DateFormat('dd/MM/yyyy').format(endAt)}',
                        ),
                        trailing:
                            const Icon(Icons.date_range),
                        onTap: () async {
                          final first =
                              await showDatePicker(
                            context: dialogContext,
                            initialDate: startAt,
                            firstDate: DateTime(2010),
                            lastDate: DateTime(2100),
                          );
                          if (first == null ||
                              !dialogContext.mounted) {
                            return;
                          }
                          final last =
                              await showDatePicker(
                            context: dialogContext,
                            initialDate:
                                endAt.isBefore(first)
                                    ? first
                                    : endAt,
                            firstDate: first,
                            lastDate: DateTime(2100),
                          );
                          if (last != null) {
                            setDialogState(() {
                              startAt = first;
                              endAt = last;
                            });
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
                      AtlasReproductiveProtocol(
                        id: protocol?.id ??
                            'reproductive_protocol_'
                                '${now.microsecondsSinceEpoch}',
                        name: name.text.trim(),
                        description:
                            description.text.trim(),
                        startAt: startAt,
                        endAt: endAt,
                        farmName:
                            widget.actionController.farmName,
                        active: active,
                        steps: steps.text
                            .split('\n')
                            .map((value) => value.trim())
                            .where((value) => value.isNotEmpty)
                            .toList(),
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
    steps.dispose();

    if (result != null) {
      await service.saveProtocol(result);
      await _load();
    }
  }

  Future<void> _editGenetic({
    AtlasGeneticAnimal? animal,
  }) async {
    final id = TextEditingController(
      text: animal?.id ?? '',
    );
    final name = TextEditingController(
      text: animal?.name ?? '',
    );
    final sex = TextEditingController(
      text: animal?.sex ?? '',
    );
    final breed = TextEditingController(
      text: animal?.breed ?? '',
    );
    final sire = TextEditingController(
      text: animal?.sireId ?? '',
    );
    final dam = TextEditingController(
      text: animal?.damId ?? '',
    );
    final genetic = TextEditingController(
      text: animal?.geneticIndex.toString() ?? '',
    );
    final fertility = TextEditingController(
      text: animal?.fertilityScore.toString() ?? '',
    );
    final calving = TextEditingController(
      text: animal?.calvingEaseScore.toString() ?? '',
    );
    final maternal = TextEditingController(
      text: animal?.maternalScore.toString() ?? '',
    );

    final result = await showDialog<AtlasGeneticAnimal>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            animal == null
                ? 'Novo registro genético'
                : 'Editar registro genético',
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _twoFields(
                    TextField(
                      controller: id,
                      decoration: const InputDecoration(
                        labelText: 'ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _twoFields(
                    TextField(
                      controller: sex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: breed,
                      decoration: const InputDecoration(
                        labelText: 'Raça',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _twoFields(
                    TextField(
                      controller: sire,
                      decoration: const InputDecoration(
                        labelText: 'Pai',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: dam,
                      decoration: const InputDecoration(
                        labelText: 'Mãe',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _twoFields(
                    _scoreField(genetic, 'Índice genético'),
                    _scoreField(fertility, 'Fertilidade'),
                  ),
                  const SizedBox(height: 10),
                  _twoFields(
                    _scoreField(
                      calving,
                      'Facilidade de parto',
                    ),
                    _scoreField(maternal, 'Maternal'),
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
                if (id.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  AtlasGeneticAnimal(
                    id: id.text.trim(),
                    name: name.text.trim(),
                    sex: sex.text.trim(),
                    breed: breed.text.trim(),
                    sireId: sire.text.trim(),
                    damId: dam.text.trim(),
                    geneticIndex:
                        double.tryParse(genetic.text) ?? 0,
                    fertilityScore:
                        double.tryParse(fertility.text) ?? 0,
                    calvingEaseScore:
                        double.tryParse(calving.text) ?? 0,
                    maternalScore:
                        double.tryParse(maternal.text) ?? 0,
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

    for (final controller in [
      id,
      name,
      sex,
      breed,
      sire,
      dam,
      genetic,
      fertility,
      calving,
      maternal,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveGeneticAnimal(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = service.buildAlerts(events);
    final projected =
        service.projectedCalvingDates(events);

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência reprodutiva'),
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
              Tab(text: 'Agenda', icon: Icon(Icons.calendar_month)),
              Tab(text: 'IATF', icon: Icon(Icons.biotech_outlined)),
              Tab(text: 'Protocolos', icon: Icon(Icons.list_alt)),
              Tab(text: 'Gestação', icon: Icon(Icons.medical_information_outlined)),
              Tab(text: 'Indicadores', icon: Icon(Icons.analytics_outlined)),
              Tab(text: 'Genética', icon: Icon(Icons.hub_outlined)),
              Tab(text: 'Alertas', icon: Icon(Icons.notifications_active_outlined)),
            ],
          ),
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: () => _editEvent(),
          icon: const Icon(Icons.add),
          label: const Text('Novo evento'),
        ),
        body: isLoading &&
                events.isEmpty &&
                protocols.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _EventsTab(
                    events: events,
                    onEdit: (event) =>
                        _editEvent(event: event),
                  ),
                  _EventsTab(
                    events: events
                        .where(
                          (event) =>
                              event.type ==
                              AtlasReproductiveEventType
                                  .fixedTimeAi,
                        )
                        .toList(),
                    onEdit: (event) =>
                        _editEvent(event: event),
                    emptyMessage:
                        'Nenhum procedimento de IATF registrado.',
                  ),
                  _ProtocolsTab(
                    protocols: protocols,
                    onAdd: () => _editProtocol(),
                    onEdit: (protocol) =>
                        _editProtocol(protocol: protocol),
                  ),
                  _PregnancyTab(
                    events: events,
                    projected: projected,
                  ),
                  _IndicatorsTab(summary: summary),
                  _GeneticsTab(
                    items: genetics,
                    onAdd: () => _editGenetic(),
                    onEdit: (animal) =>
                        _editGenetic(animal: animal),
                  ),
                  _AlertsTab(alerts: alerts),
                ],
              ),
      ),
    );
  }

  static Widget _twoFields(
    Widget first,
    Widget second,
  ) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  static Widget _scoreField(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.events,
    required this.onEdit,
    this.emptyMessage = 'Nenhum evento registrado.',
  });

  final List<AtlasReproductiveEvent> events;
  final ValueChanged<AtlasReproductiveEvent> onEdit;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            onTap: () => onEdit(event),
            leading: const CircleAvatar(
              child: Icon(Icons.event_note),
            ),
            title: Text(
              '${event.animalName.isEmpty ? event.animalId : event.animalName} — '
              '${atlasReproductiveEventTypeLabel(event.type)}',
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(event.occurredAt)}'
              '${event.result.isEmpty ? '' : ' • ${event.result}'}',
            ),
          ),
        );
      },
    );
  }
}

class _ProtocolsTab extends StatelessWidget {
  const _ProtocolsTab({
    required this.protocols,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasReproductiveProtocol> protocols;
  final VoidCallback onAdd;
  final ValueChanged<AtlasReproductiveProtocol> onEdit;

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
                    'Nenhum protocolo cadastrado.',
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
                    final protocol = protocols[index];
                    return Card(
                      child: ExpansionTile(
                        onExpansionChanged: (expanded) {
                          if (!expanded) {
                            return;
                          }
                        },
                        title: Text(protocol.name),
                        subtitle: Text(
                          '${DateFormat('dd/MM').format(protocol.startAt)} '
                          'a ${DateFormat('dd/MM/yyyy').format(protocol.endAt)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Editar',
                          onPressed: () =>
                              onEdit(protocol),
                          icon: const Icon(Icons.edit),
                        ),
                        children: protocol.steps
                            .map(
                              (step) => ListTile(
                                leading:
                                    const Icon(Icons.check),
                                title: Text(step),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PregnancyTab extends StatelessWidget {
  const _PregnancyTab({
    required this.events,
    required this.projected,
  });

  final List<AtlasReproductiveEvent> events;
  final List<DateTime> projected;

  @override
  Widget build(BuildContext context) {
    final diagnoses = events
        .where(
          (event) =>
              event.type ==
              AtlasReproductiveEventType
                  .pregnancyDiagnosis,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Diagnósticos de gestação',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        ...diagnoses.map(
          (event) => Card(
            child: ListTile(
              title: Text(
                event.animalName.isEmpty
                    ? event.animalId
                    : event.animalName,
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(event.occurredAt)} • '
                '${event.result}',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Previsão de partos',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        ...projected.map(
          (date) => Card(
            child: ListTile(
              leading: const Icon(Icons.child_friendly),
              title: Text(
                DateFormat('dd/MM/yyyy').format(date),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IndicatorsTab extends StatelessWidget {
  const _IndicatorsTab({
    required this.summary,
  });

  final AtlasReproductiveSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Metric('Serviços', summary.totalServices.toDouble(), ''),
            _Metric('Diagnósticos', summary.pregnancyDiagnoses.toDouble(), ''),
            _Metric('Prenhezes', summary.positivePregnancies.toDouble(), ''),
            _Metric('Partos', summary.calvings.toDouble(), ''),
            _Metric('Abortos', summary.abortions.toDouble(), ''),
            _Metric('Taxa de prenhez', summary.pregnancyRatePercent, '%'),
            _Metric('Taxa de concepção', summary.conceptionRatePercent, '%'),
            _Metric('Taxa de repetição', summary.repeatRatePercent, '%'),
          ],
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.unit);

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
                '${value.toStringAsFixed(unit.isEmpty ? 0 : 1)}$unit',
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

class _GeneticsTab extends StatelessWidget {
  const _GeneticsTab({
    required this.items,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasGeneticAnimal> items;
  final VoidCallback onAdd;
  final ValueChanged<AtlasGeneticAnimal> onEdit;

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
              label: const Text('Novo registro'),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum registro genético.',
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
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          '${item.name.isEmpty ? item.id : item.name} — ${item.sex}',
                        ),
                        subtitle: Text(
                          '${item.breed} • fertilidade '
                          '${item.fertilityScore.toStringAsFixed(1)}',
                        ),
                        trailing: Text(
                          item.rankingScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
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

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({
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
          leading: const Icon(
            Icons.notifications_active_outlined,
          ),
          title: Text(alerts[index]),
        ),
      ),
    );
  }
}
