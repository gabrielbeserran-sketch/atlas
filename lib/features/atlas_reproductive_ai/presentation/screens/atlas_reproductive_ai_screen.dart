import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_reproductive_ai/data/services/atlas_reproductive_prediction_storage_service.dart';
import 'package:projeto_atlas/features/atlas_reproductive_ai/domain/models/atlas_reproductive_prediction_case.dart';
import 'package:projeto_atlas/features/atlas_reproductive_ai/domain/services/atlas_reproductive_ai_engine.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasReproductiveAiScreen extends StatefulWidget {
  const AtlasReproductiveAiScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AtlasReproductiveAiScreen> createState() =>
      _AtlasReproductiveAiScreenState();
}

class _AtlasReproductiveAiScreenState extends State<AtlasReproductiveAiScreen> {
  final AtlasReproductivePredictionStorageService storage =
      AtlasReproductivePredictionStorageService();
  final AtlasReproductiveAiEngine engine = const AtlasReproductiveAiEngine();

  List<AtlasReproductivePredictionCase> cases = [];
  bool loading = true;

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
      (first, second) => parseAtlasReproductiveDate(
        second.date,
      ).compareTo(parseAtlasReproductiveDate(first.date)),
    );

    if (!mounted) return;

    setState(() {
      cases = loaded;
      loading = false;
    });
  }

  Future<void> persist() {
    return storage.save(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      cases: cases,
    );
  }

  Future<void> openForm([AtlasReproductivePredictionCase? current]) async {
    final result = await showDialog<AtlasReproductivePredictionCase>(
      context: context,
      builder: (context) => _ReproductivePredictionForm(current: current),
    );

    if (result == null || !mounted) return;

    final index = cases.indexWhere((item) => item.id == result.id);

    setState(() {
      if (index < 0) {
        cases.add(result);
      } else {
        cases[index] = result;
      }
    });

    await persist();
    await load();
  }

  Future<void> deleteCase(AtlasReproductivePredictionCase item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: Text('Deseja excluir "${item.title}"?'),
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
      cases.removeWhere((current) => current.id == item.id);
    });

    await persist();
  }

  int get highPriorityCount {
    return cases.where((item) {
      return engine.predict(item).priority == 'Alta';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Reprodutiva'),
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
        label: const Text('Nova previsão'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title: 'Inteligência Reprodutiva',
                        subtitle:
                            'Cio, prenhez, parto e probabilidade de sucesso da IATF.',
                        icon: Icons.favorite_outline,
                      ),
                      const SizedBox(height: 14),
                      Card(
                        color: const Color(0xFFFFF8E1),
                        child: const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Predições de apoio técnico'),
                          subtitle: Text(
                            'Os percentuais são estimativas explicáveis e não substituem exame, protocolo, diagnóstico ou decisão do médico-veterinário.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Avaliações',
                            value: '${cases.length}',
                            subtitle: 'Histórico preditivo',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alta prioridade',
                            value: '$highPriorityCount',
                            subtitle: 'Cenários com menor probabilidade',
                            icon: Icons.priority_high_outlined,
                            warning: highPriorityCount > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Previsões reprodutivas',
                        'Resultados ordenados da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (cases.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.favorite_outline),
                            title: Text('Nenhuma previsão cadastrada.'),
                            subtitle: Text(
                              'Cadastre condição corporal, pós-parto, ciclo e protocolo.',
                            ),
                          ),
                        )
                      else
                        ...cases.map((item) {
                          final prediction = engine.predict(item);

                          return _PredictionCard(
                            item: item,
                            prediction: prediction,
                            onEdit: () => openForm(item),
                            onDelete: () => deleteCase(item),
                          );
                        }),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.item,
    required this.prediction,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasReproductivePredictionCase item;
  final AtlasReproductivePrediction prediction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (prediction.priority) {
      'Alta' => Colors.red.shade800,
      'Média' => Colors.orange.shade800,
      _ => Colors.green.shade800,
    };

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.favorite_outline, color: color),
        ),
        title: Text(item.title),
        subtitle: Text(
          '${item.date} • prioridade ${prediction.priority} • '
          'confiança ${prediction.confidencePercent}%',
        ),
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
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              EnterpriseMetricCard(
                title: 'Probabilidade de cio',
                value: '${prediction.heatProbabilityPercent}%',
                subtitle: 'Estimativa atual',
                icon: Icons.monitor_heart_outlined,
              ),
              EnterpriseMetricCard(
                title: 'Probabilidade de prenhez',
                value: '${prediction.pregnancyProbabilityPercent}%',
                subtitle: 'Estimativa atual',
                icon: Icons.pregnant_woman_outlined,
              ),
              EnterpriseMetricCard(
                title: 'Sucesso da IATF',
                value: '${prediction.iatfSuccessProbabilityPercent}%',
                subtitle: 'Estimativa do protocolo',
                icon: Icons.science_outlined,
              ),
              EnterpriseMetricCard(
                title: 'Parto previsto',
                value: prediction.expectedCalvingDate == null
                    ? 'Não calculado'
                    : formatAtlasReproductiveDate(
                        prediction.expectedCalvingDate!,
                      ),
                subtitle: 'Baseado na data informada',
                icon: Icons.event_outlined,
              ),
            ],
          ),
          if (prediction.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 14),
            EnterpriseInsightCard(
              title: 'Fatores de risco',
              icon: Icons.warning_amber_outlined,
              items: prediction.riskFactors,
            ),
          ],
          if (prediction.positiveFactors.isNotEmpty) ...[
            const SizedBox(height: 14),
            EnterpriseInsightCard(
              title: 'Fatores favoráveis',
              icon: Icons.check_circle_outline,
              items: prediction.positiveFactors,
            ),
          ],
          const SizedBox(height: 14),
          EnterpriseInsightCard(
            title: 'Recomendações',
            icon: Icons.assignment_outlined,
            items: prediction.recommendations,
          ),
        ],
      ),
    );
  }
}

class _ReproductivePredictionForm extends StatefulWidget {
  const _ReproductivePredictionForm({this.current});

  final AtlasReproductivePredictionCase? current;

  @override
  State<_ReproductivePredictionForm> createState() =>
      _ReproductivePredictionFormState();
}

class _ReproductivePredictionFormState
    extends State<_ReproductivePredictionForm> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController bodyCondition;
  late final TextEditingController daysPostpartum;
  late final TextEditingController daysSinceService;
  late final TextEditingController serviceCount;
  late final TextEditingController notes;
  late final TextEditingController responsible;

  late String status;
  late String category;
  late String protocolType;
  late String semenQuality;
  late String technicianExperience;
  late String healthRisk;
  late bool cycleRegular;
  late bool heatSigns;
  late bool previousPregnancyLoss;

  @override
  void initState() {
    super.initState();

    final current = widget.current;

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasReproductiveDate(DateTime.now()),
    );
    bodyCondition = TextEditingController(
      text: current == null || current.bodyConditionScore == 0
          ? ''
          : current.bodyConditionScore.toString(),
    );
    daysPostpartum = TextEditingController(
      text: current == null || current.daysPostpartum == 0
          ? ''
          : current.daysPostpartum.toString(),
    );
    daysSinceService = TextEditingController(
      text: current == null ? '' : current.daysSinceLastService.toString(),
    );
    serviceCount = TextEditingController(
      text: current == null || current.serviceCount == 0
          ? ''
          : current.serviceCount.toString(),
    );
    notes = TextEditingController(text: current?.notes ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');

    status = current?.status ?? 'Em avaliação';
    category = current?.category ?? 'Matriz';
    protocolType = current?.protocolType ?? 'Não informado';
    semenQuality = current?.semenQuality ?? 'Não informado';
    technicianExperience = current?.technicianExperience ?? 'Intermediária';
    healthRisk = current?.healthRisk ?? 'Baixo';
    cycleRegular = current?.cycleRegular ?? false;
    heatSigns = current?.heatSigns ?? false;
    previousPregnancyLoss = current?.previousPregnancyLoss ?? false;
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    bodyCondition.dispose();
    daysPostpartum.dispose();
    daysSinceService.dispose();
    serviceCount.dispose();
    notes.dispose();
    responsible.dispose();
    super.dispose();
  }

  double decimal(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  int integer(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> chooseDate() async {
    final parsed = parseAtlasReproductiveDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasReproductiveDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasReproductivePredictionCase(
        id: current?.id ?? 'repro_ai_${DateTime.now().microsecondsSinceEpoch}',
        date: date.text.trim(),
        title: title.text.trim(),
        status: status,
        category: category,
        bodyConditionScore: decimal(bodyCondition),
        daysPostpartum: integer(daysPostpartum),
        daysSinceLastService: integer(daysSinceService),
        serviceCount: integer(serviceCount),
        cycleRegular: cycleRegular,
        heatSigns: heatSigns,
        previousPregnancyLoss: previousPregnancyLoss,
        protocolType: protocolType,
        semenQuality: semenQuality,
        technicianExperience: technicianExperience,
        healthRisk: healthRisk,
        notes: notes.text.trim(),
        responsible: responsible.text.trim(),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.current == null
            ? 'Nova previsão reprodutiva'
            : 'Editar previsão reprodutiva',
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                    labelText: 'Data do registro/serviço',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items:
                      const [
                            'Em avaliação',
                            'Servida',
                            'Aguardando diagnóstico',
                            'Prenhe',
                            'Vazia',
                            'Concluído',
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
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items:
                      const [
                            'Novilha',
                            'Matriz',
                            'Primípara',
                            'Doadora',
                            'Receptora',
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
                      setState(() => category = value);
                    }
                  },
                ),
                TextFormField(
                  controller: bodyCondition,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Escore corporal',
                  ),
                ),
                TextFormField(
                  controller: daysPostpartum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dias pós-parto',
                  ),
                ),
                TextFormField(
                  controller: daysSinceService,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dias desde o último serviço',
                  ),
                ),
                TextFormField(
                  controller: serviceCount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de serviços',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ciclo regular'),
                  value: cycleRegular,
                  onChanged: (value) {
                    setState(() => cycleRegular = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sinais de cio observados'),
                  value: heatSigns,
                  onChanged: (value) {
                    setState(() => heatSigns = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Histórico de perda gestacional'),
                  value: previousPregnancyLoss,
                  onChanged: (value) {
                    setState(() => previousPregnancyLoss = value);
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: protocolType,
                  decoration: const InputDecoration(labelText: 'Protocolo'),
                  items:
                      const [
                            'Não informado',
                            'IATF',
                            'IA convencional',
                            'Monta natural',
                            'Transferência de embrião',
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
                      setState(() => protocolType = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: semenQuality,
                  decoration: const InputDecoration(
                    labelText: 'Qualidade do sêmen',
                  ),
                  items: const ['Não informado', 'Alta', 'Média', 'Baixa']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => semenQuality = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: technicianExperience,
                  decoration: const InputDecoration(
                    labelText: 'Experiência técnica',
                  ),
                  items: const ['Alta', 'Intermediária', 'Baixa']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => technicianExperience = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: healthRisk,
                  decoration: const InputDecoration(
                    labelText: 'Risco sanitário',
                  ),
                  items: const ['Baixo', 'Moderado', 'Alto']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => healthRisk = value);
                    }
                  },
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(labelText: 'Responsável'),
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
        FilledButton(onPressed: save, child: const Text('Calcular previsão')),
      ],
    );
  }
}
