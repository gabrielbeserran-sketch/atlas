import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/decision_intelligence_lab/presentation/screens/atlas_decision_intelligence_lab_screen.dart';
import 'package:projeto_atlas/features/farm_audit/data/services/atlas_farm_audit_history_service.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/knowledge_learning/data/services/atlas_knowledge_repository.dart';
import 'package:projeto_atlas/features/knowledge_learning/domain/models/atlas_knowledge_case.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/domain/models/atlas_intelligent_recommendation.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/domain/services/atlas_recommendation_intelligence_engine.dart';

class AtlasRecommendationIntelligenceScreen
    extends StatefulWidget {
  const AtlasRecommendationIntelligenceScreen({
    super.key,
    this.farmId,
  });

  final String? farmId;

  @override
  State<AtlasRecommendationIntelligenceScreen>
      createState() {
    return _AtlasRecommendationIntelligenceScreenState();
  }
}

class _AtlasRecommendationIntelligenceScreenState
    extends State<AtlasRecommendationIntelligenceScreen> {
  bool loading = true;
  AtlasRecommendationPortfolio? portfolio;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
    });

    final audits =
        await AtlasFarmAuditHistoryService.instance.loadAll();

    final filteredAudits = widget.farmId == null
        ? audits
        : audits
            .where(
              (item) => item.farmId == widget.farmId,
            )
            .toList();

    if (filteredAudits.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        portfolio = null;
        loading = false;
      });

      return;
    }

    final cases =
        await AtlasKnowledgeRepository.instance.loadCases();

    final AtlasFarmAudit audit = filteredAudits.first;

    final List<AtlasKnowledgeCase> relevantCases =
        cases.where(
      (item) {
        return item.farmId == audit.farmId ||
            cases.length < 10;
      },
    ).toList();

    final generated =
        const AtlasRecommendationIntelligenceEngine()
            .generate(
      audit: audit,
      knowledgeCases:
          relevantCases.isEmpty ? cases : relevantCases,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      portfolio = generated;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = portfolio;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Recommendation Intelligence',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir laboratório de decisões',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasDecisionIntelligenceLabScreen(
                      farmId: widget.farmId,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.science_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar recomendações',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : current == null
              ? const _EmptyView()
              : Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 1180),
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _Hero(portfolio: current),
                        const SizedBox(height: 20),
                        const _SectionTitle(
                          title:
                              'Recomendações priorizadas',
                          subtitle:
                              'Sugestões explicáveis, apoiadas pela auditoria e pela memória técnica do Atlas.',
                        ),
                        const SizedBox(height: 12),
                        ...current.recommendations.map(
                          (item) =>
                              _RecommendationCard(
                            recommendation: item,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.portfolio,
  });

  final AtlasRecommendationPortfolio portfolio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF0D47A1),
            Color(0xFF00838F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Inteligência de recomendação baseada em evidências',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            portfolio.farmName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(
                label: 'Recomendações',
                value:
                    '${portfolio.recommendations.length}',
              ),
              _HeroMetric(
                label: 'Confiança média',
                value:
                    '${portfolio.averageConfidence.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                label: 'Casos de evidência',
                value: '${portfolio.evidenceCases}',
              ),
              _HeroMetric(
                label: 'Ganho esperado',
                value: _formatCurrency(
                  portfolio.expectedEconomicGain,
                ),
              ),
              _HeroMetric(
                label: 'Farm Audit Index',
                value:
                    portfolio.auditIndex.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
  });

  final AtlasIntelligentRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color =
        _priorityColor(recommendation.priority);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withValues(alpha: 0.12),
          child: Icon(
            Icons.lightbulb_outline,
            color: color,
          ),
        ),
        title: Text(
          recommendation.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${atlasFarmAuditAreaLabel(recommendation.area)} · '
          '${atlasFarmAuditPriorityLabel(recommendation.priority)} · '
          '${recommendation.confidence.toStringAsFixed(1)}% de confiança',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _TextBlock(
            title: 'Diagnóstico',
            text: recommendation.diagnosis,
          ),
          _TextBlock(
            title: 'Protocolo recomendado',
            text:
                recommendation.recommendedProtocol,
          ),
          _TextBlock(
            title: 'Por que o Atlas recomenda isso?',
            text: recommendation.justification,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Atual',
                  value: recommendation.currentScore
                      .toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Meta',
                  value: recommendation.targetScore
                      .toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Sucesso histórico',
                  value:
                      '${recommendation.successRate.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Resposta média',
                  value:
                      '${recommendation.averageResponseDays.toStringAsFixed(0)} dias',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ListBlock(
            title: 'Plano recomendado',
            items: recommendation.steps,
          ),
          _ListBlock(
            title: 'Evidências utilizadas',
            items: recommendation.evidence,
          ),
          _ListBlock(
            title: 'Riscos de execução',
            items: recommendation.risks,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Impacto econômico esperado: '
              '${_formatCurrency(recommendation.expectedEconomicGain)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$title:\n$text',
          style: const TextStyle(height: 1.45),
        ),
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...items.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 4),
                child: Text('• $item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 58,
              color: Colors.black26,
            ),
            SizedBox(height: 12),
            Text(
              'Ainda não existe auditoria para gerar recomendações.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Gere uma auditoria da fazenda antes de abrir este módulo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(
  AtlasFarmAuditPriority priority,
) {
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
