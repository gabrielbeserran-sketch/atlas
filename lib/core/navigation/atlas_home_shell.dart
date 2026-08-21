import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/branding/atlas_branding.dart';
import 'package:projeto_atlas/core/navigation/atlas_route_definition.dart';
import 'package:projeto_atlas/core/offline/presentation/atlas_offline_center_screen.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart';
import 'package:projeto_atlas/features/field_operations/presentation/screens/atlas_field_operations_screen.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_list_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart';
import 'package:projeto_atlas/features/herd/presentation/screens/herd_overview_screen.dart';
import 'package:projeto_atlas/features/livestock_operations/domain/models/atlas_livestock_module_snapshot.dart';
import 'package:projeto_atlas/features/livestock_operations/presentation/screens/atlas_livestock_module_screen.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/reports_screen.dart';
import 'package:projeto_atlas/features/saas_admin/presentation/screens/atlas_saas_admin_screen.dart';
import 'package:projeto_atlas/features/enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart';
import 'package:projeto_atlas/features/precision_hub/presentation/screens/atlas_precision_hub_screen.dart';
import 'package:projeto_atlas/features/data_intelligence/presentation/screens/atlas_data_intelligence_screen.dart';
import 'package:projeto_atlas/features/security_center/presentation/screens/atlas_security_center_screen.dart';
import 'package:projeto_atlas/features/flutter_quality/presentation/screens/atlas_flutter_quality_screen.dart';
import 'package:projeto_atlas/features/operational_readiness/presentation/screens/atlas_operational_readiness_screen.dart';
import 'package:projeto_atlas/features/release_management/presentation/screens/atlas_release_center_screen.dart';
import 'package:projeto_atlas/features/commercial_readiness/presentation/screens/atlas_commercial_readiness_screen.dart';
import 'package:projeto_atlas/features/pilot_program/presentation/screens/atlas_pilot_program_screen.dart';
import 'package:projeto_atlas/features/publication_center/presentation/screens/atlas_publication_center_screen.dart';
import 'package:projeto_atlas/features/atlas_scale/presentation/screens/atlas_scale_center_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasHomeShell extends StatefulWidget {
  const AtlasHomeShell({super.key});

  @override
  State<AtlasHomeShell> createState() => _AtlasHomeShellState();
}

class _AtlasHomeShellState extends State<AtlasHomeShell> {
  int selectedIndex = 0;

  static final List<AtlasRouteDefinition> routes = [
    AtlasRouteDefinition(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      builder: (_) => const DashboardScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Fazendas',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
      permission: 'farms.read',
      builder: (_) => const FarmListScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Rebanho',
      icon: AtlasLivestockIcons.cow,
      selectedIcon: AtlasLivestockIcons.cow,
      permission: 'animals.read',
      builder: (_) => const HerdOverviewScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Sanidade',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      permission: 'health.read',
      builder: (_) =>
          const AtlasLivestockModuleScreen(module: AtlasLivestockModule.health),
    ),
    AtlasRouteDefinition(
      label: 'Reprodução',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      permission: 'reproduction.read',
      builder: (_) => const AtlasLivestockModuleScreen(
        module: AtlasLivestockModule.reproduction,
      ),
    ),
    AtlasRouteDefinition(
      label: 'Nutrição',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      permission: 'nutrition.read',
      builder: (_) => const AtlasLivestockModuleScreen(
        module: AtlasLivestockModule.nutrition,
      ),
    ),
    AtlasRouteDefinition(
      label: 'Financeiro',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      permission: 'finance.read',
      builder: (_) => const AtlasLivestockModuleScreen(
        module: AtlasLivestockModule.finance,
      ),
    ),
    AtlasRouteDefinition(
      label: 'Estoque',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      permission: 'inventory.read',
      builder: (_) => const AtlasLivestockModuleScreen(
        module: AtlasLivestockModule.inventory,
      ),
    ),
    AtlasRouteDefinition(
      label: 'Agenda',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      permission: 'herd.read',
      builder: (_) => const SizedBox.shrink(),
    ),
    AtlasRouteDefinition(
      label: 'Offline',
      icon: Icons.cloud_off_outlined,
      selectedIcon: Icons.cloud_done,
      permission: 'sync.read',
      builder: (_) => const AtlasOfflineCenterScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Campo',
      icon: Icons.agriculture_outlined,
      selectedIcon: Icons.agriculture,
      permission: 'animals.create',
      builder: (_) => const AtlasFieldOperationsScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Inteligência',
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology,
      permission: 'ai.read',
      maturity: AtlasRouteMaturity.advancedValidation,
      builder: (_) => const AtlasIntelligenceCenterScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Precision Hub',
      icon: Icons.sensors_outlined,
      selectedIcon: Icons.sensors,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.advancedValidation,
      builder: (_) => const AtlasPrecisionHubScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Enterprise',
      icon: Icons.business_center_outlined,
      selectedIcon: Icons.business_center,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.advancedValidation,
      builder: (_) => const AtlasEnterpriseOperationsScreen(),
    ),
    AtlasRouteDefinition(
      label: 'SaaS',
      icon: Icons.cloud_outlined,
      selectedIcon: Icons.cloud,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.advancedValidation,
      builder: (_) => const AtlasSaasAdminScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Dados',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      permission: 'analytics.read',
      maturity: AtlasRouteMaturity.advancedValidation,
      builder: (_) => const AtlasDataIntelligenceScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Segurança',
      icon: Icons.security_outlined,
      selectedIcon: Icons.security,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasSecurityCenterScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Qualidade',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasFlutterQualityScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Prontidão',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasOperationalReadinessScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Releases',
      icon: Icons.rocket_launch_outlined,
      selectedIcon: Icons.rocket_launch,
      permission: 'platform.manage',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasReleaseCenterScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Comercial',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasCommercialReadinessScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Piloto',
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      permission: 'platform.read',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasPilotProgramScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Publicação',
      icon: Icons.publish_outlined,
      selectedIcon: Icons.publish,
      permission: 'platform.manage',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasPublicationCenterScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Escala',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree,
      permission: 'platform.manage',
      maturity: AtlasRouteMaturity.internalTool,
      builder: (_) => const AtlasScaleCenterScreen(),
    ),
    AtlasRouteDefinition(
      label: 'Relatórios',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      permission: 'reports.read',
      builder: (_) => const ReportsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AtlasSessionScope.of(context);
    final session = controller.session!;
    final visibleRoutes = routes
        .where(
          (route) =>
              route.permission == null || controller.allows(route.permission!),
        )
        .toList(growable: false);

    if (visibleRoutes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Nenhum módulo autorizado para este usuário.'),
        ),
      );
    }

    if (selectedIndex >= visibleRoutes.length) selectedIndex = 0;
    final selected = visibleRoutes[selectedIndex];
    final userName = session.userName.isEmpty
        ? session.email
        : session.userName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1000;
        if (desktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F7F4),
            body: Row(
              children: [
                _AtlasSidebar(
                  routes: visibleRoutes,
                  selectedIndex: selectedIndex,
                  userName: userName,
                  farmName: controller.activeFarm?.name,
                  onSelected: (index) => setState(() => selectedIndex = index),
                  onLogout: controller.logout,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _AtlasTopBar(
                        title: selected.label,
                        farmName: controller.activeFarm?.name,
                        userName: userName,
                        onSelectFarm: controller.farms.isEmpty
                            ? null
                            : () => _selectFarm(context),
                        onLogout: controller.logout,
                      ),
                      Expanded(
                        child: _selectedBody(
                          selected,
                          controller.activeFarm?.id,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7F4),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (controller.activeFarm != null)
                  Text(
                    controller.activeFarm!.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Selecionar fazenda',
                onPressed: controller.farms.isEmpty
                    ? null
                    : () => _selectFarm(context),
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
          ),
          drawer: Drawer(
            child: _AtlasSidebar(
              routes: visibleRoutes,
              selectedIndex: selectedIndex,
              userName: userName,
              farmName: controller.activeFarm?.name,
              compact: true,
              onSelected: (index) {
                Navigator.pop(context);
                setState(() => selectedIndex = index);
              },
              onLogout: () async {
                Navigator.pop(context);
                await controller.logout();
              },
            ),
          ),
          body: _selectedBody(selected, controller.activeFarm?.id),
        );
      },
    );
  }

  Widget _selectedBody(AtlasRouteDefinition selected, String? farmId) {
    final controller = AtlasSessionScope.read(context);
    final remoteFarm = controller.activeFarm;
    final farm = remoteFarm == null
        ? null
        : FarmData(
            id: remoteFarm.id,
            name: remoteFarm.name,
            city: remoteFarm.city,
            state: remoteFarm.state,
            animals: remoteFarm.animals,
            area: remoteFarm.area.round(),
          );

    Widget body;
    if (selected.label == 'Dashboard') {
      body = DashboardScreen(onNavigateModule: _navigateToLabel);
    } else if (selected.label == 'Fazendas') {
      body = const FarmListScreen(embedded: true);
    } else if (selected.label == 'Agenda') {
      body = farm == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Selecione uma fazenda para acessar este módulo.'),
              ),
            )
          : FarmAgendaListScreen(farm: farm);
    } else {
      // As rotas oficiais de Rebanho, Sanidade, Reprodução, Nutrição,
      // Financeiro e Estoque já estão definidas em [routes]. Usar o builder
      // canônico aqui evita uma segunda árvore de navegação concorrente.
      body = selected.builder(context);
    }

    if (!selected.maturity.isProductionCore) {
      body = _AtlasMaturityNotice(
        maturity: selected.maturity,
        child: body,
      );
    }

    return KeyedSubtree(
      key: ValueKey('${selected.label}:${farmId ?? 'none'}'),
      child: body,
    );
  }

  void _navigateToLabel(String label) {
    final controller = AtlasSessionScope.read(context);
    final visibleRoutes = routes
        .where(
          (route) =>
              route.permission == null || controller.allows(route.permission!),
        )
        .toList(growable: false);
    final index = visibleRoutes.indexWhere((route) => route.label == label);
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Módulo "$label" não está disponível para esta sessão.',
          ),
        ),
      );
      return;
    }
    setState(() => selectedIndex = index);
  }

  Future<void> _selectFarm(BuildContext context) async {
    final controller = AtlasSessionScope.read(context);
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Fazenda ativa'),
        children: [
          RadioGroup<String>(
            groupValue: controller.activeFarm?.id,
            onChanged: (value) => Navigator.pop(dialogContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controller.farms
                  .map(
                    (farm) => RadioListTile<String>(
                      value: farm.id,
                      title: Text(farm.name),
                      subtitle: farm.location.isEmpty
                          ? null
                          : Text(farm.location),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    final farm = controller.farms.firstWhere((item) => item.id == selected);
    await controller.selectFarm(farm);
  }
}


class _AtlasMaturityNotice extends StatelessWidget {
  const _AtlasMaturityNotice({required this.maturity, required this.child});

  final AtlasRouteMaturity maturity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final message = switch (maturity) {
      AtlasRouteMaturity.advancedValidation =>
        'Este módulo avançado está em validação e pode manter dados locais. Não é fonte oficial dos cadastros operacionais da V1.',
      AtlasRouteMaturity.internalTool =>
        'Ferramenta interna de operação, qualidade ou publicação. Não representa um módulo produtivo da fazenda.',
      AtlasRouteMaturity.v1Core => '',
    };
    return Column(
      children: [
        Material(
          color: const Color(0xFFFFF7E6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${maturity.label}: $message',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _AtlasSidebar extends StatelessWidget {
  const _AtlasSidebar({
    required this.routes,
    required this.selectedIndex,
    required this.userName,
    required this.onSelected,
    required this.onLogout,
    this.farmName,
    this.compact = false,
  });

  final List<AtlasRouteDefinition> routes;
  final int selectedIndex;
  final String userName;
  final String? farmName;
  final ValueChanged<int> onSelected;
  final Future<void> Function() onLogout;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? double.infinity : 248,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: BeserraLogo(height: 94),
            ),
            if (farmName != null && farmName!.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_work_outlined,
                      size: 18,
                      color: AtlasBranding.forest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        farmName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final selected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: const Color(0xFFEAF3E2),
                      selectedColor: AtlasBranding.forest,
                      textColor: const Color(0xFF263238),
                      iconColor: const Color(0xFF304B34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: SizedBox(
                        width: 24,
                        child: Center(
                          child: Icon(
                            selected ? route.selectedIcon : route.icon,
                            size: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        route.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onSelected(index),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AtlasBranding.forest,
                child: Text(
                  userName.trim().isEmpty
                      ? 'A'
                      : userName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Conta Atlas',
                style: TextStyle(fontSize: 11),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Sair'),
              onTap: () => onLogout(),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _AtlasTopBar extends StatelessWidget {
  const _AtlasTopBar({
    required this.title,
    required this.userName,
    required this.onLogout,
    this.farmName,
    this.onSelectFarm,
  });
  final String title;
  final String userName;
  final String? farmName;
  final VoidCallback? onSelectFarm;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E9E2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (farmName != null && farmName!.trim().isNotEmpty)
                  Text(
                    farmName!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Selecionar fazenda',
            onPressed: onSelectFarm,
            icon: const Icon(Icons.swap_horiz),
          ),
          PopupMenuButton<String>(
            tooltip: userName,
            onSelected: (value) async {
              if (value == 'logout') await onLogout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(userName)),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          ),
        ],
      ),
    );
  }
}
