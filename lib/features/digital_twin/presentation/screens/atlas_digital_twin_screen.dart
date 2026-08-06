import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/widgets/atlas_command_center_module_card.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin_simulation.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_v2_engine.dart';

class AtlasDigitalTwinScreen extends StatefulWidget {
  const AtlasDigitalTwinScreen({super.key});

  @override
  State<AtlasDigitalTwinScreen> createState() => _AtlasDigitalTwinScreenState();
}

class _AtlasDigitalTwinScreenState extends State<AtlasDigitalTwinScreen> {
  final AtlasDigitalTwinV2Engine engine = const AtlasDigitalTwinV2Engine();
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  StreamSubscription<AtlasDigitalTwin>? subscription;
  late final String reactiveRegistrationId;
  bool isLoading = true;
  bool isRefreshing = false;
  bool refreshRequested = false;
  String? selectedFarmId;
  AtlasDigitalTwinSimulationResult? simulationResult;

  @override
  void initState() {
    super.initState();
    AtlasReactiveRuntime.instance.start();
    reactiveRegistrationId = reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.digitalTwin,
      owner: 'atlas_digital_twin_screen',
      handler: _handleReactiveUpdate,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    subscription?.cancel();
    reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.digitalTwin,
      registrationId: reactiveRegistrationId,
    );
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.digitalTwin)) {
      return;
    }

    if (isRefreshing) {
      refreshRequested = true;
      return;
    }

    isRefreshing = true;

    try {
      if (!mounted) {
        return;
      }

      setState(() {
        final twins = AtlasDigitalTwinService.instance.twins;
        final selectedStillExists = selectedFarmId != null &&
            twins.any((twin) => twin.farmId == selectedFarmId);

        if (!selectedStillExists) {
          selectedFarmId = twins.isEmpty ? null : twins.first.farmId;
        }
      });
    } finally {
      isRefreshing = false;

      if (refreshRequested && mounted) {
        refreshRequested = false;
        await _handleReactiveUpdate(update);
      }
    }
  }

  Future<void> _load() async {
    await AtlasDigitalTwinService.instance.load();
    await AtlasDigitalTwinService.instance.start();

    subscription = AtlasDigitalTwinService.instance.changes.listen((twin) {
      if (!mounted) return;
      setState(() {
        selectedFarmId ??= twin.farmId;
      });
    });

    if (!mounted) return;
    final twins = AtlasDigitalTwinService.instance.twins;
    setState(() {
      selectedFarmId = twins.isEmpty ? null : twins.first.farmId;
      isLoading = false;
    });
  }

  AtlasDigitalTwin get selectedTwin {
    final farmId = selectedFarmId;
    final stored = farmId == null
        ? null
        : AtlasDigitalTwinService.instance.byFarmId(farmId);

    return stored ??
        AtlasDigitalTwin.initial(
          farmId: 'global',
          farmName: 'Propriedade demonstrativa',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final twin = selectedTwin;
    final insights = engine.buildInsights(twin);
    final twins = AtlasDigitalTwinService.instance.twins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Digital Twin 2.0'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFarmSelector(twins, twin),
            const SizedBox(height: 16),
            AtlasCommandCenterModuleCard(
              module: AtlasCommandCenterModule.digitalTwin,
              farmName: twin.farmName,
            ),
            const SizedBox(height: 16),
            _buildExecutiveHeader(twin),
            const SizedBox(height: 16),
            _buildSummaryCards(twin),
            const SizedBox(height: 20),
            const Text('Mapa operacional da propriedade',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...insights.map(_buildAreaCard),
            const SizedBox(height: 20),
            _buildRisks(twin),
            const SizedBox(height: 20),
            _buildTimeline(twin),
            const SizedBox(height: 20),
            _buildSimulation(twin),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmSelector(List<AtlasDigitalTwin> twins, AtlasDigitalTwin twin) {
    if (twins.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Modo demonstrativo'),
          subtitle: const Text(
            'O gêmeo digital será atualizado automaticamente conforme eventos reais forem registrados no Atlas.',
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedFarmId,
      decoration: const InputDecoration(
        labelText: 'Propriedade',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.agriculture),
      ),
      items: twins
          .map((item) => DropdownMenuItem(
                value: item.farmId,
                child: Text(item.farmName),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedFarmId = value;
          simulationResult = null;
        });
      },
    );
  }

  Widget _buildExecutiveHeader(AtlasDigitalTwin twin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(twin.overallScore.toStringAsFixed(0)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(twin.farmName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Tendência: ${atlasDigitalTwinTrendLabel(twin.trend)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(engine.executiveSummary(twin)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AtlasDigitalTwin twin) {
    final highRisks = twin.risks.where((risk) =>
        risk.level == AtlasFarmRiskLevel.high ||
        risk.level == AtlasFarmRiskLevel.critical).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricCard('Score geral', twin.overallScore.toStringAsFixed(0), Icons.speed),
        _metricCard('Riscos críticos', '$highRisks', Icons.warning_amber),
        _metricCard('Eventos processados', '${twin.totalProcessedEvents}', Icons.timeline),
        _metricCard('Áreas monitoradas', '6', Icons.grid_view),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAreaCard(AtlasDigitalTwinAreaInsight insight) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(atlasDigitalTwinAreaLabel(insight.area),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text('${insight.score.toStringAsFixed(0)} • ${insight.status}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: insight.score / 100),
            const SizedBox(height: 10),
            Text(insight.recommendation),
          ],
        ),
      ),
    );
  }

  Widget _buildRisks(AtlasDigitalTwin twin) {
    final risks = twin.risks.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riscos prioritários',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (risks.isEmpty)
              const Text('Nenhum risco registrado no gêmeo digital.'),
            ...risks.map((risk) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber),
                  title: Text(risk.title),
                  subtitle: Text(risk.description),
                  trailing: Text(atlasFarmRiskLevelLabel(risk.level)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(AtlasDigitalTwin twin) {
    final events = twin.timeline.take(6).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Linha do tempo operacional',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (events.isEmpty)
              const Text('Os próximos eventos operacionais aparecerão aqui.'),
            ...events.map((event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.circle, size: 12),
                  title: Text(event.title),
                  subtitle: Text(
                    '${atlasDigitalTwinAreaLabel(event.area)} • ${_date(event.occurredAt)}',
                  ),
                  trailing: Text(
                    '${event.scoreBefore.toStringAsFixed(0)} → ${event.scoreAfter.toStringAsFixed(0)}',
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulation(AtlasDigitalTwin twin) {
    final result = simulationResult;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simulador de impacto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Teste uma mudança antes de executá-la na propriedade.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openSimulationDialog(twin),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Criar simulação'),
            ),
            if (result != null) ...[
              const Divider(height: 28),
              Text(result.request.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Score: ${result.currentScore.toStringAsFixed(1)} → ${result.projectedScore.toStringAsFixed(1)} '
                '(${result.scoreVariation >= 0 ? '+' : ''}${result.scoreVariation.toStringAsFixed(1)})',
              ),
              Text(
                'Impacto financeiro projetado: R\$ ${result.projectedFinancialImpact.toStringAsFixed(2)}',
              ),
              Text(
                'Redução de risco: ${result.riskReductionPercent.toStringAsFixed(1)}% • '
                'Confiança: ${result.confidencePercent.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 8),
              Text(result.recommendation),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSimulationDialog(AtlasDigitalTwin twin) async {
    AtlasDigitalTwinArea area = AtlasDigitalTwinArea.reproductive;
    double changePercent = 10;
    double investmentValue = 15000;
    int horizonDays = 180;

    final request = await showDialog<AtlasDigitalTwinSimulationRequest>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova simulação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<AtlasDigitalTwinArea>(
                      initialValue: area,
                      decoration: const InputDecoration(labelText: 'Área'),
                      items: AtlasDigitalTwinArea.values
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(atlasDigitalTwinAreaLabel(item)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => area = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('Melhoria esperada: ${changePercent.toStringAsFixed(0)}%'),
                    Slider(
                      value: changePercent,
                      min: -20,
                      max: 40,
                      divisions: 60,
                      onChanged: (value) =>
                          setDialogState(() => changePercent = value),
                    ),
                    TextFormField(
                      initialValue: investmentValue.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Investimento previsto (R\$)',
                      ),
                      onChanged: (value) {
                        investmentValue = double.tryParse(
                              value.replaceAll(',', '.'),
                            ) ??
                            0;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: horizonDays,
                      decoration: const InputDecoration(labelText: 'Horizonte'),
                      items: const [
                        DropdownMenuItem(value: 90, child: Text('90 dias')),
                        DropdownMenuItem(value: 180, child: Text('180 dias')),
                        DropdownMenuItem(value: 365, child: Text('365 dias')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => horizonDays = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      AtlasDigitalTwinSimulationRequest(
                        title: 'Cenário de ${atlasDigitalTwinAreaLabel(area)}',
                        area: area,
                        changePercent: changePercent,
                        investmentValue: investmentValue,
                        horizonDays: horizonDays,
                      ),
                    );
                  },
                  child: const Text('Simular'),
                ),
              ],
            );
          },
        );
      },
    );

    if (request == null || !mounted) return;
    setState(() {
      simulationResult = engine.simulate(twin: twin, request: request);
    });
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
