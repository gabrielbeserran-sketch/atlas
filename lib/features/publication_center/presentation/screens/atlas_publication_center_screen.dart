import 'package:flutter/material.dart';

import '../../domain/models/atlas_publication_plan.dart';

class AtlasPublicationCenterScreen extends StatefulWidget {
  const AtlasPublicationCenterScreen({super.key});

  @override
  State<AtlasPublicationCenterScreen> createState() =>
      _AtlasPublicationCenterScreenState();
}

class _AtlasPublicationCenterScreenState
    extends State<AtlasPublicationCenterScreen> {
  late List<AtlasPublicationCheck> checks;

  @override
  void initState() {
    super.initState();
    checks = AtlasPublicationPlan.standard().checks.toList();
  }

  @override
  Widget build(BuildContext context) {
    final plan = AtlasPublicationPlan(checks: checks);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Publicação', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${plan.completedCount}/${plan.checks.length} critérios concluídos',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: plan.progress),
          const SizedBox(height: 16),
          ...List.generate(checks.length, (index) {
            final item = checks[index];
            return Card(
              child: CheckboxListTile(
                value: item.completed,
                title: Text(item.name),
                subtitle: Text(item.channel),
                onChanged: (value) {
                  setState(() {
                    checks[index] = AtlasPublicationCheck(
                      name: item.name,
                      completed: value ?? false,
                      channel: item.channel,
                    );
                  });
                },
              ),
            );
          }),
          Card(
            child: ListTile(
              leading: Icon(plan.ready ? Icons.verified : Icons.block),
              title: Text(
                plan.ready ? 'Pronto para publicação' : 'Publicação bloqueada',
              ),
              subtitle: const Text(
                'Todos os critérios devem ser aprovados antes da liberação.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
