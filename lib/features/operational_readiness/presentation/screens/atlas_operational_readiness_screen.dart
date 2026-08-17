import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/operational_readiness/domain/models/atlas_operational_readiness_report.dart';

class AtlasOperationalReadinessScreen extends StatelessWidget {
  const AtlasOperationalReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final report = AtlasOperationalReadinessReport.standard();
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Prontidão operacional',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Qualidade do backend, desempenho e infraestrutura dos Ciclos 13 a 15.',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(report.progress * 100).round()}% aprovado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: report.progress),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('${report.approvedCount} aprovados')),
                      Chip(label: Text('${report.warningCount} alertas')),
                      Chip(label: Text('${report.blockedCount} bloqueios')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...report.checks.map(
            (check) => Card(
              child: ListTile(
                leading: Icon(_icon(check.status)),
                title: Text(check.title),
                subtitle: Text('${check.category} · ${check.detail}'),
                trailing: Text(_label(check.status)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'A aprovação final depende da execução dos gates no computador de desenvolvimento e no ambiente de homologação.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(AtlasReadinessStatus status) => switch (status) {
    AtlasReadinessStatus.approved => Icons.check_circle_outline,
    AtlasReadinessStatus.warning => Icons.warning_amber_outlined,
    AtlasReadinessStatus.blocked => Icons.block_outlined,
  };

  static String _label(AtlasReadinessStatus status) => switch (status) {
    AtlasReadinessStatus.approved => 'Aprovado',
    AtlasReadinessStatus.warning => 'Atenção',
    AtlasReadinessStatus.blocked => 'Bloqueado',
  };
}
