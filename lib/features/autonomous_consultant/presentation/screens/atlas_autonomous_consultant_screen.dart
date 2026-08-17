import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/presentation/screens/atlas_recommendation_intelligence_screen.dart';
import 'package:projeto_atlas/features/farm_audit/presentation/screens/atlas_farm_audit_screen.dart';
import 'package:projeto_atlas/features/autonomous_consultant/domain/models/atlas_consultant_report.dart';
import 'package:projeto_atlas/features/autonomous_consultant/domain/services/atlas_autonomous_consultant_service.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';
import 'package:projeto_atlas/features/optimization_engine/presentation/screens/atlas_optimization_result_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasAutonomousConsultantScreen extends StatefulWidget {
  const AtlasAutonomousConsultantScreen({super.key});

  @override
  State<AtlasAutonomousConsultantScreen> createState() {
    return _AtlasAutonomousConsultantScreenState();
  }
}

class _AtlasAutonomousConsultantScreenState
    extends State<AtlasAutonomousConsultantScreen> {
  final AtlasAutonomousConsultantService service =
      const AtlasAutonomousConsultantService();

  bool isLoading = true;
  bool isAnalyzing = false;
  String? selectedFarmId;
  AtlasConsultantReport? report;

  @override
  void initState() {
    super.initState();
    _load();
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

    if (selectedTwin != null) {
      await _analyze();
    }
  }

  AtlasDigitalTwin? get selectedTwin {
    final farmId = selectedFarmId;

    if (farmId == null) {
      return null;
    }

    return AtlasDigitalTwinService.instance.byFarmId(farmId);
  }

  Future<void> _analyze() async {
    final twin = selectedTwin;

    if (twin == null) {
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 250));

    final generated = service.analyze(twin: twin);

    if (!mounted) {
      return;
    }

    setState(() {
      report = generated;
      isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final twins = AtlasDigitalTwinService.instance.twins;
    final currentReport = report;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Autonomous Consultant',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir recomendações inteligentes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasRecommendationIntelligenceScreen(
                      farmId: selectedFarmId,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            tooltip: 'Abrir auditoria inteligente',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return const AtlasFarmAuditScreen();
                  },
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: 'Gerar nova análise',
            onPressed: isAnalyzing ? null : _analyze,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedTwin == null
          ? const _EmptyConsultantView()
          : isAnalyzing && currentReport == null
          ? const Center(child: CircularProgressIndicator())
          : currentReport == null
          ? const _EmptyConsultantView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      if (twins.length > 1) ...[
                        _FarmSelector(
                          twins: twins,
                          selectedFarmId: selectedFarmId,
                          onChanged: (value) async {
                            setState(() {
                              selectedFarmId = value;
                              report = null;
                            });

                            await _analyze();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _ConsultantHero(report: currentReport),
                      const SizedBox(height: 20),
                      _DiagnosisCard(report: currentReport),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Plano de ação priorizado',
                        subtitle:
                            'Ações ordenadas pelo risco, urgência e impacto esperado.',
                      ),
                      const SizedBox(height: 12),
                      _ActionList(actions: currentReport.actions),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Estratégia recomendada',
                        subtitle:
                            'Melhor alternativa encontrada automaticamente pelo Optimization Engine.',
                      ),
                      const SizedBox(height: 12),
                      _OptimizationCard(report: currentReport),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _FarmSelector extends StatelessWidget {
  const _FarmSelector({
    required this.twins,
    required this.selectedFarmId,
    required this.onChanged,
  });

  final List<AtlasDigitalTwin> twins;
  final String? selectedFarmId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ConsultantHero extends StatelessWidget {
  const _ConsultantHero({required this.report});

  final AtlasConsultantReport report;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(report.overallPriority);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF17384D), Color(0xFF236075)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.support_agent_outlined,
            color: Color(0xFFB3E5FC),
            size: 48,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.farmName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Consultoria autônoma baseada no estado vivo da fazenda',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _HeroMetric(
                      label: 'Farm Index',
                      value: report.farmScore.toStringAsFixed(1),
                    ),
                    _HeroMetric(
                      label: 'Prioridade',
                      value: atlasConsultantPriorityLabel(
                        report.overallPriority,
                      ),
                      valueColor: color,
                    ),
                    _HeroMetric(
                      label: 'Ações',
                      value: report.actions.length.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white60),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.report});

  final AtlasConsultantReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_outlined),
                SizedBox(width: 8),
                Text(
                  'Diagnóstico executivo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.executiveDiagnosis,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            Text(
              report.strategicSummary,
              style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions});

  final List<AtlasConsultantAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: actions.map((action) {
        final color = _priorityColor(action.priority);

        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_areaIcon(action.area), color: color),
            ),
            title: Text(
              action.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasDigitalTwinAreaLabel(action.area)} · '
              '${atlasConsultantPriorityLabel(action.priority)} · '
              'até ${action.deadlineDays} dias',
            ),
            trailing: Text(
              '${action.expectedScoreImpact >= 0 ? '+' : ''}'
              '${action.expectedScoreImpact.toStringAsFixed(1)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  action.description,
                  style: const TextStyle(height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Justificativa: ${action.justification}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Impacto econômico estimado: '
                  '${_formatCurrency(action.estimatedEconomicImpact)}',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Risco de não agir: ${action.riskOfInaction}',
                  style: const TextStyle(color: Color(0xFFC62828)),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Passos recomendados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 7),
              ...action.steps.map(
                (step) => Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $step'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: action.indicators
                      .map((indicator) => Chip(label: Text(indicator)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _OptimizationCard extends StatelessWidget {
  const _OptimizationCard({required this.report});

  final AtlasConsultantReport report;

  @override
  Widget build(BuildContext context) {
    final best = report.optimizationResult.bestCandidate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.auto_awesome_outlined)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    best.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${best.optimizationScore.toStringAsFixed(1)} pontos de otimização · '
                    '${best.result.scoreVariation >= 0 ? '+' : ''}'
                    '${best.result.scoreVariation.toStringAsFixed(1)} pontos no Farm Index',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return AtlasOptimizationResultScreen(
                        result: report.optimizationResult,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver estratégia'),
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

class _EmptyConsultantView extends StatelessWidget {
  const _EmptyConsultantView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Nenhum Digital Twin está disponível.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre eventos nos módulos operacionais para gerar a consultoria autônoma.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(AtlasConsultantPriority priority) {
  switch (priority) {
    case AtlasConsultantPriority.low:
      return const Color(0xFF2E7D32);
    case AtlasConsultantPriority.moderate:
      return const Color(0xFF1565C0);
    case AtlasConsultantPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasConsultantPriority.critical:
      return const Color(0xFFC62828);
  }
}

IconData _areaIcon(AtlasDigitalTwinArea area) {
  switch (area) {
    case AtlasDigitalTwinArea.animal:
      return Icons.monitor_weight_outlined;
    case AtlasDigitalTwinArea.sanitary:
      return Icons.medical_services_outlined;
    case AtlasDigitalTwinArea.reproductive:
      return AtlasLivestockIcons.cow;
    case AtlasDigitalTwinArea.financial:
      return Icons.account_balance_wallet_outlined;
    case AtlasDigitalTwinArea.inventory:
      return Icons.inventory_2_outlined;
    case AtlasDigitalTwinArea.operational:
      return Icons.schema_outlined;
  }
}

String _formatCurrency(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;
    buffer.write(integer[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${negative ? '-' : ''}R\$ '
      '${buffer.toString()},$decimal';
}
