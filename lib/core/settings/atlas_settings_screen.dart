import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/auth/atlas_offline_pin_service.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/core/subscription/atlas_subscription_profile.dart';
import 'package:projeto_atlas/core/subscription/atlas_subscription_service.dart';

class AtlasSettingsScreen extends StatefulWidget {
  const AtlasSettingsScreen({super.key});

  @override
  State<AtlasSettingsScreen> createState() => _AtlasSettingsScreenState();
}

class _AtlasSettingsScreenState extends State<AtlasSettingsScreen> {
  final _pin = AtlasOfflinePinService.instance;
  final _subscription = AtlasSubscriptionService.instance;
  bool? configured;
  late Future<AtlasSubscriptionProfile> _subscriptionFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionFuture = _subscription.loadCurrent();
    _load();
  }

  Future<void> _load() async {
    final value = await _pin.isConfigured;
    if (mounted) setState(() => configured = value);
  }

  Future<String?> _ask(String title, {bool confirm = false}) async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN de 6 dígitos'),
            ),
            if (confirm)
              TextField(
                controller: second,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Confirmar PIN'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              d,
              !confirm || first.text == second.text ? first.text : '',
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    return result;
  }

  Future<void> _setPin({required bool changing}) async {
    if (changing) {
      final current = await _ask('Informe o PIN atual');
      if (current == null || !await _pin.verify(current)) return;
    }
    final next = await _ask(
      changing ? 'Novo PIN offline' : 'Configurar PIN offline',
      confirm: true,
    );
    if (next == null || next.isEmpty) return;
    try {
      await _pin.save(next);
      await _load();
      if (!mounted) return;
      await AtlasSessionScope.read(context).refreshOfflineAccess();
    } on ArgumentError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use um PIN numérico de 6 dígitos.')),
        );
      }
    }
  }

  Future<void> _removePin() async {
    final current = await _ask('Informe o PIN atual para remover');
    if (current == null || !await _pin.verify(current)) return;
    await _pin.remove();
    await _load();
    if (!mounted) return;
    await AtlasSessionScope.read(context).refreshOfflineAccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Perfil de acesso',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final session = AtlasSessionScope.of(context).session;
              final permissions =
                  session == null
                        ? <String>[]
                        : session.effectivePermissions.toList()
                    ..sort();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roleLabel(session?.role),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session?.hasUnrestrictedFarmAccess == true
                            ? 'Acesso completo aos módulos autorizados da fazenda.'
                            : '${permissions.length} permissão(ões) ativa(s). O menu mostra somente o necessário para seu trabalho.',
                      ),
                      if (session?.hasUnrestrictedFarmAccess != true &&
                          permissions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: permissions
                              .take(8)
                              .map(
                                (item) =>
                                    Chip(label: Text(_permissionLabel(item))),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Plano da fazenda',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          FutureBuilder<AtlasSubscriptionProfile>(
            future: _subscriptionFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final plan = snapshot.requireData;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plan.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              plan.hasUnlimitedData
                                  ? 'Dados ilimitados'
                                  : '${plan.limits['monthly_credits'] ?? 0} créditos/mês',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.consultancyIncluded
                              ? 'Inclui consultoria e gestão de equipes com acessos por função.'
                              : 'Os módulos liberados dependem deste plano e do perfil de cada colaborador.',
                        ),
                        if (plan.features.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: plan.features
                                .map(
                                  (feature) =>
                                      Chip(label: Text(_featureLabel(feature))),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: const Text(
                      'Plano disponível na próxima sincronização',
                    ),
                    subtitle: const Text(
                      'O trabalho offline continua disponível e não é bloqueado por esta consulta.',
                    ),
                    trailing: TextButton(
                      onPressed: () => setState(
                        () => _subscriptionFuture = _subscription.loadCurrent(),
                      ),
                      child: const Text('Tentar'),
                    ),
                  ),
                );
              }
              return const Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('Consultando plano da fazenda...'),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Segurança e acesso',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(
                    configured == true
                        ? 'PIN offline configurado'
                        : 'Configurar PIN offline',
                  ),
                  subtitle: const Text(
                    'Protege o acesso aos dados salvos sem internet.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _setPin(changing: configured == true),
                ),
                if (configured == true)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remover PIN offline'),
                    onTap: _removePin,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String? role) => switch (role) {
    'owner' => 'Proprietário',
    'admin' || 'companyAdministrator' => 'Administrador',
    'superAdministrator' => 'Administrador da plataforma',
    'worker' => 'Trabalhador operacional',
    'consultant' => 'Consultor',
    _ => 'Perfil de acesso',
  };

  String _permissionLabel(String permission) {
    const labels = <String, String>{
      'animals.read': 'Consultar rebanho',
      'animals.create': 'Cadastrar animais',
      'animals.update': 'Atualizar rebanho',
      'animals.delete': 'Excluir animais',
      'finance.read': 'Consultar financeiro',
      'finance.create': 'Lançar financeiro',
      'finance.update': 'Atualizar financeiro',
      'analytics.read': 'Consultar análises',
      'analytics.manage': 'Gerir análises',
      'farms.read': 'Consultar fazenda',
      'farms.update': 'Gerir fazenda',
      'sync.manage': 'Sincronizar dados',
    };
    if (labels.containsKey(permission)) return labels[permission]!;
    final namespace = permission.split('.').first;
    return switch (namespace) {
      'animals' => 'Atividades de rebanho',
      'finance' => 'Atividades financeiras',
      'analytics' => 'Análises da fazenda',
      'farms' => 'Gestão da fazenda',
      'sync' => 'Sincronização',
      _ => 'Acesso autorizado',
    };
  }

  String _featureLabel(String feature) => switch (feature) {
    'operacao_basica' => 'Operação básica',
    'operacao_completa' => 'Operação completa',
    'registro_offline' => 'Uso offline',
    'indicadores_tecnicos' => 'Indicadores técnicos',
    'consultoria' => 'Consultoria',
    'gestao_de_equipes' => 'Gestão de equipes',
    _ => 'Função liberada',
  };
}
