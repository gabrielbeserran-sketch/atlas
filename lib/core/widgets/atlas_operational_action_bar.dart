import 'package:flutter/material.dart';

/// Barra de ações canônica dos módulos operacionais do Atlas.
///
/// Mantém a ação principal e a atualização no mesmo lugar em desktop e mobile,
/// sem alterar a regra de negócio executada por cada módulo.
class AtlasOperationalActionBar extends StatelessWidget {
  const AtlasOperationalActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    required this.onRefresh,
    this.primaryIcon = Icons.add,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon = Icons.add_circle_outline,
    this.busy = false,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Future<void> Function()? onRefresh;
  final IconData primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData secondaryIcon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        final primary = FilledButton.icon(
          onPressed: busy ? null : onPrimary,
          icon: Icon(primaryIcon),
          label: Text(primaryLabel),
        );
        final secondary = secondaryLabel == null
            ? null
            : OutlinedButton.icon(
                onPressed: busy ? null : onSecondary,
                icon: Icon(secondaryIcon),
                label: Text(secondaryLabel!),
              );
        final refresh = OutlinedButton.icon(
          onPressed: busy || onRefresh == null
              ? null
              : () async => onRefresh!.call(),
          icon: const Icon(Icons.refresh_outlined),
          label: const Text('Atualizar'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              if (secondary != null) ...[const SizedBox(height: 8), secondary],
              const SizedBox(height: 8),
              refresh,
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [refresh, if (secondary != null) secondary, primary],
        );
      },
    );
  }
}
