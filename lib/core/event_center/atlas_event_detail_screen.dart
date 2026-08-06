import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventDetailScreen extends StatelessWidget {
  const AtlasEventDetailScreen({
    required this.item,
    super.key,
  });

  final AtlasEventLogEntry item;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(item.priority);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Detalhes do evento',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  color.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.event_note_outlined,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    atlasEventTypeLabel(item.type),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              atlasEventPriorityLabel(item.priority),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Identificação',
                  children: [
                    _DetailRow(
                      label: 'ID do registro',
                      value: item.id,
                    ),
                    _DetailRow(
                      label: 'ID do evento',
                      value: item.eventId,
                    ),
                    _DetailRow(
                      label: 'Módulo',
                      value: item.sourceModule,
                    ),
                    _DetailRow(
                      label: 'Fazenda',
                      value: item.farmName ?? 'Operação',
                    ),
                    _DetailRow(
                      label: 'Entidade',
                      value: item.entityType ?? 'Não informada',
                    ),
                    _DetailRow(
                      label: 'ID da entidade',
                      value: item.entityId ?? 'Não informado',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Datas',
                  children: [
                    _DetailRow(
                      label: 'Ocorrido em',
                      value: _formatDateTime(item.occurredAt),
                    ),
                    _DetailRow(
                      label: 'Registrado em',
                      value: _formatDateTime(item.recordedAt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Tags',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.isEmpty
                          ? const [
                              Text(
                                'Nenhuma tag disponível.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ]
                          : item.tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                              );
                            }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Payload',
                  children: item.payload.isEmpty
                      ? const [
                          Text(
                            'Nenhum dado adicional disponível.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ]
                      : item.payload.entries.map((entry) {
                          return _DetailRow(
                            label: entry.key,
                            value: entry.value?.toString() ?? 'null',
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}

Color _priorityColor(
  AtlasEventPriority priority,
) {
  switch (priority) {
    case AtlasEventPriority.low:
      return const Color(0xFF2E7D32);
    case AtlasEventPriority.normal:
      return const Color(0xFF1565C0);
    case AtlasEventPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasEventPriority.critical:
      return const Color(0xFFC62828);
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');

  return '$day/$month/${value.year} · $hour:$minute:$second';
}
