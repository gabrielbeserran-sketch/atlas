import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal/domain/services/animal_finance_integration_service.dart';
import 'package:projeto_atlas/features/animal/presentation/screens/animal_detail_screen.dart';
import 'package:projeto_atlas/features/animal/presentation/screens/animal_form_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_remote_authorization_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({required this.farm, required this.group, super.key});

  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  final AnimalStorageService storage = AnimalStorageService();
  final AnimalEnterpriseService enterprise = AnimalEnterpriseService();
  final AtlasEnterpriseRemoteAuthorizationService authorization =
      AtlasEnterpriseRemoteAuthorizationService.instance;
  final AnimalFinanceIntegrationService financeIntegration =
      AnimalFinanceIntegrationService();

  List<AnimalData> animals = [];
  bool isLoading = true;
  bool canRead = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;
  bool usingOfflineCache = false;
  final searchController = TextEditingController();
  String selectedSex = 'Todos';
  String selectedStatus = 'Todos';
  String selectedCategory = 'Todas';
  late final String eventSubscriptionId;
  Timer? reloadDebounce;
  bool isLoadingAnimals = false;
  bool reloadRequested = false;

  @override
  void initState() {
    super.initState();
    eventSubscriptionId = AtlasEventBus.instance.subscribe(
      owner: 'animal_list_${widget.farm.name}_${widget.group.name}',
      filter: AtlasEventFilter(
        types: const <AtlasEventType>{
          AtlasEventType.animalCreated,
          AtlasEventType.animalUpdated,
          AtlasEventType.animalDeleted,
        },
        sourceModules: const <String>{'animal'},
        farmName: widget.farm.name,
        entityType: 'animal',
      ),
      listener: handleAnimalEvent,
    );
    loadAnimals();
  }

  @override
  void dispose() {
    reloadDebounce?.cancel();
    AtlasEventBus.instance.unsubscribe(eventSubscriptionId);
    searchController.dispose();
    super.dispose();
  }

  List<String> get categories {
    final values = animals.map((animal) => animal.category).toSet().toList()
      ..sort();
    return ['Todas', ...values];
  }

  List<AnimalData> get filteredAnimals {
    final query = searchController.text.trim().toLowerCase();
    return animals.where((animal) {
      final matchesQuery =
          query.isEmpty ||
          animal.displayName.toLowerCase().contains(query) ||
          animal.tag.toLowerCase().contains(query) ||
          animal.sisbov.toLowerCase().contains(query) ||
          animal.breed.toLowerCase().contains(query) ||
          animal.category.toLowerCase().contains(query) ||
          animal.motherTag.toLowerCase().contains(query) ||
          animal.fatherTag.toLowerCase().contains(query);
      final matchesSex = selectedSex == 'Todos' || animal.sex == selectedSex;
      final matchesStatus =
          selectedStatus == 'Todos' || animal.status == selectedStatus;
      final matchesCategory =
          selectedCategory == 'Todas' || animal.category == selectedCategory;
      return matchesQuery && matchesSex && matchesStatus && matchesCategory;
    }).toList();
  }

  int get activeAnimals {
    return animals.where((animal) => animal.status == 'Ativo').length;
  }

  double get averageWeight {
    if (animals.isEmpty) {
      return 0;
    }

    final totalWeight = animals.fold<double>(
      0,
      (total, animal) => total + animal.weight,
    );

    return totalWeight / animals.length;
  }

  Future<void> handleAnimalEvent(AtlasEvent event) async {
    final eventGroupName = event.payload['groupName']?.toString();

    if (eventGroupName != null &&
        eventGroupName.trim().isNotEmpty &&
        eventGroupName != widget.group.name) {
      return;
    }

    scheduleAutomaticReload();
  }

  void scheduleAutomaticReload() {
    reloadDebounce?.cancel();

    reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(loadAnimals(showLoading: false));
    });
  }

  Future<void> loadAnimals({bool showLoading = true}) async {
    if (isLoadingAnimals) {
      reloadRequested = true;
      return;
    }

    isLoadingAnimals = true;

    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final permissions = await Future.wait<bool>([
        authorization.can('animals.read', refresh: true),
        authorization.can('animals.create', refresh: false),
        authorization.can('animals.update', refresh: false),
        authorization.can('animals.delete', refresh: false),
      ]);

      final farmId = widget.farm.id?.trim() ?? '';

      if (farmId.isEmpty) {
        throw const AtlasEnterpriseApiException(
          'Esta fazenda ainda não possui ID Enterprise.',
        );
      }

      if (widget.group.id.trim().isEmpty) {
        throw const AtlasEnterpriseApiException(
          'Este lote ainda não possui ID oficial. Atualize a lista de lotes.',
        );
      }

      if (!permissions[0]) {
        if (!mounted) return;

        setState(() {
          canRead = false;
          canCreate = permissions[1];
          canUpdate = permissions[2];
          canDelete = permissions[3];
          animals = <AnimalData>[];
          isLoading = false;
          usingOfflineCache = false;
        });
        return;
      }

      final remoteAnimals = await enterprise.listAnimals(
        farmId: farmId,
        lotId: widget.group.id,
      );

      await storage.saveAnimals(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animals: remoteAnimals,
      );

      if (!mounted) return;

      setState(() {
        canRead = permissions[0];
        canCreate = permissions[1];
        canUpdate = permissions[2];
        canDelete = permissions[3];
        animals = remoteAnimals;
        isLoading = false;
        usingOfflineCache = false;
      });
    } on AtlasEnterpriseApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        if (!mounted) return;

        setState(() {
          canRead = false;
          canCreate = false;
          canUpdate = false;
          canDelete = false;
          animals = <AnimalData>[];
          isLoading = false;
          usingOfflineCache = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }

      final cachedAnimals = await storage.loadAnimals(
        farmName: widget.farm.name,
        groupName: widget.group.name,
      );

      if (!mounted) return;

      setState(() {
        animals = cachedAnimals;
        isLoading = false;
        usingOfflineCache = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'API indisponível. Exibindo o último cache local. ${error.message}',
          ),
        ),
      );
    } finally {
      isLoadingAnimals = false;

      if (reloadRequested && mounted) {
        reloadRequested = false;
        unawaited(loadAnimals(showLoading: false));
      }
    }
  }

  Future<void> saveCache() async {
    await storage.saveAnimals(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animals: animals,
    );
  }

  Future<void> openAnimalForm() async {
    try {
      await authorization.require(
        'animals.create',
        refresh: true,
        reason: 'Seu perfil não permite cadastrar animais.',
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;
      setState(() => canCreate = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    if (!mounted) return;

    final draft = await Navigator.push<AnimalData>(
      context,
      MaterialPageRoute<AnimalData>(
        builder: (context) => const AnimalFormScreen(),
      ),
    );

    if (draft == null || !mounted) return;

    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta fazenda ainda não possui ID Enterprise.'),
        ),
      );
      return;
    }

    if (widget.group.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este lote ainda não possui ID oficial. Atualize a lista de lotes.',
          ),
        ),
      );
      return;
    }

    try {
      final created = await enterprise.createAnimal(
        farmId: farmId,
        lotId: widget.group.id,
        animal: draft,
      );

      if (!mounted) return;

      setState(() {
        animals.add(created);
        usingOfflineCache = false;
      });

      await saveCache();

      final integrationMessages = await financeIntegration.synchronize(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animal: created,
      );

      if (!mounted) return;

      final suffix = integrationMessages.isEmpty
          ? ''
          : ' ${integrationMessages.join(' ')}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${created.displayName} foi cadastrado na API Enterprise.$suffix',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 403) {
        setState(() => canCreate = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> editAnimal(AnimalData animal) async {
    try {
      await authorization.require(
        'animals.update',
        refresh: true,
        reason: 'Seu perfil não permite editar animais.',
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;
      setState(() => canUpdate = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    if (!mounted) return;

    final draft = await Navigator.push<AnimalData>(
      context,
      MaterialPageRoute<AnimalData>(
        builder: (context) => AnimalFormScreen(animal: animal),
      ),
    );

    if (draft == null || !mounted) return;

    try {
      final updated = await enterprise.updateAnimal(
        lotId: widget.group.id,
        animal: draft,
      );

      final animalIndex = animals.indexWhere((item) => item.id == animal.id);

      if (animalIndex == -1 || !mounted) return;

      setState(() {
        animals[animalIndex] = updated;
        usingOfflineCache = false;
      });

      await saveCache();

      final integrationMessages = await financeIntegration.synchronize(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animal: updated,
      );

      if (!mounted) return;

      final suffix = integrationMessages.isEmpty
          ? ''
          : ' ${integrationMessages.join(' ')}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.displayName} foi atualizado na API Enterprise.$suffix',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 403) {
        setState(() => canUpdate = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> deleteAnimal(AnimalData animal) async {
    try {
      await authorization.require(
        'animals.delete',
        refresh: true,
        reason: 'Seu perfil não permite excluir animais.',
      );
    } on AtlasRemoteAuthorizationException catch (error) {
      if (!mounted) return;
      setState(() => canDelete = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir animal'),
          content: Text(
            'Tem certeza de que deseja excluir ${animal.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await enterprise.deleteAnimal(animal.id);

      if (!mounted) return;

      setState(() {
        animals.removeWhere((item) => item.id == animal.id);
        usingOfflineCache = false;
      });

      await saveCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${animal.displayName} foi excluído da API Enterprise.',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 403) {
        setState(() => canDelete = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void openAnimalDetail(AnimalData animal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimalDetailScreen(
          animal: animal,
          farm: widget.farm,
          group: widget.group,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      floatingActionButton: canCreate && canRead
          ? FloatingActionButton.extended(
              onPressed: isLoading ? null : openAnimalForm,
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Novo animal'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        widget.farm.name,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.group.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.group.category} · '
                        '${widget.group.paddock}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (!canRead) ...[
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.lock_outline),
                            title: Text('Acesso ao rebanho bloqueado'),
                            subtitle: Text(
                              'A permissão animals.read não está habilitada para este usuário.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (usingOfflineCache) ...[
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.cloud_off_outlined),
                            title: Text('Modo de contingência'),
                            subtitle: Text(
                              'A API está indisponível. A lista mostra o último cache local.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          AnimalSummaryCard(
                            title: 'Cadastrados',
                            value: animals.length.toString(),
                            icon: AtlasLivestockIcons.cow,
                          ),
                          AnimalSummaryCard(
                            title: 'Ativos',
                            value: activeAnimals.toString(),
                            icon: Icons.check_circle_outline,
                          ),
                          AnimalSummaryCard(
                            title: 'Peso médio',
                            value: '${averageWeight.toStringAsFixed(0)} kg',
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              TextField(
                                controller: searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Busca rápida',
                                  hintText:
                                      'Nome, brinco, SISBOV, raça ou genealogia',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: 190,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedSex,
                                      decoration: const InputDecoration(
                                        labelText: 'Sexo',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Todos',
                                          child: Text('Todos'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Fêmea',
                                          child: Text('Fêmea'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Macho',
                                          child: Text('Macho'),
                                        ),
                                      ],
                                      onChanged: (value) => setState(
                                        () => selectedSex = value ?? 'Todos',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 210,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Situação',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Todos',
                                          child: Text('Todas'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Ativo',
                                          child: Text('Ativo'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Em quarentena',
                                          child: Text('Em quarentena'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Vendido',
                                          child: Text('Vendido'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Abatido',
                                          child: Text('Abatido'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Morto',
                                          child: Text('Morto'),
                                        ),
                                      ],
                                      onChanged: (value) => setState(
                                        () => selectedStatus = value ?? 'Todos',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 220,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey(categories.join('|')),
                                      initialValue:
                                          categories.contains(selectedCategory)
                                          ? selectedCategory
                                          : 'Todas',
                                      decoration: const InputDecoration(
                                        labelText: 'Categoria',
                                      ),
                                      items: categories
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () =>
                                            selectedCategory = value ?? 'Todas',
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        selectedSex = 'Todos';
                                        selectedStatus = 'Todos';
                                        selectedCategory = 'Todas';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.filter_alt_off_outlined,
                                    ),
                                    label: const Text('Limpar filtros'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Animais do lote (${filteredAnimals.length})',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (animals.isEmpty)
                        const EmptyAnimalsMessage()
                      else if (filteredAnimals.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: Text(
                              'Nenhum animal corresponde aos filtros selecionados.',
                            ),
                          ),
                        )
                      else
                        ...filteredAnimals.map(
                          (animal) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AnimalCard(
                              animal: animal,
                              canUpdate: canUpdate,
                              canDelete: canDelete,
                              onOpen: () => openAnimalDetail(animal),
                              onEdit: () => editAnimal(animal),
                              onDelete: () => deleteAnimal(animal),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AnimalSummaryCard extends StatelessWidget {
  const AnimalSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 30, color: const Color(0xFF1B5E20)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimalCard extends StatelessWidget {
  const AnimalCard({
    required this.animal,
    required this.canUpdate,
    required this.canDelete,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AnimalData animal;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = animal.status == 'Ativo';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: const Color(
                  0xFF1B5E20,
                ).withValues(alpha: 0.10),
                child: const Icon(
                  AtlasLivestockIcons.cow,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brinco ${animal.tag} · ${animal.category} · ${animal.breed}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        AnimalInformation(
                          icon: Icons.wc_outlined,
                          text: animal.sex,
                        ),
                        AnimalInformation(
                          icon: Icons.calendar_month_outlined,
                          text: animal.birthDate,
                        ),
                        AnimalInformation(
                          icon: Icons.monitor_weight_outlined,
                          text: '${formatWeight(animal.weight)} kg',
                        ),
                        if (animal.sisbov.trim().isNotEmpty)
                          AnimalInformation(
                            icon: Icons.qr_code_2_outlined,
                            text: 'SISBOV ${animal.sisbov}',
                          ),
                        if (animal.bodyConditionScore > 0)
                          AnimalInformation(
                            icon: Icons.speed_outlined,
                            text:
                                'ECC ${animal.bodyConditionScore.toStringAsFixed(1).replaceAll('.', ',')}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  animal.status,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF8D6E00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canUpdate || canDelete)
                PopupMenuButton<String>(
                  tooltip: 'Opções',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }

                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (canUpdate)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF1B5E20),
                              ),
                              SizedBox(width: 10),
                              Text('Editar animal'),
                            ],
                          ),
                        ),
                      if (canDelete)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Excluir animal'),
                            ],
                          ),
                        ),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }

    return weight.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class AnimalInformation extends StatelessWidget {
  const AnimalInformation({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class EmptyAnimalsMessage extends StatelessWidget {
  const EmptyAnimalsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(AtlasLivestockIcons.cow, size: 56, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'Nenhum animal cadastrado neste lote.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
