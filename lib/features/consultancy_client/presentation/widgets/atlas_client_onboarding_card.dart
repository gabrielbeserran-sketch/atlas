import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart';

class AtlasClientOnboardingCard extends StatelessWidget {
  const AtlasClientOnboardingCard({
    required this.progress,
    required this.canManage,
    required this.saving,
    required this.onChanged,
    super.key,
  });

  final AtlasClientOnboardingProgress progress;
  final bool canManage;
  final bool saving;
  final Future<void> Function(String stepId, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = progress.completionPercent.clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.verified_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Implantação Atlas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.complete
                            ? 'Implantação comprovada pelos dados da operação.'
                            : 'O Atlas valida automaticamente quatro etapas com dados reais da fazenda.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percent.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: percent / 100),
            const SizedBox(height: 12),
            ...AtlasClientOnboardingProgress.canonicalSteps.map((step) {
              final checked = progress.isComplete(step.id);
              final evidence = progress.evidenceFor(step.id);
              final detail = evidence?.detail.trim();
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: checked,
                onChanged: step.automatic || !canManage || saving
                    ? null
                    : (value) => onChanged(step.id, value ?? false),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (step.automatic)
                      const Tooltip(
                        message: 'Validado automaticamente pelos dados oficiais do Atlas',
                        child: Icon(Icons.verified_user_outlined, size: 18),
                      ),
                  ],
                ),
                subtitle: Text(
                  detail?.isNotEmpty == true ? detail! : step.description,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Etapas automáticas não podem ser marcadas manualmente. Corrija o dado de origem e o progresso será atualizado.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            if (!canManage)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'O treinamento é confirmado pela equipe responsável pela implantação.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            if (saving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
