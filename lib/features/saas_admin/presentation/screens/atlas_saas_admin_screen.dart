import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/platform_hubs/data/services/atlas_platform_hub_service.dart';
import 'package:projeto_atlas/features/platform_hubs/domain/models/atlas_hub_snapshot.dart';
import 'package:projeto_atlas/features/platform_hubs/presentation/widgets/atlas_metric_card.dart';

class AtlasSaasAdminScreen extends StatefulWidget {
  const AtlasSaasAdminScreen({super.key});

  @override
  State<AtlasSaasAdminScreen> createState() => _AtlasSaasAdminScreenState();
}

class _AtlasSaasAdminScreenState extends State<AtlasSaasAdminScreen>
    with SingleTickerProviderStateMixin {
  final _service = AtlasPlatformHubService();
  late final TabController _tabs;
  AtlasHubSnapshot? _portal;
  AtlasHubSnapshot? _admin;
  Map<String, dynamic> _flags = const {};
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_portal == null && !_loading) _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final controller = AtlasSessionScope.read(context);
    final canManage = controller.allows('platform.manage');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final portal = await _service.loadSaas(admin: false);
      final admin = canManage ? await _service.loadSaas(admin: true) : null;
      final flags = await _service.effectiveFlags();
      if (!mounted) return;
      setState(() {
        _portal = portal;
        _admin = admin;
        _flags = flags;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = AtlasSessionScope.of(context).allows('platform.manage');
    return Column(
      children: [
        Material(
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Portal'),
              Tab(text: 'Recursos'),
              Tab(text: 'Administração'),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _portalView(),
              _flagsView(),
              canManage
                  ? _adminView()
                  : const Center(
                      child: Text('Permissão platform.manage necessária.'),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _portalView() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Portal do cliente',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (_error != null) Text(_error.toString()),
        if (_portal != null)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _portal!.metrics.entries
                .map(
                  (entry) =>
                      AtlasMetricCard(label: entry.key, value: entry.value),
                )
                .toList(growable: false),
          ),
      ],
    ),
  );

  Widget _flagsView() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Feature flags efetivas',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (_flags.isEmpty)
          const ListTile(title: Text('Nenhuma flag efetiva.')),
        ..._flags.entries.map(
          (entry) => SwitchListTile(
            value: entry.value == true || entry.value?.toString() == 'true',
            onChanged: null,
            title: Text(entry.key),
          ),
        ),
      ],
    ),
  );

  Widget _adminView() {
    const actions = <(String, String)>[
      ('Plano', '/saas-growth/plans'),
      ('Assinatura', '/saas-growth/subscriptions'),
      ('Fatura', '/saas-growth/invoices'),
      ('Feature flag', '/saas-growth/feature-flags'),
      ('Template', '/saas-growth/communications/templates'),
      ('Onboarding', '/saas-growth/onboarding'),
      ('Importação', '/saas-growth/imports'),
      ('Exportação', '/saas-growth/exports'),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Administração SaaS',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (_admin != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _admin!.metrics.entries
                  .where((entry) => entry.value is num)
                  .map(
                    (entry) =>
                        AtlasMetricCard(label: entry.key, value: entry.value),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (action) => OutlinedButton(
                    onPressed: () => _create(action.$1, action.$2),
                    child: Text(action.$1),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Future<void> _create(String label, String path) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Código ou nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, input.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    input.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await _service.create(path, {
        'code': value.toLowerCase().replaceAll(' ', '-'),
        'name': value,
        'title': value,
        'data': <String, dynamic>{},
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label registrado.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
