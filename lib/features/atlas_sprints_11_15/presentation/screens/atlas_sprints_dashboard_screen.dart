import 'package:flutter/material.dart';
import '../../data/services/atlas_sprints_service.dart';
import '../../domain/models/atlas_sprints_dashboard_data.dart';

class AtlasSprintsDashboardScreen extends StatefulWidget {
  const AtlasSprintsDashboardScreen({super.key, required this.farmId});
  final String farmId;
  @override
  State<AtlasSprintsDashboardScreen> createState() => _State();
}

class _State extends State<AtlasSprintsDashboardScreen> {
  final _service = AtlasSprintsService();
  AtlasSprintsDashboardData? data;
  String? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final v = await _service.dashboard(widget.farmId);
      if (mounted) setState(() => data = v);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget card(String title, IconData icon, Map<String, dynamic> value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Atlas Sprints 11–15'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                card('Atlas Brain 2.0', Icons.psychology_alt, data!.brain),
                card('Atlas Vision', Icons.visibility, data!.vision),
                card('IoT', Icons.sensors, data!.iot),
                card('Atlas Cloud', Icons.cloud_done, data!.cloud),
                card('Plataforma Web', Icons.web, data!.web),
              ],
            ),
          ),
  );
}
