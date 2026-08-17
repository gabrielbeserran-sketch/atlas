import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/flutter_quality/domain/models/atlas_flutter_quality_report.dart';

class AtlasFlutterQualityScreen extends StatelessWidget {
  const AtlasFlutterQualityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final report = AtlasFlutterQualityReport(
      checks: {
        'Modelos e serialização': true,
        'Services e erros HTTP': true,
        'Widgets e estados visuais': true,
        'Navegação e permissões': true,
        'Integração Flutter ↔ API': true,
        'Offline e conflitos': true,
      },
      generatedAt: DateTime.now().toUtc(),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Qualidade Flutter',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Gate consolidado para modelos, services, widgets, navegação e integração.',
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(
              report.approved ? Icons.check_circle : Icons.warning_amber,
            ),
            title: Text(
              '${report.percent.toStringAsFixed(0)}% do gate estrutural',
            ),
            subtitle: Text(
              '${report.passed} de ${report.total} categorias preparadas',
            ),
          ),
        ),
        ...report.checks.entries.map(
          (entry) => CheckboxListTile(
            value: entry.value,
            onChanged: null,
            title: Text(entry.key),
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.terminal),
          title: Text('Comando oficial'),
          subtitle: SelectableText(
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\quality_cycles10_12.ps1',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.rule),
          title: Text('Critério de aceite'),
          subtitle: Text(
            'dart format, flutter analyze e flutter test sem falhas; backend com todos os gates aprovados.',
          ),
        ),
      ],
    );
  }
}
