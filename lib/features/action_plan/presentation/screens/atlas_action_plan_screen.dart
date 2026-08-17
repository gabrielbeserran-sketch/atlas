import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/strategy_execution/presentation/screens/atlas_strategy_execution_screen.dart';
import 'package:projeto_atlas/features/performance_center/presentation/screens/atlas_performance_center_screen.dart';
import 'package:projeto_atlas/features/action_plan/data/services/atlas_action_plan_storage_service.dart';
import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/action_plan/domain/services/atlas_action_plan_engine.dart';
import 'package:projeto_atlas/features/farm_audit/data/services/atlas_farm_audit_history_service.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/farm_audit/presentation/screens/atlas_farm_audit_screen.dart';

class AtlasActionPlanScreen extends StatefulWidget {
  const AtlasActionPlanScreen({super.key, this.farmId});
  final String? farmId;
  @override
  State<AtlasActionPlanScreen> createState() => _AtlasActionPlanScreenState();
}

class _AtlasActionPlanScreenState extends State<AtlasActionPlanScreen> {
  bool loading = true;
  AtlasActionPlan? plan;
  AtlasFarmAudit? audit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final audits = await AtlasFarmAuditHistoryService.instance.loadAll();
    final filtered = widget.farmId == null
        ? audits
        : audits.where((a) => a.farmId == widget.farmId).toList();
    final latest = filtered.isEmpty ? null : filtered.first;
    AtlasActionPlan? loaded;
    if (latest != null) {
      loaded = await AtlasActionPlanStorageService.instance.latestForFarm(
        latest.farmId,
      );
      if (loaded == null || loaded.auditId != latest.id) {
        loaded = const AtlasActionPlanEngine().generate(latest);
        await AtlasActionPlanStorageService.instance.save(loaded);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      audit = latest;
      plan = loaded;
      loading = false;
    });
  }

  Future<void> _saveMission(AtlasActionMission updated) async {
    final current = plan;
    if (current == null) {
      return;
    }
    final missions = current.missions
        .map((m) => m.id == updated.id ? updated : m)
        .toList();
    final newPlan = current.copyWith(missions: missions);
    await AtlasActionPlanStorageService.instance.save(newPlan);
    if (mounted) {
      setState(() => plan = newPlan);
    }
  }

  Future<void> _regenerate() async {
    final currentAudit = audit;
    if (currentAudit == null) {
      return;
    }
    final generated = const AtlasActionPlanEngine().generate(currentAudit);
    await AtlasActionPlanStorageService.instance.save(generated);
    if (mounted) {
      setState(() => plan = generated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Plano de Ação & Missões',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir execução estratégica',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AtlasStrategyExecutionScreen(
                    farmId: plan?.farmId ?? widget.farmId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.rocket_launch_outlined),
          ),
          IconButton(
            tooltip: 'Abrir Performance Center',
            onPressed: plan == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AtlasPerformanceCenterScreen(farmId: plan!.farmId),
                      ),
                    );
                  },
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Regenerar plano',
            onPressed: plan == null ? null : _regenerate,
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : plan == null
          ? _Empty(
              onOpenAudit: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AtlasFarmAuditScreen(),
                  ),
                );
                await _load();
              },
            )
          : _Body(plan: plan!, onMissionChanged: _saveMission),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.plan, required this.onMissionChanged});
  final AtlasActionPlan plan;
  final ValueChanged<AtlasActionMission> onMissionChanged;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _Hero(plan: plan),
            const SizedBox(height: 18),
            _Metrics(plan: plan),
            const SizedBox(height: 24),
            const Text(
              'Plano mestre da fazenda',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Missões ordenadas pela prioridade e pelo prazo.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...plan.missions.map(
              (m) => _MissionCard(mission: m, onChanged: onMissionChanged),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.plan});
  final AtlasActionPlan plan;
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
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: plan.progressPercent / 100,
                strokeWidth: 10,
                backgroundColor: Colors.white12,
                color: const Color(0xFF66BB6A),
              ),
              Text(
                '${plan.progressPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
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
                'Atlas Action Plan',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                plan.farmName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.completedMissions} de ${plan.totalMissions} missões concluídas',
                style: const TextStyle(
                  color: Color(0xFF81C784),
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
  const _Metrics({required this.plan});
  final AtlasActionPlan plan;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      final w = (c.maxWidth - 36) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Metric(
            width: w,
            label: 'Missões totais',
            value: '${plan.totalMissions}',
            icon: Icons.flag_outlined,
          ),
          _Metric(
            width: w,
            label: 'Em andamento',
            value: '${plan.inProgressMissions}',
            icon: Icons.play_circle_outline,
          ),
          _Metric(
            width: w,
            label: 'Atrasadas',
            value: '${plan.overdueMissions}',
            icon: Icons.warning_amber_outlined,
          ),
          _Metric(
            width: w,
            label: 'Impacto esperado',
            value: _money(plan.expectedImpact),
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
  final String label, value;
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

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.onChanged});
  final AtlasActionMission mission;
  final ValueChanged<AtlasActionMission> onChanged;
  @override
  Widget build(BuildContext context) {
    final color = mission.isOverdue
        ? Colors.red
        : _priorityColor(mission.priority);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            mission.status == AtlasMissionStatus.completed
                ? Icons.check
                : Icons.flag_outlined,
            color: color,
          ),
        ),
        title: Text(
          mission.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: mission.status == AtlasMissionStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          '${atlasFarmAuditAreaLabel(mission.area)} · ${atlasFarmAuditPriorityLabel(mission.priority)} · até ${_date(mission.dueDate)}',
        ),
        trailing: DropdownButton<AtlasMissionStatus>(
          value: mission.status,
          underline: const SizedBox(),
          items: AtlasMissionStatus.values
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(atlasMissionStatusLabel(s)),
                ),
              )
              .toList(),
          onChanged: (s) {
            if (s != null) {
              onChanged(
                mission.copyWith(
                  status: s,
                  completedAt: s == AtlasMissionStatus.completed
                      ? DateTime.now()
                      : null,
                ),
              );
            }
          },
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(mission.description),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Responsável: ${mission.responsible}')),
              Text(
                'Impacto: ${_money(mission.expectedImpact)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 28),
          ...mission.checklist.asMap().entries.map(
            (entry) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: entry.value.completed,
              title: Text(entry.value.title),
              onChanged: (v) {
                final list = [...mission.checklist];
                list[entry.key] = entry.value.copyWith(completed: v ?? false);
                final status = list.every((i) => i.completed)
                    ? AtlasMissionStatus.completed
                    : (list.any((i) => i.completed)
                          ? AtlasMissionStatus.inProgress
                          : mission.status);
                onChanged(
                  mission.copyWith(
                    checklist: list,
                    status: status,
                    completedAt: status == AtlasMissionStatus.completed
                        ? DateTime.now()
                        : null,
                  ),
                );
              },
            ),
          ),
          LinearProgressIndicator(
            value: mission.checklistProgress,
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${mission.completedChecklistItems}/${mission.checklist.length} etapas concluídas',
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onOpenAudit});
  final VoidCallback onOpenAudit;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag_outlined, size: 64, color: Colors.black26),
        const SizedBox(height: 12),
        const Text(
          'Ainda não existe uma auditoria para gerar o plano.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onOpenAudit,
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Abrir Auditoria Inteligente'),
        ),
      ],
    ),
  );
}

Color _priorityColor(AtlasFarmAuditPriority p) {
  switch (p) {
    case AtlasFarmAuditPriority.critical:
      return const Color(0xFFC62828);
    case AtlasFarmAuditPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasFarmAuditPriority.moderate:
      return const Color(0xFF1565C0);
    case AtlasFarmAuditPriority.low:
      return const Color(0xFF2E7D32);
  }
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _money(double v) {
  final s = v.abs().toStringAsFixed(0);
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final r = s.length - i;
    b.write(s[i]);
    if (r > 1 && r % 3 == 1) b.write('.');
  }
  return '${v < 0 ? '-' : ''}R\$ ${b.toString()}';
}
