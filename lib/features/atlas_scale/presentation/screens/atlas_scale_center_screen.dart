import 'package:flutter/material.dart';

import '../../domain/models/atlas_scale_roadmap.dart';

class AtlasScaleCenterScreen extends StatelessWidget {
  const AtlasScaleCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roadmap = AtlasScaleRoadmap.standard();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Atlas 3.0 e escala',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('Horizonte estratégico: ${roadmap.horizonYears} anos'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: roadmap.progress),
          const SizedBox(height: 16),
          ...roadmap.pillars.map(
            (pillar) => Card(
              child: ListTile(
                title: Text(pillar.title),
                subtitle: LinearProgressIndicator(value: pillar.progress),
                trailing: Text('${(pillar.progress * 100).round()}%'),
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.hub_outlined),
              title: Text('Regra de evolução'),
              subtitle: Text(
                'Novos módulos devem reutilizar contratos oficiais, preservar '
                'isolamento por tenant e passar pelos gates de qualidade.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
