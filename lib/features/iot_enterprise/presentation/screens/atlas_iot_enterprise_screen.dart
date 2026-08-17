import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/iot_enterprise/data/atlas_iot_repository.dart';

class AtlasIotEnterpriseScreen extends StatefulWidget {
  const AtlasIotEnterpriseScreen({required this.farmId, super.key});

  final String farmId;

  @override
  State<AtlasIotEnterpriseScreen> createState() =>
      _AtlasIotEnterpriseScreenState();
}

class _AtlasIotEnterpriseScreenState extends State<AtlasIotEnterpriseScreen> {
  final repository = AtlasIotRepository();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> devices = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final values = await Future.wait([
        repository.dashboard(widget.farmId),
        repository.devices(widget.farmId),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        devices = values[1] as List<Map<String, dynamic>>;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas IoT Enterprise'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      title: 'Dispositivos',
                      value: '${dashboard['total_devices'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Online',
                      value: '${dashboard['online_devices'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Offline',
                      value: '${dashboard['offline_devices'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Bateria baixa',
                      value: '${dashboard['low_battery_devices'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Dispositivos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                if (devices.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Nenhum dispositivo cadastrado.'),
                    ),
                  )
                else
                  ...devices.map(
                    (device) => Card(
                      child: ListTile(
                        leading: Icon(
                          device['status'] == 'online'
                              ? Icons.sensors
                              : Icons.sensors_off,
                        ),
                        title: Text(device['name']?.toString() ?? ''),
                        subtitle: Text(
                          '${device['device_type'] ?? ''} • '
                          '${device['external_id'] ?? ''}\n'
                          'Bateria: ${device['battery_percent'] ?? '-'}% • '
                          'Sinal: ${device['signal_strength'] ?? '-'}',
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            device['status']?.toString() ?? 'offline',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
