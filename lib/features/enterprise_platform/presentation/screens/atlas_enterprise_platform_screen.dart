import 'package:flutter/material.dart';

import '../../data/services/atlas_enterprise_repository.dart';
import '../../domain/models/atlas_enterprise_data.dart';
import '../../domain/services/atlas_enterprise_engine.dart';

class AtlasEnterprisePlatformScreen extends StatefulWidget {
  const AtlasEnterprisePlatformScreen({super.key});

  @override
  State<AtlasEnterprisePlatformScreen> createState() =>
      _AtlasEnterprisePlatformScreenState();
}

class _AtlasEnterprisePlatformScreenState
    extends State<AtlasEnterprisePlatformScreen> {
  final AtlasEnterpriseRepository _repository = AtlasEnterpriseRepository();
  final AtlasEnterpriseEngine _engine = const AtlasEnterpriseEngine();

  AtlasEnterpriseState? _state;
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasEnterpriseState state = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _persist(AtlasEnterpriseState state) async {
    setState(() {
      _state = state;
    });
    await _repository.save(state);
  }

  String _planLabel(AtlasSubscriptionPlan plan) {
    switch (plan) {
      case AtlasSubscriptionPlan.free:
        return 'Gratuito';
      case AtlasSubscriptionPlan.professional:
        return 'Profissional';
      case AtlasSubscriptionPlan.enterprise:
        return 'Enterprise';
    }
  }

  String _statusLabel(AtlasTenantStatus status) {
    switch (status) {
      case AtlasTenantStatus.active:
        return 'Ativo';
      case AtlasTenantStatus.trial:
        return 'Período de teste';
      case AtlasTenantStatus.suspended:
        return 'Suspenso';
    }
  }

  String _roleLabel(AtlasUserRole role) {
    switch (role) {
      case AtlasUserRole.administrator:
        return 'Administrador';
      case AtlasUserRole.consultant:
        return 'Consultor';
      case AtlasUserRole.veterinarian:
        return 'Veterinário';
      case AtlasUserRole.technician:
        return 'Técnico';
      case AtlasUserRole.employee:
        return 'Funcionário';
      case AtlasUserRole.producer:
        return 'Produtor';
      case AtlasUserRole.viewer:
        return 'Visualizador';
    }
  }

  String _auditLabel(AtlasAuditAction action) {
    switch (action) {
      case AtlasAuditAction.create:
        return 'Criação';
      case AtlasAuditAction.update:
        return 'Atualização';
      case AtlasAuditAction.delete:
        return 'Exclusão';
      case AtlasAuditAction.approve:
        return 'Aprovação';
      case AtlasAuditAction.export:
        return 'Exportação';
      case AtlasAuditAction.login:
        return 'Acesso';
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  AtlasTenant? get _currentTenant {
    final AtlasEnterpriseState? state = _state;
    if (state == null || state.tenants.isEmpty) {
      return null;
    }
    return state.tenants.firstWhere(
      (AtlasTenant tenant) => tenant.id == state.currentTenantId,
      orElse: () => state.tenants.first,
    );
  }

  Future<void> _editTenant([AtlasTenant? current]) async {
    final TextEditingController nameController =
        TextEditingController(text: current?.name ?? '');
    final TextEditingController documentController =
        TextEditingController(text: current?.document ?? '');
    AtlasSubscriptionPlan plan =
        current?.plan ?? AtlasSubscriptionPlan.professional;
    AtlasTenantStatus status = current?.status ?? AtlasTenantStatus.trial;

    final AtlasTenant? result = await showDialog<AtlasTenant>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return AlertDialog(
              title: Text(current == null ? 'Nova empresa' : 'Editar empresa'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da empresa',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: documentController,
                        decoration: const InputDecoration(
                          labelText: 'CPF ou CNPJ',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasSubscriptionPlan>(
                        initialValue: plan,
                        decoration: const InputDecoration(
                          labelText: 'Plano',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items: AtlasSubscriptionPlan.values
                            .map(
                              (AtlasSubscriptionPlan item) =>
                                  DropdownMenuItem<AtlasSubscriptionPlan>(
                                value: item,
                                child: Text(_planLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (AtlasSubscriptionPlan? value) {
                          if (value != null) {
                            setLocalState(() {
                              plan = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasTenantStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Situação',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                        ),
                        items: AtlasTenantStatus.values
                            .map(
                              (AtlasTenantStatus item) =>
                                  DropdownMenuItem<AtlasTenantStatus>(
                                value: item,
                                child: Text(_statusLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (AtlasTenantStatus? value) {
                          if (value != null) {
                            setLocalState(() {
                              status = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }
                    final int users = switch (plan) {
                      AtlasSubscriptionPlan.free => 3,
                      AtlasSubscriptionPlan.professional => 15,
                      AtlasSubscriptionPlan.enterprise => 999,
                    };
                    final int farms = switch (plan) {
                      AtlasSubscriptionPlan.free => 1,
                      AtlasSubscriptionPlan.professional => 50,
                      AtlasSubscriptionPlan.enterprise => 999,
                    };
                    Navigator.of(dialogContext).pop(
                      AtlasTenant(
                        id: current?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        document: documentController.text.trim(),
                        status: status,
                        plan: plan,
                        createdAt: current?.createdAt ?? DateTime.now(),
                        trialEndsAt: current?.trialEndsAt ??
                            DateTime.now().add(const Duration(days: 30)),
                        maxUsers: users,
                        maxFarms: farms,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    documentController.dispose();

    if (result == null || _state == null) {
      return;
    }

    final List<AtlasTenant> tenants = <AtlasTenant>[..._state!.tenants];
    final int index = tenants.indexWhere((AtlasTenant item) => item.id == result.id);
    if (index < 0) {
      tenants.add(result);
    } else {
      tenants[index] = result;
    }
    await _persist(
      AtlasEnterpriseState(
        tenants: tenants,
        users: _state!.users,
        audit: <AtlasAuditEntry>[
          AtlasAuditEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            tenantId: result.id,
            userName: 'Administrador',
            module: 'Empresas',
            action: index < 0 ? AtlasAuditAction.create : AtlasAuditAction.update,
            description: index < 0
                ? 'Empresa ${result.name} cadastrada.'
                : 'Cadastro de ${result.name} atualizado.',
            createdAt: DateTime.now(),
          ),
          ..._state!.audit,
        ],
        currentTenantId: _state!.currentTenantId ?? result.id,
      ),
    );
  }

  Future<void> _editUser([AtlasEnterpriseUser? current]) async {
    final AtlasTenant? tenant = _currentTenant;
    if (tenant == null || _state == null) {
      return;
    }

    final TextEditingController nameController =
        TextEditingController(text: current?.name ?? '');
    final TextEditingController emailController =
        TextEditingController(text: current?.email ?? '');
    AtlasUserRole role = current?.role ?? AtlasUserRole.consultant;
    bool active = current?.active ?? true;
    bool twoFactorEnabled = current?.twoFactorEnabled ?? false;

    final AtlasEnterpriseUser? result = await showDialog<AtlasEnterpriseUser>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return AlertDialog(
              title: Text(current == null ? 'Novo usuário' : 'Editar usuário'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasUserRole>(
                        initialValue: role,
                        decoration: const InputDecoration(
                          labelText: 'Perfil de acesso',
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        items: AtlasUserRole.values
                            .map(
                              (AtlasUserRole item) => DropdownMenuItem<AtlasUserRole>(
                                value: item,
                                child: Text(_roleLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (AtlasUserRole? value) {
                          if (value != null) {
                            setLocalState(() {
                              role = value;
                            });
                          }
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Usuário ativo'),
                        value: active,
                        onChanged: (bool value) {
                          setLocalState(() {
                            active = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Autenticação em duas etapas'),
                        value: twoFactorEnabled,
                        onChanged: (bool value) {
                          setLocalState(() {
                            twoFactorEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      AtlasEnterpriseUser(
                        id: current?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        tenantId: tenant.id,
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        role: role,
                        active: active,
                        twoFactorEnabled: twoFactorEnabled,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();

    if (result == null || _state == null) {
      return;
    }

    final List<AtlasEnterpriseUser> users = <AtlasEnterpriseUser>[..._state!.users];
    final int index = users.indexWhere((AtlasEnterpriseUser item) => item.id == result.id);
    if (index < 0) {
      users.add(result);
    } else {
      users[index] = result;
    }
    await _persist(
      AtlasEnterpriseState(
        tenants: _state!.tenants,
        users: users,
        audit: <AtlasAuditEntry>[
          AtlasAuditEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            tenantId: tenant.id,
            userName: 'Administrador',
            module: 'Usuários e permissões',
            action: index < 0 ? AtlasAuditAction.create : AtlasAuditAction.update,
            description: index < 0
                ? 'Usuário ${result.name} cadastrado.'
                : 'Permissões de ${result.name} atualizadas.',
            createdAt: DateTime.now(),
          ),
          ..._state!.audit,
        ],
        currentTenantId: _state!.currentTenantId,
      ),
    );
  }

  Widget _buildOverview(AtlasEnterpriseState state) {
    final AtlasEnterpriseSummary summary = _engine.summarize(state);
    final AtlasTenant? tenant = _currentTenant;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _MetricCard('Empresas', '${summary.tenants}', Icons.business_outlined),
            _MetricCard('Usuários ativos', '${summary.activeUsers}', Icons.people_outline),
            _MetricCard('Com 2 etapas', '${summary.twoFactorUsers}', Icons.security_outlined),
            _MetricCard('Auditorias', '${summary.auditEntries}', Icons.fact_check_outlined),
            _MetricCard(
              'Segurança',
              '${summary.securityScore.toStringAsFixed(0)}%',
              Icons.shield_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (tenant != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.apartment_outlined, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              tenant.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Plano ${_planLabel(tenant.plan)} • ${_statusLabel(tenant.status)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar empresa',
                        onPressed: () => _editTenant(tenant),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: <Widget>[
                      _Detail('Limite de usuários', '${tenant.maxUsers}'),
                      _Detail('Limite de fazendas', '${tenant.maxFarms}'),
                      _Detail(
                        'Teste até',
                        tenant.trialEndsAt == null
                            ? 'Não aplicável'
                            : _formatDate(tenant.trialEndsAt!),
                      ),
                      _Detail(
                        'Criado em',
                        _formatDate(tenant.createdAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Arquitetura Enterprise preparada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'A estrutura local de multiempresa, perfis, licenciamento e auditoria está ativa. A autenticação real, a criptografia e o isolamento no servidor serão conectados quando o backend em nuvem for implantado.',
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTenants(AtlasEnterpriseState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _editTenant(),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Nova empresa'),
          ),
        ),
        const SizedBox(height: 14),
        ...state.tenants.map(
          (AtlasTenant tenant) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
              title: Text(tenant.name),
              subtitle: Text(
                '${_planLabel(tenant.plan)} • ${_statusLabel(tenant.status)} • até ${tenant.maxUsers} usuários',
              ),
              trailing: Wrap(
                children: <Widget>[
                  if (state.currentTenantId == tenant.id)
                    const Chip(label: Text('Atual')),
                  IconButton(
                    tooltip: 'Selecionar empresa',
                    onPressed: () {
                      _persist(
                        AtlasEnterpriseState(
                          tenants: state.tenants,
                          users: state.users,
                          audit: state.audit,
                          currentTenantId: tenant.id,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () => _editTenant(tenant),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsers(AtlasEnterpriseState state) {
    final AtlasTenant? tenant = _currentTenant;
    final List<AtlasEnterpriseUser> users = tenant == null
        ? <AtlasEnterpriseUser>[]
        : state.users
            .where((AtlasEnterpriseUser user) => user.tenantId == tenant.id)
            .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _editUser(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Novo usuário'),
          ),
        ),
        const SizedBox(height: 14),
        if (users.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Nenhum usuário cadastrado nesta empresa.')),
            ),
          )
        else
          ...users.map(
            (AtlasEnterpriseUser user) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
                ),
                title: Text(user.name),
                subtitle: Text('${user.email}\n${_roleLabel(user.role)}'),
                isThreeLine: true,
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Icon(
                      user.twoFactorEnabled ? Icons.security : Icons.security_outlined,
                      color: user.twoFactorEnabled ? Colors.green : Colors.orange,
                    ),
                    Switch(
                      value: user.active,
                      onChanged: (bool value) {
                        final List<AtlasEnterpriseUser> updatedUsers = state.users
                            .map(
                              (AtlasEnterpriseUser item) => item.id == user.id
                                  ? item.copyWith(active: value)
                                  : item,
                            )
                            .toList();
                        _persist(
                          AtlasEnterpriseState(
                            tenants: state.tenants,
                            users: updatedUsers,
                            audit: state.audit,
                            currentTenantId: state.currentTenantId,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Editar usuário',
                      onPressed: () => _editUser(user),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudit(AtlasEnterpriseState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const Text(
          'Histórico de auditoria',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Rastreabilidade das principais alterações administrativas.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        if (state.audit.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Nenhum evento de auditoria registrado.')),
            ),
          )
        else
          ...state.audit.map(
            (AtlasAuditEntry item) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.history_outlined)),
                title: Text('${_auditLabel(item.action)} • ${item.module}'),
                subtitle: Text(
                  '${item.description}\n${item.userName} • ${_formatDate(item.createdAt)}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AtlasEnterpriseState? state = _state;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Atlas Enterprise Platform'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading || state == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                NavigationBar(
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _tabIndex = index;
                    });
                  },
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'Visão geral',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.business_outlined),
                      label: 'Empresas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      label: 'Usuários',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      label: 'Auditoria',
                    ),
                  ],
                ),
                Expanded(
                  child: switch (_tabIndex) {
                    0 => _buildOverview(state),
                    1 => _buildTenants(state),
                    2 => _buildUsers(state),
                    _ => _buildAudit(state),
                  },
                ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
