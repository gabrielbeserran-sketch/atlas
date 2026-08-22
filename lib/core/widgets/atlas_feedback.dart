import 'package:flutter/material.dart';

/// Feedback operacional único do Atlas.
///
/// Mantém validação, mensagens e confirmações destrutivas previsíveis em todos
/// os módulos de campo. Não contém regra de negócio.
class AtlasFeedback {
  const AtlasFeedback._();

  static bool validateForm(
    BuildContext context,
    GlobalKey<FormState> formKey, {
    String message = 'Revise os campos destacados antes de salvar.',
  }) {
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) {
      showWarning(context, message);
    }
    return valid;
  }

  static void showSuccess(BuildContext context, String message) => _show(
    context,
    message,
    Icons.check_circle_outline,
    semanticLabel: 'Sucesso',
  );

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, Icons.info_outline, semanticLabel: 'Atenção');

  static void showError(BuildContext context, String message) =>
      _show(context, message, Icons.error_outline, semanticLabel: 'Erro');

  static void _show(
    BuildContext context,
    String message,
    IconData icon, {
    required String semanticLabel,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            label: '$semanticLabel. $message',
            child: Row(
              children: [
                Icon(icon, color: Colors.white, semanticLabel: semanticLabel),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Excluir',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 32),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }
}
