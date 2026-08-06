import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal/presentation/screens/animal_list_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/herd/presentation/screens/herd_group_form_screen.dart';

class HerdListScreen extends StatefulWidget {
  const HerdListScreen({required this.farm, super.key});

  final FarmData farm;

  @override
  State<HerdListScreen> createState() => _HerdListScreenState();
}

class _HerdListScreenState extends State<HerdListScreen> {
  final HerdStorageService herdStorage = HerdStorageService();
  final HerdEnterpriseService enterprise = HerdEnterpriseService();
  final AnimalStorageService animalStorage = AnimalStorageService();

  List<HerdGroupData> groups = <HerdGroupData>[];
  Map<String, HerdGroupStatistics> groupStatistics = <String, HerdGroupStatistics>{};
  bool isLoading = true;
  bool usingOfflineCache = false;

  String get farmId => widget.farm.id?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  int get totalRegisteredAnimals => groupStatistics.values.fold(
        0,
        (total, statistics) => total + statistics.totalAnimals,
      );

  int get totalActiveAnimals => groupStatistics.values.fold(
        0,
        (total, statistics) => total + statistics.activeAnimals,
      );

  int get totalFemales => groupStatistics.values.fold(
        0,
        (total, statistics) => total + statistics.females,
      );

  int get totalMales => groupStatistics.values.fold(
        0,
        (total, statistics) => total + statistics.males,
      );

  double get overallAverageWeight {
    var totalWeight = 0.0;
    var animalsWithWeight = 0;
    for (final statistics in groupStatistics.values) {
      totalWeight += statistics.totalWeight;
      animalsWithWeight += statistics.animalsWithWeight;
    }
    return animalsWithWeight == 0 ? 0 : totalWeight / animalsWithWeight;
  }

  Future<void> loadDashboard() async {
    if (mounted) setState(() => isLoading = true);

    List<HerdGroupData> loadedGroups;
    var offline = false;

    try {
      if (farmId.isEmpty) {
        throw const AtlasEnterpriseApiException(
          'Esta fazenda ainda não possui ID remoto.',
        );
      }
      loadedGroups = await enterprise.listGroups(farmId);
      await herdStorage.saveGroups(
        farmName: widget.farm.name,
        farmId: farmId,
        groups: loadedGroups,
      );
    } on AtlasEnterpriseApiException catch (error) {
      loadedGroups = await herdStorage.loadGroups(
        widget.farm.name,
        farmId: farmId,
      );
      offline = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'API indisponível. Exibindo os lotes salvos localmente. ${error.message}',
            ),
          ),
        );
      }
    }

    final statisticsEntries = await Future.wait(
      loadedGroups.map((group) async {
        final animals = await animalStorage.loadAnimals(
          farmName: widget.farm.name,
          groupName: group.name,
        );
        return MapEntry(group.name, HerdGroupStatistics.fromAnimals(animals));
      }),
    );

    if (!mounted) return;
    setState(() {
      groups = loadedGroups;
      groupStatistics = Map<String, HerdGroupStatistics>.fromEntries(
        statisticsEntries,
      );
      usingOfflineCache = offline;
      isLoading = false;
    });
  }

  Future<void> openGroupForm() async {
    final draft = await Navigator.push<HerdGroupData>(
      context,
      MaterialPageRoute<HerdGroupData>(
        builder: (context) => const HerdGroupFormScreen(),
      ),
    );
    if (draft == null || !mounted) return;
    if (farmId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta fazenda ainda não possui ID remoto.')),
      );
      return;
    }

    try {
      final created = await enterprise.createGroup(farmId: farmId, group: draft);
      await loadDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.name} foi cadastrado com sucesso.')),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> editGroup(HerdGroupData group) async {
    final draft = await Navigator.push<HerdGroupData>(
      context,
      MaterialPageRoute<HerdGroupData>(
        builder: (context) => HerdGroupFormScreen(group: group),
      ),
    );
    if (draft == null || !mounted) return;

    try {
      final updated = await enterprise.updateGroup(draft);
      await loadDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.name} foi atualizado com sucesso.')),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> deleteGroup(HerdGroupData group) async {
    final statistics =
        groupStatistics[group.name] ?? const HerdGroupStatistics.empty();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lote'),
        content: Text(
          statistics.totalAnimals > 0
              ? '${group.name} possui ${statistics.totalAnimals} animais. Mova os animais antes de inativar o lote.'
              : 'Tem certeza de que deseja inativar ${group.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: statistics.totalAnimals > 0
                ? null
                : () => Navigator.pop(dialogContext, true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await enterprise.deleteGroup(group.id);
      await loadDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${group.name} foi inativado.')),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> openGroup(HerdGroupData group) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimalListScreen(farm: widget.farm, group: group),
      ),
    );
    await loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rebanho'),
        actions: [
          if (usingOfflineCache)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.cloud_off_outlined),
            ),
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading || usingOfflineCache ? null : openGroupForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo lote'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1150),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadDashboard,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        HerdDashboardHeader(
                          farm: widget.farm,
                          totalAnimals: totalRegisteredAnimals,
                          totalGroups: groups.length,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Indicadores do rebanho',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dados calculados com base nos animais individuais cadastrados.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            HerdIndicatorCard(
                              title: 'Animais cadastrados',
                              value: totalRegisteredAnimals.toString(),
                              subtitle: 'Somatório de todos os lotes',
                              icon: Icons.pets_outlined,
                            ),
                            HerdIndicatorCard(
                              title: 'Animais ativos',
                              value: totalActiveAnimals.toString(),
                              subtitle: totalRegisteredAnimals == 0
                                  ? 'Nenhum animal cadastrado'
                                  : '${calculatePercentage(totalActiveAnimals, totalRegisteredAnimals)}% do rebanho',
                              icon: Icons.check_circle_outline,
                            ),
                            HerdIndicatorCard(
                              title: 'Fêmeas',
                              value: totalFemales.toString(),
                              subtitle: totalRegisteredAnimals == 0
                                  ? 'Nenhum animal cadastrado'
                                  : '${calculatePercentage(totalFemales, totalRegisteredAnimals)}% do rebanho',
                              icon: Icons.female_outlined,
                            ),
                            HerdIndicatorCard(
                              title: 'Machos',
                              value: totalMales.toString(),
                              subtitle: totalRegisteredAnimals == 0
                                  ? 'Nenhum animal cadastrado'
                                  : '${calculatePercentage(totalMales, totalRegisteredAnimals)}% do rebanho',
                              icon: Icons.male_outlined,
                            ),
                            HerdIndicatorCard(
                              title: 'Peso médio',
                              value: totalRegisteredAnimals == 0
                                  ? '—'
                                  : '${formatWeight(overallAverageWeight)} kg',
                              subtitle: 'Média dos animais cadastrados',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            HerdIndicatorCard(
                              title: 'Lotes',
                              value: groups.length.toString(),
                              subtitle: groups.isEmpty
                                  ? 'Nenhum lote cadastrado'
                                  : 'Grupos de manejo ativos',
                              icon: Icons.groups_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Lotes do rebanho',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text('${groups.length} lotes', style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Clique em um lote para visualizar e cadastrar animais.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        if (groups.isEmpty)
                          const EmptyHerdMessage()
                        else
                          ...groups.map((group) {
                            final statistics = groupStatistics[group.name] ??
                                const HerdGroupStatistics.empty();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: HerdGroupCard(
                                group: group,
                                statistics: statistics,
                                onOpen: () => openGroup(group),
                                onEdit: usingOfflineCache ? () {} : () => editGroup(group),
                                onDelete: usingOfflineCache ? () {} : () => deleteGroup(group),
                              ),
                            );
                          }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class HerdDashboardHeader extends StatelessWidget {
  const HerdDashboardHeader({
    required this.farm,
    required this.totalAnimals,
    required this.totalGroups,
    super.key,
  });

  final FarmData farm;
  final int totalAnimals;
  final int totalGroups;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.pets_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestão do rebanho',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  farm.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  '${farm.city} - ${farm.state}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              HerdHeaderMetric(
                value: totalAnimals.toString(),
                label: 'animais',
              ),
              HerdHeaderMetric(value: totalGroups.toString(), label: 'lotes'),
            ],
          ),
        ],
      ),
    );
  }
}

class HerdHeaderMetric extends StatelessWidget {
  const HerdHeaderMetric({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class HerdIndicatorCard extends StatelessWidget {
  const HerdIndicatorCard({
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
      width: 255,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
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

class HerdGroupCard extends StatelessWidget {
  const HerdGroupCard({
    required this.group,
    required this.statistics,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final HerdGroupData group;
  final HerdGroupStatistics statistics;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFF1B5E20),
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.category} · ${group.paddock}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: [
                        HerdGroupInformation(
                          icon: Icons.pets_outlined,
                          text: '${statistics.totalAnimals} cadastrados',
                        ),
                        HerdGroupInformation(
                          icon: Icons.check_circle_outline,
                          text: '${statistics.activeAnimals} ativos',
                        ),
                        HerdGroupInformation(
                          icon: Icons.female_outlined,
                          text: '${statistics.females} fêmeas',
                        ),
                        HerdGroupInformation(
                          icon: Icons.male_outlined,
                          text: '${statistics.males} machos',
                        ),
                        HerdGroupInformation(
                          icon: Icons.monitor_weight_outlined,
                          text: statistics.totalAnimals == 0
                              ? 'Sem peso individual'
                              : '${formatWeight(statistics.averageWeight)} kg de média',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statistics.totalAnimals > 0
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statistics.totalAnimals > 0
                      ? '${statistics.totalAnimals} animais'
                      : 'Lote vazio',
                  style: TextStyle(
                    color: statistics.totalAnimals > 0
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF8D6E00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                          SizedBox(width: 10),
                          Text('Editar lote'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir lote'),
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
}

class HerdGroupInformation extends StatelessWidget {
  const HerdGroupInformation({
    required this.icon,
    required this.text,
    super.key,
  });

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

class EmptyHerdMessage extends StatelessWidget {
  const EmptyHerdMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(Icons.groups_outlined, size: 60, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'Nenhum lote cadastrado.',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Cadastre o primeiro lote para organizar o rebanho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class HerdGroupStatistics {
  const HerdGroupStatistics({
    required this.totalAnimals,
    required this.activeAnimals,
    required this.females,
    required this.males,
    required this.totalWeight,
    required this.animalsWithWeight,
  });

  const HerdGroupStatistics.empty()
    : totalAnimals = 0,
      activeAnimals = 0,
      females = 0,
      males = 0,
      totalWeight = 0,
      animalsWithWeight = 0;

  final int totalAnimals;
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

  factory HerdGroupStatistics.fromAnimals(List<AnimalData> animals) {
    final activeAnimals = animals.where((animal) => animal.status == 'Ativo');

    final females = animals.where((animal) => animal.sex == 'Fêmea');

    final males = animals.where((animal) => animal.sex == 'Macho');

    final animalsWithWeight = animals.where((animal) => animal.weight > 0);

    final totalWeight = animalsWithWeight.fold<double>(
      0,
      (total, animal) => total + animal.weight,
    );

    return HerdGroupStatistics(
      totalAnimals: animals.length,
      activeAnimals: activeAnimals.length,
      females: females.length,
      males: males.length,
      totalWeight: totalWeight,
      animalsWithWeight: animalsWithWeight.length,
    );
  }
}

int calculatePercentage(int value, int total) {
  if (total == 0) {
    return 0;
  }

  return ((value / total) * 100).round();
}

String formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }

  return weight.toStringAsFixed(1).replaceAll('.', ',');
}
