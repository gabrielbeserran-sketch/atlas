import 'package:flutter/material.dart';

class AtlasModuleWorkspaceGuide extends StatelessWidget {
  const AtlasModuleWorkspaceGuide({
    required this.moduleLabel,
    required this.workflows,
    this.specializedFamilies = 0,
    super.key,
  });

  final String moduleLabel;
  final List<String> workflows;
  final int specializedFamilies;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que você pode fazer em $moduleLabel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...workflows.map(
              (workflow) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(workflow)),
                  ],
                ),
              ),
            ),
            if (specializedFamilies > 0) ...[
              const Divider(height: 22),
              Text(
                'As ferramentas específicas desta área ficam organizadas aqui, '
                'sem obrigar você a procurar em outras telas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
