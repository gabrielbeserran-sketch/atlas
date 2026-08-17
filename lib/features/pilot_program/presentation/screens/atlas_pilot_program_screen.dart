import 'package:flutter/material.dart';

import '../../domain/models/atlas_pilot_plan.dart';

class AtlasPilotProgramScreen extends StatefulWidget {
  const AtlasPilotProgramScreen({super.key});

  @override
  State<AtlasPilotProgramScreen> createState() =>
      _AtlasPilotProgramScreenState();
}

class _AtlasPilotProgramScreenState extends State<AtlasPilotProgramScreen> {
  AtlasPilotPlan plan = AtlasPilotPlan.standard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Piloto real',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(plan.farmName),
          const SizedBox(height: 16),
          ...plan.metrics.map(
            (metric) => Card(
              child: ListTile(
                title: Text(metric.name),
                subtitle: LinearProgressIndicator(value: metric.progress),
                trailing: Text('${(metric.progress * 100).round()}%'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Riscos e pendências',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...plan.risks.map(
            (risk) => ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(risk),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.rule),
              title: Text('Critério de encerramento'),
              subtitle: Text(
                'Metas atingidas, riscos tratados, resultados documentados '
                'e aceite formal do produtor e responsável técnico.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
