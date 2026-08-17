import 'package:flutter/material.dart';

import '../../data/services/atlas_enterprise_24a_migration_service.dart';
import '../../data/services/atlas_enterprise_24a_repository.dart';
import '../../domain/models/atlas_enterprise_24a_data.dart';
import '../../domain/services/atlas_enterprise_session_service.dart';
import '../../domain/services/atlas_enterprise_audit_service.dart';
import '../../domain/services/atlas_enterprise_authorization_service.dart';
import 'atlas_enterprise_24b_screen.dart';

class AtlasEnterprise24AScreen extends StatefulWidget {
  const AtlasEnterprise24AScreen({super.key});

  @override
  State<AtlasEnterprise24AScreen> createState() =>
      _AtlasEnterprise24AScreenState();
}

class _AtlasEnterprise24AScreenState extends State<AtlasEnterprise24AScreen> {
  final repository = AtlasEnterprise24ARepository.instance;
  final session = AtlasEnterpriseSessionService.instance;
  final migration = const AtlasEnterprise24AMigrationService();
  final authorization = AtlasEnterpriseAuthorizationService.instance;
  final audit = AtlasEnterpriseAuditService.instance;

  AtlasEnterprise24ASnapshot? snapshot;
  AtlasEnterprise24AMigrationReport? migrationReport;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await session.ensureInitialized();
    final report = await migration.migrate();
    await session.reload();
    final value = await repository.load();

    if (!mounted) return;
    setState(() {
      migrationReport = report;
      snapshot = value;
      loading = false;
    });
  }

  Future<void> _reload() async {
    setState(() => loading = true);
    await session.reload();
    final value = await repository.load();
    if (!mounted) return;
    setState(() {
      snapshot = value;
      loading = false;
    });
  }

  Future<void> _createCompany() async {
    final name = TextEditingController();
    final document = TextEditingController();

    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova empresa'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nome da empresa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: document,
                decoration: const InputDecoration(
                  labelText: 'CPF/CNPJ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(name.text.trim().isNotEmpty);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (create == true) {
      await authorization.require('enterprise.companies.manage');
      final userId = session.currentUserId ?? 'user_admin';
      final company = await repository.createCompany(
        name: name.text,
        document: document.text,
        userId: userId,
        userName: 'Administrador',
        email: 'administrador@atlas.local',
      );
      await audit.record(
        action: 'create',
        module: 'enterprise',
        entityType: 'company',
        entityId: company.id,
        description: 'Empresa "${company.name}" criada.',
        companyId: company.id,
        userId: userId,
        after: company.toMap(),
      );
      await _reload();
    }

    name.dispose();
    document.dispose();
  }

  Future<void> _switchCompany(String companyId) async {
    try {
      await session.switchCompany(companyId);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _switchFarm(String? farmId) async {
    try {
      await session.switchFarm(farmId);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _addConsultant() async {
    final current = session.currentCompanyId;
    if (current == null) return;

    final name = TextEditingController();
    final email = TextEditingController();
    var lead = false;

    final farms = await repository.farmsForCompany(current);
    final selectedFarmIds = <String>{};

    if (!mounted) return;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Vincular consultor'),
          content: SizedBox(
            width: 620,
            height: 520,
            child: ListView(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: lead,
                  title: const Text('Consultor principal'),
                  onChanged: (value) {
                    setDialogState(() => lead = value == true);
                  },
                ),
                const Divider(),
                const Text(
                  'Fazendas autorizadas',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Nenhuma selecionada = todas as fazendas da empresa.',
                ),
                ...farms.map(
                  (farm) => CheckboxListTile(
                    value: selectedFarmIds.contains(farm.id),
                    title: Text(farm.name),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedFarmIds.add(farm.id);
                        } else {
                          selectedFarmIds.remove(farm.id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  name.text.trim().isNotEmpty && email.text.trim().isNotEmpty,
                );
              },
              child: const Text('Vincular'),
            ),
          ],
        ),
      ),
    );

    if (save == true) {
      await authorization.require('enterprise.users.invite');
      final normalizedEmail = email.text.trim().toLowerCase();
      final userId =
          'consultant_${normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

      await repository.ensureMembership(
        companyId: current,
        userId: userId,
        userName: name.text.trim(),
        email: normalizedEmail,
        role: AtlasEnterpriseMembershipRole.consultant,
      );

      final link = await repository.saveConsultantLink(
        companyId: current,
        consultantUserId: userId,
        consultantName: name.text.trim(),
        farmIds: selectedFarmIds.toList(),
        isLeadConsultant: lead,
        actorUserId: session.currentUserId ?? 'user_admin',
      );

      await audit.record(
        action: 'create',
        module: 'enterprise',
        entityType: 'consultant_link',
        entityId: link.id,
        description: 'Consultor "${link.consultantName}" vinculado.',
        companyId: current,
        userId: session.currentUserId ?? 'user_admin',
        after: link.toMap(),
      );

      await _reload();
    }

    name.dispose();
    email.dispose();
  }

  Future<void> _runIsolationTest() async {
    final value = snapshot;
    if (value == null) return;

    final userId = session.currentUserId;
    final companyId = session.currentCompanyId;
    if (userId == null || companyId == null) return;

    final companies = await repository.companiesForUser(userId);
    final allowedFarms = await repository.farmsAllowedForUser(
      companyId: companyId,
      userId: userId,
    );

    final foreignFarms = value.farms.where(
      (farm) => farm.scope.companyId != companyId,
    );

    var leakFound = false;
    for (final farm in foreignFarms) {
      if (allowedFarms.any((item) => item.id == farm.id)) {
        leakFound = true;
      }
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          leakFound ? 'Falha no teste de isolamento' : 'Isolamento validado',
        ),
        content: Text(
          leakFound
              ? 'Uma fazenda de outra empresa apareceu na carteira autorizada.'
              : 'Usuário: $userId\n'
                    'Empresas autorizadas: ${companies.length}\n'
                    'Fazendas visíveis na empresa atual: ${allowedFarms.length}\n\n'
                    'Nenhuma fazenda de outra empresa foi exposta pelo repositório 24A.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _open24B() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AtlasEnterprise24BScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = snapshot;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enterprise 24A'),
          actions: [
            IconButton(
              tooltip: 'Permissões e auditoria 24B',
              onPressed: _open24B,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
            IconButton(
              tooltip: 'Testar isolamento',
              onPressed: value == null ? null : _runIsolationTest,
              icon: const Icon(Icons.security_outlined),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Empresas'),
              Tab(text: 'Carteira'),
              Tab(text: 'Consultores'),
              Tab(text: 'Migração e contexto'),
            ],
          ),
        ),
        body: loading || value == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _CompaniesTab(
                    snapshot: value,
                    currentCompanyId: session.currentCompanyId,
                    onCreate: _createCompany,
                    onSwitch: _switchCompany,
                  ),
                  _PortfolioTab(
                    farms: value.farms
                        .where(
                          (item) =>
                              item.scope.companyId == session.currentCompanyId,
                        )
                        .toList(),
                    currentFarmId: session.currentFarmId,
                    onSwitchFarm: _switchFarm,
                  ),
                  _ConsultantsTab(
                    snapshot: value,
                    companyId: session.currentCompanyId,
                    onAdd: _addConsultant,
                  ),
                  _MigrationTab(
                    snapshot: value,
                    report: migrationReport,
                    session: session.session,
                    onTest: _runIsolationTest,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CompaniesTab extends StatelessWidget {
  const _CompaniesTab({
    required this.snapshot,
    required this.currentCompanyId,
    required this.onCreate,
    required this.onSwitch,
  });

  final AtlasEnterprise24ASnapshot snapshot;
  final String? currentCompanyId;
  final VoidCallback onCreate;
  final ValueChanged<String> onSwitch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_business),
              label: const Text('Nova empresa'),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: snapshot.companies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = snapshot.companies[index];
              final selected = item.id == currentCompanyId;
              return Card(
                child: ListTile(
                  leading: Icon(
                    selected ? Icons.business : Icons.business_outlined,
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.document.isEmpty ? 'Documento não informado' : item.document} • '
                    '${item.subscriptionPlan}',
                  ),
                  trailing: selected
                      ? const Chip(label: Text('Ativa'))
                      : FilledButton.tonal(
                          onPressed: () => onSwitch(item.id),
                          child: const Text('Selecionar'),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab({
    required this.farms,
    required this.currentFarmId,
    required this.onSwitchFarm,
  });

  final List<AtlasEnterpriseFarm> farms;
  final String? currentFarmId;
  final ValueChanged<String?> onSwitchFarm;

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) {
      return const Center(
        child: Text('Nenhuma fazenda migrada para a empresa atual.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: farms.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            child: ListTile(
              title: const Text('Todas as fazendas autorizadas'),
              trailing: currentFarmId == null
                  ? const Chip(label: Text('Contexto atual'))
                  : TextButton(
                      onPressed: () => onSwitchFarm(null),
                      child: const Text('Usar'),
                    ),
            ),
          );
        }

        final farm = farms[index - 1];
        final selected = farm.id == currentFarmId;
        return Card(
          child: ListTile(
            title: Text(farm.name),
            subtitle: Text('${farm.city}/${farm.state}'),
            trailing: selected
                ? const Chip(label: Text('Selecionada'))
                : FilledButton.tonal(
                    onPressed: () => onSwitchFarm(farm.id),
                    child: const Text('Selecionar'),
                  ),
          ),
        );
      },
    );
  }
}

class _ConsultantsTab extends StatelessWidget {
  const _ConsultantsTab({
    required this.snapshot,
    required this.companyId,
    required this.onAdd,
  });

  final AtlasEnterprise24ASnapshot snapshot;
  final String? companyId;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final links = snapshot.consultantLinks
        .where((item) => item.companyId == companyId && item.active)
        .toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Vincular consultor'),
            ),
          ),
        ),
        Expanded(
          child: links.isEmpty
              ? const Center(
                  child: Text('Nenhum consultor vinculado à empresa atual.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = links[index];
                    final farms = item.farmIds.isEmpty
                        ? 'Todas as fazendas'
                        : '${item.farmIds.length} fazenda(s)';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: Text(item.consultantName),
                        subtitle: Text(farms),
                        trailing: item.isLeadConsultant
                            ? const Chip(label: Text('Principal'))
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MigrationTab extends StatelessWidget {
  const _MigrationTab({
    required this.snapshot,
    required this.report,
    required this.session,
    required this.onTest,
  });

  final AtlasEnterprise24ASnapshot snapshot;
  final AtlasEnterprise24AMigrationReport? report;
  final AtlasEnterpriseSession? session;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('Migração 24A'),
            subtitle: Text('Versão aplicada: ${snapshot.migrationVersion}'),
            trailing: const Icon(Icons.check_circle_outline),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Usuário da sessão'),
            subtitle: Text(session?.userId ?? 'Não definido'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('companyId / tenantId ativo'),
            subtitle: Text(session?.companyId ?? 'Não definido'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.landscape_outlined),
            title: const Text('farmId ativo'),
            subtitle: Text(session?.farmId ?? 'Todas as autorizadas'),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onTest,
          icon: const Icon(Icons.security),
          label: const Text('Executar teste de isolamento multiempresa'),
        ),
        if (report != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Relatório da migração',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...report!.messages.map(
            (message) => Card(
              child: ListTile(
                leading: const Icon(Icons.check),
                title: Text(message),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
