import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/strategy_center/domain/models/atlas_strategy_data.dart';

class AtlasStrategyCenterScreen extends StatefulWidget {
  const AtlasStrategyCenterScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasStrategyData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasStrategyCenterScreen> createState() {
    return _AtlasStrategyCenterScreenState();
  }
}

class _AtlasStrategyCenterScreenState extends State<AtlasStrategyCenterScreen> {
  String? selectedFarm;
  AtlasStrategyCategory? selectedCategory;

  AtlasStrategyData get data => widget.data;

  List<String> get farms {
    final result = <String>{
      ...data.objectives.map((item) => item.farmName),
      ...data.priorities.map((item) => item.farmName),
      ...data.initiatives.map((item) => item.farmName),
      ...data.risks.map((item) => item.farmName),
      ...data.opportunities.map((item) => item.farmName),
    }.toList()..sort();

    return result;
  }

  bool _matches(String farm, AtlasStrategyCategory category) {
    return (selectedFarm == null || selectedFarm == farm) &&
        (selectedCategory == null || selectedCategory == category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Central Estratégica',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: data.hasData
          ? ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _Hero(data: data),
                const SizedBox(height: 22),
                _Filters(
                  farms: farms,
                  selectedFarm: selectedFarm,
                  selectedCategory: selectedCategory,
                  onFarmChanged: (value) {
                    setState(() {
                      selectedFarm = value;
                    });
                  },
                  onCategoryChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _Title(
                  title: 'Objetivos estratégicos',
                  subtitle: 'Resultados que orientam a operação.',
                ),
                const SizedBox(height: 12),
                ...data.objectives
                    .where((item) => _matches(item.farmName, item.category))
                    .map(
                      (item) => _ItemCard(
                        icon: Icons.flag_outlined,
                        title: item.title,
                        subtitle:
                            '${item.farmName} · '
                            '${atlasStrategyCategoryLabel(item.category)}',
                        description: item.description,
                        trailing: '${item.progressPercent.toStringAsFixed(0)}%',
                        progress: item.progressPercent,
                        onOpenFarm: widget.onOpenFarm == null
                            ? null
                            : () {
                                widget.onOpenFarm!(item.farmName);
                              },
                      ),
                    ),
                const SizedBox(height: 24),
                _Title(
                  title: 'Prioridades',
                  subtitle: 'Temas que exigem execução imediata.',
                ),
                const SizedBox(height: 12),
                ...data.priorities
                    .where((item) => _matches(item.farmName, item.category))
                    .map(
                      (item) => _ItemCard(
                        icon: Icons.priority_high_outlined,
                        title: item.title,
                        subtitle:
                            '${item.farmName} · '
                            '${atlasStrategyPriorityLabel(item.priority)}',
                        description: item.description,
                        trailing: atlasStrategyItemStatusLabel(item.status),
                        progress: item.progressPercent,
                      ),
                    ),
                const SizedBox(height: 24),
                _Title(
                  title: 'Projetos e iniciativas',
                  subtitle: 'Planos que transformam estratégia em resultado.',
                ),
                const SizedBox(height: 12),
                ...data.initiatives
                    .where((item) => _matches(item.farmName, item.category))
                    .map(
                      (item) => _ItemCard(
                        icon: Icons.rocket_launch_outlined,
                        title: item.title,
                        subtitle:
                            '${item.farmName} · '
                            '${atlasStrategyItemStatusLabel(item.status)}',
                        description:
                            '${item.description}'
                            'Impacto: ${item.expectedImpact}',
                        trailing: '${item.progressPercent.toStringAsFixed(0)}%',
                        progress: item.progressPercent,
                      ),
                    ),
                const SizedBox(height: 24),
                _Title(
                  title: 'Riscos',
                  subtitle: 'Ameaças aos objetivos estratégicos.',
                ),
                const SizedBox(height: 12),
                ...data.risks
                    .where((item) => _matches(item.farmName, item.category))
                    .map(
                      (item) => _ItemCard(
                        icon: Icons.warning_amber_outlined,
                        title: item.title,
                        subtitle:
                            '${item.farmName} · '
                            'Impacto ${atlasStrategyRiskLabel(item.impact)}',
                        description:
                            '${item.description}'
                            'Mitigação: ${item.mitigation}',
                        trailing:
                            'P ${atlasStrategyRiskLabel(item.probability)}',
                      ),
                    ),
                const SizedBox(height: 24),
                _Title(
                  title: 'Oportunidades',
                  subtitle: 'Possibilidades de ganho identificadas.',
                ),
                const SizedBox(height: 12),
                ...data.opportunities
                    .where((item) => _matches(item.farmName, item.category))
                    .map(
                      (item) => _ItemCard(
                        icon: Icons.trending_up_outlined,
                        title: item.title,
                        subtitle:
                            '${item.farmName} · '
                            '${item.confidencePercent.toStringAsFixed(0)}% de confiança',
                        description:
                            '${item.description}'
                            'Recomendação: ${item.recommendation}',
                        trailing:
                            '${item.impactValue.toStringAsFixed(0)} '
                            '${item.impactUnit}',
                      ),
                    ),
                const SizedBox(height: 32),
              ],
            )
          : const Center(
              child: Text(
                'Nenhuma estratégia disponível.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data});

  final AtlasStrategyData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A43), Color(0xFF1E4976), Color(0xFF2F6F9F)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            color: Color(0xFFFFD180),
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.mission,
                  style: const TextStyle(
                    color: Color(0xFFFFD180),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.summary,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                data.score.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFFFFD180),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                atlasStrategyStatusLabel(data.status),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.onFarmChanged,
    required this.onCategoryChanged,
  });

  final List<String> farms;
  final String? selectedFarm;
  final AtlasStrategyCategory? selectedCategory;
  final ValueChanged<String?> onFarmChanged;
  final ValueChanged<AtlasStrategyCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedFarm,
                decoration: const InputDecoration(labelText: 'Fazenda'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as fazendas'),
                  ),
                  ...farms.map(
                    (farm) => DropdownMenuItem(value: farm, child: Text(farm)),
                  ),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<AtlasStrategyCategory?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Área estratégica',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as áreas'),
                  ),
                  ...AtlasStrategyCategory.values.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(atlasStrategyCategoryLabel(category)),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.trailing,
    this.progress,
    this.onOpenFarm,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String trailing;
  final double? progress;
  final VoidCallback? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1E4976)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF1E4976),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black54, height: 1.4),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      minHeight: 7,
                      value: progress! / 100,
                    ),
                  ],
                  if (onOpenFarm != null) ...[
                    const SizedBox(height: 10),
                    ActionChip(
                      label: const Text('Abrir fazenda'),
                      onPressed: onOpenFarm,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF1E4976),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
