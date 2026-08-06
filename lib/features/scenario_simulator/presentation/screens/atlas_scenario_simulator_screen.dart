import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/optimization_engine/presentation/screens/atlas_optimization_screen.dart';
import 'package:flutter/services.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/services/atlas_simulation_service.dart';
import 'package:projeto_atlas/features/scenario_simulator/presentation/screens/atlas_scenario_result_screen.dart';

class AtlasScenarioSimulatorScreen extends StatefulWidget {
  const AtlasScenarioSimulatorScreen({super.key});

  @override
  State<AtlasScenarioSimulatorScreen> createState() {
    return _AtlasScenarioSimulatorScreenState();
  }
}

class _AtlasScenarioSimulatorScreenState
    extends State<AtlasScenarioSimulatorScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController(text: 'Cenário estratégico');

  final descriptionController = TextEditingController();

  final herdSizeController = TextEditingController(text: '0');

  final investmentController = TextEditingController(text: '0');

  final monthlyRevenueController = TextEditingController(text: '0');

  final monthlyCostController = TextEditingController(text: '0');

  bool isLoading = true;
  bool isExecuting = false;
  String? selectedFarmId;
  int horizonMonths = 12;

  double animalChange = 0;
  double sanitaryChange = 0;
  double reproductiveChange = 0;
  double financialChange = 0;
  double inventoryChange = 0;
  double operationalChange = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    herdSizeController.dispose();
    investmentController.dispose();
    monthlyRevenueController.dispose();
    monthlyCostController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await AtlasDigitalTwinService.instance.load();
    await AtlasSimulationService.instance.load();

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

  Future<void> _execute() async {
    final twin = selectedTwin;

    if (twin == null || !formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isExecuting = true;
    });

    try {
      final simulation = AtlasSimulation(
        id: 'simulation_${DateTime.now().microsecondsSinceEpoch}',
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        farmId: twin.farmId,
        farmName: twin.farmName,
        createdAt: DateTime.now(),
        horizonMonths: horizonMonths,
        changes: AtlasSimulationChanges(
          animalScoreChange: animalChange,
          sanitaryScoreChange: sanitaryChange,
          reproductiveScoreChange: reproductiveChange,
          financialScoreChange: financialChange,
          inventoryScoreChange: inventoryChange,
          operationalScoreChange: operationalChange,
          herdSizeChange: _parseInt(herdSizeController.text),
          initialInvestment: _parseDouble(investmentController.text),
          expectedMonthlyRevenueChange: _parseDouble(
            monthlyRevenueController.text,
          ),
          expectedMonthlyCostChange: _parseDouble(monthlyCostController.text),
        ),
      );

      if (!simulation.changes.hasStrategicChange) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Informe pelo menos uma alteração para executar a simulação.',
              ),
            ),
          );
        }

        return;
      }

      final result = await AtlasSimulationService.instance.execute(
        currentTwin: twin,
        simulation: simulation,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return AtlasScenarioResultScreen(result: result);
          },
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          isExecuting = false;
        });
      }
    }
  }

  Future<void> _loadSimulation(AtlasSimulation simulation) async {
    setState(() {
      selectedFarmId = simulation.farmId;
      horizonMonths = simulation.horizonMonths;
      nameController.text = simulation.name;
      descriptionController.text = simulation.description;
      animalChange = simulation.changes.animalScoreChange;
      sanitaryChange = simulation.changes.sanitaryScoreChange;
      reproductiveChange = simulation.changes.reproductiveScoreChange;
      financialChange = simulation.changes.financialScoreChange;
      inventoryChange = simulation.changes.inventoryScoreChange;
      operationalChange = simulation.changes.operationalScoreChange;
      herdSizeController.text = simulation.changes.herdSizeChange.toString();
      investmentController.text = simulation.changes.initialInvestment
          .toStringAsFixed(2);
      monthlyRevenueController.text = simulation
          .changes
          .expectedMonthlyRevenueChange
          .toStringAsFixed(2);
      monthlyCostController.text = simulation.changes.expectedMonthlyCostChange
          .toStringAsFixed(2);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cenário carregado. Ajuste os dados e execute novamente.',
        ),
      ),
    );
  }

  Future<void> _deleteSimulation(AtlasSimulation simulation) async {
    await AtlasSimulationService.instance.delete(simulation.id);

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final twins = AtlasDigitalTwinService.instance.twins;
    final twin = selectedTwin;
    final simulations = AtlasSimulationService.instance.simulations;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Simulador de Cenários',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Gerar estratégia otimizada',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return const AtlasOptimizationScreen();
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.auto_awesome_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : twin == null
          ? const _EmptySimulatorView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Form(
                    key: formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _SimulatorHero(twin: twin),
                        const SizedBox(height: 20),
                        _ScenarioIdentityCard(
                          twins: twins,
                          selectedFarmId: selectedFarmId,
                          onFarmChanged: (value) {
                            setState(() {
                              selectedFarmId = value;
                            });
                          },
                          nameController: nameController,
                          descriptionController: descriptionController,
                          horizonMonths: horizonMonths,
                          onHorizonChanged: (value) {
                            setState(() {
                              horizonMonths = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Alterações estratégicas',
                          subtitle:
                              'Ajuste o impacto esperado em cada score. Valores positivos melhoram o indicador; valores negativos reduzem.',
                        ),
                        const SizedBox(height: 12),
                        _ScoreChangesCard(
                          animalChange: animalChange,
                          sanitaryChange: sanitaryChange,
                          reproductiveChange: reproductiveChange,
                          financialChange: financialChange,
                          inventoryChange: inventoryChange,
                          operationalChange: operationalChange,
                          onAnimalChanged: (value) {
                            setState(() {
                              animalChange = value;
                            });
                          },
                          onSanitaryChanged: (value) {
                            setState(() {
                              sanitaryChange = value;
                            });
                          },
                          onReproductiveChanged: (value) {
                            setState(() {
                              reproductiveChange = value;
                            });
                          },
                          onFinancialChanged: (value) {
                            setState(() {
                              financialChange = value;
                            });
                          },
                          onInventoryChanged: (value) {
                            setState(() {
                              inventoryChange = value;
                            });
                          },
                          onOperationalChanged: (value) {
                            setState(() {
                              operationalChange = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Premissas operacionais e financeiras',
                          subtitle:
                              'Informe apenas as mudanças esperadas em relação ao estado atual.',
                        ),
                        const SizedBox(height: 12),
                        _FinancialInputsCard(
                          herdSizeController: herdSizeController,
                          investmentController: investmentController,
                          monthlyRevenueController: monthlyRevenueController,
                          monthlyCostController: monthlyCostController,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: isExecuting ? null : _execute,
                          icon: isExecuting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.science_outlined),
                          label: Text(
                            isExecuting ? 'Simulando...' : 'Executar simulação',
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _SectionTitle(
                          title: 'Cenários salvos',
                          subtitle:
                              'Simulações anteriores que podem ser reutilizadas e ajustadas.',
                        ),
                        const SizedBox(height: 12),
                        _SavedSimulationList(
                          simulations: simulations,
                          onLoad: _loadSimulation,
                          onDelete: _deleteSimulation,
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

class _SimulatorHero extends StatelessWidget {
  const _SimulatorHero({required this.twin});

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
            Icons.science_outlined,
            color: Color(0xFFB3E5FC),
            size: 44,
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teste antes de executar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O cenário parte do Digital Twin de ${twin.farmName}, '
                  'com índice atual de ${twin.overallScore.toStringAsFixed(1)}. '
                  'Os dados reais não serão alterados.',
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

class _ScenarioIdentityCard extends StatelessWidget {
  const _ScenarioIdentityCard({
    required this.twins,
    required this.selectedFarmId,
    required this.onFarmChanged,
    required this.nameController,
    required this.descriptionController,
    required this.horizonMonths,
    required this.onHorizonChanged,
  });

  final List<AtlasDigitalTwin> twins;
  final String? selectedFarmId;
  final ValueChanged<String?> onFarmChanged;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
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
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do cenário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do cenário.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição ou objetivo',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: horizonMonths,
              decoration: const InputDecoration(
                labelText: 'Horizonte da simulação',
                border: OutlineInputBorder(),
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

class _ScoreChangesCard extends StatelessWidget {
  const _ScoreChangesCard({
    required this.animalChange,
    required this.sanitaryChange,
    required this.reproductiveChange,
    required this.financialChange,
    required this.inventoryChange,
    required this.operationalChange,
    required this.onAnimalChanged,
    required this.onSanitaryChanged,
    required this.onReproductiveChanged,
    required this.onFinancialChanged,
    required this.onInventoryChanged,
    required this.onOperationalChanged,
  });

  final double animalChange;
  final double sanitaryChange;
  final double reproductiveChange;
  final double financialChange;
  final double inventoryChange;
  final double operationalChange;
  final ValueChanged<double> onAnimalChanged;
  final ValueChanged<double> onSanitaryChanged;
  final ValueChanged<double> onReproductiveChanged;
  final ValueChanged<double> onFinancialChanged;
  final ValueChanged<double> onInventoryChanged;
  final ValueChanged<double> onOperationalChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          children: [
            _ScoreSlider(
              label: 'Desempenho animal',
              icon: Icons.monitor_weight_outlined,
              value: animalChange,
              onChanged: onAnimalChanged,
            ),
            _ScoreSlider(
              label: 'Sanidade',
              icon: Icons.medical_services_outlined,
              value: sanitaryChange,
              onChanged: onSanitaryChanged,
            ),
            _ScoreSlider(
              label: 'Reprodução',
              icon: Icons.pets_outlined,
              value: reproductiveChange,
              onChanged: onReproductiveChanged,
            ),
            _ScoreSlider(
              label: 'Financeiro',
              icon: Icons.account_balance_wallet_outlined,
              value: financialChange,
              onChanged: onFinancialChanged,
            ),
            _ScoreSlider(
              label: 'Estoque',
              icon: Icons.inventory_2_outlined,
              value: inventoryChange,
              onChanged: onInventoryChanged,
            ),
            _ScoreSlider(
              label: 'Operacional',
              icon: Icons.schema_outlined,
              value: operationalChange,
              onChanged: onOperationalChanged,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final sign = value > 0 ? '+' : '';

    return Column(
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$sign${value.toStringAsFixed(0)} pontos',
              style: TextStyle(
                color: value > 0
                    ? const Color(0xFF2E7D32)
                    : value < 0
                    ? const Color(0xFFC62828)
                    : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: -25,
          max: 25,
          divisions: 50,
          label: '$sign${value.toStringAsFixed(0)}',
          onChanged: onChanged,
        ),
        if (showDivider) const Divider(height: 24),
      ],
    );
  }
}

class _FinancialInputsCard extends StatelessWidget {
  const _FinancialInputsCard({
    required this.herdSizeController,
    required this.investmentController,
    required this.monthlyRevenueController,
    required this.monthlyCostController,
  });

  final TextEditingController herdSizeController;
  final TextEditingController investmentController;
  final TextEditingController monthlyRevenueController;
  final TextEditingController monthlyCostController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 680;
            final width = twoColumns
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;

            final fields = <Widget>[
              SizedBox(
                width: width,
                child: TextFormField(
                  controller: herdSizeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Alteração no número de animais',
                    hintText: 'Ex.: 50 ou -30',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextFormField(
                  controller: investmentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Investimento inicial (R\$)',
                    hintText: 'Ex.: 50000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.savings_outlined),
                  ),
                  validator: _nonNegativeValidator,
                ),
              ),
              SizedBox(
                width: width,
                child: TextFormField(
                  controller: monthlyRevenueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Mudança mensal de receita (R\$)',
                    hintText: 'Ex.: 8000 ou -2000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  validator: _numberValidator,
                ),
              ),
              SizedBox(
                width: width,
                child: TextFormField(
                  controller: monthlyCostController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Mudança mensal de custos (R\$)',
                    hintText: 'Ex.: 3000 ou -1500',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: _numberValidator,
                ),
              ),
            ];

            return Wrap(spacing: 14, runSpacing: 14, children: fields);
          },
        ),
      ),
    );
  }
}

class _SavedSimulationList extends StatelessWidget {
  const _SavedSimulationList({
    required this.simulations,
    required this.onLoad,
    required this.onDelete,
  });

  final List<AtlasSimulation> simulations;
  final ValueChanged<AtlasSimulation> onLoad;
  final ValueChanged<AtlasSimulation> onDelete;

  @override
  Widget build(BuildContext context) {
    if (simulations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhum cenário foi salvo ainda.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Column(
      children: simulations.map((simulation) {
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.science_outlined)),
            title: Text(
              simulation.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${simulation.farmName} · '
              '${simulation.horizonMonths} meses · '
              '${_formatDate(simulation.createdAt)}',
            ),
            onTap: () => onLoad(simulation),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'load') {
                  onLoad(simulation);
                } else if (value == 'delete') {
                  onDelete(simulation);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(value: 'load', child: Text('Carregar cenário')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir cenário'),
                  ),
                ];
              },
            ),
          ),
        );
      }).toList(),
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

class _EmptySimulatorView extends StatelessWidget {
  const _EmptySimulatorView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Nenhum Digital Twin está disponível.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre eventos nos módulos operacionais para formar o estado da fazenda antes de criar simulações.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String? _numberValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  if (_tryParseDouble(value) == null) {
    return 'Informe um número válido.';
  }

  return null;
}

String? _nonNegativeValidator(String? value) {
  final general = _numberValidator(value);

  if (general != null) {
    return general;
  }

  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final parsed = _tryParseDouble(value);

  if (parsed != null && parsed < 0) {
    return 'O investimento não pode ser negativo.';
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

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}
