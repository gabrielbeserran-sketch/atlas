import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_veterinary_ai/data/services/atlas_veterinary_case_storage_service.dart';
import 'package:projeto_atlas/features/atlas_veterinary_ai/domain/models/atlas_veterinary_case.dart';
import 'package:projeto_atlas/features/atlas_veterinary_ai/domain/services/atlas_veterinary_ai_engine.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasVeterinaryAiScreen extends StatefulWidget {
  const AtlasVeterinaryAiScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AtlasVeterinaryAiScreen> createState() =>
      _AtlasVeterinaryAiScreenState();
}

class _AtlasVeterinaryAiScreenState extends State<AtlasVeterinaryAiScreen> {
  final AtlasVeterinaryCaseStorageService storage =
      AtlasVeterinaryCaseStorageService();
  final AtlasVeterinaryAiEngine engine = const AtlasVeterinaryAiEngine();

  List<AtlasVeterinaryCase> cases = [];
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
      (first, second) => parseAtlasVeterinaryDate(
        second.date,
      ).compareTo(parseAtlasVeterinaryDate(first.date)),
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

  Future<void> openForm([AtlasVeterinaryCase? current]) async {
    final result = await showDialog<AtlasVeterinaryCase>(
      context: context,
      builder: (context) => _VeterinaryCaseForm(current: current),
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

  Future<void> deleteCase(AtlasVeterinaryCase clinicalCase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: Text('Deseja excluir "${clinicalCase.title}"?'),
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
      cases.removeWhere((item) => item.id == clinicalCase.id);
    });

    await persist();
  }

  int get emergencyCount {
    return cases.where((item) {
      return engine.assess(item).triageScore >= 70;
    }).length;
  }

  int get urgentCount {
    return cases.where((item) {
      final score = engine.assess(item).triageScore;
      return score >= 40 && score < 70;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Veterinária'),
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
        label: const Text('Nova avaliação'),
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
                        title: 'Inteligência Veterinária',
                        subtitle:
                            'Pacote 51 • Triagem, sinais, hipóteses e próximos exames.',
                        icon: Icons.medical_services_outlined,
                      ),
                      const SizedBox(height: 14),
                      Card(
                        color: const Color(0xFFFFF8E1),
                        child: const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text(
                            'Ferramenta de apoio, não de diagnóstico',
                          ),
                          subtitle: Text(
                            'As hipóteses e ações não substituem exame clínico, '
                            'diagnóstico, prescrição ou acompanhamento do médico-veterinário.',
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
                            subtitle: 'Histórico clínico assistido',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Emergências',
                            value: '$emergencyCount',
                            subtitle: 'Triagem igual ou superior a 70',
                            icon: Icons.emergency_outlined,
                            warning: emergencyCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Urgentes',
                            value: '$urgentCount',
                            subtitle: 'Triagem entre 40 e 69',
                            icon: Icons.priority_high_outlined,
                            warning: urgentCount > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Avaliações clínicas assistidas',
                        'Resultados ordenados da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (cases.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.medical_information_outlined),
                            title: Text('Nenhuma avaliação cadastrada.'),
                            subtitle: Text(
                              'Registre sinais e exame físico para iniciar a triagem assistida.',
                            ),
                          ),
                        )
                      else
                        ...cases.map((clinicalCase) {
                          final assessment = engine.assess(clinicalCase);

                          return _AssessmentCard(
                            clinicalCase: clinicalCase,
                            assessment: assessment,
                            onEdit: () => openForm(clinicalCase),
                            onDelete: () => deleteCase(clinicalCase),
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

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({
    required this.clinicalCase,
    required this.assessment,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasVeterinaryCase clinicalCase;
  final AtlasVeterinaryAssessment assessment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (assessment.triageLevel) {
      'Emergência' => Colors.red.shade800,
      'Urgente' => Colors.deepOrange.shade800,
      'Prioritário' => Colors.orange.shade800,
      _ => Colors.green.shade800,
    };

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.monitor_heart_outlined, color: color),
        ),
        title: Text(clinicalCase.title),
        subtitle: Text(
          '${clinicalCase.date} • '
          '${assessment.triageLevel} '
          '(${assessment.triageScore}/100) • '
          'confiança ${assessment.confidencePercent}%',
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(assessment.summary),
          ),
          if (assessment.redFlags.isNotEmpty) ...[
            const SizedBox(height: 14),
            EnterpriseInsightCard(
              title: 'Sinais de alerta',
              icon: Icons.warning_amber_outlined,
              items: assessment.redFlags,
            ),
          ],
          const SizedBox(height: 14),
          EnterpriseInsightCard(
            title: 'Ações imediatas de apoio',
            icon: Icons.assignment_outlined,
            items: assessment.immediateActions,
          ),
          const SizedBox(height: 14),
          if (assessment.hypotheses.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Não há evidências suficientes para hipóteses.'),
              subtitle: Text(
                'Complete o exame físico e solicite avaliação veterinária.',
              ),
            )
          else
            ...assessment.hypotheses.map(
              (hypothesis) => Card(
                child: ListTile(
                  title: Text(hypothesis.name),
                  subtitle: Text(
                    '${hypothesis.score}% de compatibilidade com os sinais informados\n'
                    '${hypothesis.reasons.join(' • ')}\n'
                    'Próximas verificações: ${hypothesis.nextChecks.join(' • ')}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VeterinaryCaseForm extends StatefulWidget {
  const _VeterinaryCaseForm({this.current});

  final AtlasVeterinaryCase? current;

  @override
  State<_VeterinaryCaseForm> createState() => _VeterinaryCaseFormState();
}

class _VeterinaryCaseFormState extends State<_VeterinaryCaseForm> {
  static const availableSymptoms = [
    'Apatia',
    'Tosse',
    'Secreção nasal',
    'Dificuldade respiratória',
    'Diarreia',
    'Distensão abdominal',
    'Redução da ruminação',
    'Claudicação',
    'Edema de membro',
    'Fraqueza',
    'Tremores',
    'Linfonodos aumentados',
    'Sangramento',
  ];

  final formKey = GlobalKey<FormState>();

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController temperature;
  late final TextEditingController heartRate;
  late final TextEditingController respiratoryRate;
  late final TextEditingController durationHours;
  late final TextEditingController notes;
  late final TextEditingController responsible;

  late String status;
  late String appetite;
  late String hydration;
  late String locomotion;
  late Set<String> symptoms;

  @override
  void initState() {
    super.initState();

    final current = widget.current;

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasVeterinaryDate(DateTime.now()),
    );
    temperature = TextEditingController(
      text: current == null || current.temperatureCelsius == 0
          ? ''
          : current.temperatureCelsius.toString(),
    );
    heartRate = TextEditingController(
      text: current == null || current.heartRateBpm == 0
          ? ''
          : current.heartRateBpm.toString(),
    );
    respiratoryRate = TextEditingController(
      text: current == null || current.respiratoryRateBpm == 0
          ? ''
          : current.respiratoryRateBpm.toString(),
    );
    durationHours = TextEditingController(
      text: current == null || current.durationHours == 0
          ? ''
          : current.durationHours.toString(),
    );
    notes = TextEditingController(text: current?.notes ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');

    status = current?.status ?? 'Em avaliação';
    appetite = current?.appetite ?? 'Normal';
    hydration = current?.hydration ?? 'Normal';
    locomotion = current?.locomotion ?? 'Normal';
    symptoms = current?.symptoms.toSet() ?? <String>{};
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    temperature.dispose();
    heartRate.dispose();
    respiratoryRate.dispose();
    durationHours.dispose();
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
    final parsed = parseAtlasVeterinaryDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasVeterinaryDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasVeterinaryCase(
        id: current?.id ?? 'vet_ai_${DateTime.now().microsecondsSinceEpoch}',
        date: date.text.trim(),
        title: title.text.trim(),
        status: status,
        symptoms: symptoms.toList(growable: false),
        temperatureCelsius: decimal(temperature),
        heartRateBpm: integer(heartRate),
        respiratoryRateBpm: integer(respiratoryRate),
        appetite: appetite,
        hydration: hydration,
        locomotion: locomotion,
        durationHours: integer(durationHours),
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
            ? 'Nova avaliação veterinária'
            : 'Editar avaliação veterinária',
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Título da avaliação',
                  ),
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
                            'Em avaliação',
                            'Aguardando veterinário',
                            'Em acompanhamento',
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
                const SizedBox(height: 14),
                const Text(
                  'Sinais observados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSymptoms
                      .map((symptom) {
                        final selected = symptoms.contains(symptom);
                        return FilterChip(
                          label: Text(symptom),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                symptoms.add(symptom);
                              } else {
                                symptoms.remove(symptom);
                              }
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: temperature,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Temperatura (°C)',
                  ),
                ),
                TextFormField(
                  controller: heartRate,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Frequência cardíaca (bpm)',
                  ),
                ),
                TextFormField(
                  controller: respiratoryRate,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Frequência respiratória (mov/min)',
                  ),
                ),
                TextFormField(
                  controller: durationHours,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duração aproximada dos sinais (horas)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: appetite,
                  decoration: const InputDecoration(labelText: 'Apetite'),
                  items: const ['Normal', 'Reduzido', 'Ausente']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => appetite = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: hydration,
                  decoration: const InputDecoration(labelText: 'Hidratação'),
                  items: const ['Normal', 'Leve', 'Moderada', 'Grave']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => hydration = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: locomotion,
                  decoration: const InputDecoration(labelText: 'Locomoção'),
                  items:
                      const [
                            'Normal',
                            'Dificuldade',
                            'Não consegue ficar em pé',
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
                      setState(() => locomotion = value);
                    }
                  },
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(
                    labelText: 'Responsável pelo registro',
                  ),
                ),
                TextFormField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Histórico, observações e contexto',
                  ),
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
        FilledButton(onPressed: save, child: const Text('Avaliar')),
      ],
    );
  }
}
