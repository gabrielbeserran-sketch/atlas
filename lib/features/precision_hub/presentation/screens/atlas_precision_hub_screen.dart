import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/platform_hubs/data/services/atlas_platform_hub_service.dart';
import 'package:projeto_atlas/features/platform_hubs/domain/models/atlas_hub_snapshot.dart';
import 'package:projeto_atlas/features/platform_hubs/presentation/widgets/atlas_metric_card.dart';
import 'package:projeto_atlas/features/security_camera/presentation/widgets/atlas_security_camera_card.dart';

class AtlasPrecisionHubScreen extends StatefulWidget {
  const AtlasPrecisionHubScreen({super.key});

  @override
  State<AtlasPrecisionHubScreen> createState() =>
      _AtlasPrecisionHubScreenState();
}

class _AtlasPrecisionHubScreenState extends State<AtlasPrecisionHubScreen> {
  final _service = AtlasPlatformHubService();
  AtlasHubSnapshot? _snapshot;
  Object? _error;
  bool _loading = false;
  String? _loadedFarmId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final farmId = AtlasSessionScope.of(context).activeFarm?.id;
    if (farmId != null && farmId != _loadedFarmId && !_loading) {
      _load();
    }
  }

  Future<void> _load() async {
    final farm = AtlasSessionScope.read(context).activeFarm;
    if (farm == null) {
      setState(() => _error = 'Selecione uma fazenda.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.loadPrecision(farm.id);
      if (!mounted) return;
      setState(() {
        _snapshot = result;
        _loadedFarmId = farm.id;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AtlasSessionScope.of(context);
    final farm = controller.activeFarm;
    final canManage = controller.allows('platform.manage');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'IoT, mapas e visão',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(farm?.name ?? 'Nenhuma fazenda selecionada'),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(_error.toString()),
                trailing: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          if (_snapshot != null && farm != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _snapshot!.metrics.entries
                  .where((entry) => entry.value is num)
                  .map(
                    (entry) =>
                        AtlasMetricCard(label: entry.key, value: entry.value),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 20),
            AtlasSecurityCameraCard(
              farmId: farm.id,
              canManage: canManage,
            ),
            const SizedBox(height: 20),
            Text(
              'Operações de precisão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _action(
                  'Dispositivo',
                  Icons.sensors,
                  canManage,
                  '/precision-hub/farms/${farm.id}/devices',
                  {'device_type': 'generic', 'status': 'active'},
                ),
                _action(
                  'RFID',
                  Icons.nfc,
                  canManage,
                  '/precision-hub/farms/${farm.id}/rfid-bindings',
                  {'animal_id': '', 'active': true},
                ),
                _action(
                  'Geocerca',
                  Icons.map_outlined,
                  canManage,
                  '/precision-hub/farms/${farm.id}/geofences',
                  {'rule_type': 'inside', 'polygon': <dynamic>[]},
                ),
                _action(
                  'Análise de visão',
                  Icons.camera_alt_outlined,
                  canManage,
                  '/precision-hub/farms/${farm.id}/vision',
                  {'analysis_type': 'body_condition', 'status': 'pending'},
                ),
                _action(
                  'Geoativo',
                  Icons.layers_outlined,
                  canManage,
                  '/precision-hub/farms/${farm.id}/geo-assets',
                  {
                    'asset_type': 'point',
                    'geometry_type': 'Point',
                    'geometry': {
                      'type': 'Point',
                      'coordinates': [0, 0],
                    },
                  },
                ),
                _action(
                  'Cena remota',
                  Icons.satellite_alt_outlined,
                  canManage,
                  '/precision-hub/farms/${farm.id}/remote-sensing/scenes',
                  {'provider': 'manual', 'indices': <String, dynamic>{}},
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    bool enabled,
    String path,
    Map<String, dynamic> base,
  ) {
    return SizedBox(
      width: 205,
      child: OutlinedButton.icon(
        onPressed: enabled ? () => _create(label, path, base) : null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Future<void> _create(
    String label,
    String path,
    Map<String, dynamic> base,
  ) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Identificação'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, input.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    input.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await _service.create(path, {
        ...base,
        'name': value,
        'tag_code': value,
        'external_id': value,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label registrado.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
