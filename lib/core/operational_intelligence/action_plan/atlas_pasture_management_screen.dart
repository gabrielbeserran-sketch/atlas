import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_service.dart';

class AtlasPastureManagementScreen extends StatefulWidget {
  const AtlasPastureManagementScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasPastureManagementScreen> createState() =>
      _AtlasPastureManagementScreenState();
}

class _AtlasPastureManagementScreenState
    extends State<AtlasPastureManagementScreen> {
  final service = AtlasPastureService.instance;
  List<AtlasPaddock> paddocks = [];
  List<AtlasGrazingRotation> rotations = [];
  List<AtlasPastureOperation> operations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    paddocks = await service.loadPaddocks(
      farmName: widget.actionController.farmName,
    );
    rotations = await service.loadRotations(
      farmName: widget.actionController.farmName,
    );
    operations = await service.loadOperations(
      farmName: widget.actionController.farmName,
    );
    if (mounted) setState(() => loading = false);
  }

  Future<void> _addPaddock() async {
    final name = TextEditingController();
    final area = TextEditingController();
    final forage = TextEditingController();
    final height = TextEditingController();
    final target = TextEditingController();
    final dryMatter = TextEditingController();
    final support = TextEditingController();
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    var status = AtlasPaddockStatus.available;
    var irrigated = false;

    final result = await showDialog<AtlasPaddock>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo piquete'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: area,
                    decoration: const InputDecoration(
                      labelText: 'Área em hectares',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: forage,
                    decoration: const InputDecoration(
                      labelText: 'Espécie forrageira',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AtlasPaddockStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Situação',
                      border: OutlineInputBorder(),
                    ),
                    items: AtlasPaddockStatus.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(atlasPaddockStatusLabel(e)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: height,
                    decoration: const InputDecoration(
                      labelText: 'Altura atual em cm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: target,
                    decoration: const InputDecoration(
                      labelText: 'Altura-alvo em cm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dryMatter,
                    decoration: const InputDecoration(
                      labelText: 'Matéria seca em kg/ha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: support,
                    decoration: const InputDecoration(
                      labelText: 'Capacidade de suporte UA/ha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latitude,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: longitude,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Irrigado'),
                    value: irrigated,
                    onChanged: (value) {
                      setDialogState(() => irrigated = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasPaddock(
                    id: 'paddock_${now.microsecondsSinceEpoch}',
                    name: name.text.trim(),
                    areaHectares: double.tryParse(area.text) ?? 0,
                    forageSpecies: forage.text.trim(),
                    status: status,
                    latitude: double.tryParse(latitude.text) ?? 0,
                    longitude: double.tryParse(longitude.text) ?? 0,
                    targetHeightCm: double.tryParse(target.text) ?? 0,
                    currentHeightCm: double.tryParse(height.text) ?? 0,
                    dryMatterKgHa: double.tryParse(dryMatter.text) ?? 0,
                    supportCapacityAuHa: double.tryParse(support.text) ?? 0,
                    irrigated: irrigated,
                    farmName: widget.actionController.farmName,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    for (final c in [
      name, area, forage, height, target, dryMatter,
      support, latitude, longitude
    ]) {
      c.dispose();
    }

    if (result != null) {
      await service.savePaddock(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalArea =
        paddocks.fold<double>(0, (sum, e) => sum + e.areaHectares);
    final totalDryMatter = paddocks.fold<double>(
      0,
      (sum, e) => sum + e.dryMatterKgHa * e.areaHectares,
    );
    final avgSupport = paddocks.isEmpty
        ? 0.0
        : paddocks
                .map((e) => e.supportCapacityAuHa)
                .reduce((a, b) => a + b) /
            paddocks.length;
    final alerts = service.alerts(paddocks, operations);

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão de pastagens'),
          actions: [
            IconButton(
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Piquetes'),
              Tab(text: 'Rotação'),
              Tab(text: 'Suporte'),
              Tab(text: 'Pasto'),
              Tab(text: 'Operações'),
              Tab(text: 'Planejamento'),
              Tab(text: 'Mapa GIS'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPaddock,
          icon: const Icon(Icons.add),
          label: const Text('Novo piquete'),
        ),
        body: loading && paddocks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _list(
                    paddocks.map((e) => ListTile(
                          title: Text(e.name),
                          subtitle: Text(
                            '${e.forageSpecies} • ${e.areaHectares.toStringAsFixed(2)} ha • '
                            '${atlasPaddockStatusLabel(e.status)}',
                          ),
                          trailing: Text('${e.currentHeightCm.toStringAsFixed(1)} cm'),
                        )),
                    'Nenhum piquete cadastrado.',
                  ),
                  _list(
                    rotations.map((e) => ListTile(
                          title: Text(e.lotName),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(e.entryAt)} a '
                            '${DateFormat('dd/MM/yyyy').format(e.exitAt)}',
                          ),
                          trailing: Text('${e.animalCount} animais'),
                        )),
                    'Nenhuma rotação registrada.',
                  ),
                  _metrics([
                    ('Área total', totalArea, 'ha'),
                    ('Capacidade média', avgSupport, 'UA/ha'),
                    ('Matéria seca total', totalDryMatter, 'kg'),
                  ]),
                  _list(
                    [
                      ...paddocks.map((e) => ListTile(
                            title: Text(e.name),
                            subtitle: Text(
                              'Altura ${e.currentHeightCm.toStringAsFixed(1)} cm • '
                              '${e.dryMatterKgHa.toStringAsFixed(0)} kg MS/ha',
                            ),
                          )),
                      ...alerts.map((e) => ListTile(
                            leading: const Icon(Icons.warning_amber),
                            title: Text(e),
                          )),
                    ],
                    'Sem indicadores.',
                  ),
                  _list(
                    operations.map((e) => ListTile(
                          title: Text(atlasPastureOperationTypeLabel(e.type)),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(e.scheduledAt)} • '
                            '${e.product}',
                          ),
                          trailing: Text(
                            e.isCompleted
                                ? 'Concluída'
                                : 'R\$ ${e.cost.toStringAsFixed(2)}',
                          ),
                        )),
                    'Nenhuma operação cadastrada.',
                  ),
                  _list(
                    [
                      ...operations.map((e) => ListTile(
                            leading: const Icon(Icons.event_note),
                            title: Text(
                              '${atlasPastureOperationTypeLabel(e.type)} — '
                              '${DateFormat('MM/yyyy').format(e.scheduledAt)}',
                            ),
                          )),
                      ListTile(
                        title: const Text('Custo anual programado'),
                        trailing: Text(
                          'R\$ ${operations.fold<double>(0, (s, e) => s + e.cost).toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                    '',
                  ),
                  _list(
                    paddocks
                        .where((e) => e.latitude != 0 || e.longitude != 0)
                        .map((e) => ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(e.name),
                              subtitle: Text(
                                'Lat ${e.latitude.toStringAsFixed(6)} • '
                                'Long ${e.longitude.toStringAsFixed(6)}',
                              ),
                              trailing: Text('${e.areaHectares.toStringAsFixed(2)} ha'),
                            )),
                    'Informe latitude e longitude nos piquetes.',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _list(Iterable<Widget> children, String empty) {
    final list = children.toList();
    if (list.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => Card(child: list[index]),
    );
  }

  Widget _metrics(List<(String, double, String)> values) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: values
          .map((e) => Card(
                child: ListTile(
                  title: Text(e.$1),
                  trailing: Text(
                    '${e.$2.toStringAsFixed(2)} ${e.$3}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
