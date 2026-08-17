import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/platform_hubs/data/services/atlas_platform_hub_service.dart';
import 'package:projeto_atlas/features/platform_hubs/domain/models/atlas_hub_snapshot.dart';
import 'package:projeto_atlas/features/platform_hubs/presentation/widgets/atlas_metric_card.dart';

class AtlasEnterpriseOperationsScreen extends StatefulWidget {
  const AtlasEnterpriseOperationsScreen({super.key});

  @override
  State<AtlasEnterpriseOperationsScreen> createState() =>
      _AtlasEnterpriseOperationsScreenState();
}

class _AtlasEnterpriseOperationsScreenState
    extends State<AtlasEnterpriseOperationsScreen> {
  final _service = AtlasPlatformHubService();
  AtlasHubSnapshot? _snapshot;
  Object? _error;
  bool _loading = false;

  static const actions = <_EnterpriseAction>[
    _EnterpriseAction(
      'Visita técnica',
      '/enterprise-operations/consulting/visits',
      Icons.assignment_ind_outlined,
    ),
    _EnterpriseAction(
      'Equipe',
      '/enterprise-operations/teams',
      Icons.groups_outlined,
    ),
    _EnterpriseAction(
      'Uso de ativo',
      '/enterprise-operations/assets/usage',
      Icons.agriculture_outlined,
    ),
    _EnterpriseAction(
      'Compra',
      '/enterprise-operations/purchases',
      Icons.shopping_cart_outlined,
    ),
    _EnterpriseAction(
      'Venda',
      '/enterprise-operations/sales',
      Icons.point_of_sale_outlined,
    ),
    _EnterpriseAction(
      'Lead CRM',
      '/enterprise-operations/crm/leads',
      Icons.handshake_outlined,
    ),
    _EnterpriseAction(
      'Suporte',
      '/enterprise-operations/support/tickets',
      Icons.support_agent_outlined,
    ),
    _EnterpriseAction(
      'Workflow',
      '/enterprise-operations/workflows/definitions',
      Icons.account_tree_outlined,
    ),
    _EnterpriseAction(
      'Documento',
      '/enterprise-operations/documents',
      Icons.description_outlined,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_snapshot == null && !_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.loadEnterprise();
      if (!mounted) return;
      setState(() => _snapshot = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AtlasSessionScope.of(context);
    final canManage = controller.allows('platform.manage');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Consultoria e gestão empresarial',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(controller.activeFarm?.name ?? 'Contexto empresarial'),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Card(
              child: ListTile(
                title: Text(_error.toString()),
                trailing: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          if (_snapshot != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _snapshot!.metrics.entries
                  .where((entry) => entry.value is num)
                  .map(
                    (entry) =>
                        AtlasMetricCard(label: entry.key, value: entry.value),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 20),
          Text('Ações rápidas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (action) => SizedBox(
                    width: 210,
                    child: OutlinedButton.icon(
                      onPressed: canManage ? () => _create(action) : null,
                      icon: Icon(action.icon),
                      label: Text(action.label),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Future<void> _create(_EnterpriseAction action) async {
    final input = TextEditingController();
    final farm = AtlasSessionScope.read(context).activeFarm;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(action.label),
        content: TextField(
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome ou título'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, input.text.trim()),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    input.dispose();
    if (value == null || value.isEmpty) {
      return;
    }
    try {
      await _service.create(action.path, {
        'name': value,
        'title': value,
        'farm_id': farm?.id,
        'data': <String, dynamic>{},
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${action.label} registrado.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _EnterpriseAction {
  const _EnterpriseAction(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}
