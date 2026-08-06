import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/command_center/data/services/atlas_command_repository.dart';
import 'package:projeto_atlas/features/command_center/domain/models/atlas_command_center_data.dart';
import 'package:projeto_atlas/features/command_center/domain/services/atlas_command_engine.dart';

class AtlasCommandCenterScreen extends StatefulWidget {
  const AtlasCommandCenterScreen({super.key});

  @override
  State<AtlasCommandCenterScreen> createState() =>
      _AtlasCommandCenterScreenState();
}

class _AtlasCommandCenterScreenState
    extends State<AtlasCommandCenterScreen> {
  final AtlasCommandRepository _repository = AtlasCommandRepository();
  final AtlasCommandEngine _engine = AtlasCommandEngine();

  AtlasCommandCenterState? _state;
  AtlasCommandCategory? _selectedCategory;
  bool _showOnlyOpen = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasCommandCenterState state = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _state = state;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(
    AtlasCommandItem item,
    AtlasCommandItemStatus status,
  ) async {
    final AtlasCommandCenterState? currentState = _state;
    if (currentState == null) {
      return;
    }

    final List<AtlasCommandItem> updatedItems = currentState.items
        .map(
          (AtlasCommandItem current) =>
              current.id == item.id ? current.copyWith(status: status) : current,
        )
        .toList();
    final AtlasCommandCenterState updatedState = currentState.copyWith(
      items: updatedItems,
      lastUpdatedAt: DateTime.now(),
    );
    await _repository.save(updatedState);
    if (!mounted) {
      return;
    }
    setState(() {
      _state = updatedState;
    });
  }

  List<AtlasCommandItem> _filteredItems(AtlasCommandCenterState state) {
    return _engine.orderedItems(state).where((AtlasCommandItem item) {
      final bool matchesOpen = !_showOnlyOpen || item.isOpen;
      final bool matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      return matchesOpen && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Command Center'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final AtlasCommandCenterState state = _state!;
    final AtlasDailyBrief brief = _engine.buildBrief(state);
    final List<AtlasCommandItem> items = _filteredItems(state);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _BriefCard(brief: brief),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.1 : 2.0,
                children: <Widget>[
                  _MetricCard(
                    label: 'Prioridades críticas',
                    value: brief.criticalCount.toString(),
                    icon: Icons.warning_amber_rounded,
                  ),
                  _MetricCard(
                    label: 'Itens abertos',
                    value: brief.openCount.toString(),
                    icon: Icons.pending_actions_rounded,
                  ),
                  _MetricCard(
                    label: 'Tarefas vencidas',
                    value: brief.overdueCount.toString(),
                    icon: Icons.schedule_rounded,
                  ),
                  _MetricCard(
                    label: 'Concluídos',
                    value: brief.completedCount.toString(),
                    icon: Icons.task_alt_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _FilterCard(
            selectedCategory: _selectedCategory,
            showOnlyOpen: _showOnlyOpen,
            onCategoryChanged: (AtlasCommandCategory? category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            onShowOnlyOpenChanged: (bool value) {
              setState(() {
                _showOnlyOpen = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Fila inteligente (${items.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const _EmptyState()
          else
            ...items.map(
              (AtlasCommandItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommandItemCard(
                  item: item,
                  onStatusChanged: (AtlasCommandItemStatus status) {
                    _updateStatus(item, status);
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Última atualização: ${_formatDateTime(state.lastUpdatedAt)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }
}

class _BriefCard extends StatelessWidget {
  const _BriefCard({required this.brief});

  final AtlasDailyBrief brief;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF123B5D).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    color: Color(0xFF123B5D),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Briefing executivo do dia',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Índice de controle: ${brief.attentionScore}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(brief.message),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: brief.attentionScore / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.selectedCategory,
    required this.showOnlyOpen,
    required this.onCategoryChanged,
    required this.onShowOnlyOpenChanged,
  });

  final AtlasCommandCategory? selectedCategory;
  final bool showOnlyOpen;
  final ValueChanged<AtlasCommandCategory?> onCategoryChanged;
  final ValueChanged<bool> onShowOnlyOpenChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<AtlasCommandCategory?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<AtlasCommandCategory?>>[
                  const DropdownMenuItem<AtlasCommandCategory?>(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  ...AtlasCommandCategory.values.map(
                    (AtlasCommandCategory category) =>
                        DropdownMenuItem<AtlasCommandCategory?>(
                      value: category,
                      child: Text(_categoryLabel(category)),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
            FilterChip(
              selected: showOnlyOpen,
              label: const Text('Somente itens abertos'),
              onSelected: onShowOnlyOpenChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandItemCard extends StatelessWidget {
  const _CommandItemCard({
    required this.item,
    required this.onStatusChanged,
  });

  final AtlasCommandItem item;
  final ValueChanged<AtlasCommandItemStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  child: Icon(_categoryIcon(item.category)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.description),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PriorityBadge(priority: item.priority),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.apps_rounded, size: 16),
                  label: Text(item.sourceModule),
                ),
                Chip(
                  avatar: Icon(
                    item.isOverdue
                        ? Icons.error_outline_rounded
                        : Icons.flag_outlined,
                    size: 16,
                  ),
                  label: Text(
                    item.isOverdue
                        ? 'Vencido'
                        : _statusLabel(item.status),
                  ),
                ),
                if (item.actionLabel != null)
                  Chip(
                    avatar: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(item.actionLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (item.status != AtlasCommandItemStatus.completed)
                  TextButton.icon(
                    onPressed: () => onStatusChanged(
                      AtlasCommandItemStatus.completed,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Concluir'),
                  ),
                if (item.status == AtlasCommandItemStatus.completed)
                  TextButton.icon(
                    onPressed: () => onStatusChanged(
                      AtlasCommandItemStatus.inProgress,
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Reabrir'),
                  ),
                if (item.isOpen)
                  PopupMenuButton<AtlasCommandItemStatus>(
                    tooltip: 'Alterar status',
                    onSelected: onStatusChanged,
                    itemBuilder: (BuildContext context) =>
                        const <PopupMenuEntry<AtlasCommandItemStatus>>[
                      PopupMenuItem<AtlasCommandItemStatus>(
                        value: AtlasCommandItemStatus.newItem,
                        child: Text('Novo'),
                      ),
                      PopupMenuItem<AtlasCommandItemStatus>(
                        value: AtlasCommandItemStatus.inProgress,
                        child: Text('Em andamento'),
                      ),
                      PopupMenuItem<AtlasCommandItemStatus>(
                        value: AtlasCommandItemStatus.dismissed,
                        child: Text('Dispensar'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final AtlasCommandPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _priorityColor(priority).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _priorityLabel(priority),
        style: TextStyle(
          color: _priorityColor(priority),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: <Widget>[
            Icon(Icons.inbox_outlined, size: 42),
            SizedBox(height: 10),
            Text('Nenhum item encontrado para os filtros selecionados.'),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(AtlasCommandCategory category) {
  switch (category) {
    case AtlasCommandCategory.sanitary:
      return 'Sanidade';
    case AtlasCommandCategory.financial:
      return 'Financeiro';
    case AtlasCommandCategory.operational:
      return 'Operacional';
    case AtlasCommandCategory.reproductive:
      return 'Reprodução';
    case AtlasCommandCategory.strategic:
      return 'Estratégico';
    case AtlasCommandCategory.agenda:
      return 'Agenda';
    case AtlasCommandCategory.system:
      return 'Sistema';
  }
}

IconData _categoryIcon(AtlasCommandCategory category) {
  switch (category) {
    case AtlasCommandCategory.sanitary:
      return Icons.health_and_safety_outlined;
    case AtlasCommandCategory.financial:
      return Icons.account_balance_wallet_outlined;
    case AtlasCommandCategory.operational:
      return Icons.precision_manufacturing_outlined;
    case AtlasCommandCategory.reproductive:
      return Icons.pets_outlined;
    case AtlasCommandCategory.strategic:
      return Icons.track_changes_rounded;
    case AtlasCommandCategory.agenda:
      return Icons.calendar_month_outlined;
    case AtlasCommandCategory.system:
      return Icons.settings_outlined;
  }
}

String _priorityLabel(AtlasCommandPriority priority) {
  switch (priority) {
    case AtlasCommandPriority.critical:
      return 'Crítica';
    case AtlasCommandPriority.high:
      return 'Alta';
    case AtlasCommandPriority.medium:
      return 'Média';
    case AtlasCommandPriority.low:
      return 'Baixa';
  }
}

Color _priorityColor(AtlasCommandPriority priority) {
  switch (priority) {
    case AtlasCommandPriority.critical:
      return const Color(0xFFB3261E);
    case AtlasCommandPriority.high:
      return const Color(0xFFE65100);
    case AtlasCommandPriority.medium:
      return const Color(0xFF7A5A00);
    case AtlasCommandPriority.low:
      return const Color(0xFF2E7D32);
  }
}

String _statusLabel(AtlasCommandItemStatus status) {
  switch (status) {
    case AtlasCommandItemStatus.newItem:
      return 'Novo';
    case AtlasCommandItemStatus.inProgress:
      return 'Em andamento';
    case AtlasCommandItemStatus.completed:
      return 'Concluído';
    case AtlasCommandItemStatus.dismissed:
      return 'Dispensado';
  }
}
