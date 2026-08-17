import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_esg_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_esg_service.dart';

class AtlasEsgScreen extends StatefulWidget {
  const AtlasEsgScreen({required this.actionController, super.key});

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasEsgScreen> createState() => _AtlasEsgScreenState();
}

class _AtlasEsgScreenState extends State<AtlasEsgScreen> {
  final service = AtlasEsgService.instance;

  List<AtlasEsgRecord> records = [];
  AtlasEsgExecutiveSnapshot? snapshot;
  List<String> recommendations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    records = await service.loadRecords(
      farmName: widget.actionController.farmName,
    );
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    recommendations = await service.buildRecommendations(
      farmName: widget.actionController.farmName,
      snapshot: snapshot!,
    );
    if (mounted) setState(() => loading = false);
  }

  Future<void> _addRecord() async {
    var category = AtlasEsgCategory.carbon;
    var occurredAt = DateTime.now();
    final title = TextEditingController();
    final value = TextEditingController();
    final unit = TextEditingController();
    final financial = TextEditingController();
    final evidence = TextEditingController();
    final responsible = TextEditingController();
    final notes = TextEditingController();

    final result = await showDialog<AtlasEsgRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo registro ESG'),
              content: SizedBox(
                width: 620,
                height: 620,
                child: ListView(
                  children: [
                    DropdownButtonFormField<AtlasEsgCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: AtlasEsgCategory.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(atlasEsgCategoryLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (item) {
                        if (item != null) {
                          setDialogState(() => category = item);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(value, 'Valor'),
                      TextField(
                        controller: unit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade',
                          hintText: 'tCO2e, m³, kWh, ha...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _number(financial, 'Valor financeiro associado'),
                    _dateTile(
                      context: dialogContext,
                      title: 'Data',
                      date: occurredAt,
                      onChanged: (item) {
                        setDialogState(() => occurredAt = item);
                      },
                    ),
                    TextField(
                      controller: evidence,
                      decoration: const InputDecoration(
                        labelText: 'Evidência ou documento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) return;
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasEsgRecord(
                        id:
                            'esg_record_'
                            '${now.microsecondsSinceEpoch}',
                        category: category,
                        occurredAt: occurredAt,
                        title: title.text.trim(),
                        value: _double(value.text),
                        unit: unit.text.trim(),
                        financialValue: _double(financial.text),
                        evidence: evidence.text.trim(),
                        responsibleName: responsible.text.trim(),
                        farmName: widget.actionController.farmName,
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
      title,
      value,
      unit,
      financial,
      evidence,
      responsible,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveRecord(result);
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
          title: const Text('ESG e sustentabilidade'),
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
              Tab(text: 'Carbono'),
              Tab(text: 'Água'),
              Tab(text: 'Energia'),
              Tab(text: 'Áreas ambientais'),
              Tab(text: 'Resíduos e social'),
              Tab(text: 'Relatório ESG'),
              Tab(text: 'IA sustentável'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addRecord,
          icon: const Icon(Icons.add),
          label: const Text('Novo registro'),
        ),
        body: loading && current == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _Dashboard(snapshot: current),
                  _Carbon(snapshot: current),
                  _CategoryRecords(
                    category: AtlasEsgCategory.water,
                    records: records,
                  ),
                  _Energy(snapshot: current),
                  _Environmental(snapshot: current),
                  _WasteSocial(snapshot: current, records: records),
                  _Report(snapshot: current, records: records),
                  _Recommendations(recommendations: recommendations),
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

  static Widget _number(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _dateTile({
    required BuildContext context,
    required String title,
    required DateTime date,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});

  final AtlasEsgExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados ESG.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card(
              'Emissões líquidas',
              item.carbonInventory.netEmissionsTco2e,
              'tCO2e',
            ),
            _card('Água', item.waterConsumptionM3, 'm³'),
            _card('Energia', item.energyConsumptionKwh, 'kWh'),
            _card('Energia renovável', item.renewableEnergyPercent, '%'),
            _card('Área preservada', item.preservedAreaHectares, 'ha'),
            _card('Área recuperada', item.recoveredAreaHectares, 'ha'),
            _card('Resíduos recuperados', item.wasteRecoveredPercent, '%'),
            _card('Score ESG', item.esgScore, '/100'),
          ],
        ),
      ],
    );
  }
}

class _Carbon extends StatelessWidget {
  const _Carbon({required this.snapshot});

  final AtlasEsgExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot?.carbonInventory;
    if (item == null) {
      return const Center(child: Text('Sem inventário.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Metano entérico', item.entericMethaneTco2e, 'tCO2e'),
        _line('Dejetos', item.manureTco2e, 'tCO2e'),
        _line('Combustíveis', item.fuelTco2e, 'tCO2e'),
        _line('Eletricidade', item.electricityTco2e, 'tCO2e'),
        _line('Solo e fertilizantes', item.soilAndFertilizerTco2e, 'tCO2e'),
        _line('Sequestro', item.sequestrationTco2e, 'tCO2e'),
        const Divider(),
        _line('Emissões brutas', item.grossEmissionsTco2e, 'tCO2e'),
        _line('Emissões líquidas', item.netEmissionsTco2e, 'tCO2e'),
      ],
    );
  }
}

class _CategoryRecords extends StatelessWidget {
  const _CategoryRecords({required this.category, required this.records});

  final AtlasEsgCategory category;
  final List<AtlasEsgRecord> records;

  @override
  Widget build(BuildContext context) {
    final values = records.where((item) => item.category == category).toList();
    if (values.isEmpty) {
      return Center(
        child: Text(
          'Nenhum registro de ${atlasEsgCategoryLabel(category).toLowerCase()}.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = values[index];
        return Card(
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(item.occurredAt)} • '
              '${item.responsibleName}',
            ),
            trailing: Text('${item.value.toStringAsFixed(2)} ${item.unit}'),
          ),
        );
      },
    );
  }
}

class _Energy extends StatelessWidget {
  const _Energy({required this.snapshot});

  final AtlasEsgExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Consumo total', item.energyConsumptionKwh, 'kWh'),
        _line('Participação renovável', item.renewableEnergyPercent, '%'),
      ],
    );
  }
}

class _Environmental extends StatelessWidget {
  const _Environmental({required this.snapshot});

  final AtlasEsgExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Área preservada', item.preservedAreaHectares, 'ha'),
        _line('Área recuperada', item.recoveredAreaHectares, 'ha'),
      ],
    );
  }
}

class _WasteSocial extends StatelessWidget {
  const _WasteSocial({required this.snapshot, required this.records});

  final AtlasEsgExecutiveSnapshot? snapshot;
  final List<AtlasEsgRecord> records;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados.'));
    }
    final social = records
        .where((record) => record.category == AtlasEsgCategory.social)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Resíduos recuperados', item.wasteRecoveredPercent, '%'),
        _line('Score social', item.socialScore, '/100'),
        ...social.map(
          (record) => Card(
            child: ListTile(
              title: Text(record.title),
              subtitle: Text(record.evidence),
            ),
          ),
        ),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.snapshot, required this.records});

  final AtlasEsgExecutiveSnapshot? snapshot;
  final List<AtlasEsgRecord> records;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem relatório.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Resumo executivo ESG',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _line('Score ESG', item.esgScore, '/100'),
        _line('Score social', item.socialScore, '/100'),
        _line('Score de governança', item.governanceScore, '/100'),
        _line(
          'Emissões líquidas',
          item.carbonInventory.netEmissionsTco2e,
          'tCO2e',
        ),
        const SizedBox(height: 12),
        Text('${records.length} evidência(s) registrada(s).'),
      ],
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({required this.recommendations});

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

Widget _card(String title, double value, String unit) {
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
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
        '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
        '${unit.isEmpty || unit == '/100' ? unit : ' $unit'}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
