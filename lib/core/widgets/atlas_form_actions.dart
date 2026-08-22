import 'package:flutter/material.dart';

/// Barra de ações padronizada para formulários operacionais do Atlas.
///
/// Mantém a mesma hierarquia em Animal, Lote, Sanidade, Reprodução, Agenda,
/// Financeiro e Estoque: cancelar à esquerda e salvar como ação principal.
class AtlasFormActions extends StatelessWidget {
  const AtlasFormActions({
    required this.onSave,
    required this.saveLabel,
    this.onCancel,
    this.isSaving = false,
    super.key,
  });

  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final String saveLabel;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final cancel = onCancel ?? () => Navigator.maybePop(context);

    Widget saveButton() => FilledButton.icon(
      onPressed: isSaving ? null : onSave,
      icon: isSaving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: Text(isSaving ? 'Salvando...' : saveLabel),
    );

    Widget cancelButton() => OutlinedButton.icon(
      onPressed: isSaving ? null : cancel,
      icon: const Icon(Icons.close),
      label: const Text('Cancelar'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 52, child: saveButton()),
              const SizedBox(height: 10),
              SizedBox(height: 48, child: cancelButton()),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: SizedBox(height: 50, child: cancelButton())),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: SizedBox(height: 50, child: saveButton())),
          ],
        );
      },
    );
  }
}
