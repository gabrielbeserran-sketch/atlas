import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/health_overview_screen.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/presentation/screens/farm_finance_list_screen.dart';
import 'package:projeto_atlas/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart';
import 'package:projeto_atlas/features/livestock_operations/data/services/atlas_livestock_operations_service.dart';
import 'package:projeto_atlas/features/livestock_operations/domain/models/atlas_livestock_module_snapshot.dart';
import 'package:projeto_atlas/features/nutrition/presentation/screens/nutrition_overview_screen.dart';

class AtlasLivestockModuleScreen extends StatefulWidget {
  const AtlasLivestockModuleScreen({required this.module, super.key});

  final AtlasLivestockModule module;

  @override
  State<AtlasLivestockModuleScreen> createState() =>
      _AtlasLivestockModuleScreenState();
}

class _AtlasLivestockModuleScreenState
    extends State<AtlasLivestockModuleScreen> {
  final AtlasLivestockOperationsService _service =
      AtlasLivestockOperationsService();
  AtlasLivestockModuleSnapshot? _snapshot;
  String? _farmId;
  String? _error;
  bool _loading = false;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final farmId = AtlasSessionScope.of(context).activeFarm?.id;
    if (farmId != null && farmId != _farmId && !_loading) {
      _farmId = farmId;
      _load();
    }
  }

  Future<void> _load() async {
    final farmId = _farmId;
    if (farmId == null || farmId.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _service.load(
        module: widget.module,
        farmId: farmId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _snapshot = snapshot);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  FarmData? _activeFarmData() {
    final remote = AtlasSessionScope.read(context).activeFarm;
    if (remote == null) {
      return null;
    }
    return FarmData(
      id: remote.id,
      name: remote.name,
      city: remote.city,
      state: remote.state,
      animals: remote.animals,
      area: remote.area.round(),
    );
  }

  Future<void> _openOperational({required bool create}) async {
    final farm = _activeFarmData();
    if (farm == null) {
      return;
    }

    final Widget target = switch (widget.module) {
      AtlasLivestockModule.reproduction => ReproductionOverviewScreen(
        farm: farm,
        autoOpenCreate: create,
      ),
      AtlasLivestockModule.health => HealthOverviewScreen(
        farm: farm,
        autoOpenCreate: create,
      ),
      AtlasLivestockModule.nutrition => NutritionOverviewScreen(
        farm: farm,
        autoOpenCreate: create,
      ),
      AtlasLivestockModule.inventory => FarmInventoryListScreen(
        farm: farm,
        autoOpenCreate: create,
      ),
      AtlasLivestockModule.finance => FarmFinanceListScreen(
        farm: farm,
        autoOpenCreate: create,
      ),
    };

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => target));

    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AtlasSessionScope.of(context);
    final farm = session.activeFarm;
    if (farm == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Selecione uma fazenda para acessar este módulo.'),
        ),
      );
    }

    final data = _snapshot;
    final filtered =
        data?.items.where((item) {
          final query = _search.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.status.toLowerCase().contains(query);
        }).toList() ??
        const <AtlasModuleItemData>[];

    final horizontalPadding = MediaQuery.sizeOf(context).width < 600
        ? 16.0
        : 24.0;
    final canWrite = session.allows(_writePermission(widget.module));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          _Header(
            title: _title(widget.module),
            subtitle: '${farm.name} • dados oficiais do backend',
            icon: _icon(widget.module),
            onRefresh: _loading ? null : _load,
          ),
          const SizedBox(height: 14),
          _ModuleActionBar(
            canWrite: canWrite,
            createLabel: _createLabel(widget.module),
            manageLabel: _manageLabel(widget.module),
            onCreate: _loading || !canWrite
                ? null
                : () => _openOperational(create: true),
            onManage: _loading
                ? null
                : () => _openOperational(create: false),
          ),
          const SizedBox(height: 20),
          if (_loading && data == null)
            const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            _ErrorCard(message: _error!, onRetry: _load),
            const SizedBox(height: 16),
          ],
          if (data != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: data.metrics
                  .map((metric) => _MetricCard(metric: metric))
                  .toList(growable: false),
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Buscar neste módulo',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _sectionTitle(widget.module),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text('${filtered.length} registros')),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const _EmptyCard()
            else
              ...filtered.map(
                (item) => _ItemCard(
                  item: item,
                  onTap: () => _openOperational(create: false),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(radius: 28, child: Icon(icon, size: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleActionBar extends StatelessWidget {
  const _ModuleActionBar({
    required this.canWrite,
    required this.createLabel,
    required this.manageLabel,
    required this.onCreate,
    required this.onManage,
  });

  final bool canWrite;
  final String createLabel;
  final String manageLabel;
  final VoidCallback? onCreate;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('atlas_module_action_area'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ações do módulo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    canWrite
                        ? 'Cadastre um novo registro ou abra a gestão completa.'
                        : 'Seu perfil possui acesso somente para leitura.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                Tooltip(
                  message: canWrite
                      ? createLabel
                      : 'Seu perfil possui somente acesso de leitura neste módulo.',
                  child: FilledButton.icon(
                    key: const ValueKey('atlas_module_create_button'),
                    onPressed: onCreate,
                    icon: Icon(canWrite ? Icons.add : Icons.lock_outline),
                    label: Text(createLabel),
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('atlas_module_manage_button'),
                  onPressed: onManage,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(manageLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final AtlasMetricData metric;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metric.label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              metric.value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (metric.subtitle.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                metric.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final AtlasModuleItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      leading: Icon(_statusIcon(item.status)),
      title: Text(item.title),
      subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.status.isNotEmpty) Chip(label: Text(item.status)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text('Nenhum registro encontrado para a fazenda ativa.'),
      ),
    ),
  );
}

String _title(AtlasLivestockModule module) {
  switch (module) {
    case AtlasLivestockModule.reproduction:
      return 'Reprodução';
    case AtlasLivestockModule.health:
      return 'Sanidade';
    case AtlasLivestockModule.nutrition:
      return 'Nutrição';
    case AtlasLivestockModule.inventory:
      return 'Estoque';
    case AtlasLivestockModule.finance:
      return 'Financeiro';
  }
}

String _sectionTitle(AtlasLivestockModule module) {
  switch (module) {
    case AtlasLivestockModule.reproduction:
      return 'Próximas ações';
    case AtlasLivestockModule.health:
      return 'Alertas e eventos';
    case AtlasLivestockModule.nutrition:
      return 'Planos nutricionais';
    case AtlasLivestockModule.inventory:
      return 'Alertas e produtos';
    case AtlasLivestockModule.finance:
      return 'Lançamentos recentes';
  }
}

String _writePermission(AtlasLivestockModule module) {
  switch (module) {
    case AtlasLivestockModule.reproduction:
      return 'reproduction.write';
    case AtlasLivestockModule.health:
      return 'health.write';
    case AtlasLivestockModule.nutrition:
      return 'nutrition.write';
    case AtlasLivestockModule.inventory:
      return 'inventory.write';
    case AtlasLivestockModule.finance:
      return 'finance.write';
  }
}

String _createLabel(AtlasLivestockModule module) {
  switch (module) {
    case AtlasLivestockModule.reproduction:
      return 'Novo evento reprodutivo';
    case AtlasLivestockModule.health:
      return 'Novo evento sanitário';
    case AtlasLivestockModule.nutrition:
      return 'Nova dieta';
    case AtlasLivestockModule.inventory:
      return 'Novo produto';
    case AtlasLivestockModule.finance:
      return 'Novo lançamento';
  }
}

String _manageLabel(AtlasLivestockModule module) {
  switch (module) {
    case AtlasLivestockModule.reproduction:
      return 'Gerenciar reprodução';
    case AtlasLivestockModule.health:
      return 'Gerenciar sanidade';
    case AtlasLivestockModule.nutrition:
      return 'Gerenciar dietas';
    case AtlasLivestockModule.inventory:
      return 'Gerenciar estoque';
    case AtlasLivestockModule.finance:
      return 'Gerenciar financeiro';
  }
}

IconData _icon(AtlasLivestockModule module) {
  switch (module) {
    case AtlasLivestockModule.reproduction:
      return Icons.favorite;
    case AtlasLivestockModule.health:
      return Icons.medical_services;
    case AtlasLivestockModule.nutrition:
      return Icons.restaurant;
    case AtlasLivestockModule.inventory:
      return Icons.inventory_2;
    case AtlasLivestockModule.finance:
      return Icons.account_balance_wallet;
  }
}

IconData _statusIcon(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('critical') || normalized.contains('expired')) {
    return Icons.error_outline;
  }
  if (normalized.contains('high') ||
      normalized.contains('warning') ||
      normalized.contains('pending')) {
    return Icons.warning_amber;
  }
  if (normalized.contains('paid') ||
      normalized.contains('active') ||
      normalized.contains('registered')) {
    return Icons.check_circle_outline;
  }
  return Icons.info_outline;
}
