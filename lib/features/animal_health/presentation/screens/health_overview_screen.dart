import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/navigation/atlas_product_surface_policy.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_workspace_guide.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_action_bar.dart';
import 'package:projeto_atlas/core/widgets/atlas_empty_state.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_decision_panel.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/animal_health_list_screen.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_handling/presentation/screens/farm_handling_screen.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({
    this.farm,
    this.autoOpenCreate = false,
    this.embedded = false,
    super.key,
  });

  final FarmData? farm;
  final bool autoOpenCreate;
  final bool embedded;

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  final searchController = TextEditingController();
  final FarmStorageService farmStorage = FarmStorageService();
  final HerdStorageService herdStorage = HerdStorageService();
  final AnimalStorageService animalStorage = AnimalStorageService();
  final AnimalHealthStorageService healthStorage = AnimalHealthStorageService();

  List<HealthAnimalContext> animals = [];
  bool isLoading = true;
  String? loadError;
  String search = '';

  int get totalAnimals => animals.length;

  int get animalsWithRecords =>
      animals.where((context) => context.records.isNotEmpty).length;

  int get totalRecords =>
      animals.fold(0, (total, context) => total + context.records.length);

  int get clinicalOccurrences => animals.fold(
    0,
    (total, context) =>
        total +
        context.records
            .where((record) => record.type == 'Ocorrência clínica')
            .length,
  );

  int get scheduledReturns => animals.fold(
    0,
    (total, context) =>
        total +
        context.records.where((record) => record.hasScheduledReturn).length,
  );

  int get quarantineAnimals => animals
      .where((context) => context.records.any((record) => record.isQuarantine))
      .length;

  int get mortalities => animals.fold(
    0,
    (total, context) =>
        total + context.records.where((record) => record.isMortality).length,
  );

  DateTime? _parseDisplayDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get overdueReturns => animals.fold(
    0,
    (total, context) =>
        total +
        context.records.where((record) {
          final date = _parseDisplayDate(record.nextDate);
          return date != null && date.isBefore(_today);
        }).length,
  );

  int get activeWithdrawalAnimals => animals.where((context) {
    return context.records.any((record) {
      final dates = [
        record.withdrawalEndDate,
        record.withdrawalMeatEndDate,
        record.withdrawalMilkEndDate,
      ].map(_parseDisplayDate).whereType<DateTime>();
      return dates.any((date) => !date.isBefore(_today));
    });
  }).length;

  AtlasModuleAttentionLevel get _moduleLevel {
    if (quarantineAnimals > 0 || overdueReturns > 0) {
      return AtlasModuleAttentionLevel.critical;
    }
    if (clinicalOccurrences > 0 ||
        activeWithdrawalAnimals > 0 ||
        scheduledReturns > 0) {
      return AtlasModuleAttentionLevel.attention;
    }
    return AtlasModuleAttentionLevel.normal;
  }

  List<AtlasModuleDecisionItem> get _decisionItems {
    final items = <AtlasModuleDecisionItem>[];
    if (quarantineAnimals > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$quarantineAnimals animal(is) em quarentena',
          description: 'Revise isolamento, evolução clínica e liberação.',
          icon: Icons.health_and_safety_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (overdueReturns > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$overdueReturns retorno(s) sanitário(s) vencido(s)',
          description: 'Há aplicações ou revisões com data anterior a hoje.',
          icon: Icons.event_busy_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (activeWithdrawalAnimals > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$activeWithdrawalAnimals animal(is) em período de carência',
          description:
              'Considere a carência antes de movimentação, leite ou abate.',
          icon: Icons.timer_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    if (scheduledReturns > overdueReturns) {
      items.add(
        AtlasModuleDecisionItem(
          title: '${scheduledReturns - overdueReturns} retorno(s) programado(s)',
          description: 'Existem próximos manejos sanitários a acompanhar.',
          icon: Icons.event_repeat_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    if (animalsWithRecords < totalAnimals && totalAnimals > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '${totalAnimals - animalsWithRecords} animal(is) sem histórico',
          description:
              'Esses animais ainda não possuem registro sanitário no Atlas.',
          icon: Icons.fact_check_outlined,
        ),
      );
    }
    return items;
  }

  String get _moduleStatusTitle {
    if (_moduleLevel == AtlasModuleAttentionLevel.critical) {
      return 'Sanidade exige ação';
    }
    if (_moduleLevel == AtlasModuleAttentionLevel.attention) {
      return 'Sanidade requer acompanhamento';
    }
    return 'Sanidade sem prioridade crítica';
  }

  List<HealthAnimalContext> get filteredAnimals {
    final normalizedSearch = search.trim().toLowerCase();

    if (normalizedSearch.isEmpty) {
      return animals;
    }

    return animals.where((context) {
      return context.animal.displayName.toLowerCase().contains(
            normalizedSearch,
          ) ||
          context.animal.tag.toLowerCase().contains(normalizedSearch) ||
          context.farm.name.toLowerCase().contains(normalizedSearch) ||
          context.group.name.toLowerCase().contains(normalizedSearch);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await loadData();
    if (widget.autoOpenCreate && mounted) {
      await openNewEvent();
    }
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }
    try {
      final farms = widget.farm == null
          ? await farmStorage.loadFarms()
          : <FarmData>[widget.farm!];
      final loadedAnimals = <HealthAnimalContext>[];

      for (final farm in farms) {
        final groups = await herdStorage.loadGroups(farm.name);
        for (final group in groups) {
          final groupAnimals = await animalStorage.loadAnimals(
            farmName: farm.name,
            groupName: group.name,
          );
          for (final animal in groupAnimals) {
            final records = await healthStorage.loadRecords(
              farmName: farm.name,
              groupName: group.name,
              animalId: animal.id,
            );
            loadedAnimals.add(
              HealthAnimalContext(
                farm: farm,
                group: group,
                animal: animal,
                records: records,
              ),
            );
          }
        }
      }

      loadedAnimals.sort((first, second) {
        final farmComparison = first.farm.name.compareTo(second.farm.name);
        if (farmComparison != 0) return farmComparison;
        return first.animal.displayName.compareTo(second.animal.displayName);
      });

      if (!mounted) return;
      setState(() => animals = loadedAnimals);
    } catch (error) {
      if (!mounted) return;
      setState(() => loadError = error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openAnimal(HealthAnimalContext contextData) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AnimalHealthListScreen(
            animal: contextData.animal,
            farm: contextData.farm,
            group: contextData.group,
          );
        },
      ),
    );

    await loadData();
  }

  Future<void> openNewEvent() async {
    if (animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre um animal compatível antes de criar o evento.',
          ),
        ),
      );
      return;
    }

    HealthAnimalContext? selected;
    if (animals.length == 1) {
      selected = animals.first;
    } else {
      selected = await showDialog<HealthAnimalContext>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Selecione o animal'),
          children: animals
              .map(
                (item) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, item),
                  child: Text(
                    '${item.animal.displayName} • ${item.animal.tag}',
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (selected == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimalHealthListScreen(
          animal: selected!.animal,
          farm: selected.farm,
          group: selected.group,
          autoOpenCreate: true,
        ),
      ),
    );
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: widget.embedded ? null : AppBar(
        title: Text(
          widget.farm == null ? 'Sanidade' : 'Sanidade — ${widget.farm!.name}',
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : loadError != null && animals.isEmpty
                ? AtlasLoadErrorState(
                    message: 'Verifique sua conexão e tente novamente.',
                    onRetry: loadData,
                  )
                : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HealthHeader(),
                            const SizedBox(height: 12),
                            AtlasOperationalActionBar(
                              primaryLabel: 'Novo evento sanitário',
                              onPrimary: openNewEvent,
                              secondaryLabel:
                                  widget.farm == null ? null : 'Manejo coletivo',
                              secondaryIcon:
                                  Icons.playlist_add_check_outlined,
                              onSecondary: widget.farm == null
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => FarmHandlingScreen(
                                            farm: widget.farm!,
                                          ),
                                        ),
                                      );
                                    },
                              onRefresh: loadData,
                              busy: isLoading,
                            ),
                            const SizedBox(height: 16),
                            AtlasModuleDecisionPanel(
                              statusTitle: _moduleStatusTitle,
                              statusDescription:
                                  '$totalRecords registros • '
                                  '$scheduledReturns retornos • '
                                  '$clinicalOccurrences ocorrências clínicas',
                              items: _decisionItems,
                              level: _moduleLevel,
                            ),
                            AtlasModuleWorkspaceGuide(
                              moduleLabel: 'Sanidade',
                              workflows:
                                  AtlasProductSurfacePolicy.moduleWorkflows['Sanidade'] ??
                                      const <String>[],
                              specializedFamilies: AtlasProductSurfacePolicy
                                      .specializedCapabilityCountByOwner['Sanidade'] ??
                                  0,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _IndicatorCard(
                                  title: 'Animais',
                                  value: totalAnimals.toString(),
                                  subtitle:
                                      'Animais disponíveis para acompanhamento',
                                  icon: AtlasLivestockIcons.cow,
                                ),
                                _IndicatorCard(
                                  title: 'Com histórico',
                                  value: animalsWithRecords.toString(),
                                  subtitle: 'Animais com registros sanitários',
                                  icon: Icons.history_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Registros',
                                  value: totalRecords.toString(),
                                  subtitle: 'Eventos sanitários cadastrados',
                                  icon: Icons.assignment_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Ocorrências',
                                  value: clinicalOccurrences.toString(),
                                  subtitle: 'Ocorrências clínicas registradas',
                                  icon: Icons.monitor_heart_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Retornos',
                                  value: scheduledReturns.toString(),
                                  subtitle: 'Aplicações e revisões programadas',
                                  icon: Icons.event_repeat_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Quarentena',
                                  value: quarantineAnimals.toString(),
                                  subtitle: 'Animais com isolamento registrado',
                                  icon: Icons.warning_amber_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Mortalidade',
                                  value: mortalities.toString(),
                                  subtitle: 'Óbitos registrados no histórico',
                                  icon: Icons.analytics_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              controller: searchController,
                              onChanged: (value) {
                                setState(() {
                                  search = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar por animal, brinco, fazenda ou lote',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Acompanhamento sanitário',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Selecione um animal para consultar ou registrar vacinas, tratamentos, exames e ocorrências clínicas.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            if (animals.isEmpty)
                              _EmptyHealth()
                            else if (filteredAnimals.isEmpty)
                              _NoSearchResults(
                                onClear: () {
                                  searchController.clear();
                                  setState(() => search = '');
                                },
                              )
                            else
                              ...filteredAnimals.map(
                                (contextData) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _AnimalCard(
                                    contextData: contextData,
                                    onOpen: () => openAnimal(contextData),
                                  ),
                                ),
                              ),
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

class HealthAnimalContext {
  const HealthAnimalContext({
    required this.farm,
    required this.group,
    required this.animal,
    required this.records,
  });

  final FarmData farm;
  final HerdGroupData group;
  final AnimalData animal;
  final List<AnimalHealthData> records;

  AnimalHealthData? get latestRecord {
    if (records.isEmpty) {
      return null;
    }

    final sortedRecords = [...records]
      ..sort(
        (first, second) =>
            _parseDate(second.date).compareTo(_parseDate(first.date)),
      );

    return sortedRecords.first;
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return DateTime(1900);
    }

    return DateTime(
      int.tryParse(parts[2]) ?? 1900,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF1B5E20),
            child: Icon(
              Icons.medical_services_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central de Sanidade',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Acompanhe o histórico sanitário dos animais de todas as fazendas.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Icon(icon, color: const Color(0xFF1B5E20)),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.contextData, required this.onOpen});

  final HealthAnimalContext contextData;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final latestRecord = contextData.latestRecord;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(AtlasLivestockIcons.cow, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextData.animal.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brinco ${contextData.animal.tag} · ${contextData.farm.name} · ${contextData.group.name}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latestRecord == null
                          ? 'Nenhum registro sanitário'
                          : 'Último: ${latestRecord.type} · ${latestRecord.date}',
                      style: TextStyle(
                        color: latestRecord == null
                            ? Colors.black45
                            : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    contextData.records.length.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'registros',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHealth extends StatelessWidget {
  const _EmptyHealth();

  @override
  Widget build(BuildContext context) {
    return const AtlasEmptyState(
      icon: Icons.medical_services_outlined,
      title: 'Nenhum animal disponível',
      message:
          'Cadastre o animal no Rebanho para iniciar vacinas, tratamentos, exames e ocorrências clínicas.',
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AtlasEmptyState(
      icon: Icons.search_off_outlined,
      title: 'Nenhum animal encontrado',
      message:
          'A busca atual não encontrou animais. Limpe a busca para voltar à lista completa.',
      actionLabel: 'Limpar busca',
      onAction: onClear,
    );
  }
}
