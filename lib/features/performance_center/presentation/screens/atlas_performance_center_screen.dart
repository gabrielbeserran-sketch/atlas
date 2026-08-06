import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/benefits_realization/presentation/screens/atlas_benefits_realization_screen.dart';
import 'package:projeto_atlas/features/continuous_improvement/presentation/screens/atlas_continuous_improvement_screen.dart';
import 'package:projeto_atlas/features/action_plan/data/services/atlas_action_plan_storage_service.dart';
import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/action_plan/presentation/screens/atlas_action_plan_screen.dart';
import 'package:projeto_atlas/features/farm_audit/data/services/atlas_farm_audit_history_service.dart';
import 'package:projeto_atlas/features/performance_center/domain/models/atlas_performance_snapshot.dart';
import 'package:projeto_atlas/features/performance_center/domain/services/atlas_performance_engine.dart';

class AtlasPerformanceCenterScreen extends StatefulWidget {
  const AtlasPerformanceCenterScreen({super.key, this.farmId});
  final String? farmId;

  @override
  State<AtlasPerformanceCenterScreen> createState() =>
      _AtlasPerformanceCenterScreenState();
}

class _AtlasPerformanceCenterScreenState
    extends State<AtlasPerformanceCenterScreen> {
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  bool loading = true;
  bool refreshing = false;
  bool refreshRequested = false;
  late final String reactiveRegistrationId;
  AtlasPerformanceSnapshot? snapshot;
  AtlasActionPlan? plan;

  @override
  void initState() {
    super.initState();
    AtlasReactiveRuntime.instance.start();
    reactiveRegistrationId = reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.performanceCenter,
      owner: 'atlas_performance_center_screen',
      handler: _handleReactiveUpdate,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.performanceCenter,
      registrationId: reactiveRegistrationId,
    );
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.performanceCenter)) {
      return;
    }

    final farmId = widget.farmId;
    final hasRelevantEvent = farmId == null ||
        update.events.any((event) {
          final eventFarmId = event.farmId?.trim();
          return eventFarmId == null ||
              eventFarmId.isEmpty ||
              eventFarmId == farmId;
        });

    if (!hasRelevantEvent) {
      return;
    }

    await _load(showLoading: false);
  }

  Future<void> _load({bool showLoading = true}) async {
    if (refreshing) {
      refreshRequested = true;
      return;
    }

    refreshing = true;

    if (showLoading && mounted) {
      setState(() => loading = true);
    }

    try {
      final audits = await AtlasFarmAuditHistoryService.instance.loadAll();
    final filtered = widget.farmId == null
        ? audits
        : audits.where((audit) => audit.farmId == widget.farmId).toList();
    if (filtered.isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
          snapshot = null;
          plan = null;
        });
      }

      return;
    }
    final current = filtered.first;
    final previous = filtered.length > 1 ? filtered[1] : null;
    final loadedPlan = await AtlasActionPlanStorageService.instance
        .latestForFarm(current.farmId);
    if (!mounted) return;
    setState(() {
      plan = loadedPlan;
      snapshot = loadedPlan == null
          ? null
          : const AtlasPerformanceEngine().generate(
              plan: loadedPlan,
              currentAudit: current,
              previousAudit: previous,
            );
      loading = false;
    });
  } finally {
      refreshing = false;

      if (refreshRequested && mounted) {
        refreshRequested = false;
        unawaited(_load(showLoading: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Performance Center',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir realização de benefícios',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasBenefitsRealizationScreen(
                      farmId: widget.farmId,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Abrir melhoria contínua',
            onPressed: loading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return AtlasContinuousImprovementScreen(
                            farmId: widget.farmId,
                          );
                        },
                      ),
                    );
                  },
            icon: const Icon(Icons.autorenew),
          ),
          IconButton(
            tooltip: 'Atualizar desempenho',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : snapshot == null
          ? _Empty(
              onOpenPlan: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AtlasActionPlanScreen(farmId: widget.farmId),
                  ),
                );
                await _load();
              },
            )
          : _PerformanceBody(snapshot: snapshot!),
    );
  }
}

class _PerformanceBody extends StatelessWidget {
  const _PerformanceBody({required this.snapshot});
  final AtlasPerformanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _Hero(snapshot: snapshot),
            const SizedBox(height: 18),
            _Metrics(snapshot: snapshot),
            const SizedBox(height: 26),
            const _SectionTitle(
              title: 'Alertas inteligentes',
              subtitle: 'Situações que exigem atenção no ciclo atual.',
            ),
            const SizedBox(height: 12),
            ...snapshot.alerts.map((alert) => _AlertCard(alert: alert)),
            const SizedBox(height: 26),
            const _SectionTitle(
              title: 'KPIs e tendências',
              subtitle: 'Comparação antes × depois e avanço em direção à meta.',
            ),
            const SizedBox(height: 12),
            ...snapshot.kpis.map((kpi) => _KpiCard(kpi: kpi)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.snapshot});
  final AtlasPerformanceSnapshot snapshot;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF07111F), Color(0xFF17384D), Color(0xFF236075)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: snapshot.executionScore / 100,
                strokeWidth: 10,
                backgroundColor: Colors.white12,
                color: _scoreColor(snapshot.executionScore),
              ),
              Text(
                snapshot.executionScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Atlas Execution Score',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.farmName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _scoreLabel(snapshot.executionScore),
                style: TextStyle(
                  color: _scoreColor(snapshot.executionScore),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.snapshot});
  final AtlasPerformanceSnapshot snapshot;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final columns = constraints.maxWidth >= 850 ? 4 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Metric(
            width: width,
            label: 'Execução geral',
            value: '${snapshot.planProgress.toStringAsFixed(0)}%',
            icon: Icons.task_alt_outlined,
          ),
          _Metric(
            width: width,
            label: 'Concluídas no prazo',
            value: '${snapshot.onTimeRate.toStringAsFixed(0)}%',
            icon: Icons.schedule_outlined,
          ),
          _Metric(
            width: width,
            label: 'Impacto realizado',
            value: _money(snapshot.realizedImpact),
            icon: Icons.payments_outlined,
          ),
          _Metric(
            width: width,
            label: 'Impacto esperado',
            value: _money(snapshot.expectedImpact),
            icon: Icons.trending_up_outlined,
          ),
        ],
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final AtlasPerformanceAlert alert;
  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.severity);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(Icons.notifications_active_outlined, color: color),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(alert.message),
        trailing: Text(
          atlasPerformanceAlertSeverityLabel(alert.severity),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final AtlasPerformanceKpi kpi;
  @override
  Widget build(BuildContext context) {
    final color = _trendColor(kpi.trend);
    final sign = kpi.variation > 0 ? '+' : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    kpi.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(_trendIcon(kpi.trend), color: color),
                const SizedBox(width: 6),
                Text(
                  atlasPerformanceTrendLabel(kpi.trend),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Value(
                    label: 'Antes',
                    value: '${kpi.beforeValue.toStringAsFixed(1)} ${kpi.unit}',
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.black26),
                Expanded(
                  child: _Value(
                    label: 'Agora',
                    value: '${kpi.currentValue.toStringAsFixed(1)} ${kpi.unit}',
                  ),
                ),
                Expanded(
                  child: _Value(
                    label: 'Variação',
                    value: '$sign${kpi.variation.toStringAsFixed(1)}',
                  ),
                ),
                Expanded(
                  child: _Value(
                    label: 'Meta',
                    value: '${kpi.targetValue.toStringAsFixed(0)} ${kpi.unit}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: kpi.targetProgress.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              kpi.interpretation,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
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

class _Empty extends StatelessWidget {
  const _Empty({required this.onOpenPlan});
  final VoidCallback onOpenPlan;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights_outlined, size: 66, color: Colors.black26),
          const SizedBox(height: 12),
          const Text(
            'Ainda não existe um Plano de Ação para medir.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenPlan,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Abrir Plano de Ação'),
          ),
        ],
      ),
    ),
  );
}

Color _scoreColor(double score) => score >= 80
    ? const Color(0xFF66BB6A)
    : score >= 60
    ? const Color(0xFF42A5F5)
    : score >= 40
    ? const Color(0xFFFFB74D)
    : const Color(0xFFEF5350);
String _scoreLabel(double score) => score >= 80
    ? 'Execução de alta performance'
    : score >= 60
    ? 'Execução consistente'
    : score >= 40
    ? 'Execução exige atenção'
    : 'Execução crítica';
Color _trendColor(AtlasPerformanceTrend trend) {
  switch (trend) {
    case AtlasPerformanceTrend.improving:
      return const Color(0xFF2E7D32);
    case AtlasPerformanceTrend.stable:
      return const Color(0xFF1565C0);
    case AtlasPerformanceTrend.worsening:
      return const Color(0xFFC62828);
  }
}

IconData _trendIcon(AtlasPerformanceTrend trend) {
  switch (trend) {
    case AtlasPerformanceTrend.improving:
      return Icons.trending_up;
    case AtlasPerformanceTrend.stable:
      return Icons.trending_flat;
    case AtlasPerformanceTrend.worsening:
      return Icons.trending_down;
  }
}

Color _alertColor(AtlasPerformanceAlertSeverity severity) {
  switch (severity) {
    case AtlasPerformanceAlertSeverity.information:
      return const Color(0xFF1565C0);
    case AtlasPerformanceAlertSeverity.attention:
      return const Color(0xFFF9A825);
    case AtlasPerformanceAlertSeverity.high:
      return const Color(0xFFEF6C00);
    case AtlasPerformanceAlertSeverity.critical:
      return const Color(0xFFC62828);
  }
}

String _money(double value) {
  final fixed = value.abs().toStringAsFixed(2).split('.');
  final integer = fixed[0];
  final buffer = StringBuffer();
  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;
    buffer.write(integer[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${value < 0 ? '-' : ''}R\$ ${buffer.toString()},${fixed[1]}';
}
