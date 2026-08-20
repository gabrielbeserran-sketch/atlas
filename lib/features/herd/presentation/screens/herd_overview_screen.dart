import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal/presentation/screens/animal_detail_screen.dart';
import 'package:projeto_atlas/features/animal/presentation/screens/animal_form_screen.dart';
import 'package:projeto_atlas/features/animal_movement/presentation/screens/animal_movement_list_screen.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_list_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_workspace_data.dart';
import 'package:projeto_atlas/features/herd/presentation/screens/herd_group_form_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class HerdOverviewScreen extends StatefulWidget {
  const HerdOverviewScreen({super.key});

  @override
  State<HerdOverviewScreen> createState() => _HerdOverviewScreenState();
}

class _HerdOverviewScreenState extends State<HerdOverviewScreen> {
  final HerdEnterpriseService herdService = HerdEnterpriseService();
  final AnimalEnterpriseService animalService = AnimalEnterpriseService();
  final TextEditingController searchController = TextEditingController();

  HerdWorkspaceData workspace = const HerdWorkspaceData(
    groups: [],
    records: [],
  );
  bool isLoading = true;
  String errorMessage = '';
  List<String> loadWarnings = <String>[];
  String selectedLotId = '';
  String selectedStatus = '';
  String selectedSex = '';
  String loadedFarmId = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refreshFilters);
    WidgetsBinding.instance.addPostFrameCallback((_) => loadWorkspace());
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_refreshFilters)
      ..dispose();
    super.dispose();
  }

  void _refreshFilters() {
    if (mounted) setState(() {});
  }

  FarmData _farmData(BuildContext context) {
    final remote = AtlasSessionScope.read(context).activeFarm!;
    return FarmData(
      id: remote.id,
      name: remote.name,
      city: remote.city,
      state: remote.state,
      animals: workspace.totalAnimals,
      area: remote.area.round(),
    );
  }

  Future<List<T>> _safeLoad<T>({
    required String label,
    required Future<List<T>> Function() loader,
    required List<String> warnings,
    required List<T> fallback,
  }) async {
    try {
      // O timeout de rede pertence ao AtlasHttpClient e varia por ambiente.
      // Em produção, o cliente já usa receiveTimeout de 60 segundos.
      // Não aplicamos um segundo timeout local mais curto no Rebanho.
      return await loader();
    } catch (error) {
      warnings.add('$label indisponível');
      debugPrint('ATLAS Rebanho [$label]: $error');
      return List<T>.unmodifiable(fallback);
    }
  }

  HerdGroupData _groupForAnimal(
    AnimalData animal,
    Map<String, HerdGroupData> groupsById,
  ) {
    final lotId = animal.lotId.trim();
    if (lotId.isNotEmpty && groupsById[lotId] != null) {
      return groupsById[lotId]!;
    }
    if (lotId.isNotEmpty) {
      return HerdGroupData(
        id: lotId,
        name: 'Lote indisponível',
        category: animal.category,
        capacity: 0,
        paddock: 'Não informado',
        notes: 'O animal referencia um lote que não está na carteira ativa.',
      );
    }
    return HerdGroupData(
      name: 'Sem lote',
      category: animal.category,
      capacity: 0,
      paddock: 'Não informado',
      notes: 'Animal sem lote associado.',
    );
  }

  Future<void> loadWorkspace() async {
    final session = AtlasSessionScope.read(context);
    final farm = session.activeFarm;
    if (farm == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Selecione uma fazenda para consultar o rebanho.';
          loadWarnings = <String>[];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
        loadWarnings = <String>[];
        loadedFarmId = farm.id;
      });
    }

    final warnings = <String>[];
    try {
      final previousGroups = List<HerdGroupData>.unmodifiable(
        workspace.groups,
      );
      final previousAnimals = List<AnimalData>.unmodifiable(
        workspace.records.map((record) => record.animal),
      );

      final results = await Future.wait<dynamic>([
        _safeLoad<HerdGroupData>(
          label: 'Lotes',
          warnings: warnings,
          loader: () => herdService.listGroups(farm.id),
          fallback: previousGroups,
        ),
        _safeLoad<AnimalData>(
          label: 'Animais',
          warnings: warnings,
          loader: () => animalService.listAnimals(farmId: farm.id, lotId: ''),
          fallback: previousAnimals,
        ),
      ]);

      final groups = results[0] as List<HerdGroupData>;
      final animals = results[1] as List<AnimalData>;
      final groupsById = <String, HerdGroupData>{
        for (final group in groups) group.id: group,
      };
      final records =
          animals
              .map(
                (animal) => HerdAnimalRecord(
                  animal: animal,
                  group: _groupForAnimal(animal, groupsById),
                ),
              )
              .toList(growable: false)
            ..sort(
              (first, second) => first.animal.tag.compareTo(second.animal.tag),
            );

      if (!mounted) return;
      setState(() {
        workspace = HerdWorkspaceData(groups: groups, records: records);
        loadWarnings = List<String>.unmodifiable(warnings);
        if (selectedLotId.isNotEmpty &&
            groups.every((group) => group.id != selectedLotId)) {
          selectedLotId = '';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Não foi possível carregar o rebanho: $error';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _ensureCurrentFarm() async {
    final farmId = AtlasSessionScope.read(context).activeFarm?.id ?? '';
    if (farmId != loadedFarmId && farmId.isNotEmpty) {
      await loadWorkspace();
    }
  }

  Future<HerdGroupData?> _selectLot({String title = 'Selecionar lote'}) {
    if (workspace.groups.isEmpty) return Future.value(null);
    return showDialog<HerdGroupData>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: workspace.groups
                .map(
                  (group) => ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(group.name),
                    subtitle: Text('${group.category} • ${group.paddock}'),
                    onTap: () => Navigator.pop(dialogContext, group),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> createLot() async {
    final controller = AtlasSessionScope.read(context);
    if (!controller.allows('animals.create') &&
        !controller.allows('farms.update')) {
      _showMessage('Seu perfil não permite cadastrar lotes.');
      return;
    }
    final draft = await Navigator.push<HerdGroupData>(
      context,
      MaterialPageRoute(builder: (_) => const HerdGroupFormScreen()),
    );
    if (draft == null || !mounted) return;
    try {
      await herdService.createGroup(
        farmId: controller.activeFarm!.id,
        group: draft,
      );
      await loadWorkspace();
      _showMessage('Lote cadastrado com sucesso.');
    } on AtlasEnterpriseApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> editLot(HerdGroupData group) async {
    final controller = AtlasSessionScope.read(context);
    if (!controller.allows('animals.update') &&
        !controller.allows('farms.update')) {
      _showMessage('Seu perfil não permite editar lotes.');
      return;
    }
    final draft = await Navigator.push<HerdGroupData>(
      context,
      MaterialPageRoute(builder: (_) => HerdGroupFormScreen(group: group)),
    );
    if (draft == null || !mounted) return;
    try {
      await herdService.updateGroup(draft);
      await loadWorkspace();
      _showMessage('Lote atualizado com sucesso.');
    } on AtlasEnterpriseApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> createAnimal() async {
    final controller = AtlasSessionScope.read(context);
    if (!controller.allows('animals.create')) {
      _showMessage('Seu perfil não permite cadastrar animais.');
      return;
    }
    if (workspace.groups.isEmpty) {
      _showMessage('Cadastre um lote antes de incluir animais.');
      return;
    }
    final group = await _selectLot(title: 'Lote do novo animal');
    if (group == null || !mounted) return;
    final draft = await Navigator.push<AnimalData>(
      context,
      MaterialPageRoute(builder: (_) => const AnimalFormScreen()),
    );
    if (draft == null || !mounted) return;
    try {
      await animalService.createAnimal(
        farmId: controller.activeFarm!.id,
        lotId: group.id,
        animal: draft,
      );
      await loadWorkspace();
      _showMessage('Animal cadastrado com sucesso.');
    } on AtlasEnterpriseApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> editAnimal(HerdAnimalRecord record) async {
    final controller = AtlasSessionScope.read(context);
    if (!controller.allows('animals.update')) {
      _showMessage('Seu perfil não permite editar animais.');
      return;
    }
    final draft = await Navigator.push<AnimalData>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalFormScreen(animal: record.animal),
      ),
    );
    if (draft == null || !mounted) return;
    final selectedGroup = await _selectLot(title: 'Confirmar lote do animal');
    if (selectedGroup == null || !mounted) return;
    try {
      await animalService.updateAnimal(lotId: selectedGroup.id, animal: draft);
      await loadWorkspace();
      _showMessage('Animal atualizado com sucesso.');
    } on AtlasEnterpriseApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> deleteAnimal(HerdAnimalRecord record) async {
    final controller = AtlasSessionScope.read(context);
    if (!controller.allows('animals.delete')) {
      _showMessage('Seu perfil não permite excluir animais.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir animal'),
        content: Text('Confirma a exclusão de ${record.animal.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await animalService.deleteAnimal(record.animal.id);
      await loadWorkspace();
      _showMessage('Animal excluído com sucesso.');
    } on AtlasEnterpriseApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> openDetail(HerdAnimalRecord record) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animal: record.animal,
          farm: _farmData(context),
          group: record.group,
        ),
      ),
    );
    if (mounted) await loadWorkspace();
  }

  Future<void> openWeights(HerdAnimalRecord record) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalWeightListScreen(
          animal: record.animal,
          farm: _farmData(context),
          group: record.group,
        ),
      ),
    );
    if (mounted) await loadWorkspace();
  }

  Future<void> openMovements(HerdAnimalRecord record) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalMovementListScreen(
          animal: record.animal,
          farm: _farmData(context),
          group: record.group,
        ),
      ),
    );
    if (mounted) await loadWorkspace();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    unawaited(_ensureCurrentFarm());
    final controller = AtlasSessionScope.of(context);
    final farm = controller.activeFarm;
    final filtered = workspace.filter(
      query: searchController.text,
      lotId: selectedLotId,
      status: selectedStatus,
      sex: selectedSex,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      floatingActionButton: farm == null
          ? null
          : FloatingActionButton.extended(
              onPressed: createAnimal,
              icon: const Icon(Icons.add),
              label: const Text('Novo animal'),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadWorkspace,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        farmName: farm?.name ?? 'Nenhuma fazenda selecionada',
                        onRefresh: isLoading ? null : loadWorkspace,
                        onCreateLot: farm == null ? null : createLot,
                      ),
                      const SizedBox(height: 20),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(64),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (errorMessage.isNotEmpty)
                        _ErrorState(
                          message: errorMessage,
                          onRetry: loadWorkspace,
                        )
                      else ...[
                        if (loadWarnings.isNotEmpty) ...[
                          _HerdLoadWarning(
                            warnings: loadWarnings,
                            onRetry: loadWorkspace,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _Indicators(workspace: workspace),
                        const SizedBox(height: 20),
                        _Filters(
                          searchController: searchController,
                          groups: workspace.groups,
                          selectedLotId: selectedLotId,
                          selectedStatus: selectedStatus,
                          selectedSex: selectedSex,
                          onLotChanged: (value) =>
                              setState(() => selectedLotId = value ?? ''),
                          onStatusChanged: (value) =>
                              setState(() => selectedStatus = value ?? ''),
                          onSexChanged: (value) =>
                              setState(() => selectedSex = value ?? ''),
                          onClear: () {
                            searchController.clear();
                            setState(() {
                              selectedLotId = '';
                              selectedStatus = '';
                              selectedSex = '';
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _LotsSection(
                          groups: workspace.groups,
                          records: workspace.records,
                          onEdit: editLot,
                          onFilter: (group) =>
                              setState(() => selectedLotId = group.id),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Animais (${filtered.length})',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (filtered.isEmpty)
                          const _EmptyAnimals()
                        else
                          ...filtered.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AnimalCard(
                                record: record,
                                onOpen: () => openDetail(record),
                                onEdit: () => editAnimal(record),
                                onDelete: () => deleteAnimal(record),
                                onWeights: () => openWeights(record),
                                onMovements: () => openMovements(record),
                              ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.farmName,
    required this.onRefresh,
    required this.onCreateLot,
  });

  final String farmName;
  final VoidCallback? onRefresh;
  final VoidCallback? onCreateLot;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestão do rebanho',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(farmName, style: const TextStyle(color: Colors.black54)),
      ],
    );

    final refresh = OutlinedButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh),
      label: const Text('Atualizar'),
    );

    final create = FilledButton.icon(
      onPressed: onCreateLot,
      icon: const Icon(Icons.add_box_outlined),
      label: const Text('Novo lote'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: refresh),
                  const SizedBox(width: 8),
                  Expanded(child: create),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            refresh,
            const SizedBox(width: 10),
            create,
          ],
        );
      },
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.workspace});
  final HerdWorkspaceData workspace;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _Indicator(
        label: 'Lotes',
        value: workspace.groups.length.toString(),
        icon: Icons.groups_outlined,
      ),
      _Indicator(
        label: 'Animais',
        value: workspace.totalAnimals.toString(),
        icon: AtlasLivestockIcons.cow,
      ),
      _Indicator(
        label: 'Ativos',
        value: workspace.activeAnimals.toString(),
        icon: Icons.check_circle_outline,
      ),
      _Indicator(
        label: 'Fêmeas',
        value: workspace.females.toString(),
        icon: Icons.female,
      ),
      _Indicator(
        label: 'Machos',
        value: workspace.males.toString(),
        icon: Icons.male,
      ),
      _Indicator(
        label: 'Peso médio',
        value: workspace.averageWeight == 0
            ? '—'
            : '${workspace.averageWeight.toStringAsFixed(0)} kg',
        icon: Icons.monitor_weight_outlined,
      ),
    ],
  );
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.groups,
    required this.selectedLotId,
    required this.selectedStatus,
    required this.selectedSex,
    required this.onLotChanged,
    required this.onStatusChanged,
    required this.onSexChanged,
    required this.onClear,
  });
  final TextEditingController searchController;
  final List<HerdGroupData> groups;
  final String selectedLotId;
  final String selectedStatus;
  final String selectedSex;
  final ValueChanged<String?> onLotChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSexChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final fullWidth = constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? fullWidth : 360,
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar animal',
                    hintText: 'Brinco, SISBOV, nome ou raça',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: compact ? fullWidth : 210,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedLotId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Lote'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text(
                        'Todos os lotes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...groups.map(
                      (group) => DropdownMenuItem(
                        value: group.id,
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onLotChanged,
                ),
              ),
              SizedBox(
                width: compact ? fullWidth : 170,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas')),
                    DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                    DropdownMenuItem(value: 'Vendido', child: Text('Vendido')),
                    DropdownMenuItem(value: 'Morto', child: Text('Morto')),
                    DropdownMenuItem(value: 'Inativo', child: Text('Inativo')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: compact ? fullWidth : 160,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSex,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todos')),
                    DropdownMenuItem(value: 'Fêmea', child: Text('Fêmea')),
                    DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                  ],
                  onChanged: onSexChanged,
                ),
              ),
              SizedBox(
                width: compact ? fullWidth : null,
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpar filtros'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _LotsSection extends StatelessWidget {
  const _LotsSection({
    required this.groups,
    required this.records,
    required this.onEdit,
    required this.onFilter,
  });
  final List<HerdGroupData> groups;
  final List<HerdAnimalRecord> records;
  final ValueChanged<HerdGroupData> onEdit;
  final ValueChanged<HerdGroupData> onFilter;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const _EmptyLots();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lotes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              final count = records
                  .where((record) => record.group.id == group.id)
                  .length;
              final occupancy = group.capacity <= 0
                  ? null
                  : count / group.capacity;
              return SizedBox(
                width: 280,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onFilter(group),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Editar lote',
                                onPressed: () => onEdit(group),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ],
                          ),
                          Text(
                            '${group.category} • ${group.paddock}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            group.capacity <= 0
                                ? '$count animais'
                                : '$count de ${group.capacity} animais',
                          ),
                          if (occupancy != null) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: occupancy.clamp(0, 1).toDouble(),
                            ),
                          ],
                        ],
                      ),
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

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.record,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onWeights,
    required this.onMovements,
  });
  final HerdAnimalRecord record;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWeights;
  final VoidCallback onMovements;

  @override
  Widget build(BuildContext context) {
    final animal = record.animal;
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          child: Text(
            animal.tag.isEmpty
                ? '?'
                : animal.tag.characters.first.toUpperCase(),
          ),
        ),
        title: Text(
          animal.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${animal.tag} • ${animal.sex} • ${animal.breed} • ${record.group.name}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Ações do animal',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'weights':
                onWeights();
              case 'movements':
                onMovements();
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'weights',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.monitor_weight_outlined),
                title: Text('Pesagens'),
              ),
            ),
            PopupMenuItem(
              value: 'movements',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.swap_horiz),
                title: Text('Movimentações'),
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.delete_outline),
                title: Text('Excluir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HerdLoadWarning extends StatelessWidget {
  const _HerdLoadWarning({required this.warnings, required this.onRetry});

  final List<String> warnings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rebanho carregado parcialmente: ${warnings.join(', ')}.',
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyLots extends StatelessWidget {
  const _EmptyLots();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Row(
        children: [
          Icon(Icons.groups_outlined, size: 42),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Nenhum lote cadastrado. Use “Novo lote” para iniciar a organização do rebanho.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyAnimals extends StatelessWidget {
  const _EmptyAnimals();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text('Nenhum animal encontrado para os filtros selecionados.'),
      ),
    ),
  );
}
