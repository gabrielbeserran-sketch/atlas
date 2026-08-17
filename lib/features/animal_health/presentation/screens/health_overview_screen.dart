import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/animal_health_list_screen.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({this.farm, super.key});

  final FarmData? farm;

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final HerdStorageService herdStorage = HerdStorageService();
  final AnimalStorageService animalStorage = AnimalStorageService();
  final AnimalHealthStorageService healthStorage = AnimalHealthStorageService();

  List<HealthAnimalContext> animals = [];
  bool isLoading = true;
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
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

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
      if (farmComparison != 0) {
        return farmComparison;
      }

      return first.animal.displayName.compareTo(second.animal.displayName);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      animals = loadedAnimals;
      isLoading = false;
    });
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openNewEvent,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo evento sanitário'),
      ),
      appBar: AppBar(
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
                              const _EmptyHealth()
                            else if (filteredAnimals.isEmpty)
                              const _NoSearchResults()
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              Icon(AtlasLivestockIcons.cow, size: 48, color: Colors.black38),
              SizedBox(height: 12),
              Text(
                'Nenhum animal cadastrado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Cadastre fazendas, lotes e animais para iniciar o acompanhamento sanitário.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhum animal encontrado para esta busca.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
