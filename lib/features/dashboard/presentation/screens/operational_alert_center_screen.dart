import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/data/services/atlas_operational_intelligence_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';

class OperationalAlertCenterScreen extends StatefulWidget {
  const OperationalAlertCenterScreen({
    required this.farmId,
    required this.farmName,
    required this.onOpenArea,
    super.key,
  });

  final String farmId;
  final String farmName;
  final ValueChanged<String> onOpenArea;

  @override
  State<OperationalAlertCenterScreen> createState() =>
      _OperationalAlertCenterScreenState();
}

class _OperationalAlertCenterScreenState
    extends State<OperationalAlertCenterScreen> {
  final AtlasOperationalIntelligenceService _service =
      AtlasOperationalIntelligenceService();
  final TextEditingController _searchController = TextEditingController();

  AtlasOperationalIntelligenceData? _data;
  String? _error;
  bool _loading = true;
  String _severity = 'all';
  String _area = 'all';
  String _order = 'priority';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _service.load(widget.farmId);
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar os alertas: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AtlasOperationalAlertData> get _filteredAlerts {
    final data = _data;
    if (data == null) return const <AtlasOperationalAlertData>[];

    final query = _searchController.text.trim().toLowerCase();
    final result = data.alerts
        .where((alert) {
          if (_severity != 'all' && alert.severity.toLowerCase() != _severity) {
            return false;
          }
          if (_area != 'all' && alert.area != _area) return false;
          if (query.isEmpty) return true;
          final haystack = <String>[
            alert.title,
            alert.description,
            alert.recommendedAction,
            alert.area,
            alert.code,
            alert.entityType,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);

    switch (_order) {
      case 'due':
        result.sort((a, b) {
          final ad = a.dueAt;
          final bd = b.dueAt;
          if (ad == null && bd == null) {
            return b.priorityScore.compareTo(a.priorityScore);
          }
          if (ad == null) return 1;
          if (bd == null) return -1;
          final byDate = ad.compareTo(bd);
          return byDate != 0
              ? byDate
              : b.priorityScore.compareTo(a.priorityScore);
        });
        break;
      case 'area':
        result.sort((a, b) {
          final byArea = a.area.compareTo(b.area);
          return byArea != 0
              ? byArea
              : b.priorityScore.compareTo(a.priorityScore);
        });
        break;
      default:
        result.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    }

    return result;
  }

  List<String> get _areas {
    final data = _data;
    if (data == null) return const <String>[];
    final values = data.alerts.map((alert) => alert.area).toSet().toList();
    values.sort();
    return values;
  }

  Future<void> _openResolutionGuide(AtlasOperationalAlertData alert) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SeverityPill(severity: alert.severity),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alert.area,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (alert.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(alert.description),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Ação recomendada',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.recommendedAction.isEmpty
                      ? 'Abra o módulo de origem e corrija a condição que gerou este alerta.'
                      : alert.recommendedAction,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'O Atlas não marca este alerta como resolvido manualmente. '
                    'Ele desaparece automaticamente quando a causa real é corrigida, '
                    'preservando a integridade dos dados.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Fechar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).pop();
                          widget.onOpenArea(alert.area);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: Text('Abrir ${alert.area}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final alerts = _filteredAlerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de alertas operacionais'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _AlertHeader(
                    farmName: widget.farmName,
                    data: data,
                    error: _error,
                  ),
                  const SizedBox(height: 18),
                  if (data != null) ...[
                    _AlertFilters(
                      searchController: _searchController,
                      severity: _severity,
                      area: _area,
                      order: _order,
                      areas: _areas,
                      onSearchChanged: (_) => setState(() {}),
                      onSeverityChanged: (value) {
                        if (value != null) setState(() => _severity = value);
                      },
                      onAreaChanged: (value) {
                        if (value != null) setState(() => _area = value);
                      },
                      onOrderChanged: (value) {
                        if (value != null) setState(() => _order = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${alerts.length} alerta(s) encontrado(s)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (alerts.isEmpty)
                      const _NoAlertsCard()
                    else
                      ...alerts.map(
                        (alert) => _OperationalAlertTile(
                          alert: alert,
                          onResolve: () => _openResolutionGuide(alert),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader({
    required this.farmName,
    required this.data,
    required this.error,
  });

  final String farmName;
  final AtlasOperationalIntelligenceData? data;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final value = data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farmName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Priorize o que exige ação e abra diretamente o módulo responsável.',
              style: TextStyle(color: Colors.black54),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            if (value != null) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                    label: 'Score',
                    value: '${value.operationalScore}',
                    icon: Icons.speed,
                  ),
                  _MetricChip(
                    label: 'Críticos',
                    value: '${value.criticalAlerts}',
                    icon: Icons.crisis_alert,
                  ),
                  _MetricChip(
                    label: 'Altos',
                    value: '${value.highAlerts}',
                    icon: Icons.priority_high,
                  ),
                  _MetricChip(
                    label: 'Médios',
                    value: '${value.mediumAlerts}',
                    icon: Icons.warning_amber,
                  ),
                  _MetricChip(
                    label: 'Baixos',
                    value: '${value.lowAlerts}',
                    icon: Icons.info_outline,
                  ),
                ],
              ),
            ],
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
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $value'));
  }
}

class _AlertFilters extends StatelessWidget {
  const _AlertFilters({
    required this.searchController,
    required this.severity,
    required this.area,
    required this.order,
    required this.areas,
    required this.onSearchChanged,
    required this.onSeverityChanged,
    required this.onAreaChanged,
    required this.onOrderChanged,
  });

  final TextEditingController searchController;
  final String severity;
  final String area;
  final String order;
  final List<String> areas;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSeverityChanged;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String?> onOrderChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final fullWidth = constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: compact ? fullWidth : 330,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar alerta',
                      hintText: 'Título, área ou ação recomendada',
                    ),
                  ),
                ),
                SizedBox(
                  width: compact ? fullWidth : 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: severity,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Criticidade'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todas')),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Crítica'),
                      ),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'medium', child: Text('Média')),
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                    ],
                    onChanged: onSeverityChanged,
                  ),
                ),
                SizedBox(
                  width: compact ? fullWidth : 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: area,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Área'),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todas'),
                      ),
                      ...areas.map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onAreaChanged,
                  ),
                ),
                SizedBox(
                  width: compact ? fullWidth : 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: order,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ordenar por'),
                    items: const [
                      DropdownMenuItem(
                        value: 'priority',
                        child: Text('Prioridade'),
                      ),
                      DropdownMenuItem(value: 'due', child: Text('Prazo')),
                      DropdownMenuItem(value: 'area', child: Text('Área')),
                    ],
                    onChanged: onOrderChanged,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OperationalAlertTile extends StatelessWidget {
  const _OperationalAlertTile({required this.alert, required this.onResolve});

  final AtlasOperationalAlertData alert;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SeverityPill(severity: alert.severity),
            Text(
              alert.area,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Prioridade ${alert.priorityScore}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            if (alert.dueAt != null)
              Text(
                _formatDue(alert.dueAt!),
                style: const TextStyle(color: Colors.black54),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          alert.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        if (alert.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            alert.description,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
        if (alert.recommendedAction.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Recomendação: ${alert.recommendedAction}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );

    final action = FilledButton.tonalIcon(
      onPressed: onResolve,
      icon: const Icon(Icons.task_alt_outlined),
      label: const Text('Resolver'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;

            final body = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: compact ? 74 : 92,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: content),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [body, const SizedBox(height: 12), action],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: body),
                const SizedBox(width: 12),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _severityLabel(severity),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _NoAlertsCard extends StatelessWidget {
  const _NoAlertsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF1B5E20),
              size: 32,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Nenhum alerta corresponde aos filtros atuais.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDue(DateTime dueAt) {
  final local = dueAt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return 'Prazo: $day/$month/${local.year} às $hour:$minute';
}

Color _severityColor(String severity) {
  return switch (severity.toLowerCase()) {
    'critical' => const Color(0xFFC62828),
    'high' => const Color(0xFFEF6C00),
    'medium' => const Color(0xFFF9A825),
    _ => const Color(0xFF2E7D32),
  };
}

String _severityLabel(String severity) {
  return switch (severity.toLowerCase()) {
    'critical' => 'Crítica',
    'high' => 'Alta',
    'medium' => 'Média',
    _ => 'Baixa',
  };
}
