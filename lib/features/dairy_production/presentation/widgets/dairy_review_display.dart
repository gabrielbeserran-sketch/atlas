import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_decision_service.dart';

class DairyReviewField {
  const DairyReviewField(this.label, this.value);
  final String label;
  final String value;
}

/// Human-readable, lossless-enough summary of the dairy fields being compared.
/// Unknown future keys remain visible rather than hiding a difference.
class DairyReviewDisplay {
  static String title(String type, String id) {
    final day = id.split(':').last;
    final date = DateTime.tryParse(day);
    final formatted = date == null
        ? day
        : DateFormat('dd/MM/yyyy').format(date);
    final kind = type == 'dairy_daily_production'
        ? 'Ordenha'
        : type == 'dairy_herd_snapshot'
        ? 'Estado do lote'
        : 'Registro de Leite';
    return '$kind · $formatted';
  }

  static String localStatus(DairyReviewStatus status) => switch (status) {
    DairyReviewStatus.waitingForCache => 'Sem cópia recebida neste aparelho',
    DairyReviewStatus.sameAsCached => 'Igual à última cópia recebida',
    DairyReviewStatus.differsFromCached => 'Difere da última cópia recebida',
    DairyReviewStatus.deletedInCache => 'Excluído na última cópia recebida',
    DairyReviewStatus.localChanged =>
      'Alterado neste aparelho após a preparação',
    DairyReviewStatus.localMissing => 'Registro local não encontrado',
    DairyReviewStatus.invalidStage => 'Cópia preparada inválida',
    DairyReviewStatus.invalidCache => 'Última cópia recebida inválida',
    DairyReviewStatus.scopeConflict => 'Escopo da última cópia divergente',
  };

  static String remoteStatus(
    DairyRemoteReviewStatus status,
  ) => switch (status) {
    DairyRemoteReviewStatus.localReview => 'Revise o registro neste aparelho',
    DairyRemoteReviewStatus.absentOnServer => 'Ainda ausente no servidor',
    DairyRemoteReviewStatus.sameOnServer => 'Igual no servidor',
    DairyRemoteReviewStatus.differsOnServer => 'Valores diferentes no servidor',
    DairyRemoteReviewStatus.deletedOnServer => 'Excluído no servidor',
  };

  static List<DairyReviewField> fields(
    String type,
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) {
      return const [DairyReviewField('Dados', 'Indisponíveis')];
    }
    final known = type == 'dairy_daily_production'
        ? const <String, String>{
            'date': 'Data',
            'morning_liters': 'Leite de manhã (L)',
            'afternoon_liters': 'Leite à tarde (L)',
            'cows_milked': 'Vacas ordenhadas',
            'notes': 'Observações',
          }
        : const <String, String>{
            'date': 'Data',
            'eligible_cows': 'Vacas elegíveis',
            'lactating_cows': 'Vacas em lactação',
            'dry_cows': 'Vacas secas',
            'pregnancies_monitored': 'Gestações acompanhadas',
            'pregnancy_losses': 'Perdas gestacionais',
          };
    final fields = <DairyReviewField>[];
    for (final entry in known.entries) {
      if (!payload.containsKey(entry.key)) continue;
      final value = payload[entry.key];
      if (entry.key == 'notes' && (value == null || '$value'.trim().isEmpty)) {
        continue;
      }
      fields.add(DairyReviewField(entry.value, _format(entry.key, value)));
    }
    final extraKeys =
        payload.keys
            .where((key) => key != 'farm_id' && !known.containsKey(key))
            .toList()
          ..sort();
    for (final key in extraKeys) {
      fields.add(DairyReviewField(key, _format(key, payload[key])));
    }
    return List.unmodifiable(fields);
  }

  static String _format(String key, Object? value) {
    if (value == null) return 'Não informado';
    if (key == 'date' && value is String && value.length >= 10) {
      final date = DateTime.tryParse(value.substring(0, 10));
      if (date != null) return DateFormat('dd/MM/yyyy').format(date);
    }
    if (value is num) return NumberFormat.decimalPattern('pt_BR').format(value);
    return value.toString();
  }
}

class DairyReviewDetails extends StatelessWidget {
  const DairyReviewDetails({
    required this.local,
    this.remote,
    this.decision,
    this.onPreferLocal,
    this.onKeepServer,
    this.onRemoveDecision,
    super.key,
  });

  final DairyReviewItem local;
  final DairyRemoteReviewEntry? remote;
  final DairySavedDecision? decision;
  final VoidCallback? onPreferLocal;
  final VoidCallback? onKeepServer;
  final VoidCallback? onRemoveDecision;

  @override
  Widget build(BuildContext context) {
    final status = remote == null
        ? DairyReviewDisplay.localStatus(local.status)
        : DairyReviewDisplay.remoteStatus(remote!.status);
    return Card(
      child: ExpansionTile(
        title: Text(DairyReviewDisplay.title(local.entityType, local.entityId)),
        subtitle: Text(status),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _values(
            context,
            'Cópia preparada neste aparelho',
            local.stagedPayload,
          ),
          if (local.status == DairyReviewStatus.localChanged ||
              local.status == DairyReviewStatus.localMissing)
            _values(
              context,
              'Registro atual neste aparelho',
              local.localPayload,
            ),
          if (remote == null && local.cachedVersion != null) ...[
            const SizedBox(height: 12),
            Text(
              'Última cópia recebida · versão ${local.cachedVersion}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (local.cachedDeleted)
              const Text('Excluído nessa cópia; o servidor pode ter mudado.'),
            if (!local.cachedDeleted)
              _values(context, 'Valores recebidos', local.cachedPayload),
            Text(
              'Esta cópia pode estar desatualizada.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (remote != null) ...[
            const SizedBox(height: 12),
            Text(
              remote!.remote.found
                  ? 'Servidor · versão ${remote!.remote.version}'
                  : 'Servidor · registro ausente',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (remote!.remote.deleted)
              const Text('O registro foi excluído no servidor.'),
            if (remote!.remote.found && !remote!.remote.deleted)
              _values(context, 'Valores no servidor', remote!.remote.payload),
            Text(
              'Consulta em ${DateFormat('dd/MM/yyyy HH:mm').format(remote!.remote.readAt.toLocal())}. '
              'O servidor pode mudar após esse horário.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (decision != null) ...[
            const SizedBox(height: 12),
            Text(
              decision!.choice == DairyDecisionChoice.preferLocal
                  ? 'Preferência salva: dados deste aparelho'
                  : 'Preferência salva: não enviar registro local',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              decision!.matchesLocal(local)
                  ? 'Não enviado. O servidor será conferido novamente antes de qualquer envio.'
                  : 'Dados locais mudaram: esta preferência exige nova conferência.',
            ),
            if (onRemoveDecision != null)
              TextButton(
                onPressed: onRemoveDecision,
                child: const Text('Retirar preferência'),
              ),
          ],
          if (remote != null &&
              const {
                DairyRemoteReviewStatus.absentOnServer,
                DairyRemoteReviewStatus.differsOnServer,
                DairyRemoteReviewStatus.deletedOnServer,
              }.contains(remote!.status) &&
              onPreferLocal != null &&
              onKeepServer != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Escolha uma preferência para esta divergência. Ela será salva apenas neste aparelho e não inicia o envio.',
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onPreferLocal,
                  child: const Text('Preferir este aparelho'),
                ),
                OutlinedButton(
                  onPressed: onKeepServer,
                  child: Text(
                    remote!.status == DairyRemoteReviewStatus.absentOnServer
                        ? 'Não enviar este registro'
                        : 'Manter no servidor',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _values(
    BuildContext context,
    String heading,
    Map<String, dynamic>? data,
  ) {
    final fields = DairyReviewDisplay.fields(local.entityType, data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(heading, style: Theme.of(context).textTheme.titleSmall),
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${field.label}: ${field.value}'),
          ),
      ],
    );
  }
}
