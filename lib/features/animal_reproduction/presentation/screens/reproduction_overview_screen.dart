import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_feedback.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class ReproductionOverviewScreen extends StatefulWidget {
  const ReproductionOverviewScreen({
    this.farm,
    this.autoOpenCreate = false,
    this.embedded = false,
    super.key,
  });

  final FarmData? farm;
  final bool autoOpenCreate;
  final bool embedded;

  @override
  State<ReproductionOverviewScreen> createState() =>
      _ReproductionOverviewScreenState();
}

class _ReproductionOverviewScreenState
    extends State<ReproductionOverviewScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final HerdStorageService herdStorage = HerdStorageService();
  final AnimalStorageService animalStorage = AnimalStorageService();
  final AnimalReproductionStorageService reproductionStorage =
      AnimalReproductionStorageService();

  List<ReproductionAnimalContext> animals = [];
  bool isLoading = true;
  String? loadError;
  String search = '';

  int get totalFemales => animals.length;

  int get animalsWithRecords =>
      animals.where((context) => context.records.isNotEmpty).length;

  int get totalRecords =>
      animals.fold(0, (total, context) => total + context.records.length);

  int get pregnantAnimals => animals.where((context) {
    return context.records.any((record) {
      if (record.type != 'Diagnóstico de gestação') {
        return false;
      }

      final result = record.result.toLowerCase();
      return result.contains('prenhe') || result.contains('positivo');
    });
  }).length;

  List<ReproductionAnimalContext> get filteredAnimals {
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
      final loadedAnimals = <ReproductionAnimalContext>[];

      for (final farm in farms) {
        final groups = await herdStorage.loadGroups(farm.name);
        for (final group in groups) {
          final groupAnimals = await animalStorage.loadAnimals(
            farmName: farm.name,
            groupName: group.name,
          );
          for (final animal in groupAnimals) {
            if (!_isFemale(animal.sex)) continue;
            final records = await reproductionStorage.loadRecords(
              farmName: farm.name,
              groupName: group.name,
              animalId: animal.id,
            );
            loadedAnimals.add(
              ReproductionAnimalContext(
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

  bool _isFemale(String sex) {
    final normalized = sex.trim().toLowerCase();
    return normalized == 'fêmea' ||
        normalized == 'femea' ||
        normalized == 'female';
  }

  Future<void> openAnimal(ReproductionAnimalContext contextData) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AnimalReproductionListScreen(
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

    ReproductionAnimalContext? selected;
    if (animals.length == 1) {
      selected = animals.first;
    } else {
      selected = await showDialog<ReproductionAnimalContext>(
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
        builder: (_) => AnimalReproductionListScreen(
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
        label: const Text('Novo evento reprodutivo'),
      ),
      appBar: widget.embedded ? null : AppBar(
        title: Text(
          widget.farm == null
              ? 'Reprodução'
              : 'Reprodução — ${widget.farm!.name}',
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
                            const _ReproductionHeader(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _IndicatorCard(
                                  title: 'Fêmeas',
                                  value: totalFemales.toString(),
                                  subtitle:
                                      'Animais disponíveis para acompanhamento',
                                  icon: AtlasLivestockIcons.cow,
                                ),
                                _IndicatorCard(
                                  title: 'Com histórico',
                                  value: animalsWithRecords.toString(),
                                  subtitle: 'Animais com eventos reprodutivos',
                                  icon: Icons.history_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Registros',
                                  value: totalRecords.toString(),
                                  subtitle: 'Eventos reprodutivos cadastrados',
                                  icon: Icons.event_note_outlined,
                                ),
                                _IndicatorCard(
                                  title: 'Prenhes',
                                  value: pregnantAnimals.toString(),
                                  subtitle:
                                      'Diagnósticos positivos registrados',
                                  icon: Icons.favorite_outline,
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
                              'Animais para acompanhamento',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Selecione uma fêmea para consultar ou registrar inseminações, diagnósticos e partos.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            if (animals.isEmpty)
                              const _EmptyReproduction()
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

class ReproductionAnimalContext {
  const ReproductionAnimalContext({
    required this.farm,
    required this.group,
    required this.animal,
    required this.records,
  });

  final FarmData farm;
  final HerdGroupData group;
  final AnimalData animal;
  final List<AnimalReproductionData> records;

  AnimalReproductionData? get latestRecord {
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

class _ReproductionHeader extends StatelessWidget {
  const _ReproductionHeader();

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
            child: Icon(Icons.favorite_outline, color: Colors.white, size: 30),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central de Reprodução',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Acompanhe o histórico reprodutivo das matrizes de todas as fazendas.',
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
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
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

  final ReproductionAnimalContext contextData;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final latestRecord = contextData.latestRecord;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
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
                      'Brinco ${contextData.animal.tag} • ${contextData.farm.name} • ${contextData.group.name}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latestRecord == null
                          ? 'Nenhum registro reprodutivo'
                          : 'Último evento: ${latestRecord.type} em ${latestRecord.date}',
                      style: TextStyle(
                        color: latestRecord == null
                            ? Colors.orange.shade800
                            : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Chip(label: Text('${contextData.records.length} registros')),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReproduction extends StatelessWidget {
  const _EmptyReproduction();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.favorite_border, size: 52, color: Colors.black38),
              SizedBox(height: 14),
              Text(
                'Nenhuma fêmea cadastrada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Cadastre fazendas, lotes e animais do sexo feminino no módulo Rebanho.',
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
        child: Center(child: Text('Nenhum animal encontrado para esta busca.')),
      ),
    );
  }
}
