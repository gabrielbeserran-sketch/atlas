import 'package:flutter/material.dart';
import '../../domain/models/atlas_release_plan.dart';

class AtlasReleaseCenterScreen extends StatefulWidget {
  const AtlasReleaseCenterScreen({super.key});
  @override
  State<AtlasReleaseCenterScreen> createState() => _State();
}

class _State extends State<AtlasReleaseCenterScreen> {
  AtlasReleasePlan plan = AtlasReleasePlan.standard();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: RefreshIndicator(
      onRefresh: () async => setState(() => plan = AtlasReleasePlan.standard()),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Entrega contínua',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('${plan.version} • ${plan.environment}'),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: plan.progress),
          const SizedBox(height: 16),
          ...plan.checks.map(
            (c) => CheckboxListTile(
              value: c.completed,
              title: Text(c.title),
              onChanged: (v) => setState(
                () => plan = plan.copyWith(
                  checks: plan.checks
                      .map(
                        (x) => x.id == c.id
                            ? AtlasReleaseCheck(
                                id: x.id,
                                title: x.title,
                                completed: v ?? false,
                              )
                            : x,
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.restore),
              title: Text('Rollback seguro'),
              subtitle: Text(
                'Backup, migration downgrade controlado e artefato anterior devem estar disponíveis antes do deploy.',
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: plan.canDeploy
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Release aprovada para implantação supervisionada.',
                      ),
                    ),
                  )
                : null,
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Aprovar implantação'),
          ),
        ],
      ),
    ),
  );
}
