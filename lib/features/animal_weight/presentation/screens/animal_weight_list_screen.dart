import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/domain/services/animal_weight_event_service.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_form_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalWeightListScreen extends StatefulWidget {
  const AnimalWeightListScreen({
    required this.animal,
    required this.farm,
    required this.group,
    this.autoOpenCreate = false,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final bool autoOpenCreate;

  @override
  State<AnimalWeightListScreen> createState() => _AnimalWeightListScreenState();
}

class _AnimalWeightListScreenState extends State<AnimalWeightListScreen> {
  final AnimalWeightStorageService storage = AnimalWeightStorageService();
  final AnimalWeightEnterpriseService enterprise =
      AnimalWeightEnterpriseService();

  final AnimalWeightEventService eventService =
      const AnimalWeightEventService();

  List<AnimalWeightData> weights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await loadWeights();
    if (widget.autoOpenCreate && mounted) {
      await openWeightForm();
    }
  }

  double get currentWeight {
    if (weights.isEmpty) {
      return widget.animal.weight;
    }

    return weights.first.weight;
  }

  double get minimumWeight {
    if (weights.isEmpty) {
      return widget.animal.weight;
    }

    return weights.map((record) => record.weight).reduce((first, second) {
      return first < second ? first : second;
    });
  }

  double get maximumWeight {
    if (weights.isEmpty) {
      return widget.animal.weight;
    }

    return weights.map((record) => record.weight).reduce((first, second) {
      return first > second ? first : second;
    });
  }

  double? get latestVariation {
    if (weights.length < 2) {
      return null;
    }

    return weights[0].weight - weights[1].weight;
  }

  Future<void> loadWeights() async {
    List<AnimalWeightData> loaded = [];
    if (widget.animal.id.trim().isNotEmpty &&
        widget.farm.id?.trim().isNotEmpty == true) {
      try {
        loaded = await enterprise.listWeights(animalId: widget.animal.id);
        await storage.saveWeights(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
          weights: loaded,
        );
      } catch (_) {
        loaded = await storage.loadWeights(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
          preferRemote: false,
        );
      }
    } else {
      loaded = await storage.loadWeights(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      );
    }

    if (!mounted) return;
    setState(() {
      weights = loaded;
      sortWeights();
      isLoading = false;
    });
  }

  Future<void> saveWeights() async {
    await storage.saveWeights(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      weights: weights,
    );
  }

  void sortWeights() {
    weights.sort((first, second) {
      final firstDate = parseDate(first.date);
      final secondDate = parseDate(second.date);

      return secondDate.compareTo(firstDate);
    });
  }

  DateTime parseDate(String value) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return DateTime(1900);
    }

    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = int.tryParse(parts[2]) ?? 1900;

    return DateTime(year, month, day);
  }

  Future<void> openWeightForm() async {
    final newWeight = await Navigator.push<AnimalWeightData>(
      context,
      MaterialPageRoute<AnimalWeightData>(
        builder: (context) {
          return const AnimalWeightFormScreen();
        },
      ),
    );

    if (newWeight == null || !mounted) {
      return;
    }

    AnimalWeightData savedWeight = newWeight;
    if (widget.animal.id.trim().isNotEmpty &&
        widget.farm.id?.trim().isNotEmpty == true) {
      try {
        savedWeight = await enterprise.createWeight(
          animalId: widget.animal.id,
          weight: savedWeight,
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível sincronizar: $error')),
        );
        return;
      }
    }

    setState(() {
      weights.add(savedWeight);
      sortWeights();
    });
    await saveWeights();

    await eventService.publishWeightRecorded(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      animalName: widget.animal.displayName,
      weight: newWeight,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesagem registrada com sucesso.')),
    );
  }

  Future<void> editWeight(AnimalWeightData weightRecord) async {
    if (weightRecord.isRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesagens sincronizadas não podem ser editadas. Registre uma nova pesagem para preservar o histórico.',
          ),
        ),
      );
      return;
    }
    final editedWeight = await Navigator.push<AnimalWeightData>(
      context,
      MaterialPageRoute<AnimalWeightData>(
        builder: (context) {
          return AnimalWeightFormScreen(weightRecord: weightRecord);
        },
      ),
    );

    if (editedWeight == null || !mounted) {
      return;
    }

    final recordIndex = weights.indexWhere(
      (item) => item.id == weightRecord.id,
    );

    if (recordIndex == -1) {
      return;
    }

    setState(() {
      weights[recordIndex] = editedWeight;
      sortWeights();
    });

    await saveWeights();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesagem atualizada com sucesso.')),
    );
  }

  Future<void> deleteWeight(AnimalWeightData weightRecord) async {
    if (weightRecord.isRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesagens sincronizadas não podem ser excluídas. O histórico oficial é imutável.',
          ),
        ),
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir pesagem'),
          content: Text(
            'Deseja excluir a pesagem registrada em '
            '${weightRecord.date}?',
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

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      weights.removeWhere((item) => item.id == weightRecord.id);
    });

    await saveWeights();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesagem excluída com sucesso.')),
    );
  }

  double? calculateVariation(int index) {
    if (index >= weights.length - 1) {
      return null;
    }

    return weights[index].weight - weights[index + 1].weight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesagens')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openWeightForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova pesagem'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        widget.animal.displayName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Brinco ${widget.animal.tag} · '
                        '${widget.farm.name}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          WeightSummaryCard(
                            title: 'Peso atual',
                            value: '${formatWeight(currentWeight)} kg',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          WeightSummaryCard(
                            title: 'Menor peso',
                            value: '${formatWeight(minimumWeight)} kg',
                            icon: Icons.south_east_outlined,
                          ),
                          WeightSummaryCard(
                            title: 'Maior peso',
                            value: '${formatWeight(maximumWeight)} kg',
                            icon: Icons.north_east_outlined,
                          ),
                          WeightSummaryCard(
                            title: 'Última variação',
                            value: latestVariation == null
                                ? '—'
                                : formatVariation(latestVariation!),
                            icon: latestVariation == null
                                ? Icons.horizontal_rule
                                : latestVariation! >= 0
                                ? Icons.trending_up_outlined
                                : Icons.trending_down_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Histórico de pesagens',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acompanhe a evolução do peso ao longo do tempo.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      if (weights.isEmpty)
                        const EmptyWeightsMessage()
                      else
                        ...List.generate(weights.length, (index) {
                          final record = weights[index];
                          final variation = calculateVariation(index);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: WeightRecordCard(
                              record: record,
                              variation: variation,
                              onEdit: () {
                                editWeight(record);
                              },
                              onDelete: () {
                                deleteWeight(record);
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({
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
      width: 215,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 27, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(color: Colors.black54)),
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

class WeightRecordCard extends StatelessWidget {
  const WeightRecordCard({
    required this.record,
    required this.variation,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AnimalWeightData record;
  final double? variation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = (variation ?? 0) >= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: Color(0xFF1B5E20),
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatWeight(record.weight)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 17,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          record.date,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    if (record.bodyConditionScore > 0 ||
                        record.source.isNotEmpty ||
                        record.equipment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (record.bodyConditionScore > 0)
                            'ECC ${formatWeight(record.bodyConditionScore)}',
                          if (record.source.isNotEmpty) record.source,
                          if (record.equipment.isNotEmpty) record.equipment,
                        ].join(' · '),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(record.notes, style: const TextStyle(height: 1.4)),
                    ],
                  ],
                ),
              ),
              if (variation != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isPositive
                            ? const Color(0xFF1B5E20)
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatVariation(variation!),
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF1B5E20)
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                          Text('Editar pesagem'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir pesagem'),
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

class EmptyWeightsMessage extends StatelessWidget {
  const EmptyWeightsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 60,
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma pesagem registrada.',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre a primeira pesagem deste animal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }

  return weight.toStringAsFixed(1).replaceAll('.', ',');
}

String formatVariation(double variation) {
  final String symbol = variation > 0 ? '+' : '';

  return '$symbol${formatWeight(variation)} kg';
}
