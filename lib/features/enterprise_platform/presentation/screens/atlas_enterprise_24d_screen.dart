import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/network/atlas_environment.dart';

import '../../data/services/atlas_enterprise_remote_auth_store.dart';
import '../../domain/models/atlas_enterprise_remote_session.dart';
import '../../domain/services/atlas_enterprise_api_client.dart';
import '../../domain/services/atlas_enterprise_sync_engine_24c.dart';
import '../../domain/services/atlas_http_sync_transport.dart';

class AtlasEnterprise24DScreen extends StatefulWidget {
  const AtlasEnterprise24DScreen({super.key});

  @override
  State<AtlasEnterprise24DScreen> createState() =>
      _AtlasEnterprise24DScreenState();
}

class _AtlasEnterprise24DScreenState extends State<AtlasEnterprise24DScreen> {
  final api = AtlasEnterpriseApiClient.instance;
  final store = AtlasEnterpriseRemoteAuthStore.instance;

  final baseUrl = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  AtlasRemoteSession? session;
  Map<String, dynamic>? health;
  List<Map<String, dynamic>> backups = [];
  bool loading = true;
  String status = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    baseUrl.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    baseUrl.text = await store.baseUrl();
    session = await store.loadSession();
    if (session != null) {
      email.text = session!.email;
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _saveBaseUrl() async {
    if (AtlasEnvironmentConfig.isProduction) return;
    await store.saveBaseUrl(baseUrl.text);
    if (!mounted) return;
    setState(() {
      status = 'URL da API salva.';
    });
  }

  Future<void> _testHealth() async {
    setState(() => loading = true);
    try {
      await _saveBaseUrl();
      final result = await api.health();
      if (!mounted) return;
      setState(() {
        health = result;
        status = 'Backend conectado com sucesso.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => status = error.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      await _saveBaseUrl();
      final result = await api.login(
        email: email.text,
        password: password.text,
      );
      if (!mounted) return;
      setState(() {
        session = result;
        status = 'Autenticado em ${result.companyId} (${result.role}).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => status = error.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _remoteSync() async {
    setState(() => loading = true);
    try {
      final engine = AtlasEnterpriseSyncEngine24C(
        transport: AtlasHttpSyncTransport.instance,
      );
      final result = await engine.synchronize(
        online: true,
        companyId: session?.companyId,
      );
      if (!mounted) return;
      setState(() {
        status =
            'Sync remoto concluído: '
            '${result.synchronized} sincronizado(s), '
            '${result.conflicts} conflito(s), '
            '${result.errors} erro(s).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => status = error.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadBackups() async {
    setState(() => loading = true);
    try {
      final values = await api.backups();
      if (!mounted) return;
      setState(() {
        backups = values;
        status = '${values.length} backup(s) localizado(s).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => status = error.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _runBackup() async {
    setState(() => loading = true);
    try {
      final value = await api.runBackup();
      if (!mounted) return;
      setState(() {
        status = 'Backup criado: ${value['filename'] ?? ''}.';
      });
      await _loadBackups();
    } catch (error) {
      if (!mounted) return;
      setState(() => status = error.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enterprise 24D'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Servidor'),
              Tab(text: 'Autenticação'),
              Tab(text: 'Sync remoto'),
              Tab(text: 'Backups'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_serverTab(), _authTab(), _syncTab(), _backupTab()],
        ),
      ),
    );
  }

  Widget _serverTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: baseUrl,
          readOnly: AtlasEnvironmentConfig.isProduction,
          decoration: InputDecoration(
            labelText: 'URL da API',
            hintText: AtlasEnvironmentConfig.isProduction
                ? 'Definida na assinatura de produção'
                : 'http://localhost:8000/api/v1',
            helperText: AtlasEnvironmentConfig.isProduction
                ? 'Imutável nesta versão publicada.'
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading ? null : _testHealth,
          icon: const Icon(Icons.monitor_heart_outlined),
          label: const Text('Testar backend'),
        ),
        const SizedBox(height: 12),
        if (health != null)
          Card(
            child: ListTile(
              title: const Text('Health check'),
              subtitle: Text(health.toString()),
            ),
          ),
        _statusCard(),
      ],
    );
  }

  Widget _authTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: email,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading ? null : _login,
          icon: const Icon(Icons.login),
          label: const Text('Entrar no backend'),
        ),
        const SizedBox(height: 12),
        if (session != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(session!.userName),
              subtitle: Text(
                '${session!.email}\n'
                'Empresa: ${session!.companyId}\n'
                'Tenant: ${session!.tenantId}\n'
                'Papel: ${session!.role}',
              ),
            ),
          ),
        _statusCard(),
      ],
    );
  }

  Widget _syncTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_sync_outlined),
            title: Text('Transporte HTTP real'),
            subtitle: Text(
              'AtlasHttpSyncTransport substitui o loopback '
              'e utiliza /api/v1/sync/push e /pull.',
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: loading || session == null ? null : _remoteSync,
          icon: const Icon(Icons.sync),
          label: const Text('Sincronizar com o servidor'),
        ),
        _statusCard(),
      ],
    );
  }

  Widget _backupTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: loading || session == null ? null : _loadBackups,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Listar backups'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading || session == null ? null : _runBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Executar backup'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: backups.isEmpty
              ? const Center(child: Text('Nenhum backup carregado.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: backups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = backups[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: Text(item['filename']?.toString() ?? ''),
                        subtitle: Text(
                          '${item['engine'] ?? ''} • '
                          '${item['size_bytes'] ?? 0} bytes',
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(padding: const EdgeInsets.all(16), child: _statusCard()),
      ],
    );
  }

  Widget _statusCard() {
    if (status.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.info_outline),
        title: Text(status),
      ),
    );
  }
}
