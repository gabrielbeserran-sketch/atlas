import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_agriculture_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_agriculture_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';

class AtlasAgricultureScreen extends StatefulWidget {
  const AtlasAgricultureScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasAgricultureScreen> createState() =>
      _AtlasAgricultureScreenState();
}

class _AtlasAgricultureScreenState
    extends State<AtlasAgricultureScreen> {
  final service = AtlasAgricultureService.instance;

  List<AtlasCropField> fields = [];
  List<AtlasSoilSample> samples = [];
  List<AtlasAgriculturalOperation> operations = [];
  AtlasAgricultureExecutiveSnapshot? snapshot;
  List<String> recommendations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    fields = await service.loadFields(
      farmName: widget.actionController.farmName,
    );
    samples = await service.loadSoilSamples(
      farmName: widget.actionController.farmName,
    );
    operations = await service.loadOperations(
      farmName: widget.actionController.farmName,
    );
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    recommendations = await service.buildRecommendations(
      farmName: widget.actionController.farmName,
      snapshot: snapshot!,
    );
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _addField() async {
    final name = TextEditingController();
    final crop = TextEditingController();
    final variety = TextEditingController();
    final area = TextEditingController();
    final target = TextEditingController();
    final actual = TextEditingController();
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    final notes = TextEditingController();

    var status = AtlasCropStatus.planned;
    var integrated = false;
    DateTime? plantingAt;
    DateTime? harvestAt;

    final result = await showDialog<AtlasCropField>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova lavoura'),
              content: SizedBox(
                width: 680,
                height: 650,
                child: ListView(
                  children: [
                    _row(
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nome da área',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: crop,
                        decoration: const InputDecoration(
                          labelText: 'Cultura',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: variety,
                        decoration: const InputDecoration(
                          labelText: 'Variedade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      _number(area, 'Área (ha)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AtlasCropStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                        border: OutlineInputBorder(),
                      ),
                      items: AtlasCropStatus.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                atlasCropStatusLabel(value),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => status = value,
                          );
                        }
                      },
                    ),
                    _dateTile(
                      context: dialogContext,
                      title: 'Data de plantio',
                      date: plantingAt,
                      onChanged: (value) {
                        setDialogState(
                          () => plantingAt = value,
                        );
                      },
                    ),
                    _dateTile(
                      context: dialogContext,
                      title: 'Colheita prevista',
                      date: harvestAt,
                      onChanged: (value) {
                        setDialogState(
                          () => harvestAt = value,
                        );
                      },
                    ),
                    _row(
                      _number(
                        target,
                        'Produtividade-alvo (kg/ha)',
                      ),
                      _number(
                        actual,
                        'Produtividade realizada (kg/ha)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(latitude, 'Latitude'),
                      _number(longitude, 'Longitude'),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Integração lavoura-pecuária',
                      ),
                      value: integrated,
                      onChanged: (value) {
                        setDialogState(
                          () => integrated = value,
                        );
                      },
                    ),
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
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty ||
                        crop.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasCropField(
                        id: 'crop_field_'
                            '${now.microsecondsSinceEpoch}',
                        name: name.text.trim(),
                        crop: crop.text.trim(),
                        variety: variety.text.trim(),
                        areaHectares: _double(area.text),
                        status: status,
                        plantingAt: plantingAt,
                        expectedHarvestAt: harvestAt,
                        targetProductivityKgHa:
                            _double(target.text),
                        actualProductivityKgHa:
                            _double(actual.text),
                        latitude: _double(latitude.text),
                        longitude: _double(longitude.text),
                        integratedLivestock: integrated,
                        farmName:
                            widget.actionController.farmName,
                        notes: notes.text.trim(),
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
      name,
      crop,
      variety,
      area,
      target,
      actual,
      latitude,
      longitude,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveField(result);
      await _load();
    }
  }

  Future<void> _addSoilSample() async {
    if (fields.isEmpty) {
      return;
    }

    var fieldId = fields.first.id;
    final depth = TextEditingController(text: '20');
    final ph = TextEditingController();
    final organicMatter = TextEditingController();
    final phosphorus = TextEditingController();
    final potassium = TextEditingController();
    final saturation = TextEditingController();
    final clay = TextEditingController();
    final laboratory = TextEditingController();
    final notes = TextEditingController();
    var sampledAt = DateTime.now();

    final result = await showDialog<AtlasSoilSample>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova análise de solo'),
              content: SizedBox(
                width: 650,
                height: 620,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: fieldId,
                      decoration: const InputDecoration(
                        labelText: 'Área',
                        border: OutlineInputBorder(),
                      ),
                      items: fields
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => fieldId = value,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(depth, 'Profundidade (cm)'),
                      _number(ph, 'pH'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(
                        organicMatter,
                        'Matéria orgânica (%)',
                      ),
                      _number(
                        phosphorus,
                        'Fósforo (mg/dm³)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(
                        potassium,
                        'Potássio (mg/dm³)',
                      ),
                      _number(
                        saturation,
                        'Saturação por bases (%)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _number(clay, 'Argila (%)'),
                    _dateTile(
                      context: dialogContext,
                      title: 'Data da coleta',
                      date: sampledAt,
                      onChanged: (value) {
                        setDialogState(
                          () => sampledAt = value,
                        );
                      },
                    ),
                    TextField(
                      controller: laboratory,
                      decoration: const InputDecoration(
                        labelText: 'Laboratório',
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
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasSoilSample(
                        id: 'soil_sample_'
                            '${now.microsecondsSinceEpoch}',
                        fieldId: fieldId,
                        sampledAt: sampledAt,
                        depthCm: _double(depth.text),
                        ph: _double(ph.text),
                        organicMatterPercent:
                            _double(organicMatter.text),
                        phosphorusMgDm3:
                            _double(phosphorus.text),
                        potassiumMgDm3:
                            _double(potassium.text),
                        baseSaturationPercent:
                            _double(saturation.text),
                        clayPercent: _double(clay.text),
                        laboratory:
                            laboratory.text.trim(),
                        farmName:
                            widget.actionController.farmName,
                        notes: notes.text.trim(),
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
      depth,
      ph,
      organicMatter,
      phosphorus,
      potassium,
      saturation,
      clay,
      laboratory,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveSoilSample(result);
      await _load();
    }
  }

  Future<void> _addOperation() async {
    if (fields.isEmpty) {
      return;
    }

    var fieldId = fields.first.id;
    var type = AtlasAgriculturalOperationType.planting;
    var scheduledAt = DateTime.now();
    final product = TextEditingController();
    final dose = TextEditingController();
    final area = TextEditingController();
    final cost = TextEditingController();
    final responsible = TextEditingController();
    final notes = TextEditingController();

    final result =
        await showDialog<AtlasAgriculturalOperation>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova operação agrícola'),
              content: SizedBox(
                width: 620,
                height: 600,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: fieldId,
                      decoration: const InputDecoration(
                        labelText: 'Área',
                        border: OutlineInputBorder(),
                      ),
                      items: fields
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => fieldId = value,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<
                        AtlasAgriculturalOperationType>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Operação',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          AtlasAgriculturalOperationType.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    atlasAgriculturalOperationTypeLabel(
                                      value,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => type = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: product,
                        decoration: const InputDecoration(
                          labelText: 'Produto/insumo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: dose,
                        decoration: const InputDecoration(
                          labelText: 'Dose',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(area, 'Área (ha)'),
                      _number(cost, 'Custo'),
                    ),
                    _dateTile(
                      context: dialogContext,
                      title: 'Data programada',
                      date: scheduledAt,
                      onChanged: (value) {
                        setDialogState(
                          () => scheduledAt = value,
                        );
                      },
                    ),
                    TextField(
                      controller: responsible,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
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
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasAgriculturalOperation(
                        id: 'agriculture_operation_'
                            '${now.microsecondsSinceEpoch}',
                        fieldId: fieldId,
                        type: type,
                        scheduledAt: scheduledAt,
                        completedAt: null,
                        product: product.text.trim(),
                        dose: dose.text.trim(),
                        areaHectares: _double(area.text),
                        cost: _double(cost.text),
                        responsibleName:
                            responsible.text.trim(),
                        farmName:
                            widget.actionController.farmName,
                        notes: notes.text.trim(),
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
      product,
      dose,
      area,
      cost,
      responsible,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveOperation(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = snapshot;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agricultura integrada'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Painel'),
              Tab(text: 'Lavouras'),
              Tab(text: 'Solo'),
              Tab(text: 'Operações'),
              Tab(text: 'Cronograma'),
              Tab(text: 'Custos'),
              Tab(text: 'ILP'),
              Tab(text: 'IA agrícola'),
            ],
          ),
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: _addField,
          icon: const Icon(Icons.add),
          label: const Text('Nova lavoura'),
        ),
        body: loading && current == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _Dashboard(snapshot: current),
                  _Fields(
                    fields: fields,
                    onAdd: _addField,
                  ),
                  _Soil(
                    samples: samples,
                    fields: fields,
                    onAdd: _addSoilSample,
                  ),
                  _Operations(
                    operations: operations,
                    fields: fields,
                    onAdd: _addOperation,
                  ),
                  _Schedule(
                    operations: operations,
                    fields: fields,
                  ),
                  _Costs(snapshot: current),
                  _Integration(fields: fields),
                  _Intelligence(
                    recommendations: recommendations,
                  ),
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

  static Widget _number(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _dateTile({
    required BuildContext context,
    required String title,
    required DateTime? date,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        date == null
            ? 'Não informada'
            : DateFormat('dd/MM/yyyy').format(date),
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});

  final AtlasAgricultureExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados agrícolas.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricCard(
              'Lavouras',
              item.totalFields.toDouble(),
              '',
            ),
            _metricCard(
              'Área total',
              item.totalAreaHectares,
              'ha',
            ),
            _metricCard(
              'Área plantada',
              item.plantedAreaHectares,
              'ha',
            ),
            _metricCard(
              'Área ILP',
              item.integratedAreaHectares,
              'ha',
            ),
            _metricCard(
              'Produtividade-alvo',
              item.averageTargetProductivityKgHa,
              'kg/ha',
            ),
            _metricCard(
              'Produtividade atual',
              item.averageActualProductivityKgHa,
              'kg/ha',
            ),
            _metricCard(
              'Solo',
              item.averageSoilScore,
              '/100',
            ),
            _metricCard(
              'Score',
              item.agricultureScore,
              '/100',
            ),
          ],
        ),
      ],
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({
    required this.fields,
    required this.onAdd,
  });

  final List<AtlasCropField> fields;
  final VoidCallback onAdd;

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
              label: const Text('Nova lavoura'),
            ),
          ),
        ),
        Expanded(
          child: fields.isEmpty
              ? const Center(
                  child: Text('Nenhuma lavoura cadastrada.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: fields.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = fields[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${item.name} — ${item.crop}',
                        ),
                        subtitle: Text(
                          '${item.variety} • '
                          '${item.areaHectares.toStringAsFixed(2)} ha • '
                          '${atlasCropStatusLabel(item.status)}',
                        ),
                        trailing: Text(
                          '${item.productivityAchievementPercent.toStringAsFixed(1)}%',
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

class _Soil extends StatelessWidget {
  const _Soil({
    required this.samples,
    required this.fields,
    required this.onAdd,
  });

  final List<AtlasSoilSample> samples;
  final List<AtlasCropField> fields;
  final VoidCallback onAdd;

  String fieldName(String id) {
    for (final item in fields) {
      if (item.id == id) return item.name;
    }
    return 'Área';
  }

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
              label: const Text('Nova análise'),
            ),
          ),
        ),
        Expanded(
          child: samples.isEmpty
              ? const Center(
                  child: Text('Nenhuma análise de solo.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: samples.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = samples[index];
                    return Card(
                      child: ListTile(
                        title: Text(fieldName(item.fieldId)),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(item.sampledAt)} • '
                          'pH ${item.ph.toStringAsFixed(1)} • '
                          'V% ${item.baseSaturationPercent.toStringAsFixed(1)}',
                        ),
                        trailing: Text(
                          'Solo ${item.soilScore.toStringAsFixed(0)}/100',
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

class _Operations extends StatelessWidget {
  const _Operations({
    required this.operations,
    required this.fields,
    required this.onAdd,
  });

  final List<AtlasAgriculturalOperation> operations;
  final List<AtlasCropField> fields;
  final VoidCallback onAdd;

  String fieldName(String id) {
    for (final item in fields) {
      if (item.id == id) return item.name;
    }
    return 'Área';
  }

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
              label: const Text('Nova operação'),
            ),
          ),
        ),
        Expanded(
          child: operations.isEmpty
              ? const Center(
                  child: Text('Nenhuma operação agrícola.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: operations.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = operations[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          atlasAgriculturalOperationTypeLabel(
                            item.type,
                          ),
                        ),
                        subtitle: Text(
                          '${fieldName(item.fieldId)} • '
                          '${DateFormat('dd/MM/yyyy').format(item.scheduledAt)} • '
                          '${item.product}',
                        ),
                        trailing: Text(
                          'R\$ ${item.cost.toStringAsFixed(2)}',
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

class _Schedule extends StatelessWidget {
  const _Schedule({
    required this.operations,
    required this.fields,
  });

  final List<AtlasAgriculturalOperation> operations;
  final List<AtlasCropField> fields;

  String fieldName(String id) {
    for (final item in fields) {
      if (item.id == id) return item.name;
    }
    return 'Área';
  }

  @override
  Widget build(BuildContext context) {
    if (operations.isEmpty) {
      return const Center(child: Text('Cronograma vazio.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: operations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = operations[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.event_note),
            title: Text(
              atlasAgriculturalOperationTypeLabel(item.type),
            ),
            subtitle: Text(fieldName(item.fieldId)),
            trailing: Text(
              DateFormat('dd/MM/yyyy').format(item.scheduledAt),
              style: TextStyle(
                color: item.isOverdue
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Costs extends StatelessWidget {
  const _Costs({required this.snapshot});

  final AtlasAgricultureExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem custos.'));
    }
    final costPerHectare = item.totalAreaHectares <= 0
        ? 0.0
        : item.totalOperatingCost / item.totalAreaHectares;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line(
          'Custo operacional total',
          item.totalOperatingCost,
          'R\$',
        ),
        _line(
          'Custo por hectare',
          costPerHectare,
          'R\$/ha',
        ),
        _line(
          'Operações atrasadas',
          item.overdueOperations.toDouble(),
          '',
        ),
      ],
    );
  }
}

class _Integration extends StatelessWidget {
  const _Integration({required this.fields});

  final List<AtlasCropField> fields;

  @override
  Widget build(BuildContext context) {
    final integrated =
        fields.where((item) => item.integratedLivestock).toList();
    if (integrated.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma área marcada como integração lavoura-pecuária.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: integrated.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = integrated[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.sync_alt),
            title: Text(item.name),
            subtitle: Text(
              '${item.crop} • ${item.areaHectares.toStringAsFixed(2)} ha',
            ),
            trailing: const Text('ILP'),
          ),
        );
      },
    );
  }
}

class _Intelligence extends StatelessWidget {
  const _Intelligence({
    required this.recommendations,
  });

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(recommendations[index]),
        ),
      ),
    );
  }
}

Widget _metricCard(String title, double value, String unit) {
  return SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
              '${unit.isEmpty || unit == '/100' ? unit : ' $unit'}',
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

Widget _line(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${unit == 'R\$' ? 'R\$ ' : ''}'
        '${value.toStringAsFixed(2)}'
        '${unit == 'R\$/ha' ? ' R\$/ha' : ''}',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}
