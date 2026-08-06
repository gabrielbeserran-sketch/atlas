import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_people_management_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_people_management_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';

class AtlasPeopleManagementScreen extends StatefulWidget {
  const AtlasPeopleManagementScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasPeopleManagementScreen> createState() =>
      _AtlasPeopleManagementScreenState();
}

class _AtlasPeopleManagementScreenState
    extends State<AtlasPeopleManagementScreen> {
  final service = AtlasPeopleManagementService.instance;

  List<AtlasTeamMember> members = [];
  List<AtlasWorkShift> shifts = [];
  List<AtlasTrainingRecord> trainings = [];
  List<AtlasPerformanceReview> reviews = [];
  AtlasPeopleExecutiveSnapshot? snapshot;
  List<String> recommendations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    members = await service.loadMembers(
      farmName: widget.actionController.farmName,
    );
    shifts = await service.loadShifts(
      farmName: widget.actionController.farmName,
    );
    trainings = await service.loadTrainings(
      farmName: widget.actionController.farmName,
    );
    reviews = await service.loadReviews(
      farmName: widget.actionController.farmName,
    );
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    recommendations = await service.buildRecommendations(
      farmName: widget.actionController.farmName,
      snapshot: snapshot!,
    );
    if (mounted) setState(() => loading = false);
  }

  String memberName(String id) {
    for (final member in members) {
      if (member.id == id) return member.name;
    }
    return 'Colaborador';
  }

  Future<void> _openTeam() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasTeamManagementScreen(
          actionController: widget.actionController,
        ),
      ),
    );
    await _load();
  }

  Future<void> _addShift() async {
    if (members.isEmpty) return;
    var memberId = members.first.id;
    var startAt = DateTime.now();
    var endAt = DateTime.now().add(const Duration(hours: 8));
    var status = AtlasWorkShiftStatus.planned;
    final activity = TextEditingController();
    final location = TextEditingController();
    final notes = TextEditingController();

    final result = await showDialog<AtlasWorkShift>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova escala'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador',
                      border: OutlineInputBorder(),
                    ),
                    items: members
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => memberId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: activity,
                    decoration: const InputDecoration(
                      labelText: 'Atividade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  _dateTimeTile(
                    context: dialogContext,
                    title: 'Início',
                    value: startAt,
                    onChanged: (value) {
                      setDialogState(() => startAt = value);
                    },
                  ),
                  _dateTimeTile(
                    context: dialogContext,
                    title: 'Fim',
                    value: endAt,
                    onChanged: (value) {
                      setDialogState(() => endAt = value);
                    },
                  ),
                  DropdownButtonFormField<AtlasWorkShiftStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Situação',
                      border: OutlineInputBorder(),
                    ),
                    items: AtlasWorkShiftStatus.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              atlasWorkShiftStatusLabel(item),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasWorkShift(
                    id: 'work_shift_${now.microsecondsSinceEpoch}',
                    memberId: memberId,
                    startAt: startAt,
                    endAt: endAt,
                    activity: activity.text.trim(),
                    location: location.text.trim(),
                    status: status,
                    farmName: widget.actionController.farmName,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    activity.dispose();
    location.dispose();
    notes.dispose();

    if (result != null) {
      await service.saveShift(result);
      await _load();
    }
  }

  Future<void> _addTraining() async {
    if (members.isEmpty) return;
    var memberId = members.first.id;
    var completedAt = DateTime.now();
    DateTime? validUntil;
    final title = TextEditingController();
    final score = TextEditingController();
    final certificate = TextEditingController();
    final notes = TextEditingController();

    final result = await showDialog<AtlasTrainingRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo treinamento'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador',
                      border: OutlineInputBorder(),
                    ),
                    items: members
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => memberId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Treinamento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  _dateTile(
                    context: dialogContext,
                    title: 'Conclusão',
                    value: completedAt,
                    onChanged: (value) {
                      setDialogState(() => completedAt = value);
                    },
                  ),
                  _dateTile(
                    context: dialogContext,
                    title: 'Validade',
                    value: validUntil,
                    onChanged: (value) {
                      setDialogState(() => validUntil = value);
                    },
                  ),
                  _number(score, 'Nota (%)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: certificate,
                    decoration: const InputDecoration(
                      labelText: 'Certificado',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasTrainingRecord(
                    id: 'training_${now.microsecondsSinceEpoch}',
                    memberId: memberId,
                    title: title.text.trim(),
                    completedAt: completedAt,
                    validUntil: validUntil,
                    scorePercent: _double(score.text),
                    certificate: certificate.text.trim(),
                    farmName: widget.actionController.farmName,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    score.dispose();
    certificate.dispose();
    notes.dispose();

    if (result != null) {
      await service.saveTraining(result);
      await _load();
    }
  }

  Future<void> _addReview() async {
    if (members.isEmpty) return;
    var memberId = members.first.id;
    final productivity = TextEditingController(text: '80');
    final quality = TextEditingController(text: '80');
    final safety = TextEditingController(text: '80');
    final teamwork = TextEditingController(text: '80');
    final notes = TextEditingController();

    final result = await showDialog<AtlasPerformanceReview>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Avaliação de desempenho'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador',
                      border: OutlineInputBorder(),
                    ),
                    items: members
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => memberId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _number(productivity, 'Produtividade (%)'),
                  const SizedBox(height: 10),
                  _number(quality, 'Qualidade (%)'),
                  const SizedBox(height: 10),
                  _number(safety, 'Segurança (%)'),
                  const SizedBox(height: 10),
                  _number(teamwork, 'Trabalho em equipe (%)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Feedback',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasPerformanceReview(
                    id: 'performance_${now.microsecondsSinceEpoch}',
                    memberId: memberId,
                    reviewedAt: now,
                    productivityPercent:
                        _double(productivity.text),
                    qualityPercent: _double(quality.text),
                    safetyPercent: _double(safety.text),
                    teamworkPercent: _double(teamwork.text),
                    managerNotes: notes.text.trim(),
                    farmName: widget.actionController.farmName,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    productivity.dispose();
    quality.dispose();
    safety.dispose();
    teamwork.dispose();
    notes.dispose();

    if (result != null) {
      await service.saveReview(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = snapshot;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão de pessoas'),
          actions: [
            IconButton(
              tooltip: 'Cadastro da equipe',
              onPressed: _openTeam,
              icon: const Icon(Icons.groups_outlined),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Painel'),
              Tab(text: 'Colaboradores'),
              Tab(text: 'Escalas'),
              Tab(text: 'Jornadas'),
              Tab(text: 'Treinamentos'),
              Tab(text: 'Desempenho'),
              Tab(text: 'Competências'),
              Tab(text: 'IA de pessoas'),
            ],
          ),
        ),
        body: loading && current == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _PeopleDashboard(snapshot: current),
                  _Members(members: members, onOpen: _openTeam),
                  _Shifts(
                    shifts: shifts,
                    memberName: memberName,
                    onAdd: _addShift,
                  ),
                  _Hours(snapshot: current),
                  _Trainings(
                    trainings: trainings,
                    memberName: memberName,
                    onAdd: _addTraining,
                  ),
                  _Reviews(
                    reviews: reviews,
                    memberName: memberName,
                    onAdd: _addReview,
                  ),
                  _Competencies(
                    trainings: trainings,
                    memberName: memberName,
                  ),
                  _PeopleRecommendations(
                    values: recommendations,
                  ),
                ],
              ),
      ),
    );
  }

  static Widget _number(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static Widget _dateTimeTile({
    required BuildContext context,
    required String title,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        DateFormat('dd/MM/yyyy HH:mm').format(value),
      ),
      trailing: const Icon(Icons.schedule),
      onTap: () async {
        final selected = await _pickDateTime(context, value);
        if (selected != null) onChanged(selected);
      },
    );
  }

  static Widget _dateTile({
    required BuildContext context,
    required String title,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        value == null
            ? 'Não informada'
            : DateFormat('dd/MM/yyyy').format(value),
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _PeopleDashboard extends StatelessWidget {
  const _PeopleDashboard({required this.snapshot});

  final AtlasPeopleExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados de pessoas.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card('Ativos', item.activeMembers.toDouble(), ''),
            _card('Horas planejadas', item.plannedHours, 'h'),
            _card('Horas concluídas', item.completedHours, 'h'),
            _card('Ausências', item.absences.toDouble(), ''),
            _card(
              'Cobertura de treinamento',
              item.trainingCoveragePercent,
              '%',
            ),
            _card(
              'Treinamentos vencidos',
              item.expiredTrainings.toDouble(),
              '',
            ),
            _card(
              'Desempenho médio',
              item.averagePerformancePercent,
              '%',
            ),
            _card('Score de pessoas', item.peopleScore, '/100'),
          ],
        ),
      ],
    );
  }
}

class _Members extends StatelessWidget {
  const _Members({
    required this.members,
    required this.onOpen,
  });

  final List<AtlasTeamMember> members;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Gerenciar equipe'),
            ),
          ),
        ),
        Expanded(
          child: members.isEmpty
              ? const Center(
                  child: Text('Nenhum colaborador cadastrado.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: members.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = members[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${atlasTeamMemberRoleLabel(item.role)} • '
                          '${item.email}',
                        ),
                        trailing: Text(
                          item.active ? 'Ativo' : 'Inativo',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Shifts extends StatelessWidget {
  const _Shifts({
    required this.shifts,
    required this.memberName,
    required this.onAdd,
  });

  final List<AtlasWorkShift> shifts;
  final String Function(String) memberName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova escala'),
            ),
          ),
        ),
        Expanded(
          child: shifts.isEmpty
              ? const Center(child: Text('Nenhuma escala.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = shifts[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${memberName(item.memberId)} — ${item.activity}',
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(item.startAt)} • '
                          '${item.plannedHours.toStringAsFixed(1)} h • '
                          '${item.location}',
                        ),
                        trailing: Text(
                          atlasWorkShiftStatusLabel(item.status),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Hours extends StatelessWidget {
  const _Hours({required this.snapshot});

  final AtlasPeopleExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados.'));
    }
    final bank = item.completedHours - item.plannedHours;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Horas planejadas', item.plannedHours, 'h'),
        _line('Horas concluídas', item.completedHours, 'h'),
        _line('Saldo de horas', bank, 'h'),
        _line('Ausências', item.absences.toDouble(), ''),
      ],
    );
  }
}

class _Trainings extends StatelessWidget {
  const _Trainings({
    required this.trainings,
    required this.memberName,
    required this.onAdd,
  });

  final List<AtlasTrainingRecord> trainings;
  final String Function(String) memberName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo treinamento'),
            ),
          ),
        ),
        Expanded(
          child: trainings.isEmpty
              ? const Center(
                  child: Text('Nenhum treinamento.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: trainings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = trainings[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          '${memberName(item.memberId)} • '
                          '${DateFormat('dd/MM/yyyy').format(item.completedAt)}',
                        ),
                        trailing: Text(
                          item.isExpired
                              ? 'Vencido'
                              : '${item.scorePercent.toStringAsFixed(0)}%',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({
    required this.reviews,
    required this.memberName,
    required this.onAdd,
  });

  final List<AtlasPerformanceReview> reviews;
  final String Function(String) memberName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova avaliação'),
            ),
          ),
        ),
        Expanded(
          child: reviews.isEmpty
              ? const Center(
                  child: Text('Nenhuma avaliação.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = reviews[index];
                    return Card(
                      child: ListTile(
                        title: Text(memberName(item.memberId)),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy')
                              .format(item.reviewedAt),
                        ),
                        trailing: Text(
                          '${item.overallScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Competencies extends StatelessWidget {
  const _Competencies({
    required this.trainings,
    required this.memberName,
  });

  final List<AtlasTrainingRecord> trainings;
  final String Function(String) memberName;

  @override
  Widget build(BuildContext context) {
    if (trainings.isEmpty) {
      return const Center(
        child: Text('Sem competências registradas.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trainings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = trainings[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(item.title),
            subtitle: Text(memberName(item.memberId)),
            trailing: Text(item.certificate),
          ),
        );
      },
    );
  }
}

class _PeopleRecommendations extends StatelessWidget {
  const _PeopleRecommendations({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(values[index]),
        ),
      ),
    );
  }
}

Widget _card(String title, double value, String unit) {
  return SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
              '${unit.isEmpty || unit == '/100' ? unit : ' $unit'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _line(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
        '${unit.isEmpty ? '' : ' $unit'}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
