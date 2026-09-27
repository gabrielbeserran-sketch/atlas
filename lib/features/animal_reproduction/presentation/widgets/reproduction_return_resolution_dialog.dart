import 'package:flutter/material.dart';

class ReturnResolutionInput {
  const ReturnResolutionInput(this.responsible, this.reason);
  final String responsible;
  final String reason;
}

Future<ReturnResolutionInput?> showReturnResolutionDialog(
  BuildContext context, {
  required bool cancel,
  String responsible = '',
}) {
  final form = GlobalKey<FormState>();
  var actor = responsible;
  var reason = '';
  return showDialog<ReturnResolutionInput>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(cancel ? 'Cancelar retorno' : 'Concluir retorno'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A previsão original será preservada. Esta baixa não registra diagnóstico, parto ou outro resultado clínico. A confirmação exige conexão com o servidor.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: responsible,
                decoration: const InputDecoration(
                  labelText: 'Responsável pela baixa',
                ),
                onChanged: (value) => actor = value,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Informe o responsável.'
                    : null,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: cancel
                      ? 'Motivo do cancelamento'
                      : 'Observação (opcional)',
                ),
                onChanged: (value) => reason = value,
                validator: (value) => cancel && (value ?? '').trim().isEmpty
                    ? 'Informe o motivo.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(
                context,
                ReturnResolutionInput(actor.trim(), reason.trim()),
              );
            }
          },
          child: const Text('Confirmar baixa'),
        ),
      ],
    ),
  );
}
