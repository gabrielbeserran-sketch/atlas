import 'package:flutter/material.dart';

import '../atlas_design_system.dart';

/// Catálogo interno do Design System. Não faz parte da navegação de produção.
class AtlasDesignSystemCatalogScreen extends StatelessWidget {
  const AtlasDesignSystemCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atlas Design System')),
      body: ListView(
        padding: const EdgeInsets.all(AtlasSpacing.pageHorizontal),
        children: [
          Text('Fundamentos', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AtlasSpacing.lg),
          Wrap(
            spacing: AtlasSpacing.sm,
            runSpacing: AtlasSpacing.sm,
            children: const [
              AtlasStatusChip(label: 'Operacional', tone: AtlasStatusTone.success),
              AtlasStatusChip(label: 'Atenção', tone: AtlasStatusTone.warning),
              AtlasStatusChip(label: 'Crítico', tone: AtlasStatusTone.critical),
              AtlasStatusChip(label: 'Informação', tone: AtlasStatusTone.info),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sectionGap),
          const AtlasMetricCard(
            label: 'Taxa de prenhez',
            value: '68,4%',
            supportingText: '+4,8 p.p. no ciclo atual',
            icon: Icons.insights_outlined,
            statusLabel: 'Evolução',
            statusTone: AtlasStatusTone.success,
          ),
          const SizedBox(height: AtlasSpacing.sectionGap),
          AtlasSection(
            title: 'Ações',
            description: 'Hierarquia de decisão consistente em todos os módulos.',
            child: Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              children: [
                AtlasButton(label: 'Salvar', onPressed: () {}),
                AtlasButton(
                  label: 'Revisar',
                  variant: AtlasButtonVariant.secondary,
                  onPressed: () {},
                ),
                AtlasButton(
                  label: 'Cancelar',
                  variant: AtlasButtonVariant.ghost,
                  onPressed: () {},
                ),
                AtlasButton(
                  label: 'Excluir',
                  variant: AtlasButtonVariant.danger,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
