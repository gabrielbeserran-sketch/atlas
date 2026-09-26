import 'package:flutter/material.dart';
import '../../data/services/atlas_operations_repository.dart';

class OperationsLegacyRecoveryScreen extends StatefulWidget {
  const OperationsLegacyRecoveryScreen({
    super.key,
    required this.repository,
    required this.actorId,
    required this.farmId,
    required this.isAuthorized,
  });
  final AtlasOperationsRepository repository;
  final String actorId;
  final String farmId;
  final bool Function() isAuthorized;
  @override
  State<OperationsLegacyRecoveryScreen> createState() => _RecoveryState();
}

class _RecoveryState extends State<OperationsLegacyRecoveryScreen> {
  List<Map<String, dynamic>>? records;
  final selected = <int>{};
  bool acknowledged = false;
  bool busy = false;
  String? error;
  Future<void> review() async {
    if (!acknowledged || !widget.isAuthorized()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.reviewLegacy(
        isAuthorized: widget.isAuthorized,
      );
      if (mounted && widget.isAuthorized()) {
        setState(() {
          records = result;
          selected.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível revisar. Confira o acesso e a integridade dos registros.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recover() async {
    if (busy || selected.isEmpty || !widget.isAuthorized()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Confirmar atribuição'),
        content: Text(
          'Copiar ${selected.length} operação(ões) para a fazenda ${widget.farmId}? Confirme que pertencem a esta empresa/fazenda. O arquivo antigo será mantido. Não copie registros de outros clientes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Confirmar recuperação'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !widget.isAuthorized()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final count = await widget.repository.recoverLegacy(
        reviewed: selected.map((i) => records![i]).toList(),
        actorId: widget.actorId,
        confirmedOwnership: true,
        isAuthorized: widget.isAuthorized,
      );
      if (!mounted || !widget.isAuthorized()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count operação(ões) recuperada(s). As já recuperadas não foram duplicadas.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Recuperação recusada. A origem foi preservada; revise novamente. Pode haver alteração, ID duplicado ou conflito no destino.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recuperar operações antigas')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Os registros antigos não identificam a empresa proprietária. Esta revisão é uma atribuição manual, não uma comprovação automática de propriedade. A auditoria é local e a origem não será excluída.',
        ),
        if (records == null) ...[
          CheckboxListTile(
            value: acknowledged,
            onChanged: busy
                ? null
                : (value) => setState(() => acknowledged = value ?? false),
            title: const Text(
              'Tenho autorização para revisar os registros antigos deste dispositivo.',
            ),
          ),
          FilledButton(
            onPressed: acknowledged && !busy ? review : null,
            child: const Text('Revisar registros'),
          ),
        ] else ...[
          Text(
            'Destino: fazenda ${widget.farmId}. Selecione somente registros desta operação.',
          ),
          if (records!.isEmpty)
            const Text('Nenhum registro antigo disponível.'),
          for (var i = 0; i < records!.length; i++)
            CheckboxListTile(
              value: selected.contains(i),
              onChanged: busy
                  ? null
                  : (value) => setState(() {
                      if (value == true) {
                        selected.add(i);
                      } else {
                        selected.remove(i);
                      }
                    }),
              title: Text(records![i]['title']?.toString() ?? 'Sem título'),
              subtitle: Text(
                'ID: ${records![i]['id']} · vínculo antigo: ${records![i]['farmId'] ?? 'ausente'}\nData: ${records![i]['scheduledAt'] ?? 'ausente'} · custo previsto: ${records![i]['plannedCost'] ?? 'ausente'}',
              ),
            ),
          FilledButton(
            onPressed: !busy && selected.isNotEmpty ? recover : null,
            child: const Text('Recuperar selecionadas'),
          ),
        ],
        if (busy) const LinearProgressIndicator(),
        if (error != null) Text(error!),
      ],
    ),
  );
}
