import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/data/services/animal_nutrition_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalExecutivePanelScreen extends StatefulWidget {
  const AnimalExecutivePanelScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalExecutivePanelScreen> createState() =>
      _AnimalExecutivePanelScreenState();
}

class _AnimalExecutivePanelScreenState
    extends State<AnimalExecutivePanelScreen> {
  bool loading = true;

  int health = 0;
  int reproduction = 0;
  int weights = 0;
  int nutrition = 0;
  int score = 0;

  double latestWeight = 0;
  double gmd = 0;

  List<String> recommendations = <String>[];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final results = await Future.wait<dynamic>([
      AnimalHealthStorageService().loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      AnimalReproductionStorageService().loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      AnimalWeightStorageService().loadWeights(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      AnimalNutritionStorageService().load(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
    ]);

    final healthRecords = results[0] as List<dynamic>;
    final reproductionRecords = results[1] as List<dynamic>;
    final weightRecords = results[2] as List<dynamic>;
    final nutritionPlans = results[3] as List<dynamic>;

    weightRecords.sort(
      (first, second) => parseEnterpriseDate(
        first.date.toString(),
      ).compareTo(parseEnterpriseDate(second.date.toString())),
    );

    final currentWeight = weightRecords.isEmpty
        ? widget.animal.weight
        : (weightRecords.last.weight as num).toDouble();

    var calculatedGmd = 0.0;

    if (weightRecords.length >= 2) {
      final days = parseEnterpriseDate(weightRecords.last.date.toString())
          .difference(parseEnterpriseDate(weightRecords.first.date.toString()))
          .inDays;

      if (days > 0) {
        calculatedGmd =
            ((weightRecords.last.weight as num).toDouble() -
                (weightRecords.first.weight as num).toDouble()) /
            days;
      }
    }

    var calculatedScore = 40;
    if (weightRecords.length >= 2) calculatedScore += 15;
    if (healthRecords.isNotEmpty) calculatedScore += 10;
    if (reproductionRecords.isNotEmpty) calculatedScore += 10;
    if (nutritionPlans.isNotEmpty) calculatedScore += 10;
    if (calculatedGmd > 0) {
      calculatedScore += 10;
    } else if (calculatedGmd < 0) {
      calculatedScore -= 15;
    }
    if (widget.animal.bodyConditionScore > 0) {
      calculatedScore += 5;
    }

    calculatedScore = calculatedScore.clamp(0, 100).toInt();

    final generatedRecommendations = <String>[
      if (weightRecords.length < 2)
        'Cadastre duas ou mais pesagens para habilitar tendência e projeções.',
      if (calculatedGmd < 0) 'Prioridade alta: investigar perda de peso.',
      if (healthRecords.isEmpty)
        'Completar histórico sanitário e calendário preventivo.',
      if (reproductionRecords.isEmpty &&
          widget.animal.sex.toLowerCase().contains('f'))
        'Cadastrar situação e histórico reprodutivo.',
      if (nutritionPlans.isEmpty) 'Cadastrar dieta e meta nutricional.',
      if (calculatedScore >= 75)
        'Animal com boa completude de dados e desempenho global.',
      if (calculatedScore < 50)
        'O score está baixo; priorize qualidade dos dados e riscos críticos.',
    ];

    if (!mounted) return;

    setState(() {
      health = healthRecords.length;
      reproduction = reproductionRecords.length;
      weights = weightRecords.length;
      nutrition = nutritionPlans.length;
      latestWeight = currentWeight;
      gmd = calculatedGmd;
      score = calculatedScore;
      recommendations = generatedRecommendations;
      loading = false;
    });
  }

  String get level {
    if (score >= 80) return 'Excelente';
    if (score >= 65) return 'Bom';
    if (score >= 45) return 'Atenção';
    return 'Crítico';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel executivo do animal'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                        title: 'Visão executiva — ${widget.animal.displayName}',
                        subtitle:
                            'Score, valor técnico, riscos e próximas ações integradas.',
                        icon: Icons.dashboard_customize_outlined,
                      ),
                      const SizedBox(height: 18),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final scoreWidget = SizedBox(
                                width: 130,
                                height: 130,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: score / 100,
                                      strokeWidth: 13,
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$score',
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(level),
                                      ],
                                    ),
                                  ],
                                ),
                              );

                              final description = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Score geral do animal',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Combina completude dos dados, crescimento, sanidade, reprodução e nutrição.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 14),
                                  LinearProgressIndicator(
                                    value: score / 100,
                                    minHeight: 10,
                                  ),
                                ],
                              );

                              if (constraints.maxWidth < 650) {
                                return Column(
                                  children: [
                                    scoreWidget,
                                    const SizedBox(height: 20),
                                    description,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  scoreWidget,
                                  const SizedBox(width: 24),
                                  Expanded(child: description),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Peso atual',
                            value: '${_decimal(latestWeight, 1)} kg',
                            subtitle: 'Último dado disponível',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'GMD',
                            value: '${_decimal(gmd, 3)} kg/dia',
                            subtitle: 'Tendência histórica',
                            icon: Icons.trending_up_outlined,
                            warning: gmd < 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Sanidade',
                            value: '$health registros',
                            subtitle: 'Rastreabilidade clínica',
                            icon: Icons.health_and_safety_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Reprodução',
                            value: '$reproduction registros',
                            subtitle: 'Histórico reprodutivo',
                            icon: Icons.favorite_outline,
                          ),
                          EnterpriseMetricCard(
                            title: 'Pesagens',
                            value: '$weights',
                            subtitle: 'Base de desempenho',
                            icon: Icons.auto_graph_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Nutrição',
                            value: '$nutrition planos',
                            subtitle: 'Dietas registradas',
                            icon: Icons.restaurant_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      EnterpriseInsightCard(
                        title: 'Próximas ações sugeridas',
                        items: recommendations.isEmpty
                            ? const [
                                'Nenhuma ação prioritária foi identificada.',
                              ]
                            : recommendations,
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseInsightCard(
                        title: 'Interpretação estratégica',
                        icon: Icons.business_center_outlined,
                        items: [
                          'O score é um indicador de apoio e deve ser interpretado junto com objetivos do lote e da fazenda.',
                          'Dados mais completos aumentam a confiança das recomendações.',
                          'A prioridade operacional deve combinar risco, impacto econômico e urgência.',
                        ],
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _decimal(double value, int decimals) {
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }
}
