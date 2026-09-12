import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/auth/atlas_offline_pin_service.dart';

class AtlasSettingsScreen extends StatefulWidget {
  const AtlasSettingsScreen({super.key});

  @override
  State<AtlasSettingsScreen> createState() => _AtlasSettingsScreenState();
}

class _AtlasSettingsScreenState extends State<AtlasSettingsScreen> {
  final _pin = AtlasOfflinePinService.instance;
  bool? configured;

  @override
  void initState() {
    super.initState();
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
    } on ArgumentError {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use um PIN numérico de 6 dígitos.')),
        );
    }
  }

  Future<void> _removePin() async {
    final current = await _ask('Informe o PIN atual para remover');
    if (current == null || !await _pin.verify(current)) return;
    await _pin.remove();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
}
