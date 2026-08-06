import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/settings/atlas_system_settings.dart';
import 'package:projeto_atlas/core/system_center/atlas_system_center_models.dart';
import 'package:projeto_atlas/core/system_center/atlas_system_center_repository.dart';

class AtlasSystemCenterScreen extends StatefulWidget {
  const AtlasSystemCenterScreen({super.key});

  @override
  State<AtlasSystemCenterScreen> createState() {
    return _AtlasSystemCenterScreenState();
  }
}

class _AtlasSystemCenterScreenState extends State<AtlasSystemCenterScreen> {
  final AtlasSystemCenterRepository _repository =
      AtlasSystemCenterRepository();

  AtlasSystemSnapshot? _snapshot;
  bool _loading = true;
  bool _inspecting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasSystemSnapshot snapshot = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _inspect() async {
    setState(() {
      _inspecting = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final DateTime inspectedAt = await _repository.registerInspection();
    final AtlasSystemSnapshot refreshed = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = refreshed.copyWith(lastInspection: inspectedAt);
      _inspecting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspeção do sistema concluída.')),
    );
  }

  Future<void> _updateSettings(AtlasSystemSettings settings) async {
    await _repository.saveSettings(settings);
    if (!mounted || _snapshot == null) {
      return;
    }
    setState(() {
      _snapshot = _snapshot!.copyWith(settings: settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas System Center'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(_snapshot!),
    );
  }

  Widget _buildContent(AtlasSystemSnapshot snapshot) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildHeader(snapshot),
          const SizedBox(height: 16),
          _buildMetrics(snapshot),
          const SizedBox(height: 20),
          const Text(
            'Configurações globais',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSettings(snapshot.settings),
          const SizedBox(height: 20),
          const Text(
            'Inventário técnico',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...snapshot.modules.map(_buildModuleCard),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _inspecting ? null : _inspect,
            icon: _inspecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.manage_search_outlined),
            label: Text(
              _inspecting ? 'Inspecionando...' : 'Executar inspeção do sistema',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AtlasSystemSnapshot snapshot) {
    final String inspectionText = snapshot.lastInspection == null
        ? 'Nenhuma inspeção registrada'
        : 'Última inspeção: ${_formatDate(snapshot.lastInspection!)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.settings_suggest_outlined, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sprint Enterprise 2',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Versão ${snapshot.version} • Índice arquitetural ${snapshot.architectureScore}%',
            ),
            const SizedBox(height: 5),
            Text(
              inspectionText,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(AtlasSystemSnapshot snapshot) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _metric('Módulos', snapshot.modules.length.toString()),
        _metric('Serviços', snapshot.registeredServices.toString()),
        _metric('Repositórios', snapshot.registeredRepositories.toString()),
        _metric('Chaves locais', snapshot.storageKeys.toString()),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettings(AtlasSystemSettings settings) {
    return Card(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Sincronização automática'),
            subtitle: const Text('Prepara o envio dos dados quando houver conexão.'),
            value: settings.automaticSync,
            onChanged: (bool value) {
              _updateSettings(settings.copyWith(automaticSync: value));
            },
          ),
          SwitchListTile(
            title: const Text('Sincronizar somente por Wi-Fi'),
            value: settings.wifiOnly,
            onChanged: (bool value) {
              _updateSettings(settings.copyWith(wifiOnly: value));
            },
          ),
          SwitchListTile(
            title: const Text('Notificações do sistema'),
            value: settings.notificationsEnabled,
            onChanged: (bool value) {
              _updateSettings(settings.copyWith(notificationsEnabled: value));
            },
          ),
          SwitchListTile(
            title: const Text('Diagnóstico automático'),
            value: settings.diagnosticsEnabled,
            onChanged: (bool value) {
              _updateSettings(settings.copyWith(diagnosticsEnabled: value));
            },
          ),
          SwitchListTile(
            title: const Text('Modo compacto'),
            value: settings.compactMode,
            onChanged: (bool value) {
              _updateSettings(settings.copyWith(compactMode: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(AtlasSystemModule module) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.extension_outlined),
        ),
        title: Text(module.name),
        subtitle: Text(module.category),
        trailing: Chip(label: Text(module.status)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
