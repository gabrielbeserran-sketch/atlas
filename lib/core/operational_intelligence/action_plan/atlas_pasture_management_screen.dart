import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_area_overview.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_basis_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_scope.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_sync.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_grazing_animals_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

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
  final grazingBasisService = AtlasPastureGrazingBasisService();
  final grazingSync = AtlasPastureGrazingSync();
  final grazingAnimalsService = AtlasGrazingAnimalsService();
  AtlasGrazingSelection? grazingSelection;
  bool syncingBasis = false;
  String syncMessage =
      'A base é salva neste dispositivo. Sincronize quando houver conexão.';
  List<Map<String, dynamic>> grazingConflicts = [];
  List<Map<String, dynamic>> grazingReviews = [];
  List<AtlasPaddock> paddocks = [];
  List<AtlasGrazingRotation> rotations = [];
  List<AtlasPastureOperation> operations = [];
  AtlasRemoteFarm? authorizedFarm;
  AtlasPastureGrazingBasis? grazingBasis;
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
    authorizedFarm = await _resolveAuthorizedFarm();
    final farm = authorizedFarm;
    grazingBasis = farm == null
        ? null
        : await grazingBasisService.loadLatest(
            tenantId: farm.tenantId,
            companyId: farm.companyId,
            farmId: farm.id,
          );
    grazingConflicts = [];
    grazingReviews = [];
    grazingSelection = null;
    if (farm != null) {
      try {
        grazingConflicts = await grazingSync.conflicts(
          farm.tenantId,
          farm.companyId,
          farm.id,
        );
        grazingReviews = await grazingBasisService.reviewedHistory(
          tenantId: farm.tenantId,
          companyId: farm.companyId,
          farmId: farm.id,
        );
        if (grazingBasis != null) {
          grazingSelection = await grazingAnimalsService.loadCurrent(
            grazingBasis!,
          );
        }
      } catch (_) {
        syncMessage =
            'Não foi possível ler a revisão de conflitos; dados preservados.';
      }
    } else {
      grazingConflicts = [];
      grazingReviews = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<AtlasRemoteFarm?> _resolveAuthorizedFarm() async {
    final store = AtlasEnterpriseRemoteAuthStore.instance;
    final session = await store.loadSession();
    final farmId = await store.loadActiveFarm();
    final portfolio = await store.loadFarmPortfolio();
    return AtlasPastureGrazingScope.resolve(
      session: session,
      activeFarmId: farmId,
      portfolio: portfolio,
      expectedFarmName: widget.actionController.farmName,
    );
  }

  Future<void> _syncGrazingBasis() async {
    final farm = authorizedFarm;
    if (farm == null || syncingBasis) return;
    setState(() => syncingBasis = true);
    final result = await grazingSync.synchronize(
      tenantId: farm.tenantId,
      companyId: farm.companyId,
      farmId: farm.id,
      isAuthorized: () async {
        final current = await _resolveAuthorizedFarm();
        return current?.id == farm.id &&
            current?.companyId == farm.companyId &&
            current?.tenantId == farm.tenantId;
      },
    );
    if (!mounted) return;
    setState(() {
      syncingBasis = false;
      syncMessage = result.message;
    });
    await _load();
  }

  Future<void> _selectGrazingAnimals() async {
    final basis = grazingBasis;
    final farm = authorizedFarm;
    if (basis == null || farm == null || syncingBasis) return;
    Future<bool> authorized() async {
      final currentFarm = await _resolveAuthorizedFarm();
      final currentBasis = await grazingBasisService.loadLatest(
        tenantId: basis.tenantId,
        companyId: basis.companyId,
        farmId: basis.farmId,
      );
      return currentFarm?.id == basis.farmId &&
          currentFarm?.companyId == basis.companyId &&
          currentFarm?.tenantId == basis.tenantId &&
          currentBasis?.hasSameData(basis) == true;
    }

    AtlasGrazingRoster? roster;
    try {
      roster = await grazingAnimalsService.loadRoster(basis);
    } catch (_) {
      /* não reutiliza cache ilegível */
    }
    if (!mounted) return;
    final selected = {...?grazingSelection?.animalIds};
    var search = '';
    var busy = false;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final candidates =
              roster?.animals
                  .where(
                    (e) =>
                        e.active &&
                        '${e.tag} ${e.name}'.toLowerCase().contains(
                          search.toLowerCase(),
                        ),
                  )
                  .toList() ??
              <AtlasGrazingCandidate>[];
          return AlertDialog(
            title: const Text('Animais realmente em pastejo'),
            content: SizedBox(
              width: 560,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fazenda: ${farm.name} • ${selected.length}/${basis.grazingAnimals} selecionados',
                  ),
                  const Text(
                    'Selecione por brinco/identificação. Este vínculo é local; ainda não calcula UA/ha.',
                  ),
                  Text(
                    roster == null
                        ? 'Consulte a carteira uma vez com internet para selecionar offline.'
                        : 'Carteira de ${DateFormat('dd/MM/yyyy HH:mm').format(roster!.recordedAt.toLocal())}'
                              '${roster!.isCurrent(DateTime.now()) ? '' : ' — atualize para salvar.'}',
                  ),
                  TextField(
                    onChanged: (value) => update(() => search = value),
                    decoration: const InputDecoration(
                      labelText: 'Buscar por brinco ou nome',
                    ),
                  ),
                  if (busy) const LinearProgressIndicator(),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: candidates.length,
                      itemBuilder: (_, index) {
                        final animal = candidates[index];
                        return CheckboxListTile(
                          value: selected.contains(animal.id),
                          title: Text('${animal.tag} • ${animal.name}'),
                          onChanged: busy
                              ? null
                              : (value) => update(() {
                                  if (value == true) {
                                    selected.add(animal.id);
                                  } else {
                                    selected.remove(animal.id);
                                  }
                                }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        update(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          final refreshed = await grazingAnimalsService
                              .refreshRoster(basis, authorized);
                          if (!dialogContext.mounted) return;
                          update(() {
                            roster = refreshed;
                            final eligible = refreshed.animals
                                .where((e) => e.active)
                                .map((e) => e.id)
                                .toSet();
                            selected.removeWhere(
                              (id) => !eligible.contains(id),
                            );
                          });
                        } catch (_) {
                          if (dialogContext.mounted) {
                            update(
                              () => error =
                                  'Consulta não concluída. Carteira local preservada.',
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) update(() => busy = false);
                        }
                      },
                child: const Text('Atualizar carteira'),
              ),
              FilledButton(
                onPressed:
                    busy ||
                        selected.length != basis.grazingAnimals ||
                        roster?.isCurrent(DateTime.now()) != true
                    ? null
                    : () async {
                        update(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await grazingAnimalsService.saveSelection(
                            basis,
                            selected.toList(),
                            authorized,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            update(() {
                              busy = false;
                              error =
                                  'Confira a base, a quantidade e os animais ativos antes de salvar.';
                            });
                          }
                        }
                      },
                child: const Text('Vincular animais'),
              ),
            ],
          );
        },
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _reviewGrazingConflict(Map<String, dynamic> item) async {
    if (syncingBasis) return;
    final farm = authorizedFarm;
    final session = await AtlasEnterpriseRemoteAuthStore.instance.loadSession();
    if (farm == null || session == null || !mounted) return;
    final remote = AtlasPastureGrazingBasis.fromMap(
      Map<String, dynamic>.from(item['remote'] as Map),
    );
    final local = AtlasPastureGrazingBasis.fromMap(
      Map<String, dynamic>.from(item['local'] as Map),
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar conflito de pastejo'),
        content: Text(
          'Fazenda: ${farm.name}\n'
          'Neste dispositivo: ${local.grazingAnimals} animais / ${local.effectiveAreaHa} ha\n'
          'Servidor: ${remote.grazingAnimals} animais / ${remote.effectiveAreaHa} ha\n\n'
          'Ao aceitar, o indicador local usará a versão confirmada pelo servidor. '
          'As duas versões, o autor e a data da revisão serão arquivados. '
          'Nenhum dado será alterado no servidor. Se os dados do servidor estiverem errados, '
          'cancele e registre uma nova base após conferir a operação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar versão do servidor'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => syncingBasis = true);
    try {
      await grazingSync.acceptRemoteConflict(
        expectedRemote: remote,
        reviewedBy: session.userId,
        isAuthorized: () async {
          final currentFarm = await _resolveAuthorizedFarm();
          final currentSession = await AtlasEnterpriseRemoteAuthStore.instance
              .loadSession();
          return currentSession?.userId == session.userId &&
              currentFarm?.id == farm.id &&
              currentFarm?.companyId == remote.companyId &&
              currentFarm?.tenantId == remote.tenantId;
        },
      );
      syncMessage =
          'Versão do servidor aceita. As duas versões foram arquivadas neste dispositivo.';
    } catch (_) {
      syncMessage =
          'Revisão não concluída. Nenhuma versão foi descartada; atualize a tela.';
    } finally {
      if (mounted) {
        setState(() => syncingBasis = false);
        await _load();
      }
    }
  }

  Future<void> _editGrazingBasis() async {
    final farm = authorizedFarm;
    if (farm == null) return;
    final area = TextEditingController(
      text: grazingBasis?.effectiveAreaHa.toString().replaceAll('.', ',') ?? '',
    );
    final animals = TextEditingController(
      text: grazingBasis?.grazingAnimals.toString() ?? '',
    );
    var confirmed = false;
    String? error;
    final result = await showDialog<AtlasPastureGrazingBasis>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Base efetiva de pastejo'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fazenda: ${farm.name}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Informe apenas hectares únicos disponíveis para pastejo '
                    'e animais que estão realmente nessa área. Não some '
                    'piquetes sobrepostos nem conte todo o rebanho automaticamente.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: area,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Área efetiva de pasto (ha)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: animals,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Animais atualmente em pastejo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: confirmed,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Confirmei que a área informada é única, sem sobreposição.',
                    ),
                    onChanged: (value) =>
                        setDialogState(() => confirmed = value == true),
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final candidate = AtlasPastureGrazingBasis(
                  tenantId: farm.tenantId,
                  companyId: farm.companyId,
                  farmId: farm.id,
                  effectiveAreaHa:
                      double.tryParse(area.text.trim().replaceAll(',', '.')) ??
                      0,
                  grazingAnimals: int.tryParse(animals.text.trim()) ?? 0,
                  uniqueAreaConfirmed: confirmed,
                  recordedAt: DateTime.now(),
                );
                try {
                  candidate.validate(farmTotalAreaHa: farm.area);
                  Navigator.pop(dialogContext, candidate);
                } on ArgumentError catch (failure) {
                  setDialogState(() => error = failure.message.toString());
                }
              },
              child: const Text('Salvar base'),
            ),
          ],
        ),
      ),
    );
    area.dispose();
    animals.dispose();
    if (result == null) return;
    try {
      await grazingBasisService.save(result, farmTotalAreaHa: farm.area);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar a base de pastejo neste dispositivo.',
          ),
        ),
      );
    }
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
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(atlasPaddockStatusLabel(e)),
                          ),
                        )
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
      name,
      area,
      forage,
      height,
      target,
      dryMatter,
      support,
      latitude,
      longitude,
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
    final areaOverview = AtlasPastureAreaOverview.fromPaddocks(paddocks);
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
                    paddocks.map(
                      (e) => ListTile(
                        title: Text(e.name),
                        subtitle: Text(
                          '${e.forageSpecies} • ${e.areaHectares.toStringAsFixed(2)} ha • '
                          '${atlasPaddockStatusLabel(e.status)}',
                        ),
                        trailing: Text(
                          '${e.currentHeightCm.toStringAsFixed(1)} cm',
                        ),
                      ),
                    ),
                    'Nenhum piquete cadastrado.',
                  ),
                  _list(
                    rotations.map(
                      (e) => ListTile(
                        title: Text(e.lotName),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(e.entryAt)} a '
                          '${DateFormat('dd/MM/yyyy').format(e.exitAt)}',
                        ),
                        trailing: Text('${e.animalCount} animais'),
                      ),
                    ),
                    'Nenhuma rotação registrada.',
                  ),
                  _metrics(
                    [
                      (
                        'Soma nominal dos piquetes',
                        areaOverview.nominalAreaHa,
                        'ha',
                      ),
                      (
                        'Suporte médio ponderado pela área',
                        areaOverview.weightedSupportAuHa,
                        'UA/ha',
                      ),
                      (
                        'Matéria seca registrada',
                        areaOverview.totalDryMatterKg,
                        'kg',
                      ),
                    ],
                    invalidPaddockCount: areaOverview.invalidPaddockCount,
                    grazingBasis: grazingBasis,
                    canEditGrazingBasis: authorizedFarm != null,
                  ),
                  _list([
                    ...paddocks.map(
                      (e) => ListTile(
                        title: Text(e.name),
                        subtitle: Text(
                          'Altura ${e.currentHeightCm.toStringAsFixed(1)} cm • '
                          '${e.dryMatterKgHa.toStringAsFixed(0)} kg MS/ha',
                        ),
                      ),
                    ),
                    ...alerts.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.warning_amber),
                        title: Text(e),
                      ),
                    ),
                  ], 'Sem indicadores.'),
                  _list(
                    operations.map(
                      (e) => ListTile(
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
                      ),
                    ),
                    'Nenhuma operação cadastrada.',
                  ),
                  _list([
                    ...operations.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text(
                          '${atlasPastureOperationTypeLabel(e.type)} — '
                          '${DateFormat('MM/yyyy').format(e.scheduledAt)}',
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Custo anual programado'),
                      trailing: Text(
                        'R\$ ${operations.fold<double>(0, (s, e) => s + e.cost).toStringAsFixed(2)}',
                      ),
                    ),
                  ], ''),
                  _list(
                    paddocks
                        .where((e) => e.latitude != 0 || e.longitude != 0)
                        .map(
                          (e) => ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(e.name),
                            subtitle: Text(
                              'Lat ${e.latitude.toStringAsFixed(6)} • '
                              'Long ${e.longitude.toStringAsFixed(6)}',
                            ),
                            trailing: Text(
                              '${e.areaHectares.toStringAsFixed(2)} ha',
                            ),
                          ),
                        ),
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

  Widget _metrics(
    List<(String, double?, String)> values, {
    required int invalidPaddockCount,
    required AtlasPastureGrazingBasis? grazingBasis,
    required bool canEditGrazingBasis,
  }) {
    final registeredArea = authorizedFarm?.area;
    final exceedsRegisteredArea =
        grazingBasis != null &&
        registeredArea != null &&
        registeredArea > 0 &&
        grazingBasis.effectiveAreaHa > registeredArea;
    final currentBasis =
        grazingBasis?.isCurrentAt(DateTime.now()) == true &&
        !exceedsRegisteredArea;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'A soma dos piquetes não confirma a área efetiva de pastagem: '
              'pode haver sobreposição ou área fora de uso. A lotação por hectare '
              'de pasto só será calculada com uma base validada.'
              '${invalidPaddockCount > 0 ? ' $invalidPaddockCount piquete(s) com área inválida ficaram fora da soma.' : ''}',
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lotação da área efetiva de pasto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (currentBasis)
                  Text(
                    '${grazingBasis!.animalsPerHectare.toStringAsFixed(2)} animais/ha',
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                else
                  const Text('Sem índice atual'),
                const SizedBox(height: 6),
                Text(
                  grazingBasis == null
                      ? 'Informe a área única e os animais em pastejo para calcular.'
                      : '${grazingBasis.grazingAnimals} animais / '
                            '${grazingBasis.effectiveAreaHa.toStringAsFixed(2)} ha '
                            'confirmados em '
                            '${DateFormat('dd/MM/yyyy').format(grazingBasis.recordedAt)}.'
                            '${exceedsRegisteredArea
                                ? ' A área efetiva supera a área total cadastrada; revise a base.'
                                : currentBasis
                                ? ''
                                : ' Atualize o número de animais: a confirmação tem mais de sete dias.'}',
                ),
                const SizedBox(height: 4),
                const Text(
                  'Base informada pelo produtor; não equivale a UA/ha nem à lotação da área total da fazenda.',
                ),
                if (canEditGrazingBasis) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: syncingBasis ? null : _editGrazingBasis,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      grazingBasis == null
                          ? 'Informar base efetiva'
                          : 'Atualizar base efetiva',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: syncingBasis ? null : _syncGrazingBasis,
                    icon: const Icon(Icons.sync),
                    label: Text(
                      syncingBasis
                          ? 'Sincronizando base…'
                          : 'Sincronizar base de pastejo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(syncMessage),
                  if (grazingBasis != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      grazingSelection == null
                          ? 'Animais desta base ainda não identificados.'
                          : '${grazingSelection!.animalIds.length} animais vinculados a esta confirmação. '
                                'Seleção de ${DateFormat('dd/MM/yyyy').format(grazingSelection!.recordedAt.toLocal())}; vínculo local.',
                    ),
                    OutlinedButton.icon(
                      onPressed: syncingBasis ? null : _selectGrazingAnimals,
                      icon: const Icon(Icons.checklist),
                      label: const Text('Identificar animais em pastejo'),
                    ),
                  ],
                  if (grazingConflicts.isNotEmpty)
                    ExpansionTile(
                      title: Text(
                        '${grazingConflicts.length} conflito(s) preservado(s)',
                      ),
                      subtitle: const Text(
                        'Nenhuma versão foi substituída. Revise antes de reenviar.',
                      ),
                      children: grazingConflicts.map((item) {
                        final local = item['local'] as Map?;
                        final remote = item['remote'] as Map?;
                        return ListTile(
                          onTap: syncingBasis
                              ? null
                              : () => _reviewGrazingConflict(item),
                          trailing: const Icon(Icons.fact_check_outlined),
                          title: Text(
                            'Operação ${local?['operationId'] ?? ''}',
                          ),
                          subtitle: Text(
                            'Neste dispositivo: ${local?['grazingAnimals']} animais / ${local?['effectiveAreaHa']} ha\n'
                            'Servidor: ${remote?['grazingAnimals']} animais / ${remote?['effectiveAreaHa']} ha',
                          ),
                        );
                      }).toList(),
                    ),
                  if (grazingReviews.isNotEmpty)
                    ExpansionTile(
                      title: Text(
                        '${grazingReviews.length} revisão(ões) arquivada(s)',
                      ),
                      subtitle: const Text(
                        'Auditoria local: versões originais preservadas.',
                      ),
                      children: grazingReviews.reversed.map((item) {
                        final local = item['local'] as Map;
                        final remote = item['remote'] as Map;
                        return ListTile(
                          title: Text(
                            'Versão do servidor aceita • ${item['reviewedAt']}',
                          ),
                          subtitle: Text(
                            'Autor: ${item['reviewedBy']}\n'
                            'Original: ${local['grazingAnimals']} animais / ${local['effectiveAreaHa']} ha\n'
                            'Aceita: ${remote['grazingAnimals']} animais / ${remote['effectiveAreaHa']} ha',
                          ),
                        );
                      }).toList(),
                    ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione e sincronize uma fazenda autorizada para registrar esta base.',
                  ),
                ],
              ],
            ),
          ),
        ),
        ...values.map(
          (e) => Card(
            child: ListTile(
              title: Text(e.$1),
              trailing: Text(
                e.$2 == null
                    ? 'Sem dados'
                    : '${e.$2!.toStringAsFixed(2)} ${e.$3}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
