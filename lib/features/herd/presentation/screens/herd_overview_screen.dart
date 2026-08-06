import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_list_screen.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/herd/presentation/screens/herd_list_screen.dart';

class HerdOverviewScreen extends StatefulWidget {
  const HerdOverviewScreen({super.key});

  @override
  State<HerdOverviewScreen> createState() => _HerdOverviewScreenState();
}

class _HerdOverviewScreenState extends State<HerdOverviewScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final HerdStorageService herdStorage = HerdStorageService();
  final AnimalStorageService animalStorage = AnimalStorageService();

  List<HerdFarmOverview> overviews = [];
  bool isLoading = true;

  int get totalFarms => overviews.length;

  int get totalGroups {
    return overviews.fold(0, (total, overview) => total + overview.groups);
  }

  int get totalAnimals {
    return overviews.fold(0, (total, overview) => total + overview.animals);
  }

  int get totalActiveAnimals {
    return overviews.fold(
      0,
      (total, overview) => total + overview.activeAnimals,
    );
  }

  double get averageWeight {
    var totalWeight = 0.0;
    var animalsWithWeight = 0;

    for (final overview in overviews) {
      totalWeight += overview.totalWeight;
      animalsWithWeight += overview.animalsWithWeight;
    }

    if (animalsWithWeight == 0) {
      return 0;
    }

    return totalWeight / animalsWithWeight;
  }

  @override
  void initState() {
    super.initState();
    loadOverview();
  }

  Future<void> loadOverview() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final farms = await farmStorage.loadFarms();
    final loadedOverviews = <HerdFarmOverview>[];

    for (final farm in farms) {
      final groups = await herdStorage.loadGroups(farm.name);
      final animals = <AnimalData>[];

      for (final group in groups) {
        final groupAnimals = await animalStorage.loadAnimals(
          farmName: farm.name,
          groupName: group.name,
        );
        animals.addAll(groupAnimals);
      }

      loadedOverviews.add(
        HerdFarmOverview.fromData(
          farm: farm,
          groups: groups,
          animals: animals,
        ),
      );
    }

    loadedOverviews.sort((first, second) {
      return second.animals.compareTo(first.animals);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      overviews = loadedOverviews;
      isLoading = false;
    });
  }

  Future<void> openFarm(HerdFarmOverview overview) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return HerdListScreen(farm: overview.farm);
        },
      ),
    );

    await loadOverview();
  }

  Future<void> openFarms() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const FarmListScreen();
        },
      ),
    );

    await loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Rebanho'),
        actions: [
          IconButton(
            tooltip: 'Atualizar rebanho',
            onPressed: isLoading ? null : loadOverview,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadOverview,
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
                            const HerdOverviewHeader(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                HerdOverviewIndicator(
                                  title: 'Fazendas',
                                  value: totalFarms.toString(),
                                  subtitle: 'Propriedades com gestão disponível',
                                  icon: Icons.landscape_outlined,
                                ),
                                HerdOverviewIndicator(
                                  title: 'Lotes',
                                  value: totalGroups.toString(),
                                  subtitle: 'Grupos de manejo cadastrados',
                                  icon: Icons.groups_outlined,
                                ),
                                HerdOverviewIndicator(
                                  title: 'Animais',
                                  value: totalAnimals.toString(),
                                  subtitle: 'Cadastros individuais no Atlas',
                                  icon: Icons.pets_outlined,
                                ),
                                HerdOverviewIndicator(
                                  title: 'Ativos',
                                  value: totalActiveAnimals.toString(),
                                  subtitle: 'Animais atualmente no rebanho',
                                  icon: Icons.check_circle_outline,
                                ),
                                HerdOverviewIndicator(
                                  title: 'Peso médio',
                                  value: totalAnimals == 0
                                      ? '—'
                                      : '${averageWeight.toStringAsFixed(0)} kg',
                                  subtitle: 'Média dos animais com peso',
                                  icon: Icons.monitor_weight_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rebanho por fazenda',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Escolha uma propriedade para gerenciar lotes e animais.',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: openFarms,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                  ),
                                  icon: const Icon(Icons.add_business_outlined),
                                  label: const Text('Gerenciar fazendas'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (overviews.isEmpty)
                              EmptyHerdOverview(onOpenFarms: openFarms)
                            else
                              ...overviews.map(
                                (overview) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: HerdFarmCard(
                                    overview: overview,
                                    onOpen: () {
                                      openFarm(overview);
                                    },
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

class HerdFarmOverview {
  const HerdFarmOverview({
    required this.farm,
    required this.groups,
    required this.animals,
    required this.activeAnimals,
    required this.females,
    required this.males,
    required this.totalWeight,
    required this.animalsWithWeight,
  });

  final FarmData farm;
  final int groups;
  final int animals;
  final int activeAnimals;
  final int females;
  final int males;
  final double totalWeight;
  final int animalsWithWeight;

  double get averageWeight {
    if (animalsWithWeight == 0) {
      return 0;
    }

    return totalWeight / animalsWithWeight;
  }

  factory HerdFarmOverview.fromData({
    required FarmData farm,
    required List<HerdGroupData> groups,
    required List<AnimalData> animals,
  }) {
    final activeAnimals = animals.where((animal) {
      return animal.status == 'Ativo';
    }).length;
    final females = animals.where((animal) {
      return animal.sex == 'Fêmea';
    }).length;
    final males = animals.where((animal) {
      return animal.sex == 'Macho';
    }).length;
    final animalsWithWeight = animals.where((animal) {
      return animal.weight > 0;
    }).toList();

    return HerdFarmOverview(
      farm: farm,
      groups: groups.length,
      animals: animals.length,
      activeAnimals: activeAnimals,
      females: females,
      males: males,
      totalWeight: animalsWithWeight.fold<double>(
        0,
        (total, animal) => total + animal.weight,
      ),
      animalsWithWeight: animalsWithWeight.length,
    );
  }
}

class HerdOverviewHeader extends StatelessWidget {
  const HerdOverviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.pets_outlined, color: Colors.white, size: 52),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central de Gestão do Rebanho',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Controle lotes, animais, pesos e histórico por propriedade.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HerdOverviewIndicator extends StatelessWidget {
  const HerdOverviewIndicator({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF1B5E20), size: 29),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class HerdFarmCard extends StatelessWidget {
  const HerdFarmCard({
    required this.overview,
    required this.onOpen,
    super.key,
  });

  final HerdFarmOverview overview;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: Color(0xFF1B5E20),
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.farm.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${overview.farm.city} - ${overview.farm.state}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        HerdFarmMetric(
                          icon: Icons.groups_outlined,
                          label: '${overview.groups} lotes',
                        ),
                        HerdFarmMetric(
                          icon: Icons.pets_outlined,
                          label: '${overview.animals} animais',
                        ),
                        HerdFarmMetric(
                          icon: Icons.check_circle_outline,
                          label: '${overview.activeAnimals} ativos',
                        ),
                        HerdFarmMetric(
                          icon: Icons.female_outlined,
                          label: '${overview.females} fêmeas',
                        ),
                        HerdFarmMetric(
                          icon: Icons.male_outlined,
                          label: '${overview.males} machos',
                        ),
                        HerdFarmMetric(
                          icon: Icons.monitor_weight_outlined,
                          label: overview.animalsWithWeight == 0
                              ? 'Sem pesos cadastrados'
                              : '${overview.averageWeight.toStringAsFixed(0)} kg de média',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

class HerdFarmMetric extends StatelessWidget {
  const HerdFarmMetric({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class EmptyHerdOverview extends StatelessWidget {
  const EmptyHerdOverview({required this.onOpenFarms, super.key});

  final VoidCallback onOpenFarms;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.landscape_outlined,
                size: 52,
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nenhuma fazenda cadastrada',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              const Text(
                'Cadastre uma propriedade para começar a gestão do rebanho.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpenFarms,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar fazenda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
