import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_history.dart';
import 'package:projeto_atlas/features/executive_brain/domain/services/atlas_executive_brain_history_service.dart';

class AtlasExecutiveBrainHistoryScreen extends StatefulWidget {
  const AtlasExecutiveBrainHistoryScreen({super.key});

  @override
  State<AtlasExecutiveBrainHistoryScreen> createState() {
    return _AtlasExecutiveBrainHistoryScreenState();
  }
}

class _AtlasExecutiveBrainHistoryScreenState
    extends State<AtlasExecutiveBrainHistoryScreen> {
  AtlasExecutiveBrainChangeType? selectedType;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await AtlasExecutiveBrainHistoryService.instance.load();

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  List<AtlasExecutiveBrainHistoryEntry> get filteredEntries {
    final entries =
        AtlasExecutiveBrainHistoryService.instance.entries;

    if (selectedType == null) {
      return entries;
    }

    return entries
        .where((item) => item.changeType == selectedType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = filteredEntries;
    final total =
        AtlasExecutiveBrainHistoryService.instance.entries.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Histórico do Executive Brain',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: total == 0 ? null : _confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${entries.length} de $total registros exibidos',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: DropdownButtonFormField<
                                AtlasExecutiveBrainChangeType?>(
                              initialValue: selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por alteração',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<
                                    AtlasExecutiveBrainChangeType?>(
                                  value: null,
                                  child: Text('Todas'),
                                ),
                                ...AtlasExecutiveBrainChangeType.values.map(
                                  (type) {
                                    return DropdownMenuItem<
                                        AtlasExecutiveBrainChangeType?>(
                                      value: type,
                                      child: Text(
                                        atlasExecutiveBrainChangeTypeLabel(
                                          type,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const _EmptyHistoryView()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            22,
                            10,
                            22,
                            28,
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            return _HistoryCard(
                              item: entries[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limpar histórico?'),
          content: const Text(
            'Todas as mudanças registradas nesta execução serão removidas.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AtlasExecutiveBrainHistoryService.instance.clear();

    if (!mounted) {
      return;
    }

    setState(() {});
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final AtlasExecutiveBrainHistoryEntry item;

  @override
  Widget build(BuildContext context) {
    final color = _changeColor(item.changeType);
    final scoreVariation = item.previousScore == null
        ? null
        : item.currentScore - item.previousScore!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    _changeIcon(item.changeType),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atlasExecutiveBrainChangeTypeLabel(
                          item.changeType,
                        ),
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(item.recordedAt),
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Score ${item.currentScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (scoreVariation != null)
                      Text(
                        '${scoreVariation >= 0 ? '+' : ''}'
                        '${scoreVariation.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: scoreVariation >= 0
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFC62828),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.reason,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anterior: '
                    '${item.previousDecisionTitle ?? 'Nenhuma decisão'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atual: '
                    '${item.currentDecisionTitle ?? 'Nenhuma decisão'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  label: 'Confiança',
                  value:
                      '${item.currentConfidencePercent.toStringAsFixed(0)}%',
                ),
                _MetricChip(
                  label: 'Status',
                  value: item.currentStatus.name,
                ),
                _MetricChip(
                  label: 'ID atual',
                  value: item.currentDecisionId ?? 'Sem decisão',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 54,
              color: Colors.black26,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhuma mudança registrada.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'O histórico será preenchido quando o Executive Brain publicar novas decisões.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
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

Color _changeColor(
  AtlasExecutiveBrainChangeType type,
) {
  switch (type) {
    case AtlasExecutiveBrainChangeType.initialized:
      return const Color(0xFF1565C0);
    case AtlasExecutiveBrainChangeType.decisionChanged:
      return const Color(0xFF6A1B9A);
    case AtlasExecutiveBrainChangeType.decisionRemoved:
      return const Color(0xFFC62828);
    case AtlasExecutiveBrainChangeType.priorityChanged:
      return const Color(0xFFEF6C00);
    case AtlasExecutiveBrainChangeType.scoreChanged:
      return const Color(0xFF00838F);
    case AtlasExecutiveBrainChangeType.strategyChanged:
      return const Color(0xFF2E7D32);
  }
}

IconData _changeIcon(
  AtlasExecutiveBrainChangeType type,
) {
  switch (type) {
    case AtlasExecutiveBrainChangeType.initialized:
      return Icons.play_circle_outline;
    case AtlasExecutiveBrainChangeType.decisionChanged:
      return Icons.swap_horiz;
    case AtlasExecutiveBrainChangeType.decisionRemoved:
      return Icons.remove_circle_outline;
    case AtlasExecutiveBrainChangeType.priorityChanged:
      return Icons.priority_high;
    case AtlasExecutiveBrainChangeType.scoreChanged:
      return Icons.monitor_heart_outlined;
    case AtlasExecutiveBrainChangeType.strategyChanged:
      return Icons.route_outlined;
  }
}
