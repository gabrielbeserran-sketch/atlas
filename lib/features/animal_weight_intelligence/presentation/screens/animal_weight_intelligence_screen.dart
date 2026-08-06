import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_list_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalWeightIntelligenceScreen extends StatefulWidget {
  const AnimalWeightIntelligenceScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalWeightIntelligenceScreen> createState() =>
      _AnimalWeightIntelligenceScreenState();
}

class _AnimalWeightIntelligenceScreenState
    extends State<AnimalWeightIntelligenceScreen> {
  final AnimalWeightStorageService storage =
      AnimalWeightStorageService();

  List<AnimalWeightData> data = <AnimalWeightData>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final loaded = await storage.loadWeights(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseEnterpriseDate(
        first.date,
      ).compareTo(parseEnterpriseDate(second.date)),
    );

    if (!mounted) return;

    setState(() {
      data = loaded;
      loading = false;
    });
  }

  double get current =>
      data.isEmpty ? widget.animal.weight : data.last.weight;

  double? get gmd {
    if (data.length < 2) return null;

    final days = parseEnterpriseDate(data.last.date)
        .difference(parseEnterpriseDate(data.first.date))
        .inDays;

    if (days <= 0) return null;
    return (data.last.weight - data.first.weight) / days;
  }

  double? project(int days) {
    final gain = gmd;
    if (gain == null) return null;
    return math.max(0.0, current + gain * days);
  }

  String kg(double? value) {
    if (value == null) return 'Dados insuficientes';
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  Future<void> manage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AnimalWeightListScreen(
          animal: widget.animal,
          farm: widget.farm,
          group: widget.group,
        ),
      ),
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    final gain = gmd;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesagens inteligentes'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : manage,
        icon: const Icon(Icons.monitor_weight_outlined),
        label: const Text('Gerenciar pesagens'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title:
                            'Desempenho de ${widget.animal.displayName}',
                        subtitle:
                            'GMD, tendência, projeção e consistência do crescimento.',
                        icon: Icons.auto_graph_outlined,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Peso atual',
                            value: kg(current),
                            subtitle: data.isEmpty
                                ? 'Peso cadastral'
                                : 'Pesagem de ${data.last.date}',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'GMD histórico',
                            value: gain == null
                                ? 'Dados insuficientes'
                                : '${gain.toStringAsFixed(3).replaceAll('.', ',')} kg/dia',
                            subtitle: 'Primeira à última pesagem',
                            icon: Icons.trending_up_outlined,
                            warning: gain != null && gain < 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Projeção 30 dias',
                            value: kg(project(30)),
                            subtitle: 'Estimativa linear',
                            icon: Icons.query_stats_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Projeção 90 dias',
                            value: kg(project(90)),
                            subtitle: 'Estimativa linear',
                            icon: Icons.timeline_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Histórico',
                            value: '${data.length} pesagens',
                            subtitle:
                                'Qualidade: ${_qualityLabel()}',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Variação total',
                            value: data.length < 2
                                ? 'Dados insuficientes'
                                : kg(
                                    data.last.weight -
                                        data.first.weight,
                                  ),
                            subtitle: 'Do início ao fim da série',
                            icon: Icons.compare_arrows_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      EnterpriseInsightCard(
                        title: 'Leitura de desempenho',
                        items: [
                          if (data.length < 2)
                            'Cadastre ao menos duas pesagens em datas diferentes.',
                          if (gain != null && gain < 0)
                            'Há perda de peso. Avalie consumo, sanidade, competição e mudança de lote.',
                          if (gain != null && gain >= 0 && gain < 0.1)
                            'O ganho é baixo; revise a meta da categoria e a estratégia nutricional.',
                          if (gain != null && gain >= 0.1)
                            'O animal apresenta tendência positiva de crescimento.',
                          if (data.length >= 4)
                            'A série possui dados suficientes para acompanhar tendência com maior confiança.',
                        ],
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Série de pesagens',
                        'Evolução cronológica do peso.',
                      ),
                      const SizedBox(height: 12),
                      if (data.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text(
                              'Nenhuma pesagem cadastrada.',
                            ),
                          ),
                        )
                      else
                        ...data.reversed.take(12).map(
                              (record) => Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(
                                      Icons.monitor_weight_outlined,
                                    ),
                                  ),
                                  title: Text(kg(record.weight)),
                                  subtitle: Text(
                                    record.notes.isEmpty
                                        ? record.date
                                        : '${record.date} • ${record.notes}',
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _qualityLabel() {
    if (data.length >= 4) return 'Boa';
    if (data.length >= 2) return 'Intermediária';
    return 'Baixa';
  }
}
