import 'package:flutter/material.dart';
import '../../domain/models/atlas_commercial_readiness.dart';

class AtlasCommercialReadinessScreen extends StatelessWidget {
  const AtlasCommercialReadinessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = AtlasCommercialReadiness.standard();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Preparação comercial',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: data.progress),
          const SizedBox(height: 16),
          ...data.items.map(
            (e) => Card(
              child: ListTile(
                leading: Icon(e.completed ? Icons.check_circle : Icons.pending),
                title: Text(e.title),
                subtitle: Text(e.category),
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.school),
              title: Text('Treinamento e demonstração'),
              subtitle: Text(
                'Materiais em docs/commercial e docs/training, com roteiro de onboarding, importação e demonstração.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
