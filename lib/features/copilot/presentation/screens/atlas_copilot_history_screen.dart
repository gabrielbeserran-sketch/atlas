import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_history_storage_service.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_conversation_summary.dart';
import 'package:projeto_atlas/features/copilot/presentation/screens/atlas_copilot_conversation_viewer_screen.dart';

class AtlasCopilotHistoryScreen extends StatefulWidget {
  const AtlasCopilotHistoryScreen({required this.currentContextKey, super.key});

  final String currentContextKey;

  @override
  State<AtlasCopilotHistoryScreen> createState() {
    return _AtlasCopilotHistoryScreenState();
  }
}

class _AtlasCopilotHistoryScreenState extends State<AtlasCopilotHistoryScreen> {
  final AtlasCopilotHistoryStorageService storage =
      const AtlasCopilotHistoryStorageService();

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;

  AtlasCopilotHistoryFilter selectedFilter = AtlasCopilotHistoryFilter.all;

  AtlasCopilotHistorySort selectedSort = AtlasCopilotHistorySort.recent;

  List<AtlasCopilotConversationSummary> summaries = [];

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);

    loadHistories();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);

    searchController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> loadHistories() async {
    setState(() {
      isLoading = true;
    });

    final loaded = await storage.loadConversationSummaries();

    if (!mounted) {
      return;
    }

    setState(() {
      summaries = loaded;
      isLoading = false;
    });
  }

  List<AtlasCopilotConversationSummary> get filteredSummaries {
    final query = _normalize(searchController.text);

    final filtered = summaries.where((summary) {
      if (!_matchesFilter(summary)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchable = _normalize(
        '${summary.contextLabel} '
        '${summary.lastMessage}',
      );

      return searchable.contains(query);
    }).toList();

    switch (selectedSort) {
      case AtlasCopilotHistorySort.recent:
        filtered.sort(
          (first, second) => second.updatedAt.compareTo(first.updatedAt),
        );

      case AtlasCopilotHistorySort.messageCount:
        filtered.sort((first, second) {
          final countComparison = second.messageCount.compareTo(
            first.messageCount,
          );

          if (countComparison != 0) {
            return countComparison;
          }

          return second.updatedAt.compareTo(first.updatedAt);
        });
    }

    return filtered;
  }

  bool _matchesFilter(AtlasCopilotConversationSummary summary) {
    switch (selectedFilter) {
      case AtlasCopilotHistoryFilter.all:
        return true;

      case AtlasCopilotHistoryFilter.operation:
        return summary.isOperationContext;

      case AtlasCopilotHistoryFilter.farms:
        return summary.isFarmContext;
    }
  }

  int get totalMessages {
    return summaries.fold<int>(0, (sum, summary) => sum + summary.messageCount);
  }

  int get farmConversationCount {
    return summaries.where((summary) {
      return summary.isFarmContext;
    }).length;
  }

  int get operationConversationCount {
    return summaries.where((summary) {
      return summary.isOperationContext;
    }).length;
  }

  Future<void> openConversation(AtlasCopilotConversationSummary summary) async {
    final result = await Navigator.of(context)
        .push<AtlasCopilotConversationViewerResult>(
          MaterialPageRoute<AtlasCopilotConversationViewerResult>(
            builder: (context) {
              return AtlasCopilotConversationViewerScreen(
                summary: summary,
                currentContextKey: widget.currentContextKey,
              );
            },
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    if (result.continueCurrentConversation) {
      Navigator.of(context).pop();
      return;
    }

    if (result.deleted) {
      await loadHistories();
    }
  }

  Future<void> deleteConversation(
    AtlasCopilotConversationSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir conversa?'),
          content: Text(
            'O histórico de "${summary.contextLabel}" será apagado.',
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
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await storage.clear(contextKey: summary.contextKey);

    await loadHistories();
  }

  Future<void> clearAll() async {
    if (summaries.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar todos os históricos?'),
          content: const Text(
            'Todas as conversas do Copiloto Atlas serão removidas.',
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
              child: const Text('Apagar tudo'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await storage.clearAll();

    searchController.clear();

    setState(() {
      selectedFilter = AtlasCopilotHistoryFilter.all;

      selectedSort = AtlasCopilotHistorySort.recent;
    });

    await loadHistories();
  }

  void clearSearchAndFilters() {
    searchController.clear();

    setState(() {
      selectedFilter = AtlasCopilotHistoryFilter.all;

      selectedSort = AtlasCopilotHistorySort.recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleSummaries = filteredSummaries;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Históricos do Copiloto',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<AtlasCopilotHistorySort>(
            tooltip: 'Ordenar',
            initialValue: selectedSort,
            onSelected: (value) {
              setState(() {
                selectedSort = value;
              });
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: AtlasCopilotHistorySort.recent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.schedule),
                    title: Text('Mais recentes'),
                  ),
                ),
                PopupMenuItem(
                  value: AtlasCopilotHistorySort.messageCount,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.format_list_numbered),
                    title: Text('Mais mensagens'),
                  ),
                ),
              ];
            },
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            tooltip: 'Apagar todos',
            onPressed: summaries.isEmpty || isLoading ? null : clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : summaries.isEmpty
          ? const _EmptyHistoryView()
          : RefreshIndicator(
              onRefresh: loadHistories,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: Column(
                        children: [
                          _HistorySummaryPanel(
                            conversationCount: summaries.length,
                            farmCount: farmConversationCount,
                            operationCount: operationConversationCount,
                            messageCount: totalMessages,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar fazenda ou mensagem...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar busca',
                                      onPressed: searchController.clear,
                                      icon: const Icon(Icons.close),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _HistoryFilterBar(
                            selected: selectedFilter,
                            allCount: summaries.length,
                            operationCount: operationConversationCount,
                            farmCount: farmConversationCount,
                            onSelected: (filter) {
                              setState(() {
                                selectedFilter = filter;
                              });
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${visibleSummaries.length} '
                                  '${visibleSummaries.length == 1 ? 'conversa encontrada' : 'conversas encontradas'}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                selectedSort == AtlasCopilotHistorySort.recent
                                    ? 'Mais recentes'
                                    : 'Mais mensagens',
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (visibleSummaries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FilteredEmptyView(onClear: clearSearchAndFilters),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      sliver: SliverList.separated(
                        itemCount: visibleSummaries.length,
                        separatorBuilder: (_, __) {
                          return const SizedBox(height: 11);
                        },
                        itemBuilder: (context, index) {
                          final summary = visibleSummaries[index];

                          return _HistoryCard(
                            summary: summary,
                            isCurrent:
                                summary.contextKey == widget.currentContextKey,
                            onOpen: () {
                              openConversation(summary);
                            },
                            onDelete: () {
                              deleteConversation(summary);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
}

class _HistorySummaryPanel extends StatelessWidget {
  const _HistorySummaryPanel({
    required this.conversationCount,
    required this.farmCount,
    required this.operationCount,
    required this.messageCount,
  });

  final int conversationCount;
  final int farmCount;
  final int operationCount;
  final int messageCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _HistoryMetricCard(
              width: width,
              label: 'Conversas',
              value: conversationCount.toString(),
              icon: Icons.forum_outlined,
              color: const Color(0xFF1565C0),
            ),
            _HistoryMetricCard(
              width: width,
              label: 'Fazendas',
              value: farmCount.toString(),
              icon: Icons.agriculture_outlined,
              color: const Color(0xFF1B5E20),
            ),
            _HistoryMetricCard(
              width: width,
              label: 'Operação',
              value: operationCount.toString(),
              icon: Icons.business_outlined,
              color: const Color(0xFF6A1B9A),
            ),
            _HistoryMetricCard(
              width: width,
              label: 'Mensagens',
              value: messageCount.toString(),
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFEF6C00),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryMetricCard extends StatelessWidget {
  const _HistoryMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.selected,
    required this.allCount,
    required this.operationCount,
    required this.farmCount,
    required this.onSelected,
  });

  final AtlasCopilotHistoryFilter selected;

  final int allCount;
  final int operationCount;
  final int farmCount;

  final ValueChanged<AtlasCopilotHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            count: allCount,
            selected: selected == AtlasCopilotHistoryFilter.all,
            onSelected: () {
              onSelected(AtlasCopilotHistoryFilter.all);
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Operação',
            count: operationCount,
            selected: selected == AtlasCopilotHistoryFilter.operation,
            onSelected: () {
              onSelected(AtlasCopilotHistoryFilter.operation);
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Fazendas',
            count: farmCount,
            selected: selected == AtlasCopilotHistoryFilter.farms,
            onSelected: () {
              onSelected(AtlasCopilotHistoryFilter.farms);
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
      label: Text('$label ($count)'),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.summary,
    required this.isCurrent,
    required this.onOpen,
    required this.onDelete,
  });

  final AtlasCopilotConversationSummary summary;

  final bool isCurrent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = summary.isFarmContext
        ? const Color(0xFF1B5E20)
        : const Color(0xFF1565C0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  summary.isFarmContext
                      ? Icons.agriculture_outlined
                      : Icons.business_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.contextLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Atual',
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.lastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${summary.messageCount} mensagens · '
                            '${_formatDateTime(summary.updatedAt)}',
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir conversa',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }
}

class _FilteredEmptyView extends StatelessWidget {
  const _FilteredEmptyView({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 54, color: Colors.black38),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma conversa encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            const Text(
              'Tente alterar a busca ou os filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Limpar filtros'),
            ),
          ],
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
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 54, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Nenhum histórico salvo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'As conversas aparecerão aqui depois que você utilizar o Copiloto Atlas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

enum AtlasCopilotHistoryFilter { all, operation, farms }

enum AtlasCopilotHistorySort { recent, messageCount }
