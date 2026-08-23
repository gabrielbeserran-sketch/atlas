import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/navigation/atlas_product_surface_policy.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_workspace_guide.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_decision_panel.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_action_bar.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart';

class InventoryOverviewScreen extends StatefulWidget {
  const InventoryOverviewScreen({
    this.farm,
    this.embedded = false,
    super.key,
  });

  final FarmData? farm;
  final bool embedded;

  @override
  State<InventoryOverviewScreen> createState() =>
      _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState extends State<InventoryOverviewScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final FarmInventoryStorageService inventoryStorage =
      FarmInventoryStorageService();

  List<InventoryFarmContext> farmContexts = [];
  bool isLoading = true;
  String search = '';
  String selectedFilter = 'Todos';

  int get totalProducts =>
      farmContexts.fold(0, (total, context) => total + context.items.length);

  int get lowStockCount =>
      farmContexts.fold(0, (total, context) => total + context.lowStockCount);

  int get expiredCount =>
      farmContexts.fold(0, (total, context) => total + context.expiredCount);

  int get nearExpirationCount => farmContexts.fold(
    0,
    (total, context) => total + context.nearExpirationCount,
  );

  double get totalValue =>
      farmContexts.fold(0, (total, context) => total + context.totalValue);

  int get outOfStockCount => farmContexts.fold(
    0,
    (total, context) =>
        total + context.items.where((item) => item.isOutOfStock).length,
  );

  AtlasModuleAttentionLevel get moduleLevel {
    if (expiredCount > 0 || outOfStockCount > 0) {
      return AtlasModuleAttentionLevel.critical;
    }
    if (lowStockCount > 0 || nearExpirationCount > 0) {
      return AtlasModuleAttentionLevel.attention;
    }
    return AtlasModuleAttentionLevel.normal;
  }

  String get moduleStatusTitle {
    if (moduleLevel == AtlasModuleAttentionLevel.critical) {
      return 'Estoque exige ação';
    }
    if (moduleLevel == AtlasModuleAttentionLevel.attention) {
      return 'Estoque requer reposição ou revisão';
    }
    return 'Estoque sob controle';
  }

  List<AtlasModuleDecisionItem> get decisionItems {
    final items = <AtlasModuleDecisionItem>[];
    if (outOfStockCount > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$outOfStockCount produto(s) sem estoque',
          description:
              'Revise reposição antes que faltem insumos para os manejos.',
          icon: Icons.remove_shopping_cart_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (expiredCount > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$expiredCount produto(s) vencido(s)',
          description:
              'Separe os itens vencidos e revise descarte e reposição.',
          icon: Icons.event_busy_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (lowStockCount > outOfStockCount) {
      items.add(
        AtlasModuleDecisionItem(
          title: '${lowStockCount - outOfStockCount} item(ns) abaixo do mínimo',
          description:
              'Considere o estoque mínimo e a velocidade de consumo.',
          icon: Icons.warning_amber_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    if (nearExpirationCount > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$nearExpirationCount produto(s) próximos do vencimento',
          description:
              'Priorize uso adequado ou remanejamento antes da perda.',
          icon: Icons.schedule_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    return items;
  }

  InventoryFarmContext? get activeContext =>
      farmContexts.isEmpty ? null : farmContexts.first;

  List<InventoryFarmContext> get filteredContexts {
    final query = search.trim().toLowerCase();

    return farmContexts.where((context) {
      final matchesSearch =
          query.isEmpty ||
          context.farm.name.toLowerCase().contains(query) ||
          context.farm.city.toLowerCase().contains(query) ||
          context.farm.state.toLowerCase().contains(query) ||
          context.items.any(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query) ||
                item.supplier.toLowerCase().contains(query),
          );

      if (!matchesSearch) {
        return false;
      }

      if (selectedFilter == 'Estoque baixo') {
        return context.lowStockCount > 0;
      }

      if (selectedFilter == 'Vencidos') {
        return context.expiredCount > 0;
      }

      if (selectedFilter == 'Vencimento próximo') {
        return context.nearExpirationCount > 0;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final farms = widget.farm == null
        ? await farmStorage.loadFarms()
        : <FarmData>[widget.farm!];
    final contexts = <InventoryFarmContext>[];

    for (final farm in farms) {
      final items = await inventoryStorage.loadItems(
        farm.name,
        farmId: farm.id ?? '',
      );
      contexts.add(InventoryFarmContext(farm: farm, items: items));
    }

    contexts.sort(
      (first, second) => first.farm.name.toLowerCase().compareTo(
        second.farm.name.toLowerCase(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      farmContexts = contexts;
      isLoading = false;
    });
  }

  Future<void> openFarmInventory(InventoryFarmContext contextData) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return FarmInventoryListScreen(farm: contextData.farm);
        },
      ),
    );

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Estoque'),
              actions: [
                IconButton(
                  tooltip: 'Atualizar dados',
                  onPressed: isLoading ? null : loadData,
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _InventoryHeader(),
                            const SizedBox(height: 12),
                            AtlasOperationalActionBar(
                              primaryLabel: 'Gerenciar estoque',
                              primaryIcon: Icons.inventory_2_outlined,
                              onPrimary: activeContext == null
                                  ? null
                                  : () => openFarmInventory(activeContext!),
                              onRefresh: loadData,
                              busy: isLoading,
                            ),
                            const SizedBox(height: 16),
                            AtlasModuleDecisionPanel(
                              statusTitle: moduleStatusTitle,
                              statusDescription:
                                  '$totalProducts produtos • '
                                  '${_formatCurrency(totalValue)} em estoque',
                              items: decisionItems,
                              level: moduleLevel,
                            ),
                            const SizedBox(height: 16),
                            AtlasModuleWorkspaceGuide(
                              moduleLabel: 'Estoque',
                              workflows:
                                  AtlasProductSurfacePolicy.moduleWorkflows['Estoque'] ??
                                      const <String>[],
                              specializedFamilies:
                                  AtlasProductSurfacePolicy
                                          .specializedCapabilityCountByOwner['Estoque'] ??
                                      0,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _IndicatorCard(
                                  title: 'Produtos',
                                  value: totalProducts.toString(),
                                  subtitle: 'Itens cadastrados',
                                  icon: Icons.inventory_2_outlined,
                                  color: const Color(0xFF1B5E20),
                                ),
                                _IndicatorCard(
                                  title: 'Estoque baixo',
                                  value: lowStockCount.toString(),
                                  subtitle: 'Itens no limite mínimo',
                                  icon: Icons.warning_amber_outlined,
                                  color: lowStockCount > 0
                                      ? const Color(0xFFEF6C00)
                                      : const Color(0xFF1B5E20),
                                ),
                                _IndicatorCard(
                                  title: 'Vencidos',
                                  value: expiredCount.toString(),
                                  subtitle: 'Produtos fora da validade',
                                  icon: Icons.event_busy_outlined,
                                  color: expiredCount > 0
                                      ? Colors.red.shade700
                                      : const Color(0xFF1B5E20),
                                ),
                                _IndicatorCard(
                                  title: 'Próximos do vencimento',
                                  value: nearExpirationCount.toString(),
                                  subtitle: 'Validade em até 30 dias',
                                  icon: Icons.schedule_outlined,
                                  color: nearExpirationCount > 0
                                      ? const Color(0xFFEF6C00)
                                      : const Color(0xFF1B5E20),
                                ),
                                _IndicatorCard(
                                  title: 'Valor em estoque',
                                  value: _formatCurrency(totalValue),
                                  subtitle: 'Patrimônio armazenado',
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: const Color(0xFF1565C0),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  search = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar por fazenda, produto, categoria ou fornecedor',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final filter in const [
                                  'Todos',
                                  'Estoque baixo',
                                  'Vencidos',
                                  'Vencimento próximo',
                                ])
                                  ChoiceChip(
                                    label: Text(filter),
                                    selected: selectedFilter == filter,
                                    onSelected: (_) {
                                      setState(() {
                                        selectedFilter = filter;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'Estoque por fazenda',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Selecione uma propriedade para cadastrar produtos e registrar entradas ou saídas.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            if (farmContexts.isEmpty)
                              const _EmptyInventory()
                            else if (filteredContexts.isEmpty)
                              const _NoSearchResults()
                            else
                              ...filteredContexts.map(
                                (contextData) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _FarmInventoryCard(
                                    contextData: contextData,
                                    onOpen: () =>
                                        openFarmInventory(contextData),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class InventoryFarmContext {
  const InventoryFarmContext({required this.farm, required this.items});

  final FarmData farm;
  final List<FarmInventoryData> items;

  int get lowStockCount => items.where((item) => item.hasLowStock).length;

  int get expiredCount => items.where(_isExpired).length;

  int get nearExpirationCount => items.where(_isNearExpiration).length;

  double get totalValue =>
      items.fold(0, (total, item) => total + item.totalValue);

  static bool _isExpired(FarmInventoryData item) {
    final date = _parseDate(item.expirationDate);
    if (date == null) {
      return false;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    return date.isBefore(today);
  }

  static bool _isNearExpiration(FarmInventoryData item) {
    final date = _parseDate(item.expirationDate);
    if (date == null) {
      return false;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final limit = today.add(const Duration(days: 30));

    return !date.isBefore(today) && !date.isAfter(limit);
  }

  static DateTime? _parseDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF1B5E20),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central de Estoque',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Acompanhe quantidades, valores e validade dos produtos de todas as propriedades.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E8E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmInventoryCard extends StatelessWidget {
  const _FarmInventoryCard({required this.contextData, required this.onOpen});

  final InventoryFarmContext contextData;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hasAlerts =
        contextData.lowStockCount > 0 ||
        contextData.expiredCount > 0 ||
        contextData.nearExpirationCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasAlerts
                  ? const Color(0xFFFFCC80)
                  : const Color(0xFFE4E8E5),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: hasAlerts
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                child: Icon(
                  hasAlerts
                      ? Icons.warning_amber_outlined
                      : Icons.inventory_2_outlined,
                  color: hasAlerts
                      ? const Color(0xFFEF6C00)
                      : const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextData.farm.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${contextData.farm.city} - ${contextData.farm.state}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text('${contextData.items.length} produto(s)'),
                        Text(_formatCurrency(contextData.totalValue)),
                        if (contextData.lowStockCount > 0)
                          Text(
                            '${contextData.lowStockCount} com estoque baixo',
                            style: const TextStyle(color: Color(0xFFEF6C00)),
                          ),
                        if (contextData.expiredCount > 0)
                          Text(
                            '${contextData.expiredCount} vencido(s)',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.landscape_outlined,
      title: 'Nenhuma fazenda cadastrada',
      message: 'Cadastre uma fazenda para começar a controlar o estoque.',
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.search_off_outlined,
      title: 'Nenhum resultado encontrado',
      message: 'Altere a pesquisa ou selecione outro filtro.',
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8E5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.black38),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final positionFromEnd = digits.length - index;
    buffer.write(digits[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},${parts[1]}';
}
