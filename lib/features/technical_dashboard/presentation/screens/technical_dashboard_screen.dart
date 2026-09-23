import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/widgets/atlas_command_center_module_card.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/dairy_production/presentation/screens/dairy_production_screen.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_analysis.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_period.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_financial_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_weight_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/services/technical_dashboard_service.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

enum TechnicalProductionFocus { dairy, beef }

class TechnicalDashboardScreen extends StatefulWidget {
  const TechnicalDashboardScreen({
    this.initialFarm,
    this.productionFocus,
    super.key,
  });

  final FarmData? initialFarm;
  final TechnicalProductionFocus? productionFocus;

  @override
  State<TechnicalDashboardScreen> createState() =>
      _TechnicalDashboardScreenState();
}

class _TechnicalDashboardScreenState extends State<TechnicalDashboardScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final TechnicalDashboardService dashboardService =
      TechnicalDashboardService();

  List<FarmData> farms = const [];
  FarmData? selectedFarm;
  TechnicalDashboardAnalysis? analysis;
  TechnicalDashboardPeriod selectedPeriod = TechnicalDashboardPeriod.last30Days;
  bool isLoading = true;
  bool isRefreshingAnalysis = false;
  bool analysisReloadRequested = false;
  Timer? analysisReloadDebounce;
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;
  late final String reactiveRegistrationId;

  @override
  void initState() {
    super.initState();

    AtlasReactiveRuntime.instance.start();

    reactiveRegistrationId = reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.technicalDashboard,
      owner: 'technical_dashboard_screen',
      handler: handleReactiveUpdate,
    );

    unawaited(loadFarms());
  }

  @override
  void dispose() {
    analysisReloadDebounce?.cancel();
    reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.technicalDashboard,
      registrationId: reactiveRegistrationId,
    );
    super.dispose();
  }

  Future<void> handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.technicalDashboard)) {
      return;
    }

    final farm = selectedFarm;

    if (farm == null) {
      return;
    }

    final hasRelevantEvent = update.events.any((event) {
      final eventFarmName = event.farmName?.trim();
      return eventFarmName == null ||
          eventFarmName.isEmpty ||
          eventFarmName == farm.name;
    });

    if (!hasRelevantEvent) {
      return;
    }

    scheduleAnalysisReload();
  }

  void scheduleAnalysisReload() {
    analysisReloadDebounce?.cancel();
    analysisReloadDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(loadSummary(showLoading: false));
    });
  }

  Future<void> loadFarms() async {
    setState(() => isLoading = true);
    final loadedFarms = await farmStorage.loadFarms();
    final currentName = selectedFarm?.name ?? widget.initialFarm?.name;
    FarmData? nextFarm;
    for (final farm in loadedFarms) {
      if (farm.name == currentName) {
        nextFarm = farm;
        break;
      }
    }
    nextFarm ??= widget.initialFarm;
    nextFarm ??= loadedFarms.isEmpty ? null : loadedFarms.first;
    if (!mounted) return;
    setState(() {
      farms = loadedFarms;
      selectedFarm = nextFarm;
    });
    await loadSummary();
  }

  Future<void> loadSummary({bool showLoading = true}) async {
    final farm = selectedFarm;
    if (farm == null) {
      if (!mounted) return;
      setState(() {
        analysis = null;
        isLoading = false;
      });
      return;
    }

    if (isRefreshingAnalysis) {
      analysisReloadRequested = true;
      return;
    }

    isRefreshingAnalysis = true;

    if (showLoading && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final loadedAnalysis = await dashboardService.loadAnalysis(
        farm,
        period: selectedPeriod,
      );
      if (!mounted) return;
      setState(() {
        analysis = loadedAnalysis;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar o painel: $error')),
      );
    } finally {
      isRefreshingAnalysis = false;

      if (analysisReloadRequested && mounted) {
        analysisReloadRequested = false;
        unawaited(loadSummary(showLoading: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (widget.productionFocus == TechnicalProductionFocus.dairy &&
              selectedFarm != null)
            IconButton(
              tooltip: 'Registrar produção diária',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DairyProductionScreen(farm: selectedFarm!),
                  ),
                );
              },
              icon: const Icon(Icons.add_chart_outlined),
            ),
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: isLoading ? null : loadSummary,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadFarms,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _heading,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _description,
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      _FarmSelector(
                        farms: farms,
                        selectedFarm: selectedFarm,
                        onChanged: isLoading
                            ? null
                            : (farm) async {
                                setState(() => selectedFarm = farm);
                                await loadSummary();
                              },
                      ),
                      const SizedBox(height: 16),
                      _PeriodSelector(
                        selectedPeriod: selectedPeriod,
                        enabled: !isLoading,
                        onSelected: (period) async {
                          if (period == selectedPeriod) return;
                          setState(() => selectedPeriod = period);
                          await loadSummary();
                        },
                      ),
                      const SizedBox(height: 18),
                      AtlasCommandCenterModuleCard(
                        module: AtlasCommandCenterModule.technicalDashboard,
                        farmName: selectedFarm?.name,
                      ),
                      const SizedBox(height: 24),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (analysis == null)
                        const _EmptyDashboard()
                      else
                        _SummaryContent(
                          analysis: analysis!,
                          productionFocus: widget.productionFocus,
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

  String get _title => switch (widget.productionFocus) {
    TechnicalProductionFocus.dairy => 'Produção de leite',
    TechnicalProductionFocus.beef => 'Produção de corte',
    null => 'Painel Técnico Integrado',
  };

  String get _heading => switch (widget.productionFocus) {
    TechnicalProductionFocus.dairy => 'Indicadores técnicos do leite',
    TechnicalProductionFocus.beef => 'Indicadores técnicos do corte',
    null => 'Visão técnica da fazenda',
  };

  String get _description => switch (widget.productionFocus) {
    TechnicalProductionFocus.dairy =>
      'Acompanhe os dados de rebanho e reprodução que formarão os índices produtivos e reprodutivos.',
    TechnicalProductionFocus.beef =>
      'Acompanhe peso, ganho, reprodução e sanidade para formar os indicadores de desempenho do rebanho.',
    null =>
      'Indicadores reais de rebanho, reprodução, sanidade, nutrição, financeiro e estoque.',
  };
}

class _FarmSelector extends StatelessWidget {
  const _FarmSelector({
    required this.farms,
    required this.selectedFarm,
    required this.onChanged,
  });

  final List<FarmData> farms;
  final FarmData? selectedFarm;
  final ValueChanged<FarmData?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<FarmData>(
          initialValue: selectedFarm,
          decoration: const InputDecoration(
            labelText: 'Fazenda analisada',
            prefixIcon: Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(),
          ),
          items: farms
              .map(
                (farm) => DropdownMenuItem<FarmData>(
                  value: farm,
                  child: Text('${farm.name} • ${farm.city} - ${farm.state}'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.enabled,
    required this.onSelected,
  });

  final TechnicalDashboardPeriod selectedPeriod;
  final bool enabled;
  final ValueChanged<TechnicalDashboardPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.date_range_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Text(
                  'Período analisado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TechnicalDashboardPeriod.values.map((period) {
                return ChoiceChip(
                  label: Text(period.label),
                  selected: selectedPeriod == period,
                  onSelected: enabled ? (_) => onSelected(period) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonPanel extends StatelessWidget {
  const _ComparisonPanel({required this.analysis});

  final TechnicalDashboardAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final previous = analysis.previous;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows_outlined,
                  color: Color(0xFF1B5E20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysis.hasComparison
                        ? 'Comparação com o período anterior'
                        : 'Visão consolidada de todo o histórico',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              analysis.hasComparison
                  ? 'As variações abaixo comparam períodos de mesma duração.'
                  : 'Selecione um período para visualizar variações automáticas.',
              style: const TextStyle(color: Colors.black54),
            ),
            if (previous != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _VariationBadge(
                    label: 'Receitas',
                    value: analysis.incomeVariationPercent,
                    positiveIsGood: true,
                  ),
                  _VariationBadge(
                    label: 'Despesas',
                    value: analysis.expenseVariationPercent,
                    positiveIsGood: false,
                  ),
                  _VariationBadge(
                    label: 'Saldo',
                    value: analysis.balanceVariationPercent,
                    positiveIsGood: true,
                  ),
                  _VariationBadge(
                    label: 'Registros sanitários',
                    value: analysis.healthRecordVariationPercent,
                    positiveIsGood: null,
                  ),
                  _VariationBadge(
                    label: 'Registros reprodutivos',
                    value: analysis.reproductionRecordVariationPercent,
                    positiveIsGood: null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VariationBadge extends StatelessWidget {
  const _VariationBadge({
    required this.label,
    required this.value,
    required this.positiveIsGood,
  });

  final String label;
  final double? value;
  final bool? positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final variation = value;
    final isPositive = variation != null && variation > 0;
    final isNegative = variation != null && variation < 0;
    final icon = isPositive
        ? Icons.trending_up
        : isNegative
        ? Icons.trending_down
        : Icons.trending_flat;

    Color foreground = Colors.blueGrey.shade700;
    Color background = Colors.blueGrey.shade50;
    if (positiveIsGood != null && variation != null && variation != 0) {
      final isGood = positiveIsGood! ? isPositive : isNegative;
      foreground = isGood ? Colors.green.shade800 : Colors.red.shade800;
      background = isGood ? Colors.green.shade50 : Colors.red.shade50;
    }

    final text = variation == null
        ? 'Sem base anterior'
        : '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(1)}%';

    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: foreground),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.analysis, this.productionFocus});

  final TechnicalDashboardAnalysis analysis;
  final TechnicalProductionFocus? productionFocus;

  TechnicalFarmSummary get summary => analysis.current;

  double? get _beefLatestWeightCoveragePercent {
    return analysis.beefLatestWeightCoverage.percent;
  }

  int? get _beefLatestWeightAgeDays {
    final last = analysis.beefLatestWeightCoverage.latestMeasurementDate;
    if (last == null) return null;
    final reference = DateTime(
      analysis.generatedAt.year,
      analysis.generatedAt.month,
      analysis.generatedAt.day,
    );
    final date = DateTime(last.year, last.month, last.day);
    return reference.difference(date).inDays;
  }

  Future<void> _showPendingWeighings(BuildContext context) async {
    final pending = analysis.pendingWeighingAnimals;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pesagens pendentes (${pending.length})'),
        content: SizedBox(
          width: 560,
          height: MediaQuery.sizeOf(dialogContext).height * 0.55,
          child: ListView.separated(
            itemCount: pending.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final animal = pending[index];
              final lastDate = animal.lastValidWeightDate;
              final dateLabel = lastDate == null
                  ? 'Sem pesagem válida registrada'
                  : 'Última pesagem válida: ${DateFormat('dd/MM/yyyy').format(lastDate)}';
              final groupLabel = animal.groupName.trim();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text(animal.label),
                subtitle: Text(
                  groupLabel.isEmpty ? dateLabel : '$groupLabel · $dateLabel',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  List<String> get _beefOperationalDataAlerts {
    final alerts = [...summary.beefHerd.dataQualityAlerts];
    if (summary.areaHectares == null) {
      alerts.add(
        'Cadastre a área total da fazenda para calcular animais/ha e peso vivo/ha. Esses índices não substituem a lotação da área de pastagem.',
      );
    }
    if (summary.activeAnimals == 0) return alerts;
    if (summary.activeAnimalsWithoutValidWeight > 0) {
      final missing = summary.activeAnimalsWithoutValidWeight;
      final missingLabel = missing == 1
          ? '1 animal ativo está sem peso válido'
          : '$missing animais ativos estão sem peso válido';
      alerts.add(
        '$missingLabel no cadastro; o peso médio usa apenas os registrados e o peso vivo/ha aguarda a base completa.',
      );
    }
    if (analysis.beefWeightGain.animalCount == 0) {
      alerts.add(
        'Registre duas pesagens em datas distintas do mesmo animal nos últimos 12 meses para calcular o ganho médio diário.',
      );
    } else if (analysis.beefWeightGain.animalCount / summary.activeAnimals <
        0.5) {
      alerts.add(
        'O GMD usa pares de pesagens de ${analysis.beefWeightGain.animalCount}/${summary.activeAnimals} animais ativos; amplie a amostra antes de generalizar o resultado.',
      );
    }
    final coverage = _beefLatestWeightCoveragePercent;
    if (coverage != null && coverage < 50) {
      final missing = analysis.beefLatestWeightCoverage.unweighedAnimalCount;
      final missingLabel = missing == 1
          ? '1 animal ainda precisa de pesagem'
          : '$missing animais ainda precisam de pesagem';
      alerts.add(
        'Pesagens válidas nos últimos 90 dias cobrem ${coverage.toStringAsFixed(0)}% dos animais ativos; $missingLabel para cobrir o rebanho antes de usar o GMD como referência.',
      );
    }
    final age = _beefLatestWeightAgeDays;
    if (age != null && age > 90) {
      alerts.add(
        'A última pesagem foi há $age dias; atualize os pesos antes de usar GMD e peso por hectare como retrato atual.',
      );
    }
    return alerts;
  }

  int? get _dairySnapshotAgeDays {
    final snapshot = summary.latestDairySnapshot;
    if (snapshot == null) return null;
    final today = DateTime(
      analysis.generatedAt.year,
      analysis.generatedAt.month,
      analysis.generatedAt.day,
    );
    final date = DateTime(
      snapshot.date.year,
      snapshot.date.month,
      snapshot.date.day,
    );
    return today.difference(date).inDays;
  }

  List<String> get _dairyOperationalDataAlerts {
    final alerts = [...summary.dairyOperationalDataAlerts];
    final snapshotAge = _dairySnapshotAgeDays;
    if (snapshotAge == null) {
      alerts.add(
        'Registre o estado do lote para atualizar vacas em lactação, vacas secas e perdas gestacionais.',
      );
    } else if (snapshotAge > 7) {
      alerts.add(
        'O estado do lote foi registrado há $snapshotAge dias; atualize-o antes de interpretar os índices por vaca em lactação.',
      );
    }
    return alerts;
  }

  List<String> get _productionDataQualityAlerts => switch (productionFocus) {
    TechnicalProductionFocus.dairy => _dairyOperationalDataAlerts,
    TechnicalProductionFocus.beef => _beefOperationalDataAlerts,
    null => const [],
  };

  String get _productionDataQualityTitle => switch (productionFocus) {
    TechnicalProductionFocus.dairy => 'Dados técnicos para revisar — Leite',
    TechnicalProductionFocus.beef => 'Dados técnicos para revisar — Corte',
    null => 'Dados técnicos para revisar',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComparisonPanel(analysis: analysis),
        const SizedBox(height: 18),
        _FinancialEvolutionCard(points: analysis.financialSeries),
        const SizedBox(height: 18),
        if (productionFocus == TechnicalProductionFocus.beef) ...[
          _WeightEvolutionCard(points: analysis.weightSeries),
          const SizedBox(height: 18),
        ],
        if (_productionDataQualityAlerts.isNotEmpty) ...[
          _ModuleCard(
            width: double.infinity,
            title: _productionDataQualityTitle,
            icon: Icons.fact_check_outlined,
            metrics: [
              (
                'Itens que precisam de revisão',
                '${_productionDataQualityAlerts.length}',
              ),
              for (final alert in _productionDataQualityAlerts)
                ('Registro necessário', alert),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (productionFocus == TechnicalProductionFocus.dairy) ...[
          _ModuleCard(
            width: double.infinity,
            title: 'Índices reprodutivos do leite',
            icon: Icons.monitor_heart_outlined,
            metrics: [
              (
                'Produção média',
                summary.dairyProduction.averageLitersPerDay == null
                    ? 'Sem ordenhas registradas'
                    : '${summary.dairyProduction.averageLitersPerDay!.toStringAsFixed(1)} L/dia',
              ),
              (
                'Litros por hectare',
                summary.dairyProduction.averageLitersPerHectare == null
                    ? 'Informe área e ordenhas'
                    : '${summary.dairyProduction.averageLitersPerHectare!.toStringAsFixed(1)} L/ha/dia',
              ),
              (
                'Litros por vaca ordenhada',
                summary.dairyProduction.litersPerMilkedCow == null
                    ? 'Registre ordenhas válidas'
                    : '${summary.dairyProduction.litersPerMilkedCow!.toStringAsFixed(1)} L/vaca/dia',
              ),
              (
                'Litros por vaca em lactação',
                summary.dairyProduction.litersPerLactatingCow == null
                    ? 'Informe o estado atual do lote'
                    : '${summary.dairyProduction.litersPerLactatingCow!.toStringAsFixed(1)} L/vaca/dia',
              ),
              (
                'Média de vacas ordenhadas',
                summary.dairyProduction.averageMilkedCows == null
                    ? 'Sem ordenhas válidas'
                    : '${summary.dairyProduction.averageMilkedCows!.toStringAsFixed(1)} vacas/dia',
              ),
              (
                '% de vacas em lactação',
                summary.latestDairySnapshot?.lactatingPercent == null
                    ? 'Registre o estado do lote'
                    : '${summary.latestDairySnapshot!.lactatingPercent!.toStringAsFixed(1)}%',
              ),
              (
                'Atualização do estado do lote',
                _dairySnapshotAgeDays == null
                    ? 'Ainda não registrado'
                    : _dairySnapshotAgeDays == 0
                    ? 'Atualizado hoje'
                    : 'Há $_dairySnapshotAgeDays dia(s)',
              ),
              (
                '% de vacas secas',
                summary.latestDairySnapshot?.dryPercent == null
                    ? 'Registre o estado do lote'
                    : '${summary.latestDairySnapshot!.dryPercent!.toStringAsFixed(1)}%',
              ),
              (
                'Perdas gestacionais',
                summary.latestDairySnapshot?.pregnancyLossPercent == null
                    ? 'Informe gestações acompanhadas'
                    : '${summary.latestDairySnapshot!.pregnancyLossPercent!.toStringAsFixed(1)}% '
                          '(${summary.latestDairySnapshot!.pregnancyLosses}/${summary.latestDairySnapshot!.pregnanciesMonitored})',
              ),
              (
                'Dias de ordenha na base',
                '${summary.dairyProduction.recordedDays}/${summary.dairyProduction.windowDays}',
              ),
              (
                'Cobertura da produção',
                '${summary.dairyProduction.coveragePercent.toStringAsFixed(0)}% '
                    '· ${summary.dairyProduction.missingDays} dia(s) sem ordenha válida',
              ),
              (
                'DEL médio',
                summary.dairyReproduction.averageDaysInMilk == null
                    ? 'Dados insuficientes'
                    : '${summary.dairyReproduction.averageDaysInMilk!.toStringAsFixed(0)} dias',
              ),
              (
                'Matrizes com parto conhecido',
                '${summary.dairyReproduction.lactatingCowsWithKnownCalving}',
              ),
              (
                'Taxa de concepção',
                summary.dairyReproduction.conceptionRate == null
                    ? 'Dados insuficientes'
                    : '${summary.dairyReproduction.conceptionRate!.toStringAsFixed(1)}%',
              ),
              (
                'Inseminações',
                '${summary.dairyReproduction.inseminationAttempts}',
              ),
              (
                'Diagnósticos positivos',
                '${summary.dairyReproduction.confirmedPregnancies}',
              ),
              (
                'Período seco médio',
                summary.dairyReproduction.averageDryPeriodDays == null
                    ? 'Dados insuficientes'
                    : '${summary.dairyReproduction.averageDryPeriodDays!.toStringAsFixed(0)} dias',
              ),
              (
                'Período de serviço',
                summary.dairyReproduction.averageServicePeriodDays == null
                    ? 'Dados insuficientes'
                    : '${summary.dairyReproduction.averageServicePeriodDays!.toStringAsFixed(0)} dias',
              ),
              (
                'Idade ao 1º parto',
                summary.dairyReproduction.averageAgeAtFirstCalvingDays == null
                    ? 'Dados insuficientes'
                    : '${(summary.dairyReproduction.averageAgeAtFirstCalvingDays! / 30.4375).toStringAsFixed(1)} meses',
              ),
              (
                'Taxa de prenhez (diagnósticos)',
                summary.dairyReproduction.pregnancyRateFromLatestDiagnosis ==
                        null
                    ? 'Dados insuficientes'
                    : '${summary.dairyReproduction.pregnancyRateFromLatestDiagnosis!.toStringAsFixed(1)}%',
              ),
              (
                'Matrizes diagnosticadas',
                '${summary.dairyReproduction.cowsWithPregnancyDiagnosis}',
              ),
              (
                'Cobertura de reposição (12 meses)',
                summary.dairyReproduction.replacementCoverageRate == null
                    ? 'Sem saídas registradas'
                    : '${summary.dairyReproduction.replacementCoverageRate!.toStringAsFixed(1)}%',
              ),
              (
                'Entradas / saídas de fêmeas',
                '${summary.dairyReproduction.femaleEntries} / '
                    '${summary.dairyReproduction.femaleExits + summary.dairyReproduction.reproductiveCulls}',
              ),
              (
                'Descartes reprodutivos',
                '${summary.dairyReproduction.reproductiveCulls}',
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (productionFocus == TechnicalProductionFocus.beef) ...[
          _ModuleCard(
            width: double.infinity,
            title: 'Indicadores de corte',
            icon: Icons.trending_up_outlined,
            footnote:
                'Animais/ha e kg/ha usam a área total cadastrada da fazenda. Não representam a lotação da área de pastagem.',
            metrics: [
              (
                'Animais por hectare de área total',
                summary.stockingRate == null
                    ? 'Informe a área total'
                    : '${summary.stockingRate!.toStringAsFixed(2)} animais/ha',
              ),
              (
                'Peso vivo por hectare de área total',
                summary.liveWeightPerHectare == null
                    ? summary.areaHectares == null
                          ? 'Informe a área total'
                          : summary.activeAnimals == 0
                          ? 'Sem animais ativos'
                          : summary.activeAnimalsWithoutValidWeight > 0
                          ? 'Complete os pesos (${summary.activeAnimalsWithValidWeight}/${summary.activeAnimals})'
                          : 'Sem base válida'
                    : '${summary.liveWeightPerHectare!.toStringAsFixed(1)} kg/ha',
              ),
              (
                'Área total usada nestes índices',
                summary.areaHectares == null
                    ? 'Não cadastrada'
                    : '${summary.areaHectares!.toStringAsFixed(1)} ha',
              ),
              (
                'Ganho médio diário dos animais pareados (12 meses)',
                analysis.beefWeightGain.averageKgPerDay == null
                    ? 'Sem animais com duas pesagens válidas'
                    : '${analysis.beefWeightGain.averageKgPerDay!.toStringAsFixed(3)} kg/dia',
              ),
              (
                'Cobertura de pesagens (90 dias)',
                _beefLatestWeightCoveragePercent == null
                    ? 'Sem animais ativos'
                    : '${analysis.beefLatestWeightCoverage.weighedAnimalCount}/${analysis.beefLatestWeightCoverage.activeAnimalCount} animais '
                          '(${_beefLatestWeightCoveragePercent!.toStringAsFixed(0)}%)',
              ),
              (
                'Animais ativos sem pesagem recente',
                _beefLatestWeightCoveragePercent == null
                    ? 'Sem animais ativos'
                    : '${analysis.beefLatestWeightCoverage.unweighedAnimalCount}',
              ),
              (
                'Última pesagem de animal ativo',
                _beefLatestWeightAgeDays == null
                    ? 'Sem pesagens válidas de animais ativos'
                    : '${DateFormat('dd/MM/yyyy').format(analysis.beefLatestWeightCoverage.latestMeasurementDate!)} '
                          '· há $_beefLatestWeightAgeDays dia(s)',
              ),
              (
                'Base do ganho médio diário',
                '${analysis.beefWeightGain.animalCount}/${summary.activeAnimals} animais ativos com pares válidos',
              ),
              (
                'Taxa de desfrute comercial (12 meses)',
                summary.beefHerd.offtakeRate == null
                    ? 'Sem rebanho exposto'
                    : '${summary.beefHerd.offtakeRate!.toStringAsFixed(1)}%',
              ),
              (
                'Saídas comerciais datadas',
                '${summary.beefHerd.commercialExits}',
              ),
              (
                'Receita bruta de vendas (12 meses)',
                'R\$ ${summary.beefHerd.commercialRevenue.toStringAsFixed(2)}',
              ),
              (
                'Valor médio por cabeça',
                summary.beefHerd.averageSaleValue == null
                    ? 'Sem valores registrados'
                    : 'R\$ ${summary.beefHerd.averageSaleValue!.toStringAsFixed(2)}',
              ),
              (
                'Idade média na venda (12 meses)',
                summary.beefHerd.averageSaleAgeMonths == null
                    ? 'Sem nascimento e venda válidos'
                    : '${summary.beefHerd.averageSaleAgeMonths!.toStringAsFixed(1)} meses (aprox.)',
              ),
              (
                'Vendas com idade calculável',
                '${summary.beefHerd.salesWithKnownAge}/${summary.beefHerd.commercialExits}',
              ),
              (
                'Vendas com valor registrado',
                '${summary.beefHerd.commercialExitsWithValue}/${summary.beefHerd.commercialExits}',
              ),
              (
                'Preço médio realizado por kg',
                summary.beefHerd.averageSalePricePerKg == null
                    ? 'Informe peso e valor da venda'
                    : 'R\$ ${summary.beefHerd.averageSalePricePerKg!.toStringAsFixed(2)}/kg',
              ),
              (
                'Vendas com peso e valor',
                '${summary.beefHerd.salesWithWeightAndValue}/${summary.beefHerd.commercialExits}',
              ),
              (
                'Mortalidade (12 meses)',
                summary.beefHerd.mortalityRate == null
                    ? 'Sem rebanho exposto'
                    : '${summary.beefHerd.mortalityRate!.toStringAsFixed(1)}% '
                          '(${summary.beefHerd.mortalities})',
              ),
              (
                'Principal causa de óbito',
                summary.beefHerd.primaryMortalityCause ?? 'Sem óbitos datados',
              ),
              ('Animais ativos', '${summary.activeAnimals}'),
              (
                'Peso médio dos ativos com peso',
                summary.activeAnimalsWithValidWeight == 0
                    ? 'Sem pesos válidos'
                    : '${summary.averageWeight.toStringAsFixed(1)} kg',
              ),
              (
                'Base de pesos do rebanho ativo',
                '${summary.activeAnimalsWithValidWeight}/${summary.activeAnimals} animais',
              ),
            ],
          ),
          if (analysis.pendingWeighingAnimals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Animais para pesar'),
                subtitle: Text(
                  analysis.pendingWeighingAnimals.length == 1
                      ? '1 animal ativo sem pesagem válida nos últimos 90 dias'
                      : '${analysis.pendingWeighingAnimals.length} animais ativos sem pesagem válida nos últimos 90 dias',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPendingWeighings(context),
              ),
            ),
          ],
          const SizedBox(height: 18),
        ],
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MainIndicator(
              label: 'Animais ativos',
              value: summary.activeAnimals.toString(),
              icon: AtlasLivestockIcons.cow,
            ),
            _MainIndicator(
              label: 'Saldo financeiro',
              value: _money(summary.balance),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _MainIndicator(
              label: 'Valor em estoque',
              value: _money(summary.inventoryValue),
              icon: Icons.inventory_2_outlined,
            ),
            _MainIndicator(
              label: 'Alertas técnicos',
              value: summary.totalAlerts.toString(),
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth = width >= 1000
                ? (width - 32) / 3
                : width >= 650
                ? (width - 16) / 2
                : width;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ModuleCard(
                  width: cardWidth,
                  title: 'Rebanho',
                  icon: Icons.groups_outlined,
                  metrics: [
                    ('Animais cadastrados', '${summary.totalAnimals}'),
                    ('Animais ativos', '${summary.activeAnimals}'),
                    ('Animais vendidos', '${summary.soldAnimals}'),
                    ('Lotes', '${summary.groupCount}'),
                    (
                      'Peso médio dos ativos',
                      summary.activeAnimalsWithValidWeight == 0
                          ? 'Sem pesos válidos'
                          : '${summary.averageWeight.toStringAsFixed(0)} kg',
                    ),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Reprodução',
                  icon: Icons.favorite_outline,
                  metrics: [
                    ('Registros', '${summary.reproductionRecords}'),
                    ('Prenhezes confirmadas', '${summary.positivePregnancies}'),
                    (
                      'Eventos pendentes',
                      '${summary.pendingReproductionEvents}',
                    ),
                    (
                      'Eventos atrasados',
                      '${summary.overdueReproductionEvents}',
                    ),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Sanidade',
                  icon: Icons.health_and_safety_outlined,
                  metrics: [
                    ('Registros sanitários', '${summary.healthRecords}'),
                    ('Retornos atrasados', '${summary.overdueHealthReturns}'),
                    ('Carências ativas', '${summary.activeWithdrawals}'),
                    ('Quarentenas', '${summary.quarantines}'),
                    ('Custo sanitário', _money(summary.healthCost)),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Nutrição',
                  icon: Icons.grass_outlined,
                  metrics: [
                    ('Dietas cadastradas', '${summary.nutritionPlans}'),
                    ('Animais atendidos', '${summary.nutritionAnimals}'),
                    (
                      'Consumo diário',
                      '${summary.dailyFeedKg.toStringAsFixed(1)} kg',
                    ),
                    ('Custo diário', _money(summary.dailyFeedCost)),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Financeiro',
                  icon: Icons.payments_outlined,
                  metrics: [
                    ('Receitas', _money(summary.income)),
                    ('Despesas', _money(summary.expenses)),
                    ('Saldo', _money(summary.balance)),
                    ('Contas vencidas', '${summary.overdueAccounts}'),
                    ('Custo por animal', _money(summary.costPerActiveAnimal)),
                  ],
                ),
                _ModuleCard(
                  width: cardWidth,
                  title: 'Estoque',
                  icon: Icons.inventory_outlined,
                  metrics: [
                    ('Produtos', '${summary.inventoryItems}'),
                    ('Valor armazenado', _money(summary.inventoryValue)),
                    ('Abaixo do mínimo', '${summary.lowStockItems}'),
                    ('Sem saldo', '${summary.outOfStockItems}'),
                    ('Movimentações', '${summary.inventoryMovements}'),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WeightEvolutionCard extends StatelessWidget {
  const _WeightEvolutionCard({required this.points});

  final List<TechnicalWeightSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final recent = points.length > 6
        ? points.sublist(points.length - 6)
        : points;
    final maximum = recent.fold<double>(
      1,
      (current, point) =>
          point.averageWeight > current ? point.averageWeight : current,
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evolução do peso por animal',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Média da última pesagem válida de cada animal no mês. O número abaixo indica quantos animais compõem a média.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (recent.isEmpty)
              const SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Registre pesagens válidas para acompanhar a evolução.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = constraints.maxWidth < 520
                      ? 520.0
                      : constraints.maxWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      height: 205,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final point in recent)
                            Expanded(
                              child: Semantics(
                                label:
                                    '${point.label}: ${point.averageWeight.toStringAsFixed(1)} quilos, ${point.animalCount} animais',
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${point.averageWeight.toStringAsFixed(0)} kg',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 36,
                                      height:
                                          (point.averageWeight / maximum * 116)
                                              .clamp(12.0, 116.0)
                                              .toDouble(),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(point.label),
                                    Text(
                                      '${point.animalCount} animais',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FinancialEvolutionCard extends StatelessWidget {
  const _FinancialEvolutionCard({required this.points});

  final List<TechnicalFinancialSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final hasValues = points.any(
      (point) => point.income != 0 || point.expenses != 0,
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evolução financeira mensal',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Receitas, despesas e saldo dos meses mais recentes.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _ChartLegend(label: 'Receitas', color: Color(0xFF2E7D32)),
                _ChartLegend(label: 'Despesas', color: Color(0xFFC62828)),
                _ChartLegend(label: 'Saldo', color: Color(0xFF1565C0)),
              ],
            ),
            const SizedBox(height: 18),
            if (!hasValues)
              const SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'Cadastre receitas ou despesas para gerar o gráfico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = constraints.maxWidth < 560
                        ? 560.0
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: CustomPaint(
                          painter: _FinancialChartPainter(points),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _FinancialChartPainter extends CustomPainter {
  const _FinancialChartPainter(this.points);

  final List<TechnicalFinancialSeriesPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 62.0;
    const right = 18.0;
    const top = 14.0;
    const bottom = 48.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    if (chartWidth <= 0 || chartHeight <= 0 || points.isEmpty) return;

    var maximum = 0.0;
    for (final point in points) {
      maximum = [
        maximum,
        point.income.abs(),
        point.expenses.abs(),
        point.balance.abs(),
      ].reduce((a, b) => a > b ? a : b);
    }
    if (maximum == 0) maximum = 1;
    maximum *= 1.15;

    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.2;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final value = maximum * (1 - i / 4);
      _drawText(
        canvas,
        _compactMoney(value),
        Offset(0, y - 7),
        const TextStyle(fontSize: 10, color: Colors.black54),
        maxWidth: left - 8,
        align: TextAlign.right,
      );
    }

    final zeroY = top + chartHeight;
    canvas.drawLine(
      Offset(left, zeroY),
      Offset(size.width - right, zeroY),
      axisPaint,
    );

    final groupWidth = chartWidth / points.length;
    final barWidth = (groupWidth * 0.24).clamp(8.0, 24.0).toDouble();
    final incomePaint = Paint()..color = const Color(0xFF2E7D32);
    final expensePaint = Paint()..color = const Color(0xFFC62828);
    final balancePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFF1565C0);
    final balancePath = Path();

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final centerX = left + groupWidth * (index + 0.5);
      final incomeHeight = chartHeight * point.income / maximum;
      final expenseHeight = chartHeight * point.expenses / maximum;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth - 2,
            zeroY - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(3),
        ),
        incomePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + 2,
            zeroY - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(3),
        ),
        expensePaint,
      );

      final normalizedBalance = point.balance.clamp(0, maximum).toDouble();
      final balanceY = zeroY - chartHeight * normalizedBalance / maximum;
      if (index == 0) {
        balancePath.moveTo(centerX, balanceY);
      } else {
        balancePath.lineTo(centerX, balanceY);
      }
      canvas.drawCircle(Offset(centerX, balanceY), 3.5, pointPaint);

      _drawText(
        canvas,
        point.label,
        Offset(centerX - groupWidth / 2, zeroY + 10),
        const TextStyle(fontSize: 10, color: Colors.black54),
        maxWidth: groupWidth,
        align: TextAlign.center,
      );
    }

    canvas.drawPath(balancePath, balancePaint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)} mi';
    }
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)} mil';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(covariant _FinancialChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _MainIndicator extends StatelessWidget {
  const _MainIndicator({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.metrics,
    this.footnote,
  });

  final double width;
  final String title;
  final IconData icon;
  final List<(String, String)> metrics;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1B5E20)),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...metrics.map(
                (metric) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          metric.$1,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          metric.$2,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (footnote != null) ...[
                const Divider(height: 20),
                Text(footnote!, style: const TextStyle(color: Colors.black54)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.home_work_outlined, size: 54, color: Colors.black38),
              SizedBox(height: 14),
              Text(
                'Cadastre uma fazenda para gerar o painel técnico.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(double value) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
}
