import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_management_summary.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_management_service.dart';
import 'package:projeto_atlas/features/atlas_bi/presentation/screens/atlas_bi_management_dashboard_screen.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_forecast_service.dart';
import 'package:projeto_atlas/features/atlas_bi/presentation/screens/atlas_bi_forecast_screen.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_benchmark_service.dart';
import 'package:projeto_atlas/features/atlas_bi/presentation/screens/atlas_bi_benchmark_screen.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/services/atlas_bi_analytics_service.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/presentation/screens/atlas_bi_analytics_screen.dart';
import 'package:projeto_atlas/features/atlas_bi/presentation/screens/atlas_bi_screen.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/models/atlas_executive_intelligence_data.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/services/atlas_executive_intelligence_service.dart';
import 'package:projeto_atlas/features/executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/models/atlas_executive_ai_advisor_data.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/services/atlas_executive_ai_advisor_service.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/presentation/screens/atlas_executive_ai_advisor_screen.dart';
import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';
import 'package:projeto_atlas/features/decision_engine/domain/services/atlas_decision_engine_service.dart';
import 'package:projeto_atlas/features/decision_engine/presentation/screens/atlas_decision_engine_screen.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/services/atlas_predictive_analytics_service.dart';
import 'package:projeto_atlas/features/predictive_analytics/presentation/screens/atlas_predictive_analytics_screen.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/services/atlas_workflow_service.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/models/atlas_decision_engine_v2_data.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/services/atlas_decision_engine_v2_service.dart';
import 'package:projeto_atlas/features/decision_engine_v2/presentation/screens/atlas_decision_engine_v2_screen.dart';
import 'package:projeto_atlas/features/mission_control/domain/models/atlas_mission_control_data.dart';
import 'package:projeto_atlas/features/mission_control/domain/services/atlas_mission_control_service.dart';
import 'package:projeto_atlas/features/mission_control/presentation/screens/atlas_mission_control_screen.dart';

class AtlasBiHubScreen extends StatefulWidget {
  const AtlasBiHubScreen({required this.data, this.onOpenFarm, super.key});

  final AtlasBiData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasBiHubScreen> createState() {
    return _AtlasBiHubScreenState();
  }
}

class _AtlasBiHubScreenState extends State<AtlasBiHubScreen> {
  final AtlasBiForecastService forecastService = const AtlasBiForecastService();

  final AtlasBiManagementService managementService =
      const AtlasBiManagementService();

  final AtlasBiBenchmarkService benchmarkService =
      const AtlasBiBenchmarkService();

  final AtlasBiAnalyticsService analyticsService =
      const AtlasBiAnalyticsService();

  final AtlasExecutiveIntelligenceService executiveIntelligenceService =
      const AtlasExecutiveIntelligenceService();

  final AtlasExecutiveAiAdvisorService executiveAdvisorService =
      const AtlasExecutiveAiAdvisorService();

  final AtlasDecisionEngineService decisionEngineService =
      const AtlasDecisionEngineService();

  final AtlasPredictiveAnalyticsService predictiveAnalyticsService =
      const AtlasPredictiveAnalyticsService();

  final AtlasWorkflowService workflowService = const AtlasWorkflowService();

  final AtlasDecisionEngineV2Service decisionEngineV2Service =
      const AtlasDecisionEngineV2Service();

  final AtlasMissionControlService missionControlService =
      const AtlasMissionControlService();

  int selectedHorizonDays = 90;

  AtlasBiManagementSummary get managementSummary {
    return managementService.build(widget.data);
  }

  AtlasBiForecastDashboardData get forecastData {
    return forecastService.buildDashboard(
      indicators: widget.data.indicators,
      horizonDays: selectedHorizonDays,
    );
  }

  AtlasBiBenchmarkData get benchmarkData {
    return benchmarkService.build(data: widget.data);
  }

  AtlasBiAnalyticsData get analyticsData {
    return analyticsService.build(
      input: AtlasBiAnalyticsInput(
        indicators: widget.data.indicators,
        defaultInvestmentValue: 10000.0,
      ),
    );
  }

  AtlasExecutiveIntelligenceData get executiveIntelligenceData {
    return executiveIntelligenceService.build(
      bi: widget.data,
      forecast: forecastData,
      benchmark: benchmarkData,
      analytics: analyticsData,
    );
  }

  AtlasExecutiveAiAdvisorData get executiveAdvisorData {
    return executiveAdvisorService.build(
      bi: widget.data,
      forecast: forecastData,
      benchmark: benchmarkData,
      analytics: analyticsData,
      intelligence: executiveIntelligenceData,
    );
  }

  AtlasDecisionEngineData get decisionEngineData {
    return decisionEngineService.build(
      bi: widget.data,
      forecast: forecastData,
      benchmark: benchmarkData,
      analytics: analyticsData,
      intelligence: executiveIntelligenceData,
      advisor: executiveAdvisorData,
    );
  }

  AtlasPredictiveAnalyticsData get predictiveAnalyticsData {
    return predictiveAnalyticsService.build(
      indicators: widget.data.indicators,
      horizonDays: selectedHorizonDays,
    );
  }

  AtlasWorkflowData get workflowData {
    return workflowService.buildDashboard(workflows: const <AtlasWorkflow>[]);
  }

  AtlasDecisionEngineV2Data get decisionEngineV2Data {
    return decisionEngineV2Service.build(
      decisionEngine: decisionEngineData,
      predictive: predictiveAnalyticsData,
      workflow: workflowData,
    );
  }

  AtlasMissionControlData get missionControlData {
    return missionControlService.build(
      decisionEngine: decisionEngineV2Data,
      predictive: predictiveAnalyticsData,
      workflow: workflowData,
      userName: 'Gabriel',
    );
  }

  Future<void> _openManagementDashboard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasBiManagementDashboardScreen(data: managementSummary);
        },
      ),
    );
  }

  Future<void> _openAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasBiScreen(
            data: widget.data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openForecast() async {
    final data = forecastData;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasBiForecastScreen(
            data: data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openBenchmark() async {
    final data = benchmarkData;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasBiBenchmarkScreen(
            data: data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openAdvancedAnalytics() async {
    final data = analyticsData;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasBiAnalyticsScreen(
            data: data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openExecutiveIntelligence() async {
    final data = executiveIntelligenceData;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasExecutiveIntelligenceScreen(
            data: data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openExecutiveAdvisor() async {
    final data = executiveAdvisorData;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasExecutiveAiAdvisorScreen(
            data: data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openDecisionEngine() async {
    final data = decisionEngineData;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasDecisionEngineScreen(
            data: data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openPredictiveAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasPredictiveAnalyticsScreen(
            data: predictiveAnalyticsData,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openDecisionEngineV2() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasDecisionEngineV2Screen(
            data: decisionEngineV2Data,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  Future<void> _openMissionControl() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasMissionControlScreen(
            data: missionControlData,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forecast = forecastData;
    final benchmark = benchmarkData;
    final analytics = analyticsData;
    final executiveIntelligence = executiveIntelligenceData;
    final executiveAdvisor = executiveAdvisorData;
    final decisionEngine = decisionEngineData;
    final predictive = predictiveAnalyticsData;
    final decisionV2 = decisionEngineV2Data;
    final mission = missionControlData;

    final priority = forecast.priorityForecast;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Central Atlas BI',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _BiHubHero(data: widget.data, forecast: forecast),
                const SizedBox(height: 22),
                _HorizonSelector(
                  selectedDays: selectedHorizonDays,
                  onChanged: (value) {
                    setState(() {
                      selectedHorizonDays = value;
                    });
                  },
                ),
                const SizedBox(height: 22),
                _HubAccessCard(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Business Intelligence 2.0',
                  description:
                      'Pulso executivo, metas, tendências por área e prioridades gerenciais.',
                  metric: '${managementSummary.score.toStringAsFixed(0)}/100',
                  metricLabel: managementSummary.statusLabel,
                  buttonLabel: 'Abrir BI 2.0',
                  onPressed: _openManagementDashboard,
                  colors: const [Color(0xFF0B1F33), Color(0xFF176B87)],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final analyticsCard = _HubAccessCard(
                      icon: Icons.analytics_outlined,
                      title: 'Análise consolidada',
                      description:
                          'Ranking das fazendas, indicadores, tendências e insights automáticos.',
                      metric: '${widget.data.score.toStringAsFixed(0)}/100',
                      metricLabel: atlasBiStatusLabel(widget.data.status),
                      buttonLabel: 'Abrir Atlas BI',
                      onPressed: _openAnalytics,
                      colors: const [Color(0xFF0B1F33), Color(0xFF1E5F8A)],
                    );

                    final forecastCard = _HubAccessCard(
                      icon: Icons.auto_graph_outlined,
                      title: 'Forecast preditivo',
                      description:
                          'Projeções, probabilidade de atingir metas, confiança e risco futuro.',
                      metric: '${forecast.highRiskCount}',
                      metricLabel: 'alto risco',
                      buttonLabel: 'Abrir Forecast',
                      onPressed: _openForecast,
                      colors: const [Color(0xFF161A30), Color(0xFF54507A)],
                    );

                    if (compact) {
                      return Column(
                        children: [
                          analyticsCard,
                          const SizedBox(height: 14),
                          forecastCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: analyticsCard),
                        const SizedBox(width: 14),
                        Expanded(child: forecastCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final benchmarkCard = _HubAccessCard(
                      icon: Icons.leaderboard_outlined,
                      title: 'Benchmarking',
                      description:
                          'Ranking das fazendas, referências internas e oportunidades de melhoria.',
                      metric: '${benchmark.farms.length}',
                      metricLabel: benchmark.farms.length == 1
                          ? 'fazenda comparada'
                          : 'fazendas comparadas',
                      buttonLabel: 'Abrir Benchmarking',
                      onPressed: _openBenchmark,
                      colors: const [Color(0xFF102027), Color(0xFF3A7378)],
                    );

                    final analyticsCard = _HubAccessCard(
                      icon: Icons.insights_outlined,
                      title: 'Analytics Avançado',
                      description:
                          'Gargalos, ROI, correlações, cenários e ranking de investimentos.',
                      metric: '${analytics.score.toStringAsFixed(0)}/100',
                      metricLabel: 'score analítico',
                      buttonLabel: 'Abrir Analytics',
                      onPressed: _openAdvancedAnalytics,
                      colors: const [Color(0xFF1A1033), Color(0xFF5B3B82)],
                    );

                    if (compact) {
                      return Column(
                        children: [
                          benchmarkCard,
                          const SizedBox(height: 14),
                          analyticsCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: benchmarkCard),
                        const SizedBox(width: 14),
                        Expanded(child: analyticsCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final intelligenceCard = _HubAccessCard(
                      icon: Icons.psychology_alt_outlined,
                      title: 'Inteligência Executiva',
                      description:
                          'Causas-raiz, efeitos em cadeia, consequências futuras e prioridades executivas.',
                      metric:
                          '${executiveIntelligence.intelligenceScore.toStringAsFixed(0)}/100',
                      metricLabel: atlasExecutiveIntelligenceMaturityLabel(
                        executiveIntelligence.maturity,
                      ),
                      buttonLabel: 'Abrir Inteligência',
                      onPressed: _openExecutiveIntelligence,
                      colors: const [Color(0xFF071A2B), Color(0xFF20639B)],
                    );

                    final advisorCard = _HubAccessCard(
                      icon: Icons.smart_toy_outlined,
                      title: 'Executive AI Advisor',
                      description:
                          'Parecer executivo, diagnóstico, prioridades, riscos ocultos e plano de ação.',
                      metric:
                          '${executiveAdvisor.advisorScore.toStringAsFixed(0)}/100',
                      metricLabel: atlasExecutiveAdvisorStatusLabel(
                        executiveAdvisor.status,
                      ),
                      buttonLabel: 'Abrir Advisor',
                      onPressed: _openExecutiveAdvisor,
                      colors: const [Color(0xFF0B132B), Color(0xFF3A506B)],
                    );

                    if (compact) {
                      return Column(
                        children: [
                          intelligenceCard,
                          const SizedBox(height: 14),
                          advisorCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: intelligenceCard),
                        const SizedBox(width: 14),
                        Expanded(child: advisorCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _DecisionEngineAccessCard(
                  data: decisionEngine,
                  onOpen: _openDecisionEngine,
                ),
                const SizedBox(height: 14),
                _MissionControlHubCard(
                  data: mission,
                  onOpen: _openMissionControl,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final predictiveCard = _HubAccessCard(
                      icon: Icons.auto_graph_outlined,
                      title: 'Predictive Analytics',
                      description:
                          'Previsões, riscos futuros, cenários e simulações E se...?',
                      metric: predictive.score.toStringAsFixed(0),
                      metricLabel: atlasPredictiveAnalyticsStatusLabel(
                        predictive.status,
                      ),
                      buttonLabel: 'Abrir previsões',
                      onPressed: _openPredictiveAnalytics,
                      colors: const [Color(0xFF081C24), Color(0xFF1F6D79)],
                    );

                    final decisionV2Card = _HubAccessCard(
                      icon: Icons.hub_outlined,
                      title: 'Decision Engine 2.0',
                      description:
                          'Melhor ação de hoje, planos diário, semanal e mensal.',
                      metric: decisionV2.score.toStringAsFixed(0),
                      metricLabel: atlasDecisionEngineV2StatusLabel(
                        decisionV2.status,
                      ),
                      buttonLabel: 'Abrir decisões 2.0',
                      onPressed: _openDecisionEngineV2,
                      colors: const [Color(0xFF0A192F), Color(0xFF28536B)],
                    );

                    if (compact) {
                      return Column(
                        children: [
                          predictiveCard,
                          const SizedBox(height: 14),
                          decisionV2Card,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: predictiveCard),
                        const SizedBox(width: 14),
                        Expanded(child: decisionV2Card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                const _SectionTitle(
                  title: 'Resumo da inteligência preditiva',
                  subtitle:
                      'Visão consolidada das tendências para o horizonte selecionado.',
                ),
                const SizedBox(height: 13),
                _ForecastSummaryCard(data: forecast),
                if (priority != null) ...[
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Prioridade preditiva',
                    subtitle:
                        'Indicador que exige maior atenção considerando risco e probabilidade da meta.',
                  ),
                  const SizedBox(height: 13),
                  _PriorityForecastCard(
                    forecast: priority,
                    onOpenFarm: widget.onOpenFarm,
                  ),
                ],
                const SizedBox(height: 26),
                const _SectionTitle(
                  title: 'Inteligência comparativa',
                  subtitle:
                      'Referência interna e desempenho médio das fazendas.',
                ),
                const SizedBox(height: 13),
                _HubBenchmarkSummary(data: benchmark, onOpen: _openBenchmark),
                const SizedBox(height: 26),
                const _SectionTitle(
                  title: 'Inteligência de decisão',
                  subtitle:
                      'Principal gargalo e melhor oportunidade de investimento.',
                ),
                const SizedBox(height: 13),
                _HubAnalyticsSummary(
                  data: analytics,
                  onOpen: _openAdvancedAnalytics,
                ),
                const SizedBox(height: 26),
                const _SectionTitle(
                  title: 'Cérebro executivo do Atlas',
                  subtitle:
                      'Causas, parecer e decisão prioritária consolidados em uma única visão.',
                ),
                const SizedBox(height: 13),
                _ExecutiveIntelligenceSummaryCard(
                  data: executiveIntelligence,
                  onOpen: _openExecutiveIntelligence,
                ),
                const SizedBox(height: 13),
                _ExecutiveAdvisorSummaryCard(
                  data: executiveAdvisor,
                  onOpen: _openExecutiveAdvisor,
                ),
                const SizedBox(height: 13),
                _DecisionEngineSummaryCard(
                  data: decisionEngine,
                  onOpen: _openDecisionEngine,
                  onOpenFarm: widget.onOpenFarm,
                ),
                const SizedBox(height: 26),
                const _SectionTitle(
                  title: 'Indicadores com maior risco',
                  subtitle: 'Projeções ordenadas por criticidade.',
                ),
                const SizedBox(height: 13),
                _RiskForecastList(
                  forecasts: forecast.forecasts
                      .where((item) {
                        return item.risk == AtlasBiForecastRisk.critical ||
                            item.risk == AtlasBiForecastRisk.high;
                      })
                      .take(6)
                      .toList(),
                  onOpenFarm: widget.onOpenFarm,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BiHubHero extends StatelessWidget {
  const _BiHubHero({required this.data, required this.forecast});

  final AtlasBiData data;
  final AtlasBiForecastDashboardData forecast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A2B), Color(0xFF123A5A), Color(0xFF3F3C68)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_outlined, color: Color(0xFF80DEEA), size: 32),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Central de Inteligência',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Indicadores',
                    value: data.indicators.length,
                  ),
                  _HeroMetric(label: 'Fazendas', value: data.rankings.length),
                  _HeroMetric(label: 'Insights', value: data.insights.length),
                  _HeroMetric(
                    label: 'Projeções',
                    value: forecast.forecasts.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.score.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Color(0xFF80DEEA),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Score analítico',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: data.score / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF80DEEA),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), side],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _HorizonSelector extends StatelessWidget {
  const _HorizonSelector({required this.selectedDays, required this.onChanged});

  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const horizons = [30, 60, 90, 180];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 11),
            const Expanded(
              child: Text(
                'Horizonte da previsão',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: horizons.map((days) {
                return ChoiceChip(
                  label: Text('$days dias'),
                  selected: selectedDays == days,
                  onSelected: (_) {
                    onChanged(days);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubAccessCard extends StatelessWidget {
  const _HubAccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.metric,
    required this.metricLabel,
    required this.buttonLabel,
    required this.onPressed,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String description;
  final String metric;
  final String metricLabel;
  final String buttonLabel;
  final VoidCallback onPressed;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFB2EBF2), size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              metric,
              style: const TextStyle(
                color: Color(0xFFB2EBF2),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              metricLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB2EBF2),
                foregroundColor: const Color(0xFF071A2B),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastSummaryCard extends StatelessWidget {
  const _ForecastSummaryCard({required this.data});

  final AtlasBiForecastDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _SummaryMetric(
                  label: 'Positivos',
                  value: data.positiveCount,
                  icon: Icons.trending_up,
                  color: const Color(0xFF1B5E20),
                ),
                _SummaryMetric(
                  label: 'Estáveis',
                  value: data.stableCount,
                  icon: Icons.trending_flat,
                  color: const Color(0xFF1565C0),
                ),
                _SummaryMetric(
                  label: 'Negativos',
                  value: data.negativeCount,
                  icon: Icons.trending_down,
                  color: const Color(0xFFEF6C00),
                ),
                _SummaryMetric(
                  label: 'Alto risco',
                  value: data.highRiskCount,
                  icon: Icons.warning_amber_outlined,
                  color: const Color(0xFFC62828),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityForecastCard extends StatelessWidget {
  const _PriorityForecastCard({
    required this.forecast,
    required this.onOpenFarm,
  });

  final AtlasBiForecast forecast;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _forecastRiskColor(forecast.risk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.crisis_alert_outlined, color: color, size: 28),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        forecast.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  atlasBiForecastRiskLabel(forecast.risk),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              forecast.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label:
                      '${forecast.targetProbabilityPercent.toStringAsFixed(0)}% de chance da meta',
                  color: const Color(0xFF1565C0),
                ),
                _InfoChip(
                  label:
                      '${forecast.confidencePercent.toStringAsFixed(0)}% de confiança',
                  color: const Color(0xFF455A64),
                ),
                _InfoChip(
                  label: atlasBiForecastTrendLabel(forecast.trend),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              forecast.recommendation,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                avatar: const Icon(Icons.agriculture_outlined, size: 16),
                label: const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(forecast.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskForecastList extends StatelessWidget {
  const _RiskForecastList({required this.forecasts, required this.onOpenFarm});

  final List<AtlasBiForecast> forecasts;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhuma projeção em risco alto ou crítico.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Column(
      children: forecasts.map((forecast) {
        final color = _forecastRiskColor(forecast.risk);

        return Card(
          child: ListTile(
            leading: Icon(Icons.auto_graph_outlined, color: color),
            title: Text(
              forecast.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${forecast.farmName} · '
              '${forecast.targetProbabilityPercent.toStringAsFixed(0)}% de chance da meta',
            ),
            trailing: Text(
              atlasBiForecastRiskLabel(forecast.risk),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(forecast.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _HubBenchmarkSummary extends StatelessWidget {
  const _HubBenchmarkSummary({required this.data, required this.onOpen});

  final AtlasBiBenchmarkData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final leader = data.farms.isEmpty ? null : data.farms.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.leaderboard_outlined,
                  color: Color(0xFF234E52),
                  size: 28,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Benchmarking interno',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Abrir'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            if (leader != null) ...[
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF234E52).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Referência atual: '
                  '${leader.farmName} · '
                  '${leader.score.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    color: Color(0xFF234E52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubAnalyticsSummary extends StatelessWidget {
  const _HubAnalyticsSummary({required this.data, required this.onOpen});

  final AtlasBiAnalyticsData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final bottleneck = data.mainBottleneck;
    final investment = data.bestInvestment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_outlined,
                  color: Color(0xFF5B3B82),
                  size: 28,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Analytics avançado',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Abrir'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            if (bottleneck != null) ...[
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Gargalo principal: '
                  '${bottleneck.indicatorTitle} · '
                  '${bottleneck.farmName}',
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (investment != null) ...[
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Melhor investimento: '
                  '${investment.title} · '
                  '${investment.roiPercent.toStringAsFixed(1)}% de ROI',
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissionControlHubCard extends StatelessWidget {
  const _MissionControlHubCard({required this.data, required this.onOpen});

  final AtlasMissionControlData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.status) {
      AtlasMissionControlStatus.stable => const Color(0xFF80CBC4),
      AtlasMissionControlStatus.attention => const Color(0xFFFFCC80),
      AtlasMissionControlStatus.highRisk => const Color(0xFFEF9A9A),
      AtlasMissionControlStatus.critical => const Color(0xFFFF8A80),
    };

    final priority = data.topPriority;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF07111F), Color(0xFF132A3A), Color(0xFF254B62)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar_outlined, color: color, size: 32),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Text(
                          'Atlas Mission Control',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: '${data.priorities.length} prioridades',
                        color: const Color(0xFFFFCC80),
                      ),
                      _InfoChip(
                        label: '${data.alerts.length} alertas',
                        color: const Color(0xFFEF9A9A),
                      ),
                      _InfoChip(
                        label: '${data.dailyPlan.length} ações hoje',
                        color: const Color(0xFF90CAF9),
                      ),
                    ],
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 13),
                    Text(
                      'Prioridade nº 1: '
                      '${priority.title} · ${priority.farmName}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 235,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.globalScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasMissionControlStatusLabel(data.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${data.executionProbabilityPercent.toStringAsFixed(0)}% de execução prevista',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB3E5FC),
                        foregroundColor: const Color(0xFF07111F),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir controle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
                  side,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DecisionEngineAccessCard extends StatelessWidget {
  const _DecisionEngineAccessCard({required this.data, required this.onOpen});

  final AtlasDecisionEngineData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final decision = data.mainDecision;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(21),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF101820), Color(0xFF1E3A5F), Color(0xFF345995)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        color: Color(0xFFB3E5FC),
                        size: 31,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Atlas Decision Engine',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    data.summary,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  if (decision != null) ...[
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Decisão prioritária: '
                        '${decision.title} · '
                        '${decision.farmName}',
                        style: const TextStyle(
                          color: Color(0xFFB3E5FC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 230,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.engineScore.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Color(0xFFB3E5FC),
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasDecisionEngineStatusLabel(data.status),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${data.confidencePercent.toStringAsFixed(0)}% de confiança',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB3E5FC),
                        foregroundColor: const Color(0xFF101820),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir decisões',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
                  side,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExecutiveIntelligenceSummaryCard extends StatelessWidget {
  const _ExecutiveIntelligenceSummaryCard({
    required this.data,
    required this.onOpen,
  });

  final AtlasExecutiveIntelligenceData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cause = data.mainRootCause;
    final priority = data.topPriority;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_alt_outlined,
                  color: Color(0xFF20639B),
                  size: 28,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Inteligência Executiva',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Abrir'),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              data.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            if (cause != null) ...[
              const SizedBox(height: 12),
              _ExecutiveSummaryLine(
                icon: Icons.search_outlined,
                label: 'Causa-raiz principal',
                value: '${cause.title} · ${cause.farmName}',
                color: const Color(0xFFC62828),
              ),
            ],
            if (priority != null) ...[
              const SizedBox(height: 8),
              _ExecutiveSummaryLine(
                icon: Icons.flag_outlined,
                label: 'Prioridade executiva',
                value: '${priority.title} · ${priority.deadlineDays} dias',
                color: const Color(0xFFEF6C00),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExecutiveAdvisorSummaryCard extends StatelessWidget {
  const _ExecutiveAdvisorSummaryCard({
    required this.data,
    required this.onOpen,
  });

  final AtlasExecutiveAiAdvisorData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final weeklyPriority = data.weeklyPriorities.isEmpty
        ? null
        : data.weeklyPriorities.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  color: Color(0xFF3A506B),
                  size: 28,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Parecer do AI Advisor',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Abrir'),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              data.executiveSummary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 11),
            _ExecutiveSummaryLine(
              icon: Icons.assignment_outlined,
              label: 'Diagnóstico',
              value: data.diagnostic,
              color: const Color(0xFF3A506B),
            ),
            if (weeklyPriority != null) ...[
              const SizedBox(height: 8),
              _ExecutiveSummaryLine(
                icon: Icons.today_outlined,
                label: 'Prioridade da semana',
                value: '${weeklyPriority.title} · ${weeklyPriority.farmName}',
                color: const Color(0xFFEF6C00),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionEngineSummaryCard extends StatelessWidget {
  const _DecisionEngineSummaryCard({
    required this.data,
    required this.onOpen,
    required this.onOpenFarm,
  });

  final AtlasDecisionEngineData data;
  final VoidCallback onOpen;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final decision = data.mainDecision;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  color: Color(0xFF345995),
                  size: 28,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Decisão recomendada',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Abrir'),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              data.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            if (decision != null) ...[
              const SizedBox(height: 13),
              Text(
                decision.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                decision.farmName,
                style: const TextStyle(
                  color: Color(0xFF345995),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    label:
                        'Urgência: ${atlasDecisionUrgencyLabel(decision.urgency)}',
                    color: const Color(0xFFEF6C00),
                  ),
                  _InfoChip(
                    label: 'Risco: ${atlasDecisionRiskLabel(decision.risk)}',
                    color: const Color(0xFFC62828),
                  ),
                  _InfoChip(
                    label:
                        '${decision.confidencePercent.toStringAsFixed(0)}% de confiança',
                    color: const Color(0xFF1565C0),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                'Impacto financeiro esperado: '
                'R\$ ${decision.expectedFinancialImpact.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onOpenFarm != null) ...[
                const SizedBox(height: 11),
                ActionChip(
                  avatar: const Icon(Icons.agriculture_outlined, size: 16),
                  label: const Text('Abrir fazenda'),
                  onPressed: () {
                    onOpenFarm!(decision.farmName);
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ExecutiveSummaryLine extends StatelessWidget {
  const _ExecutiveSummaryLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, height: 1.35),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
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

Color _forecastRiskColor(AtlasBiForecastRisk risk) {
  switch (risk) {
    case AtlasBiForecastRisk.low:
      return const Color(0xFF1B5E20);

    case AtlasBiForecastRisk.medium:
      return const Color(0xFFEF6C00);

    case AtlasBiForecastRisk.high:
      return const Color(0xFFC62828);

    case AtlasBiForecastRisk.critical:
      return const Color(0xFF8E0000);
  }
}
