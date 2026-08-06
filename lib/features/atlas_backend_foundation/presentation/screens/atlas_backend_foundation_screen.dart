
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/data/services/atlas_backend_foundation_storage_service.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/models/atlas_backend_foundation_record.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/services/atlas_backend_foundation_analytics_service.dart';

class AtlasBackendFoundationScreen extends StatefulWidget {
  const AtlasBackendFoundationScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasBackendFoundationModule initialModule;

  @override
  State<AtlasBackendFoundationScreen> createState() => _AtlasBackendFoundationScreenState();
}

class _AtlasBackendFoundationScreenState extends State<AtlasBackendFoundationScreen> {
  final storage = AtlasBackendFoundationStorageService();
  final analyticsService = const AtlasBackendFoundationAnalyticsService();
  late AtlasBackendFoundationModule selectedModule;
  List<AtlasBackendFoundationRecord> records = [];
  bool loading = true;
  String selectedFeature = 'Todos';

  @override
  void initState() {
    super.initState();
    selectedModule = widget.initialModule;
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final loaded = await storage.load(farmName: widget.farm.name, animalId: widget.animal.id);
    loaded.sort((a, b) => parseAtlasBackendDate(b.date).compareTo(parseAtlasBackendDate(a.date)));
    if (!mounted) return;
    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> persist() => storage.save(
    farmName: widget.farm.name,
    animalId: widget.animal.id,
    records: records,
  );

  List<AtlasBackendFoundationRecord> get visibleRecords => records.where((e) =>
    e.module == selectedModule && (selectedFeature == 'Todos' || e.feature == selectedFeature)
  ).toList();

  Future<void> openForm([AtlasBackendFoundationRecord? current]) async {
    final result = await showDialog<AtlasBackendFoundationRecord>(
      context: context,
      builder: (_) => _BackendForm(module: selectedModule, current: current),
    );
    if (result == null || !mounted) return;
    final index = records.indexWhere((e) => e.id == result.id);
    setState(() {
      if (index < 0) {
        records.add(result);
      } else {
        records[index] = result;
      }
    });
    await persist();
    await load();
  }

  Future<void> deleteRecord(AtlasBackendFoundationRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text('Deseja excluir "${record.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => records.removeWhere((e) => e.id == record.id));
    await persist();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = analyticsService.analyze(module: selectedModule, records: records);
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedModule.title),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                EnterpriseModuleHeader(
                  title: selectedModule.title,
                  subtitle: '${selectedModule.packageLabel} • ${widget.farm.name}',
                  icon: _moduleIcon(selectedModule),
                ),
                const SizedBox(height: 12),
                const Card(
                  color: Color(0xFFFFF8E1),
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Fase 36 — Backend real e arquitetura multempresa'),
                    subtitle: Text(
                      'Esta fase cria a camada funcional de planejamento, acompanhamento e integração. '
                      'A implantação real do servidor exige PostgreSQL, backend, credenciais e infraestrutura configurados.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AtlasBackendFoundationModule.values.map((module) => ChoiceChip(
                    label: Text(module.packageLabel),
                    selected: selectedModule == module,
                    onSelected: (_) => setState(() {
                      selectedModule = module;
                      selectedFeature = 'Todos';
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    EnterpriseMetricCard(title: 'Cobertura', value: '${analytics.coveragePercent.toStringAsFixed(0)}%', subtitle: 'Funcionalidades', icon: Icons.grid_view_outlined),
                    EnterpriseMetricCard(title: 'Score técnico', value: '${analytics.score}/100', subtitle: 'Maturidade', icon: Icons.analytics_outlined, warning: analytics.score < 50),
                    EnterpriseMetricCard(title: 'Registros', value: '${analytics.recordCount}', subtitle: 'Histórico', icon: Icons.fact_check_outlined),
                    EnterpriseMetricCard(title: 'Operacionais', value: '${analytics.operationalCount}', subtitle: 'Ativos', icon: Icons.task_alt_outlined),
                    EnterpriseMetricCard(title: 'Alertas', value: '${analytics.alertCount}', subtitle: 'Riscos técnicos', icon: Icons.warning_amber_outlined, warning: analytics.alertCount > 0),
                    EnterpriseMetricCard(title: 'Disponibilidade', value: '${analytics.averageAvailability.toStringAsFixed(1)}%', subtitle: 'Média', icon: Icons.cloud_done_outlined),
                    EnterpriseMetricCard(title: 'Taxa de erro', value: '${analytics.averageErrorRate.toStringAsFixed(1)}%', subtitle: 'Média', icon: Icons.error_outline),
                    EnterpriseMetricCard(title: 'Latência', value: '${analytics.averageLatency.toStringAsFixed(0)} ms', subtitle: 'Média', icon: Icons.speed_outlined),
                    EnterpriseMetricCard(title: 'Progresso', value: '${analytics.averageProgress.toStringAsFixed(0)}%', subtitle: 'Médio', icon: Icons.timeline_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                EnterpriseInsightCard(title: 'Recomendações Atlas', items: analytics.recommendations),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Todos', ...selectedModule.features].map((feature) => ChoiceChip(
                    label: Text(feature),
                    selected: selectedFeature == feature,
                    onSelected: (_) => setState(() => selectedFeature = feature),
                  )).toList(),
                ),
                const SizedBox(height: 18),
                if (visibleRecords.isEmpty)
                  const Card(child: ListTile(title: Text('Nenhum registro encontrado.')))
                else
                  ...visibleRecords.map((record) => Card(
                    child: ListTile(
                      leading: Icon(_moduleIcon(record.module)),
                      title: Text(record.title),
                      subtitle: Text('${record.feature}\n${record.date} • ${record.status} • ${record.progressPercent}%'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') openForm(record);
                          if (value == 'delete') deleteRecord(record);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Excluir')),
                        ],
                      ),
                    ),
                  )),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _BackendForm extends StatefulWidget {
  const _BackendForm({required this.module, this.current});
  final AtlasBackendFoundationModule module;
  final AtlasBackendFoundationRecord? current;

  @override
  State<_BackendForm> createState() => _BackendFormState();
}

class _BackendFormState extends State<_BackendForm> {
  final keyForm = GlobalKey<FormState>();
  late String feature;
  late String status;
  late String priority;
  late final Map<String, TextEditingController> c;

  @override
  void initState() {
    super.initState();
    final r = widget.current;
    feature = r?.feature ?? widget.module.features.first;
    status = r?.status ?? 'Planejado';
    priority = r?.priority ?? 'Média';
    c = {
      'title': TextEditingController(text: r?.title ?? ''),
      'date': TextEditingController(text: r?.date ?? formatAtlasBackendDate(DateTime.now())),
      'environment': TextEditingController(text: r?.environment ?? ''),
      'resource': TextEditingController(text: r?.resourceName ?? ''),
      'route': TextEditingController(text: r?.routeOrTable ?? ''),
      'company': TextEditingController(text: r?.companyName ?? ''),
      'owner': TextEditingController(text: r?.ownerName ?? ''),
      'progress': TextEditingController(text: r == null ? '' : r.progressPercent.toString()),
      'availability': TextEditingController(text: r == null ? '' : r.availabilityPercent.toString()),
      'error': TextEditingController(text: r == null ? '' : r.errorRatePercent.toString()),
      'latency': TextEditingController(text: r == null ? '' : r.latencyMs.toString()),
      'alerts': TextEditingController(text: r == null ? '' : r.alertCount.toString()),
      'notes': TextEditingController(text: r?.notes ?? ''),
    };
  }

  double d(String key) => double.tryParse(c[key]!.text.replaceAll(',', '.')) ?? 0;
  int i(String key) => int.tryParse(c[key]!.text) ?? 0;

  void save() {
    if (!keyForm.currentState!.validate()) return;
    final now = DateTime.now().toIso8601String();
    Navigator.pop(context, AtlasBackendFoundationRecord(
      id: widget.current?.id ?? 'backend_${DateTime.now().microsecondsSinceEpoch}',
      module: widget.module,
      feature: feature,
      title: c['title']!.text.trim(),
      date: c['date']!.text.trim(),
      status: status,
      priority: priority,
      environment: c['environment']!.text.trim(),
      resourceName: c['resource']!.text.trim(),
      routeOrTable: c['route']!.text.trim(),
      companyName: c['company']!.text.trim(),
      ownerName: c['owner']!.text.trim(),
      progressPercent: i('progress').clamp(0, 100),
      availabilityPercent: d('availability').clamp(0, 100),
      errorRatePercent: d('error').clamp(0, 100),
      latencyMs: d('latency'),
      alertCount: i('alerts') < 0 ? 0 : i('alerts'),
      notes: c['notes']!.text.trim(),
      createdAt: widget.current?.createdAt ?? now,
      updatedAt: now,
    ));
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration dec(String label) => InputDecoration(labelText: label);
    return AlertDialog(
      title: Text(widget.current == null ? 'Novo registro' : 'Editar registro'),
      content: SizedBox(
        width: 760,
        child: Form(
          key: keyForm,
          child: SingleChildScrollView(
            child: Column(children: [
              DropdownButtonFormField<String>(
                initialValue: feature,
                decoration: dec('Funcionalidade'),
                items: widget.module.features.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => feature = v!),
              ),
              TextFormField(
                controller: c['title'],
                decoration: dec('Título'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              ),
              for (final item in [
                ('date', 'Data'),
                ('environment', 'Ambiente'),
                ('resource', 'Recurso ou serviço'),
                ('route', 'Rota, tabela ou coleção'),
                ('company', 'Empresa'),
                ('owner', 'Responsável'),
                ('progress', 'Progresso (0 a 100%)'),
                ('availability', 'Disponibilidade (0 a 100%)'),
                ('error', 'Taxa de erro (0 a 100%)'),
                ('latency', 'Latência (ms)'),
                ('alerts', 'Alertas'),
              ])
                TextFormField(controller: c[item.$1], decoration: dec(item.$2)),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: dec('Situação'),
                items: const ['Planejado', 'Ativo', 'Validado', 'Concluído', 'Disponível', 'Atenção', 'Crítico', 'Bloqueado', 'Indisponível']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => status = v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: dec('Prioridade'),
                items: const ['Baixa', 'Média', 'Alta', 'Urgente']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => priority = v!),
              ),
              TextFormField(controller: c['notes'], minLines: 3, maxLines: 6, decoration: dec('Observações')),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: save, child: const Text('Salvar')),
      ],
    );
  }
}

IconData _moduleIcon(AtlasBackendFoundationModule module) => switch (module) {
  AtlasBackendFoundationModule.backendFoundation => Icons.dns_outlined,
  AtlasBackendFoundationModule.environmentConfiguration => Icons.settings_suggest_outlined,
  AtlasBackendFoundationModule.postgresqlDatabase => Icons.storage_outlined,
  AtlasBackendFoundationModule.versionedMigrations => Icons.schema_outlined,
  AtlasBackendFoundationModule.multiCompanyArchitecture => Icons.account_tree_outlined,
  AtlasBackendFoundationModule.usersCompaniesApi => Icons.business_outlined,
  AtlasBackendFoundationModule.farmsGroupsApi => Icons.agriculture_outlined,
  AtlasBackendFoundationModule.animalsApi => Icons.pets_outlined,
  AtlasBackendFoundationModule.livestockEventsApi => Icons.event_note_outlined,
  AtlasBackendFoundationModule.backendAdministrationCenter => Icons.admin_panel_settings_outlined,
};
