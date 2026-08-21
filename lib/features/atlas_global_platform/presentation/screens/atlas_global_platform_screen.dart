import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_global_platform/data/services/atlas_global_platform_storage_service.dart';
import 'package:projeto_atlas/features/atlas_global_platform/domain/models/atlas_global_platform_record.dart';
import 'package:projeto_atlas/features/atlas_global_platform/domain/services/atlas_global_platform_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasGlobalPlatformScreen extends StatefulWidget {
  const AtlasGlobalPlatformScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AtlasGlobalPlatformScreen> createState() =>
      _AtlasGlobalPlatformScreenState();
}

class _AtlasGlobalPlatformScreenState extends State<AtlasGlobalPlatformScreen> {
  final AtlasGlobalPlatformStorageService storage =
      AtlasGlobalPlatformStorageService();
  final AtlasGlobalPlatformAnalyticsService analyticsService =
      const AtlasGlobalPlatformAnalyticsService();

  List<AtlasGlobalPlatformRecord> records = [];
  bool loading = true;
  AtlasGlobalPlatformFeature? selectedFeature;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final loaded = await storage.load(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseAtlasGlobalDate(
        second.date,
      ).compareTo(parseAtlasGlobalDate(first.date)),
    );

    if (!mounted) return;

    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> persist() {
    return storage.save(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      records: records,
    );
  }

  List<AtlasGlobalPlatformRecord> get visibleRecords {
    if (selectedFeature == null) return records;

    return records
        .where((record) => record.feature == selectedFeature)
        .toList(growable: false);
  }

  Future<void> openForm([AtlasGlobalPlatformRecord? current]) async {
    final result = await showDialog<AtlasGlobalPlatformRecord>(
      context: context,
      builder: (context) =>
          _GlobalRecordForm(record: current, initialFeature: selectedFeature),
    );

    if (result == null || !mounted) return;

    final index = records.indexWhere((record) => record.id == result.id);

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

  Future<void> deleteRecord(AtlasGlobalPlatformRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text('Deseja excluir "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      records.removeWhere((item) => item.id == record.id);
    });

    await persist();
  }

  int featureCount(AtlasGlobalPlatformFeature feature) {
    return records.where((record) => record.feature == feature).length;
  }

  int featureAlerts(AtlasGlobalPlatformFeature feature) {
    return records
        .where((record) => record.feature == feature && record.isCritical)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final analytics = analyticsService.analyze(records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plataforma Atlas Global'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title: 'Plataforma Atlas Global',
                        subtitle:
                            'Multiempresa, usuários, '
                            'integrações, API e Command Center.',
                        icon: Icons.public_outlined,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Cobertura',
                            value:
                                '${analytics.coveragePercent.toStringAsFixed(0)}%',
                            subtitle: 'Funcionalidades implantadas',
                            icon: Icons.grid_view_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score global',
                            value: '${analytics.score}/100',
                            subtitle: analytics.score >= 70
                                ? 'Plataforma consistente'
                                : 'Requer evolução',
                            icon: Icons.analytics_outlined,
                            warning: analytics.score < 50,
                          ),
                          EnterpriseMetricCard(
                            title: 'Registros',
                            value: '${analytics.recordCount}',
                            subtitle: 'Componentes cadastrados',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Operacionais',
                            value: '${analytics.operationalCount}',
                            subtitle: 'Ativos, conectados ou homologados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Crítico, atenção, bloqueado ou offline',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Média principal',
                            value: analytics.averagePrimaryValue
                                .toStringAsFixed(2)
                                .replaceAll('.', ','),
                            subtitle: 'Indicador configurável',
                            icon: Icons.calculate_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Atlas Command Center',
                        'Visão consolidada das cinco camadas '
                            'da Plataforma Global.',
                      ),
                      const SizedBox(height: 12),
                      _CommandCenterGrid(
                        records: records,
                        selectedFeature: selectedFeature,
                        onSelected: (feature) {
                          setState(() {
                            selectedFeature = selectedFeature == feature
                                ? null
                                : feature;
                          });
                        },
                        featureCount: featureCount,
                        featureAlerts: featureAlerts,
                      ),
                      const SizedBox(height: 22),
                      EnterpriseInsightCard(
                        title: 'Recomendações de plataforma',
                        items: analytics.recommendations,
                      ),
                      const SizedBox(height: 22),
                      _FeatureFilter(
                        selected: selectedFeature,
                        onSelected: (feature) {
                          setState(() {
                            selectedFeature = feature;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      const EnterpriseSectionTitle(
                        'Registros da Plataforma Global',
                        'Governança, integrações e componentes '
                            'ordenados pela data.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.public_outlined),
                            title: Text('Nenhum registro encontrado.'),
                            subtitle: Text(
                              'Cadastre o primeiro componente '
                              'deste recurso.',
                            ),
                          ),
                        )
                      else
                        ...visibleRecords.map(
                          (record) => _RecordCard(
                            record: record,
                            onEdit: () => openForm(record),
                            onDelete: () => deleteRecord(record),
                          ),
                        ),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CommandCenterGrid extends StatelessWidget {
  const _CommandCenterGrid({
    required this.records,
    required this.selectedFeature,
    required this.onSelected,
    required this.featureCount,
    required this.featureAlerts,
  });

  final List<AtlasGlobalPlatformRecord> records;
  final AtlasGlobalPlatformFeature? selectedFeature;
  final ValueChanged<AtlasGlobalPlatformFeature> onSelected;
  final int Function(AtlasGlobalPlatformFeature) featureCount;
  final int Function(AtlasGlobalPlatformFeature) featureAlerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 650
            ? 3
            : 1;

        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AtlasGlobalPlatformFeature.values
              .map((feature) {
                final selected = feature == selectedFeature;
                final alerts = featureAlerts(feature);

                return SizedBox(
                  width: width,
                  child: Card(
                    color: selected ? const Color(0xFFE4F0E0) : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelected(feature),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Icon(_featureIcon(feature)),
                                ),
                                const Spacer(),
                                if (alerts > 0)
                                  Badge(
                                    label: Text('$alerts'),
                                    child: const Icon(Icons.warning_amber),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              feature.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              feature.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${featureCount(feature)} registro(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _FeatureFilter extends StatelessWidget {
  const _FeatureFilter({required this.selected, required this.onSelected});

  final AtlasGlobalPlatformFeature? selected;
  final ValueChanged<AtlasGlobalPlatformFeature?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        ...AtlasGlobalPlatformFeature.values.map(
          (feature) => ChoiceChip(
            avatar: Icon(_featureIcon(feature), size: 18),
            label: Text(feature.title),
            selected: selected == feature,
            onSelected: (_) => onSelected(feature),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasGlobalPlatformRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Crítico' || 'Bloqueado' || 'Offline' => Colors.red.shade700,
      'Atenção' => Colors.orange.shade800,
      'Ativo' ||
      'Conectado' ||
      'Homologado' ||
      'Concluído' => Colors.green.shade800,
      _ => Colors.blueGrey,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_featureIcon(record.feature), color: color),
        ),
        title: Text(record.title),
        subtitle: Text(
          '${record.feature.title}\n'
          '${record.date} • ${record.status}'
          '${record.entityName.isEmpty ? '' : ' • ${record.entityName}'}'
          '${record.roleOrScope.isEmpty ? '' : '\n${record.roleOrScope}'}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}

class _GlobalRecordForm extends StatefulWidget {
  const _GlobalRecordForm({this.record, this.initialFeature});

  final AtlasGlobalPlatformRecord? record;
  final AtlasGlobalPlatformFeature? initialFeature;

  @override
  State<_GlobalRecordForm> createState() => _GlobalRecordFormState();
}

class _GlobalRecordFormState extends State<_GlobalRecordForm> {
  final formKey = GlobalKey<FormState>();

  late AtlasGlobalPlatformFeature feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController entityName;
  late final TextEditingController roleOrScope;
  late final TextEditingController primaryValue;
  late final TextEditingController secondaryValue;
  late final TextEditingController unit;
  late final TextEditingController endpointOrReference;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    feature =
        record?.feature ??
        widget.initialFeature ??
        AtlasGlobalPlatformFeature.multiCompany;

    status = record?.status ?? 'Planejado';

    title = TextEditingController(text: record?.title ?? '');
    date = TextEditingController(
      text: record?.date ?? formatAtlasGlobalDate(DateTime.now()),
    );
    entityName = TextEditingController(text: record?.entityName ?? '');
    roleOrScope = TextEditingController(text: record?.roleOrScope ?? '');
    primaryValue = TextEditingController(
      text: record == null ? '' : record.primaryValue.toString(),
    );
    secondaryValue = TextEditingController(
      text: record == null ? '' : record.secondaryValue.toString(),
    );
    unit = TextEditingController(text: record?.unit ?? '');
    endpointOrReference = TextEditingController(
      text: record?.endpointOrReference ?? '',
    );
    notes = TextEditingController(text: record?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    entityName.dispose();
    roleOrScope.dispose();
    primaryValue.dispose();
    secondaryValue.dispose();
    unit.dispose();
    endpointOrReference.dispose();
    notes.dispose();
    super.dispose();
  }

  double number(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  Future<void> chooseDate() async {
    final parsed = parseAtlasGlobalDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasGlobalDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.record;

    Navigator.pop(
      context,
      AtlasGlobalPlatformRecord(
        id: current?.id ?? 'global_${DateTime.now().microsecondsSinceEpoch}',
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        entityName: entityName.text.trim(),
        roleOrScope: roleOrScope.text.trim(),
        primaryValue: number(primaryValue),
        secondaryValue: number(secondaryValue),
        unit: unit.text.trim(),
        endpointOrReference: endpointOrReference.text.trim(),
        notes: notes.text.trim(),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.record == null
            ? 'Novo componente global'
            : 'Editar componente global',
      ),
      content: SizedBox(
        width: 700,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<AtlasGlobalPlatformFeature>(
                  initialValue: feature,
                  decoration: const InputDecoration(
                    labelText: 'Funcionalidade',
                  ),
                  items: AtlasGlobalPlatformFeature.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.title),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => feature = value);
                    }
                  },
                ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o título.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: date,
                  readOnly: true,
                  onTap: chooseDate,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items:
                      const [
                            'Planejado',
                            'Em implantação',
                            'Ativo',
                            'Conectado',
                            'Homologado',
                            'Concluído',
                            'Atenção',
                            'Crítico',
                            'Bloqueado',
                            'Offline',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => status = value);
                    }
                  },
                ),
                TextFormField(
                  controller: entityName,
                  decoration: const InputDecoration(
                    labelText: 'Empresa, usuário, parceiro ou integração',
                  ),
                ),
                TextFormField(
                  controller: roleOrScope,
                  decoration: const InputDecoration(
                    labelText: 'Perfil, permissão, escopo ou finalidade',
                  ),
                ),
                TextFormField(
                  controller: primaryValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Indicador principal',
                  ),
                ),
                TextFormField(
                  controller: secondaryValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Indicador secundário',
                  ),
                ),
                TextFormField(
                  controller: unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    hintText:
                        'Ex.: usuários, empresas, req/min, %, integrações',
                  ),
                ),
                TextFormField(
                  controller: endpointOrReference,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint, identificador ou referência',
                  ),
                ),
                TextFormField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: save, child: const Text('Salvar')),
      ],
    );
  }
}

IconData _featureIcon(AtlasGlobalPlatformFeature feature) {
  return switch (feature) {
    AtlasGlobalPlatformFeature.multiCompany => Icons.domain_outlined,
    AtlasGlobalPlatformFeature.advancedMultiUser => Icons.people_outline,
    AtlasGlobalPlatformFeature.integrationMarketplace =>
      Icons.extension_outlined,
    AtlasGlobalPlatformFeature.publicApi => Icons.api_outlined,
    AtlasGlobalPlatformFeature.commandCenter =>
      Icons.dashboard_customize_outlined,
  };
}
