import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/offline_operation.dart';

class OfflineFailedOperationsSection extends StatelessWidget {
  const OfflineFailedOperationsSection({
    required this.operations,
    required this.total,
    super.key,
  });

  final List<OfflineOperation> operations;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Falhas que precisam de revisão',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Os registros permanecem neste dispositivo. '
          'Falhas permanentes não são reenviadas automaticamente.',
        ),
        const SizedBox(height: 8),
        for (final operation in operations)
          Card(
            child: ExpansionTile(
              key: ValueKey('offline-failure-${operation.id}'),
              leading: const Icon(Icons.error_outline),
              title: Text(
                '${operation.entityType} • ${operation.entityId}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                operation.lastError.isEmpty
                    ? 'O servidor recusou esta alteração.'
                    : operation.lastError,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Fazenda: ${operation.farmId ?? 'Registro geral'}\n'
                      'Operação: ${operation.id}\n'
                      'Tentativas: ${operation.attempts}\n'
                      'Criada em: ${DateFormat('dd/MM/yyyy HH:mm').format(operation.createdAt.toLocal())}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (total > operations.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Exibindo ${operations.length} de $total falhas. '
              'Use o filtro de fazenda para localizar outras.',
            ),
          ),
      ],
    );
  }
}
