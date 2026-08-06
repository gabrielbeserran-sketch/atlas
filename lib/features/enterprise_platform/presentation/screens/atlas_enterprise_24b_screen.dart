import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/atlas_enterprise_24a_repository.dart';
import '../../data/services/atlas_enterprise_permission_repository.dart';
import '../../domain/models/atlas_enterprise_24a_data.dart';
import '../../domain/models/atlas_enterprise_audit_data.dart';
import '../../domain/models/atlas_enterprise_permission_data.dart';
import '../../domain/services/atlas_enterprise_audit_service.dart';
import '../../domain/services/atlas_enterprise_authorization_service.dart';
import '../../domain/services/atlas_enterprise_session_service.dart';
import 'atlas_enterprise_24c_screen.dart';

class AtlasEnterprise24BScreen extends StatefulWidget {
  const AtlasEnterprise24BScreen({super.key});

  @override
  State<AtlasEnterprise24BScreen> createState() =>
      _AtlasEnterprise24BScreenState();
}

class _AtlasEnterprise24BScreenState
    extends State<AtlasEnterprise24BScreen> {
  final enterprise = AtlasEnterprise24ARepository.instance;
  final permissions =
      AtlasEnterprisePermissionRepository.instance;
  final authorization =
      AtlasEnterpriseAuthorizationService.instance;
  final audit = AtlasEnterpriseAuditService.instance;
  final session = AtlasEnterpriseSessionService.instance;

  AtlasEnterprise24ASnapshot? snapshot;
  List<AtlasCustomEnterpriseRole> customRoles = [];
  List<AtlasUserPermissionPolicy> policies = [];
  List<AtlasEnterpriseAuditRecord> auditRecords = [];
  AtlasAuditIntegrityResult? integrity;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await session.ensureInitialized();
    final value = await enterprise.load();
    final companyId = session.currentCompanyId;
    final roles =
        await permissions.loadCustomRoles(companyId: companyId);
    final loadedPolicies =
        await permissions.loadPolicies(companyId: companyId);
    final records = await audit.search(companyId: companyId);
    final verified = await audit.verifyIntegrity();

    if (!mounted) return;
    setState(() {
      snapshot = value;
      customRoles = roles;
      policies = loadedPolicies;
      auditRecords = records;
      integrity = verified;
      loading = false;
    });
  }

  List<AtlasEnterpriseMembership> get companyMemberships {
    final companyId = session.currentCompanyId;
    return snapshot?.memberships
            .where(
              (item) =>
                  item.companyId == companyId && item.active,
            )
            .toList() ??
        <AtlasEnterpriseMembership>[];
  }

  Future<void> _createCustomRole() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final selected = <String>{};

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo papel personalizado'),
          content: SizedBox(
            width: 720,
            height: 650,
            child: ListView(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                ...AtlasEnterprisePermissions.catalog.map(
                  (permission) => CheckboxListTile(
                    value: selected.contains(permission.key),
                    title: Text(permission.label),
                    subtitle: Text(permission.key),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selected.add(permission.key);
                        } else {
                          selected.remove(permission.key);
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
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                name.text.trim().isNotEmpty,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await authorization.require(
        'enterprise.permissions.manage',
      );
      final now = DateTime.now();
      final companyId = session.currentCompanyId!;
      final role = AtlasCustomEnterpriseRole(
        id: 'custom_role_${now.microsecondsSinceEpoch}',
        companyId: companyId,
        name: name.text.trim(),
        description: description.text.trim(),
        permissionKeys: selected,
        active: true,
        createdBy: session.currentUserId ?? 'system',
        createdAt: now,
        updatedAt: now,
      );
      await permissions.saveCustomRole(role);
      await audit.record(
        action: 'create',
        module: 'permissions',
        entityType: 'custom_role',
        entityId: role.id,
        description:
            'Papel personalizado "${role.name}" criado.',
        after: role.toMap(),
      );
      await _load();
    }

    name.dispose();
    description.dispose();
  }

  Future<void> _editUserPolicy(
    AtlasEnterpriseMembership membership,
  ) async {
    await authorization.require(
      'enterprise.permissions.manage',
    );

    final previous = await permissions.findPolicy(
      companyId: membership.companyId,
      userId: membership.userId,
    );

    String? customRoleId = previous?.customRoleId;
    final effects =
        <String, AtlasPermissionEffect>{...?previous?.effects};

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Permissões — ${membership.userName}'),
          content: SizedBox(
            width: 760,
            height: 680,
            child: ListView(
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: customRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Papel personalizado (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Usar papel-base da associação'),
                    ),
                    ...customRoles.map(
                      (role) => DropdownMenuItem<String?>(
                        value: role.id,
                        child: Text(role.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => customRoleId = value);
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Overrides por usuário',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Padrão = herda do papel. Permitir e Negar sobrescrevem o padrão.',
                ),
                const SizedBox(height: 8),
                ...AtlasEnterprisePermissions.catalog.map(
                  (permission) {
                    final effect = effects[permission.key];
                    return Card(
                      child: ListTile(
                        title: Text(permission.label),
                        subtitle: Text(permission.key),
                        trailing:
                            DropdownButton<AtlasPermissionEffect?>(
                          value: effect,
                          hint: const Text('Padrão'),
                          items: const [
                            DropdownMenuItem<
                                AtlasPermissionEffect?>(
                              value: null,
                              child: Text('Padrão'),
                            ),
                            DropdownMenuItem<
                                AtlasPermissionEffect?>(
                              value: AtlasPermissionEffect.allow,
                              child: Text('Permitir'),
                            ),
                            DropdownMenuItem<
                                AtlasPermissionEffect?>(
                              value: AtlasPermissionEffect.deny,
                              child: Text('Negar'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == null) {
                                effects.remove(permission.key);
                              } else {
                                effects[permission.key] = value;
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final now = DateTime.now();
      final policy = AtlasUserPermissionPolicy(
        id: previous?.id ??
            'policy_${membership.companyId}_'
                '${membership.userId}',
        companyId: membership.companyId,
        userId: membership.userId,
        customRoleId: customRoleId,
        effects: effects,
        updatedBy: session.currentUserId ?? 'system',
        updatedAt: now,
      );

      await permissions.savePolicy(policy);
      await audit.record(
        action: previous == null ? 'create' : 'update',
        module: 'permissions',
        entityType: 'user_policy',
        entityId: policy.id,
        description:
            'Política de acesso de ${membership.userName} atualizada.',
        before: previous?.toMap() ??
            const <String, dynamic>{},
        after: policy.toMap(),
      );
      await _load();
    }
  }

  Future<void> _showEffective(
    AtlasEnterpriseMembership membership,
  ) async {
    final effective = await authorization.effectivePermissions(
      companyId: membership.companyId,
      userId: membership.userId,
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Acesso efetivo — ${membership.userName}'),
        content: SizedBox(
          width: 650,
          height: 600,
          child: ListView(
            children: [
              Text(
                'Papel-base: '
                '${atlasEnterpriseMembershipRoleLabel(effective.membershipRole)}',
              ),
              Text(
                'Papel personalizado: '
                '${effective.customRoleId ?? 'nenhum'}',
              ),
              const Divider(),
              ...AtlasEnterprisePermissions.catalog.map(
                (permission) => ListTile(
                  leading: Icon(
                    effective.allows(permission.key)
                        ? Icons.check_circle_outline
                        : Icons.block,
                  ),
                  title: Text(permission.label),
                  subtitle: Text(permission.key),
                  trailing: Text(
                    effective.allows(permission.key)
                        ? 'Permitido'
                        : 'Negado',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSecurityTests() async {
    final companyId = session.currentCompanyId;
    final userId = session.currentUserId;
    if (companyId == null || userId == null) return;

    final effective = await authorization.effectivePermissions();
    final permissionCheck = await authorization.can(
      'enterprise.permissions.read',
    );
    final fakeFarmDenied = !(await enterprise.canUserAccessFarm(
      userId: userId,
      companyId: companyId,
      farmId: '__farm_from_another_company__',
    ));
    final verified = await audit.verifyIntegrity();

    await audit.record(
      action: 'security_test',
      module: 'enterprise',
      entityType: 'authorization',
      entityId: '24b_security_suite',
      description:
          'Suite local de autorização 24B executada.',
      after: <String, dynamic>{
        'effectivePermissionCount': effective.allowed.length,
        'permissionReadCheck': permissionCheck,
        'foreignFarmDenied': fakeFarmDenied,
        'auditIntegrityValid': verified.valid,
      },
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teste de segurança 24B'),
        content: Text(
          'Permissões efetivas: ${effective.allowed.length}\n'
          'Leitura de permissões: ${permissionCheck ? 'OK' : 'NEGADA'}\n'
          'Fazenda externa bloqueada: ${fakeFarmDenied ? 'OK' : 'FALHA'}\n'
          'Integridade da auditoria: ${verified.valid ? 'OK' : 'FALHA'}\n'
          'Registros verificados: ${verified.checkedRecords}',
        ),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    await _load();
  }

  Future<void> _open24C() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AtlasEnterprise24CScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enterprise 24B'),
          actions: [
            IconButton(
              tooltip: 'Versionamento e sincronização 24C',
              onPressed: _open24C,
              icon: const Icon(Icons.sync_alt_outlined),
            ),
            IconButton(
              tooltip: 'Executar testes',
              onPressed: loading ? null : _runSecurityTests,
              icon: const Icon(Icons.security),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Permissões'),
              Tab(text: 'Acesso efetivo'),
              Tab(text: 'Auditoria'),
              Tab(text: 'Segurança'),
            ],
          ),
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: loading ? null : _createCustomRole,
          icon: const Icon(Icons.add),
          label: const Text('Papel personalizado'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _PermissionsTab(
                    memberships: companyMemberships,
                    onEdit: _editUserPolicy,
                  ),
                  _EffectiveAccessTab(
                    memberships: companyMemberships,
                    onOpen: _showEffective,
                  ),
                  _AuditTab(
                    records: auditRecords,
                    integrity: integrity,
                  ),
                  _SecurityTab(
                    integrity: integrity,
                    onRun: _runSecurityTests,
                  ),
                ],
              ),
      ),
    );
  }
}

class _PermissionsTab extends StatelessWidget {
  const _PermissionsTab({
    required this.memberships,
    required this.onEdit,
  });

  final List<AtlasEnterpriseMembership> memberships;
  final ValueChanged<AtlasEnterpriseMembership> onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: memberships.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = memberships[index];
        return Card(
          child: ListTile(
            title: Text(item.userName),
            subtitle: Text(
              '${item.email} • '
              '${atlasEnterpriseMembershipRoleLabel(item.role)}',
            ),
            trailing: FilledButton.tonal(
              onPressed: () => onEdit(item),
              child: const Text('Permissões'),
            ),
          ),
        );
      },
    );
  }
}

class _EffectiveAccessTab extends StatelessWidget {
  const _EffectiveAccessTab({
    required this.memberships,
    required this.onOpen,
  });

  final List<AtlasEnterpriseMembership> memberships;
  final ValueChanged<AtlasEnterpriseMembership> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: memberships.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = memberships[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: Text(item.userName),
            subtitle: Text(
              atlasEnterpriseMembershipRoleLabel(item.role),
            ),
            trailing: TextButton(
              onPressed: () => onOpen(item),
              child: const Text('Ver acesso efetivo'),
            ),
          ),
        );
      },
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({
    required this.records,
    required this.integrity,
  });

  final List<AtlasEnterpriseAuditRecord> records;
  final AtlasAuditIntegrityResult? integrity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: ListTile(
            leading: Icon(
              integrity?.valid == true
                  ? Icons.verified_user_outlined
                  : Icons.warning_amber_rounded,
            ),
            title: const Text('Integridade da trilha'),
            subtitle: Text(
              integrity?.valid == true
                  ? '${integrity!.checkedRecords} registro(s) validados na cadeia.'
                  : 'A cadeia precisa ser verificada.',
            ),
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const Center(
                  child: Text('Nenhum evento de auditoria.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: records.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = records[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(item.description),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm:ss').format(item.occurredAt)} • '
                          '${item.userId} • ${item.result}',
                        ),
                        childrenPadding:
                            const EdgeInsets.all(16),
                        children: [
                          SelectableText(
                            const JsonEncoder.withIndent('  ')
                                .convert(
                              <String, dynamic>{
                                'action': item.action,
                                'module': item.module,
                                'entityType': item.entityType,
                                'entityId': item.entityId,
                                'farmId': item.farmId,
                                'before': item.before,
                                'after': item.after,
                                'source': item.source,
                                'device': item.device,
                                'justification':
                                    item.justification,
                                'hash': item.integrityHash,
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab({
    required this.integrity,
    required this.onRun,
  });

  final AtlasAuditIntegrityResult? integrity;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.policy_outlined),
            title: Text('RBAC granular'),
            subtitle: Text(
              'Papel-base + papel personalizado + allow/deny por usuário.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.route_outlined),
            title: Text('Proteção de rotas e widgets'),
            subtitle: Text(
              'AtlasProtectedRoute e AtlasPermissionGate.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.admin_panel_settings_outlined),
            title: Text('Proteção de serviços'),
            subtitle: Text(
              'Operações sensíveis podem exigir permissionKey no serviço.',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Auditoria append-only'),
            subtitle: Text(
              integrity?.valid == true
                  ? 'Cadeia de integridade válida.'
                  : 'Ainda sem confirmação de integridade.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRun,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Executar testes 24B'),
        ),
      ],
    );
  }
}
