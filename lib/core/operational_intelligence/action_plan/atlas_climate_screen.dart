import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_climate_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_climate_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';

class AtlasClimateScreen extends StatefulWidget {
  const AtlasClimateScreen({required this.actionController, super.key});

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasClimateScreen> createState() => _AtlasClimateScreenState();
}

class _AtlasClimateScreenState extends State<AtlasClimateScreen> {
  final service = AtlasClimateService.instance;

  List<AtlasClimateObservation> observations = [];
  List<AtlasClimateForecast> forecasts = [];
  AtlasClimateExecutiveSnapshot? snapshot;
  List<String> recommendations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    observations = await service.loadObservations(
      farmName: widget.actionController.farmName,
    );
    forecasts = await service.loadForecasts(
      farmName: widget.actionController.farmName,
    );
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    recommendations = await service.buildRecommendations(
      farmName: widget.actionController.farmName,
      snapshot: snapshot!,
    );
    if (mounted) setState(() => loading = false);
  }

  Future<void> _addObservation() async {
    var occurredAt = DateTime.now();
    final rainfall = TextEditingController();
    final minimum = TextEditingController();
    final maximum = TextEditingController();
    final humidity = TextEditingController();
    final wind = TextEditingController();
    final radiation = TextEditingController();
    final notes = TextEditingController();

    final result = await showDialog<AtlasClimateObservation>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo registro climático'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dateTile(
                        context: dialogContext,
                        title: 'Data',
                        date: occurredAt,
                        onChanged: (value) {
                          setDialogState(() => occurredAt = value);
                        },
                      ),
                      _row(
                        _number(rainfall, 'Chuva (mm)'),
                        _number(humidity, 'Umidade relativa (%)'),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        _number(minimum, 'Temperatura mínima (°C)'),
                        _number(maximum, 'Temperatura máxima (°C)'),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        _number(wind, 'Vento (km/h)'),
                        _number(radiation, 'Radiação (MJ/m²)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasClimateObservation(
                        id:
                            'climate_observation_'
                            '${now.microsecondsSinceEpoch}',
                        occurredAt: occurredAt,
                        rainfallMm: _double(rainfall.text),
                        minimumTemperatureC: _double(minimum.text),
                        maximumTemperatureC: _double(maximum.text),
                        relativeHumidityPercent: _double(humidity.text),
                        windSpeedKmH: _double(wind.text),
                        solarRadiationMjM2: _double(radiation.text),
                        farmName: widget.actionController.farmName,
                        notes: notes.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      rainfall,
      minimum,
      maximum,
      humidity,
      wind,
      radiation,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveObservation(result);
      await _load();
    }
  }

  Future<void> _addForecast() async {
    var forecastAt = DateTime.now().add(const Duration(days: 1));
    final rainfall = TextEditingController();
    final minimum = TextEditingController();
    final maximum = TextEditingController();
    final humidity = TextEditingController();
    final probability = TextEditingController();
    final source = TextEditingController();

    final result = await showDialog<AtlasClimateForecast>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova previsão climática'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dateTile(
                        context: dialogContext,
                        title: 'Data prevista',
                        date: forecastAt,
                        onChanged: (value) {
                          setDialogState(() => forecastAt = value);
                        },
                      ),
                      _number(rainfall, 'Chuva esperada (mm)'),
                      const SizedBox(height: 10),
                      _row(
                        _number(minimum, 'Temperatura mínima (°C)'),
                        _number(maximum, 'Temperatura máxima (°C)'),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        _number(humidity, 'Umidade relativa (%)'),
                        _number(probability, 'Probabilidade de chuva (%)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: source,
                        decoration: const InputDecoration(
                          labelText: 'Fonte',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasClimateForecast(
                        id:
                            'climate_forecast_'
                            '${now.microsecondsSinceEpoch}',
                        forecastAt: forecastAt,
                        expectedRainfallMm: _double(rainfall.text),
                        minimumTemperatureC: _double(minimum.text),
                        maximumTemperatureC: _double(maximum.text),
                        relativeHumidityPercent: _double(humidity.text),
                        probabilityOfRainPercent: _double(probability.text),
                        source: source.text.trim(),
                        farmName: widget.actionController.farmName,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      rainfall,
      minimum,
      maximum,
      humidity,
      probability,
      source,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveForecast(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = snapshot;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência climática'),
          actions: [
            IconButton(
              tooltip: 'Nova previsão',
              onPressed: _addForecast,
              icon: const Icon(Icons.cloud_outlined),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Painel'),
              Tab(text: 'Histórico'),
              Tab(text: 'Previsão'),
              Tab(text: 'Chuvas'),
              Tab(text: 'Temperatura'),
              Tab(text: 'Estresse térmico'),
              Tab(text: 'Alertas'),
              Tab(text: 'Planejamento'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addObservation,
          icon: const Icon(Icons.add),
          label: const Text('Registrar clima'),
        ),
        body: loading && current == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _Dashboard(snapshot: current),
                  _History(observations: observations),
                  _Forecasts(forecasts: forecasts),
                  _Rainfall(snapshot: current),
                  _Temperature(snapshot: current),
                  _ThermalStress(observations: observations, snapshot: current),
                  _Recommendations(recommendations: recommendations),
                  _Planning(
                    forecasts: forecasts,
                    recommendations: recommendations,
                  ),
                ],
              ),
      ),
    );
  }

  static Widget _row(Widget first, Widget second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  static Widget _number(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _dateTile({
    required BuildContext context,
    required String title,
    required DateTime date,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});

  final AtlasClimateExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados climáticos.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card('Chuva 30 dias', item.totalRainfall30DaysMm, 'mm'),
            _card('Máxima média', item.averageMaximumTemperatureC, '°C'),
            _card('Umidade média', item.averageHumidityPercent, '%'),
            _card('THI máximo', item.maximumThi, ''),
            _card('Dias de estresse', item.thermalStressDays.toDouble(), ''),
            _card('Dias secos', item.dryDays.toDouble(), ''),
            _card('Chuva prevista', item.forecastRainfall7DaysMm, 'mm'),
            _card('Score', item.climateScore, '/100'),
          ],
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.observations});

  final List<AtlasClimateObservation> observations;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) {
      return const Center(child: Text('Nenhum registro climático.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: observations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = observations[index];
        return Card(
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(item.occurredAt)),
            subtitle: Text(
              '${item.minimumTemperatureC.toStringAsFixed(1)} a '
              '${item.maximumTemperatureC.toStringAsFixed(1)} °C • '
              '${item.relativeHumidityPercent.toStringAsFixed(1)}% UR',
            ),
            trailing: Text('${item.rainfallMm.toStringAsFixed(1)} mm'),
          ),
        );
      },
    );
  }
}

class _Forecasts extends StatelessWidget {
  const _Forecasts({required this.forecasts});

  final List<AtlasClimateForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const Center(child: Text('Nenhuma previsão registrada.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: forecasts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = forecasts[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(DateFormat('dd/MM/yyyy').format(item.forecastAt)),
            subtitle: Text(
              '${item.minimumTemperatureC.toStringAsFixed(1)} a '
              '${item.maximumTemperatureC.toStringAsFixed(1)} °C • '
              '${item.probabilityOfRainPercent.toStringAsFixed(0)}% de chuva',
            ),
            trailing: Text('${item.expectedRainfallMm.toStringAsFixed(1)} mm'),
          ),
        );
      },
    );
  }
}

class _Rainfall extends StatelessWidget {
  const _Rainfall({required this.snapshot});

  final AtlasClimateExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Chuva acumulada em 30 dias', item.totalRainfall30DaysMm, 'mm'),
        _line('Chuva prevista em 7 dias', item.forecastRainfall7DaysMm, 'mm'),
        _line('Dias secos', item.dryDays.toDouble(), ''),
      ],
    );
  }
}

class _Temperature extends StatelessWidget {
  const _Temperature({required this.snapshot});

  final AtlasClimateExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line(
          'Temperatura máxima média',
          item.averageMaximumTemperatureC,
          '°C',
        ),
        _line('Umidade relativa média', item.averageHumidityPercent, '%'),
        _line('THI máximo', item.maximumThi, ''),
      ],
    );
  }
}

class _ThermalStress extends StatelessWidget {
  const _ThermalStress({required this.observations, required this.snapshot});

  final List<AtlasClimateObservation> observations;
  final AtlasClimateExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final risky = observations
        .where((item) => item.thermalStressRisk != AtlasClimateRiskLevel.low)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (snapshot != null)
          _line(
            'Dias com risco alto/crítico',
            snapshot!.thermalStressDays.toDouble(),
            '',
          ),
        ...risky.map(
          (item) => Card(
            child: ListTile(
              title: Text(DateFormat('dd/MM/yyyy').format(item.occurredAt)),
              subtitle: Text(
                'THI ${item.temperatureHumidityIndex.toStringAsFixed(1)}',
              ),
              trailing: Text(
                atlasClimateRiskLevelLabel(item.thermalStressRisk),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({required this.recommendations});

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(recommendations[index]),
        ),
      ),
    );
  }
}

class _Planning extends StatelessWidget {
  const _Planning({required this.forecasts, required this.recommendations});

  final List<AtlasClimateForecast> forecasts;
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Planejamento baseado na previsão',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...recommendations.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.task_alt),
              title: Text(item),
            ),
          ),
        ),
        if (forecasts.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Cadastre previsões para ampliar o planejamento.'),
            ),
          ),
      ],
    );
  }
}

Widget _card(String title, double value, String unit) {
  return SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
              '${unit.isEmpty || unit == '/100' ? unit : ' $unit'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _line(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
        '${unit.isEmpty ? '' : ' $unit'}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
