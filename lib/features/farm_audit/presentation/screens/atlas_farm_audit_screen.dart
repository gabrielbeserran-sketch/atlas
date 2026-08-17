import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/action_plan/presentation/screens/atlas_action_plan_screen.dart';
import 'package:projeto_atlas/features/autonomous_consultant/domain/models/atlas_consultant_report.dart';
import 'package:projeto_atlas/features/autonomous_consultant/domain/services/atlas_autonomous_consultant_service.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_service.dart';
import 'package:projeto_atlas/features/farm_audit/data/services/atlas_farm_audit_history_service.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/farm_audit/domain/services/atlas_farm_audit_engine.dart';

class AtlasFarmAuditScreen extends StatefulWidget {
  const AtlasFarmAuditScreen({super.key});

  @override
  State<AtlasFarmAuditScreen> createState() {
    return _AtlasFarmAuditScreenState();
  }
}

class _AtlasFarmAuditScreenState extends State<AtlasFarmAuditScreen> {
  final AtlasFarmAuditEngine engine = const AtlasFarmAuditEngine();

  final AtlasAutonomousConsultantService consultantService =
      const AtlasAutonomousConsultantService();

  bool isLoading = true;
  bool isGenerating = false;
  String? selectedFarmId;
  AtlasFarmAudit? audit;
  List<AtlasFarmAudit> history = <AtlasFarmAudit>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  AtlasDigitalTwin? get selectedTwin {
    final farmId = selectedFarmId;

    if (farmId == null) {
      return null;
    }

    return AtlasDigitalTwinService.instance.byFarmId(farmId);
  }

  Future<void> _load() async {
    await AtlasDigitalTwinService.instance.load();

    final twins = AtlasDigitalTwinService.instance.twins;

    if (!mounted) {
      return;
    }

    setState(() {
      selectedFarmId = twins.isEmpty ? null : twins.first.farmId;
      isLoading = false;
    });

    if (selectedTwin != null) {
      await _loadHistory();

      if (history.isNotEmpty) {
        setState(() {
          audit = history.first;
        });
      } else {
        await _generateAudit();
      }
    }
  }

  Future<void> _loadHistory() async {
    final farmId = selectedFarmId;

    if (farmId == null) {
      return;
    }

    final loaded = await AtlasFarmAuditHistoryService.instance.byFarmId(farmId);

    if (!mounted) {
      return;
    }

    setState(() {
      history = loaded;
    });
  }

  Future<void> _generateAudit() async {
    final twin = selectedTwin;

    if (twin == null || isGenerating) {
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final AtlasConsultantReport consultantReport = consultantService.analyze(
        twin: twin,
      );

      final generated = engine.execute(
        twin: twin,
        consultantReport: consultantReport,
      );

      await AtlasFarmAuditHistoryService.instance.save(generated);

      await _loadHistory();

      if (!mounted) {
        return;
      }

      setState(() {
        audit = generated;
      });
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final twins = AtlasDigitalTwinService.instance.twins;
    final currentAudit = audit;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Farm Audit',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir plano de ação',
            onPressed: currentAudit == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            AtlasActionPlanScreen(farmId: currentAudit.farmId),
                      ),
                    );
                  },
            icon: const Icon(Icons.flag_outlined),
          ),
          IconButton(
            tooltip: 'Gerar nova auditoria',
            onPressed: isGenerating ? null : _generateAudit,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedTwin == null
          ? const _EmptyAuditView()
          : currentAudit == null
          ? const Center(child: CircularProgressIndicator())
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
                              audit = null;
                              history = <AtlasFarmAudit>[];
                            });

                            await _loadHistory();

                            if (history.isNotEmpty) {
                              setState(() {
                                audit = history.first;
                              });
                            } else {
                              await _generateAudit();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _AuditHero(audit: currentAudit),
                      const SizedBox(height: 20),
                      _DiagnosisCard(audit: currentAudit),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Avaliação por área',
                        subtitle:
                            'Pontuação técnica das 12 áreas da consultoria veterinária.',
                      ),
                      const SizedBox(height: 12),
                      _AreaGrid(results: currentAudit.areaResults),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Ranking de problemas',
                        subtitle:
                            'Gargalos organizados pela prioridade e pelo impacto econômico estimado.',
                      ),
                      const SizedBox(height: 12),
                      _ProblemList(problems: currentAudit.problems),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Oportunidades',
                        subtitle:
                            'Possíveis investimentos classificados pelo retorno estimado.',
                      ),
                      const SizedBox(height: 12),
                      _OpportunityList(
                        opportunities: currentAudit.opportunities,
                      ),
                      if (history.length > 1) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Evolução histórica',
                          subtitle:
                              'Comparação das últimas auditorias armazenadas.',
                        ),
                        const SizedBox(height: 12),
                        _HistoryCard(history: history),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AuditHero extends StatelessWidget {
  const _AuditHero({required this.audit});

  final AtlasFarmAudit audit;

  @override
  Widget build(BuildContext context) {
    final color = _classificationColor(audit.classification);

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
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: audit.overallIndex / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white12,
                  color: color,
                ),
                Text(
                  audit.overallIndex.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
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
                  'Atlas Farm Audit Index',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  audit.farmName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${atlasFarmAuditClassificationLabel(audit.classification)} · '
                  '${audit.problems.length} problemas · '
                  '${audit.opportunities.length} oportunidades',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.audit});

  final AtlasFarmAudit audit;

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
                Icon(Icons.assignment_outlined),
                SizedBox(width: 8),
                Text(
                  'Parecer técnico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(audit.diagnosis, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _AreaGrid extends StatelessWidget {
  const _AreaGrid({required this.results});

  final List<AtlasFarmAuditAreaResult> results;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 2;

        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: results.map((result) {
            final color = _statusColor(result.status);

            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              atlasFarmAuditAreaLabel(result.area),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            result.score.toStringAsFixed(1),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: result.score / 100,
                        minHeight: 8,
                        color: color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        atlasFarmAuditAreaStatusLabel(result.status),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProblemList extends StatelessWidget {
  const _ProblemList({required this.problems});

  final List<AtlasFarmAuditProblem> problems;

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.verified_outlined, color: Color(0xFF2E7D32)),
          title: Text('Nenhum problema relevante identificado.'),
        ),
      );
    }

    return Column(
      children: problems.map((problem) {
        final color = _priorityColor(problem.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.warning_amber_outlined, color: color),
            ),
            title: Text(
              problem.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${problem.description}\n'
              'Prazo recomendado: ${problem.recommendedDeadlineDays} dias',
            ),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  atlasFarmAuditPriorityLabel(problem.priority),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(problem.estimatedAnnualImpact),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OpportunityList extends StatelessWidget {
  const _OpportunityList({required this.opportunities});

  final List<AtlasFarmAuditOpportunity> opportunities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: opportunities.map((opportunity) {
        return Card(
          child: ExpansionTile(
            leading: const CircleAvatar(
              child: Icon(Icons.trending_up_outlined),
            ),
            title: Text(
              opportunity.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasFarmAuditAreaLabel(opportunity.area)} · '
              'ROI ${opportunity.roiPercent.toStringAsFixed(1)}%',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(opportunity.description),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FinancialMetric(
                      label: 'Investimento',
                      value: _formatCurrency(opportunity.estimatedInvestment),
                    ),
                  ),
                  Expanded(
                    child: _FinancialMetric(
                      label: 'Retorno estimado',
                      value: _formatCurrency(opportunity.estimatedReturn),
                    ),
                  ),
                  Expanded(
                    child: _FinancialMetric(
                      label: 'ROI',
                      value: '${opportunity.roiPercent.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final List<AtlasFarmAudit> history;

  @override
  Widget build(BuildContext context) {
    final visible = history.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: visible.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: Text(_formatDate(item.generatedAt))),
                  Expanded(
                    flex: 2,
                    child: LinearProgressIndicator(
                      value: item.overallIndex / 100,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.overallIndex.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
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

class _EmptyAuditView extends StatelessWidget {
  const _EmptyAuditView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Nenhum Digital Twin está disponível.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre eventos da fazenda antes de gerar a auditoria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color _classificationColor(AtlasFarmAuditClassification classification) {
  switch (classification) {
    case AtlasFarmAuditClassification.excellent:
      return const Color(0xFF66BB6A);
    case AtlasFarmAuditClassification.good:
      return const Color(0xFF42A5F5);
    case AtlasFarmAuditClassification.attention:
      return const Color(0xFFFFB74D);
    case AtlasFarmAuditClassification.critical:
      return const Color(0xFFEF5350);
  }
}

Color _statusColor(AtlasFarmAuditAreaStatus status) {
  switch (status) {
    case AtlasFarmAuditAreaStatus.excellent:
      return const Color(0xFF2E7D32);
    case AtlasFarmAuditAreaStatus.good:
      return const Color(0xFF1565C0);
    case AtlasFarmAuditAreaStatus.attention:
      return const Color(0xFFEF6C00);
    case AtlasFarmAuditAreaStatus.critical:
      return const Color(0xFFC62828);
  }
}

Color _priorityColor(AtlasFarmAuditPriority priority) {
  switch (priority) {
    case AtlasFarmAuditPriority.low:
      return const Color(0xFF2E7D32);
    case AtlasFarmAuditPriority.moderate:
      return const Color(0xFF1565C0);
    case AtlasFarmAuditPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasFarmAuditPriority.critical:
      return const Color(0xFFC62828);
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

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}
