import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasMainLayout extends StatelessWidget {
  const AtlasMainLayout({
    required this.selectedIndex,
    required this.title,
    required this.body,
    required this.onDestinationSelected,
    this.userName = 'Gabriel',
    this.farmName,
    this.actions = const [],
    this.floatingActionButton,
    super.key,
  });

  final int selectedIndex;
  final String title;
  final Widget body;
  final ValueChanged<int> onDestinationSelected;

  final String userName;
  final String? farmName;

  final List<Widget> actions;
  final Widget? floatingActionButton;

  static const double desktopBreakpoint = 1000;

  static const List<AtlasNavigationItem> navigationItems = [
    AtlasNavigationItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AtlasNavigationItem(
      label: 'Fazendas',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
    ),
    AtlasNavigationItem(
      label: 'Rebanho',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    AtlasNavigationItem(
      label: 'Animais',
      icon: AtlasLivestockIcons.cow,
      selectedIcon: AtlasLivestockIcons.cow,
    ),
    AtlasNavigationItem(
      label: 'Piquetes',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
    AtlasNavigationItem(
      label: 'Sanidade',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
    ),
    AtlasNavigationItem(
      label: 'Reprodução',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
    ),
    AtlasNavigationItem(
      label: 'Pesagens',
      icon: Icons.monitor_weight_outlined,
      selectedIcon: Icons.monitor_weight,
    ),
    AtlasNavigationItem(
      label: 'Documentos',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
    ),
    AtlasNavigationItem(
      label: 'Financeiro',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    AtlasNavigationItem(
      label: 'Estoque',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    AtlasNavigationItem(
      label: 'Agenda',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    AtlasNavigationItem(
      label: 'Relatórios',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    AtlasNavigationItem(
      label: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useDesktopLayout = constraints.maxWidth >= desktopBreakpoint;

        if (useDesktopLayout) {
          return _buildDesktopLayout(context);
        }

        return _buildCompactLayout(context);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          AtlasDesktopSidebar(
            selectedIndex: selectedIndex,
            userName: userName,
            farmName: farmName,
            onDestinationSelected: onDestinationSelected,
          ),
          Expanded(
            child: Column(
              children: [
                AtlasTopBar(
                  title: title,
                  userName: userName,
                  farmName: farmName,
                  actions: actions,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      drawer: AtlasMobileDrawer(
        selectedIndex: selectedIndex,
        userName: userName,
        farmName: farmName,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          onDestinationSelected(index);
        },
      ),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18351C),
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            if (farmName != null && farmName!.trim().isNotEmpty)
              Text(
                farmName!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          ...actions,
          AtlasUserAvatar(userName: userName),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class AtlasDesktopSidebar extends StatelessWidget {
  const AtlasDesktopSidebar({
    required this.selectedIndex,
    required this.userName,
    required this.onDestinationSelected,
    this.farmName,
    super.key,
  });

  final int selectedIndex;
  final String userName;
  final String? farmName;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Color(0xFF153E1B),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const AtlasBrandHeader(),
            if (farmName != null && farmName!.trim().isNotEmpty)
              AtlasSelectedFarm(farmName: farmName!),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                children: [
                  const AtlasMenuSectionTitle(title: 'GESTÃO'),
                  ...List.generate(5, (index) {
                    return AtlasNavigationTile(
                      item: AtlasMainLayout.navigationItems[index],
                      selected: selectedIndex == index,
                      onTap: () {
                        onDestinationSelected(index);
                      },
                    );
                  }),
                  const AtlasMenuSectionTitle(title: 'MANEJOS'),
                  ...List.generate(4, (position) {
                    final index = position + 5;

                    return AtlasNavigationTile(
                      item: AtlasMainLayout.navigationItems[index],
                      selected: selectedIndex == index,
                      onTap: () {
                        onDestinationSelected(index);
                      },
                    );
                  }),
                  const AtlasMenuSectionTitle(title: 'ADMINISTRAÇÃO'),
                  ...List.generate(4, (position) {
                    final index = position + 9;

                    return AtlasNavigationTile(
                      item: AtlasMainLayout.navigationItems[index],
                      selected: selectedIndex == index,
                      onTap: () {
                        onDestinationSelected(index);
                      },
                    );
                  }),
                  const AtlasMenuSectionTitle(title: 'SISTEMA'),
                  AtlasNavigationTile(
                    item: AtlasMainLayout.navigationItems[13],
                    selected: selectedIndex == 13,
                    onTap: () {
                      onDestinationSelected(13);
                    },
                  ),
                ],
              ),
            ),
            AtlasSidebarUser(userName: userName),
          ],
        ),
      ),
    );
  }
}

class AtlasMobileDrawer extends StatelessWidget {
  const AtlasMobileDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.onDestinationSelected,
    this.farmName,
    super.key,
  });

  final int selectedIndex;
  final String userName;
  final String? farmName;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      backgroundColor: const Color(0xFF153E1B),
      child: SafeArea(
        child: Column(
          children: [
            const AtlasBrandHeader(),
            if (farmName != null && farmName!.trim().isNotEmpty)
              AtlasSelectedFarm(farmName: farmName!),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                itemCount: AtlasMainLayout.navigationItems.length,
                itemBuilder: (context, index) {
                  return AtlasNavigationTile(
                    item: AtlasMainLayout.navigationItems[index],
                    selected: selectedIndex == index,
                    onTap: () {
                      onDestinationSelected(index);
                    },
                  );
                },
              ),
            ),
            AtlasSidebarUser(userName: userName),
          ],
        ),
      ),
    );
  }
}

class AtlasTopBar extends StatelessWidget {
  const AtlasTopBar({
    required this.title,
    required this.userName,
    required this.actions,
    this.farmName,
    super.key,
  });

  final String title;
  final String userName;
  final String? farmName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3E9E4))),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF18351C),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (farmName != null && farmName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    farmName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: 10),
          Container(width: 1, height: 32, color: const Color(0xFFE3E9E4)),
          const SizedBox(width: 16),
          AtlasUserAvatar(userName: userName),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: Color(0xFF18351C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Administrador',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AtlasBrandHeader extends StatelessWidget {
  const AtlasBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2C5932))),
      ),
      child: const Row(
        children: [
          AtlasBrandSymbol(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATLAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gestão Pecuária',
                  style: TextStyle(color: Color(0xFFB9D5BC), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasBrandSymbol extends StatelessWidget {
  const AtlasBrandSymbol({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF2C14E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        AtlasLivestockIcons.cow,
        color: Color(0xFF153E1B),
        size: 28,
      ),
    );
  }
}

class AtlasSelectedFarm extends StatelessWidget {
  const AtlasSelectedFarm({required this.farmName, super.key});

  final String farmName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.home_work_outlined,
            color: Color(0xFFF2C14E),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Propriedade selecionada',
                  style: TextStyle(color: Color(0xFFB9D5BC), fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  farmName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasMenuSectionTitle extends StatelessWidget {
  const AtlasMenuSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8EB493),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class AtlasNavigationTile extends StatelessWidget {
  const AtlasNavigationTile({
    required this.item,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AtlasNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0xFFF2C14E) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected
                      ? const Color(0xFF153E1B)
                      : const Color(0xFFC6D8C8),
                  size: 22,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF153E1B)
                          : const Color(0xFFE3EEE4),
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF153E1B),
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AtlasSidebarUser extends StatelessWidget {
  const AtlasSidebarUser({required this.userName, super.key});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2C5932))),
      ),
      child: Row(
        children: [
          AtlasUserAvatar(userName: userName, darkBackground: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Administrador',
                  style: TextStyle(color: Color(0xFFB9D5BC), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'A função de sair será conectada posteriormente.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.logout_outlined,
              color: Color(0xFFB9D5BC),
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasUserAvatar extends StatelessWidget {
  const AtlasUserAvatar({
    required this.userName,
    this.darkBackground = false,
    super.key,
  });

  final String userName;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isEmpty
        ? 'U'
        : userName.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 19,
      backgroundColor: darkBackground
          ? const Color(0xFFF2C14E)
          : const Color(0xFFE0EFE2),
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF153E1B),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AtlasNavigationItem {
  const AtlasNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
