import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/autonomous_consultant/presentation/screens/atlas_autonomous_consultant_screen.dart';
import 'package:flutter/services.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_request.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/services/atlas_optimization_engine.dart';
import 'package:projeto_atlas/features/optimization_engine/presentation/screens/atlas_optimization_result_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasOptimizationScreen extends StatefulWidget {
  const AtlasOptimizationScreen({super.key});

  @override
  State<AtlasOptimizationScreen> createState() {
    return _AtlasOptimizationScreenState();
  }
}

class _AtlasOptimizationScreenState extends State<AtlasOptimizationScreen> {
  final formKey = GlobalKey<FormState>();

  final maxInvestmentController = TextEditingController(text: '100000');

  final maxHerdExpansionController = TextEditingController(text: '100');

  bool isLoading = true;
  bool isOptimizing = false;
  String? selectedFarmId;
  int horizonMonths = 12;
  double minimumScore = 55;

  AtlasOptimizationObjective objective =
      AtlasOptimizationObjective.balancedGrowth;

  AtlasOptimizationRiskTolerance riskTolerance =
      AtlasOptimizationRiskTolerance.moderate;

  final AtlasOptimizationEngine engine = const AtlasOptimizationEngine();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    maxInvestmentController.dispose();
    maxHerdExpansionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await AtlasDigitalTwinService.instance.load();

    if (!mounted) {
      return;
    }

    final twins = AtlasDigitalTwinService.instance.twins;

    setState(() {
      selectedFarmId = twins.isEmpty ? null : twins.first.farmId;
      isLoading = false;
    });
  }

  AtlasDigitalTwin? get selectedTwin {
    final farmId = selectedFarmId;

    if (farmId == null) {
      return null;
    }

    return AtlasDigitalTwinService.instance.byFarmId(farmId);
  }

  Future<void> _optimize() async {
    final twin = selectedTwin;

    if (twin == null || !formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isOptimizing = true;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final request = AtlasOptimizationRequest(
        id: 'optimization_${DateTime.now().microsecondsSinceEpoch}',
        farmId: twin.farmId,
        farmName: twin.farmName,
        objective: objective,
        horizonMonths: horizonMonths,
        maxInvestment: _parseDouble(maxInvestmentController.text),
        maxRisk: riskTolerance,
        maxHerdExpansion: _parseInt(maxHerdExpansionController.text),
        minimumScore: minimumScore,
        generatedAt: DateTime.now(),
      );

      final result = engine.optimize(currentTwin: twin, request: request);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return AtlasOptimizationResultScreen(result: result);
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOptimizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final twins = AtlasDigitalTwinService.instance.twins;
    final twin = selectedTwin;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Optimization Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir consultor autônomo',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return const AtlasAutonomousConsultantScreen();
                  },
                ),
              );
            },
            icon: const Icon(Icons.support_agent_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : twin == null
          ? const _EmptyOptimizationView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Form(
                    key: formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _OptimizationHero(twin: twin),
                        const SizedBox(height: 20),
                        _ObjectiveCard(
                          twins: twins,
                          selectedFarmId: selectedFarmId,
                          onFarmChanged: (value) {
                            setState(() {
                              selectedFarmId = value;
                            });
                          },
                          objective: objective,
                          onObjectiveChanged: (value) {
                            setState(() {
                              objective = value;
                            });
                          },
                          horizonMonths: horizonMonths,
                          onHorizonChanged: (value) {
                            setState(() {
                              horizonMonths = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Limites da otimização',
                          subtitle:
                              'O motor descartará ou penalizará estratégias que ultrapassem estas restrições.',
                        ),
                        const SizedBox(height: 12),
                        _ConstraintCard(
                          maxInvestmentController: maxInvestmentController,
                          maxHerdExpansionController:
                              maxHerdExpansionController,
                          riskTolerance: riskTolerance,
                          onRiskChanged: (value) {
                            setState(() {
                              riskTolerance = value;
                            });
                          },
                          minimumScore: minimumScore,
                          onMinimumScoreChanged: (value) {
                            setState(() {
                              minimumScore = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: isOptimizing ? null : _optimize,
                          icon: isOptimizing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: Text(
                            isOptimizing
                                ? 'Otimizando...'
                                : 'Gerar melhor estratégia',
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _OptimizationHero extends StatelessWidget {
  const _OptimizationHero({required this.twin});

  final AtlasDigitalTwin twin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF17384D), Color(0xFF236075)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: Color(0xFFFFE082),
            size: 46,
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O Atlas procura a melhor alternativa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Serão gerados e comparados vários cenários sobre o Digital Twin de '
                  '${twin.farmName}, cujo índice atual é '
                  '${twin.overallScore.toStringAsFixed(1)}.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.twins,
    required this.selectedFarmId,
    required this.onFarmChanged,
    required this.objective,
    required this.onObjectiveChanged,
    required this.horizonMonths,
    required this.onHorizonChanged,
  });

  final List<AtlasDigitalTwin> twins;
  final String? selectedFarmId;
  final ValueChanged<String?> onFarmChanged;
  final AtlasOptimizationObjective objective;
  final ValueChanged<AtlasOptimizationObjective> onObjectiveChanged;
  final int horizonMonths;
  final ValueChanged<int> onHorizonChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          children: [
            if (twins.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedFarmId,
                decoration: const InputDecoration(
                  labelText: 'Fazenda',
                  border: OutlineInputBorder(),
                ),
                items: twins.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.farmId,
                    child: Text(item.farmName),
                  );
                }).toList(),
                onChanged: onFarmChanged,
              ),
              const SizedBox(height: 14),
            ],
            DropdownButtonFormField<AtlasOptimizationObjective>(
              initialValue: objective,
              decoration: const InputDecoration(
                labelText: 'Objetivo principal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: AtlasOptimizationObjective.values.map((item) {
                return DropdownMenuItem<AtlasOptimizationObjective>(
                  value: item,
                  child: Text(atlasOptimizationObjectiveLabel(item)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onObjectiveChanged(value);
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: horizonMonths,
              decoration: const InputDecoration(
                labelText: 'Horizonte da análise',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 3, child: Text('3 meses')),
                DropdownMenuItem(value: 6, child: Text('6 meses')),
                DropdownMenuItem(value: 12, child: Text('12 meses')),
                DropdownMenuItem(value: 24, child: Text('24 meses')),
                DropdownMenuItem(value: 36, child: Text('36 meses')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onHorizonChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstraintCard extends StatelessWidget {
  const _ConstraintCard({
    required this.maxInvestmentController,
    required this.maxHerdExpansionController,
    required this.riskTolerance,
    required this.onRiskChanged,
    required this.minimumScore,
    required this.onMinimumScoreChanged,
  });

  final TextEditingController maxInvestmentController;
  final TextEditingController maxHerdExpansionController;
  final AtlasOptimizationRiskTolerance riskTolerance;
  final ValueChanged<AtlasOptimizationRiskTolerance> onRiskChanged;
  final double minimumScore;
  final ValueChanged<double> onMinimumScoreChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          children: [
            TextFormField(
              controller: maxInvestmentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Investimento máximo (R\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.savings_outlined),
              ),
              validator: _nonNegativeValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: maxHerdExpansionController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Expansão máxima do rebanho',
                border: OutlineInputBorder(),
                prefixIcon: Icon(AtlasLivestockIcons.cow),
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');

                if (parsed == null || parsed < 0) {
                  return 'Informe uma quantidade válida.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AtlasOptimizationRiskTolerance>(
              initialValue: riskTolerance,
              decoration: const InputDecoration(
                labelText: 'Tolerância máxima ao risco',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: AtlasOptimizationRiskTolerance.values.map((item) {
                return DropdownMenuItem<AtlasOptimizationRiskTolerance>(
                  value: item,
                  child: Text(atlasOptimizationRiskToleranceLabel(item)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onRiskChanged(value);
                }
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Score mínimo permitido',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  minimumScore.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: minimumScore,
              min: 30,
              max: 80,
              divisions: 50,
              label: minimumScore.toStringAsFixed(0),
              onChanged: onMinimumScoreChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _EmptyOptimizationView extends StatelessWidget {
  const _EmptyOptimizationView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Nenhum Digital Twin está disponível.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre eventos na fazenda antes de executar a otimização.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String? _nonNegativeValidator(String? value) {
  final parsed = _tryParseDouble(value ?? '');

  if (parsed == null || parsed < 0) {
    return 'Informe um valor válido.';
  }

  return null;
}

double _parseDouble(String value) {
  return _tryParseDouble(value) ?? 0;
}

double? _tryParseDouble(String value) {
  var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');

  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else {
    normalized = normalized.replaceAll(',', '.');
  }

  return double.tryParse(normalized);
}

int _parseInt(String value) {
  return int.tryParse(value.trim()) ?? 0;
}
