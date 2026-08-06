import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_document/data/services/animal_document_storage_service.dart';
import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/data/services/animal_nutrition_storage_service.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/domain/models/animal_nutrition_plan.dart';
import 'package:projeto_atlas/features/animal_operations_center/data/services/animal_operational_task_storage_service.dart';
import 'package:projeto_atlas/features/animal_operations_center/domain/models/animal_operational_task.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

enum AnimalOperationsView {
  validation,
  agenda,
  pending,
  integration,
  farmDashboard,
  companyDashboard,
}

class AnimalOperationsCenterScreen extends StatefulWidget {
  const AnimalOperationsCenterScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialView,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AnimalOperationsView initialView;

  @override
  State<AnimalOperationsCenterScreen> createState() =>
      _AnimalOperationsCenterScreenState();
}

class _AnimalOperationsCenterScreenState
    extends State<AnimalOperationsCenterScreen> {
  final AnimalOperationalTaskStorageService taskStorage =
      AnimalOperationalTaskStorageService();
  final AnimalDocumentStorageService documentStorage =
      AnimalDocumentStorageService();
  final AnimalHealthStorageService healthStorage =
      AnimalHealthStorageService();
  final AnimalReproductionStorageService reproductionStorage =
      AnimalReproductionStorageService();
  final AnimalWeightStorageService weightStorage =
      AnimalWeightStorageService();
  final AnimalNutritionStorageService nutritionStorage =
      AnimalNutritionStorageService();
  final AnimalEnterpriseService animalEnterpriseService =
      AnimalEnterpriseService();

  late AnimalOperationsView selectedView;

  List<AnimalOperationalTask> tasks = [];
  List<AnimalDocumentData> documents = [];
  List<AnimalHealthData> health = [];
  List<AnimalReproductionData> reproduction = [];
  List<AnimalWeightData> weights = [];
  List<AnimalNutritionPlan> nutrition = [];
  List<AnimalData> farmAnimals = [];

  bool loading = true;
  bool backendAvailable = false;
  String backendMessage = 'Não verificado';

  @override
  void initState() {
    super.initState();
    selectedView = widget.initialView;
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final localResults = await Future.wait<dynamic>([
      taskStorage.load(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      documentStorage.loadDocuments(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      healthStorage.loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      reproductionStorage.loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      weightStorage.loadWeights(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      nutritionStorage.load(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
    ]);

    var available = false;
    var message = 'API Enterprise indisponível';
    var animals = <AnimalData>[];

    try {
      final farmId = widget.farm.id?.trim() ?? '';

      if (farmId.isEmpty) {
        throw StateError(
          'A fazenda atual não possui identificador Enterprise.',
        );
      }

      animals = await animalEnterpriseService.listAnimals(
        farmId: farmId,
        lotId: '',
      );
      available = true;
      message = 'API Enterprise conectada';
    } catch (error) {
      message = 'Dados locais ativos; API não respondeu';
    }

    if (!mounted) return;

    setState(() {
      tasks = localResults[0] as List<AnimalOperationalTask>;
      documents = localResults[1] as List<AnimalDocumentData>;
      health = localResults[2] as List<AnimalHealthData>;
      reproduction =
          localResults[3] as List<AnimalReproductionData>;
      weights = localResults[4] as List<AnimalWeightData>;
      nutrition = localResults[5] as List<AnimalNutritionPlan>;
      farmAnimals = animals;
      backendAvailable = available;
      backendMessage = message;
      loading = false;
    });
  }

  Future<void> saveTasks() async {
    await taskStorage.save(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      tasks: tasks,
    );
  }

  List<AnimalOperationalTask> get openTasks {
    final result = tasks.where((task) => !task.completed).toList();
    result.sort(
      (first, second) => parseEnterpriseDate(
        first.dueDate,
      ).compareTo(parseEnterpriseDate(second.dueDate)),
    );
    return result;
  }

  List<AnimalOperationalTask> get completedTasks {
    return tasks.where((task) => task.completed).toList();
  }

  List<AnimalDocumentData> get documentAlerts {
    return documents.where((document) {
      return document.isExpired || document.expiresSoon;
    }).toList();
  }

  List<String> get automaticPendingItems {
    final items = <String>[];

    if (weights.length < 2) {
      items.add('Cadastrar pelo menos duas pesagens.');
    }
    if (health.isEmpty) {
      items.add('Completar o histórico sanitário.');
    }
    if (reproduction.isEmpty &&
        widget.animal.sex.toLowerCase().contains('f')) {
      items.add('Cadastrar a situação reprodutiva.');
    }
    if (nutrition.isEmpty) {
      items.add('Cadastrar dieta e meta nutricional.');
    }
    if (documents.isEmpty) {
      items.add('Cadastrar documentos essenciais.');
    }

    for (final document in documentAlerts) {
      items.add(
        '${document.title}: ${document.expirationStatus}.',
      );
    }

    return items;
  }

  int get validationScore {
    var score = 20;

    if (weights.length >= 2) score += 20;
    if (health.isNotEmpty) score += 15;
    if (reproduction.isNotEmpty ||
        !widget.animal.sex.toLowerCase().contains('f')) {
      score += 15;
    }
    if (nutrition.isNotEmpty) score += 15;
    if (documents.isNotEmpty) score += 15;

    return score.clamp(0, 100).toInt();
  }

  double get latestWeight {
    if (weights.isEmpty) return widget.animal.weight;

    final sorted = [...weights]
      ..sort(
        (first, second) => parseEnterpriseDate(
          first.date,
        ).compareTo(parseEnterpriseDate(second.date)),
      );

    return sorted.last.weight;
  }

  double? get gmd {
    if (weights.length < 2) return null;

    final sorted = [...weights]
      ..sort(
        (first, second) => parseEnterpriseDate(
          first.date,
        ).compareTo(parseEnterpriseDate(second.date)),
      );

    final days = parseEnterpriseDate(sorted.last.date)
        .difference(parseEnterpriseDate(sorted.first.date))
        .inDays;

    if (days <= 0) return null;

    return (sorted.last.weight - sorted.first.weight) / days;
  }

  Future<void> createTask() async {
    final task = await showDialog<AnimalOperationalTask>(
      context: context,
      builder: (context) => const _TaskFormDialog(),
    );

    if (task == null || !mounted) return;

    setState(() => tasks.add(task));
    await saveTasks();
  }

  Future<void> toggleTask(AnimalOperationalTask task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;

    final completed = !task.completed;

    setState(() {
      tasks[index] = task.copyWith(
        completed: completed,
        completedAt:
            completed ? DateTime.now().toIso8601String() : '',
      );
    });

    await saveTasks();
  }

  Future<void> deleteTask(AnimalOperationalTask task) async {
    setState(() {
      tasks.removeWhere((item) => item.id == task.id);
    });
    await saveTasks();
  }

  String viewTitle() {
    return switch (selectedView) {
      AnimalOperationsView.validation =>
        'Validação integral dos módulos',
      AnimalOperationsView.agenda => 'Agenda inteligente',
      AnimalOperationsView.pending =>
        'Central de pendências',
      AnimalOperationsView.integration =>
        'Integração Enterprise',
      AnimalOperationsView.farmDashboard =>
        'Dashboard da fazenda',
      AnimalOperationsView.companyDashboard =>
        'Dashboard da empresa',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewTitle()),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
          selectedView == AnimalOperationsView.agenda
              ? FloatingActionButton.extended(
                  onPressed: loading ? null : createTask,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Nova tarefa'),
                )
              : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title: viewTitle(),
                        subtitle:
                            '${widget.animal.displayName} • '
                            '${widget.farm.name} • ${widget.group.name}',
                        icon: _viewIcon(selectedView),
                      ),
                      const SizedBox(height: 18),
                      _ViewSelector(
                        selected: selectedView,
                        onSelected: (view) {
                          setState(() => selectedView = view);
                        },
                      ),
                      const SizedBox(height: 22),
                      _buildSelectedView(),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    return switch (selectedView) {
      AnimalOperationsView.validation =>
        _buildValidation(),
      AnimalOperationsView.agenda => _buildAgenda(),
      AnimalOperationsView.pending => _buildPending(),
      AnimalOperationsView.integration =>
        _buildIntegration(),
      AnimalOperationsView.farmDashboard =>
        _buildFarmDashboard(),
      AnimalOperationsView.companyDashboard =>
        _buildCompanyDashboard(),
    };
  }

  Widget _buildValidation() {
    final checks = <({String title, bool ok, String detail})>[
      (
        title: 'Pesagens inteligentes',
        ok: weights.length >= 2,
        detail: '${weights.length} pesagens encontradas',
      ),
      (
        title: 'Sanidade Enterprise',
        ok: health.isNotEmpty,
        detail: '${health.length} registros sanitários',
      ),
      (
        title: 'Reprodução Enterprise',
        ok: reproduction.isNotEmpty ||
            !widget.animal.sex.toLowerCase().contains('f'),
        detail: '${reproduction.length} registros reprodutivos',
      ),
      (
        title: 'Nutrição Enterprise',
        ok: nutrition.isNotEmpty,
        detail: '${nutrition.length} planos nutricionais',
      ),
      (
        title: 'Documentos',
        ok: documents.isNotEmpty,
        detail: '${documents.length} documentos',
      ),
      (
        title: 'Backend Enterprise',
        ok: backendAvailable,
        detail: backendMessage,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Score de validação',
              value: '$validationScore/100',
              subtitle: validationScore >= 80
                  ? 'Base operacional consistente'
                  : 'Existem lacunas de dados',
              icon: Icons.verified_outlined,
              warning: validationScore < 60,
            ),
            EnterpriseMetricCard(
              title: 'Módulos verificados',
              value: '${checks.length}',
              subtitle: 'Validação local e Enterprise',
              icon: Icons.fact_check_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Pendências automáticas',
              value: '${automaticPendingItems.length}',
              subtitle: 'Lacunas e vencimentos',
              icon: Icons.rule_folder_outlined,
              warning: automaticPendingItems.isNotEmpty,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...checks.map(
          (check) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: check.ok
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                child: Icon(
                  check.ok
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: check.ok
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
              ),
              title: Text(check.title),
              subtitle: Text(check.detail),
              trailing: Text(check.ok ? 'OK' : 'Revisar'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Tarefas abertas',
              value: '${openTasks.length}',
              subtitle: 'Ações programadas',
              icon: Icons.event_note_outlined,
              warning: openTasks.isNotEmpty,
            ),
            EnterpriseMetricCard(
              title: 'Concluídas',
              value: '${completedTasks.length}',
              subtitle: 'Histórico de execução',
              icon: Icons.task_alt_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Alertas documentais',
              value: '${documentAlerts.length}',
              subtitle: 'Vencidos ou próximos',
              icon: Icons.event_busy_outlined,
              warning: documentAlerts.isNotEmpty,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const EnterpriseSectionTitle(
          'Próximas ações',
          'Agenda individual ordenada pela data prevista.',
        ),
        const SizedBox(height: 12),
        if (openTasks.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Nenhuma tarefa aberta.'),
              subtitle: Text(
                'Clique em Nova tarefa para criar a agenda.',
              ),
            ),
          )
        else
          ...openTasks.map(
            (task) => _TaskCard(
              task: task,
              onToggle: () => toggleTask(task),
              onDelete: () => deleteTask(task),
            ),
          ),
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 22),
          const EnterpriseSectionTitle(
            'Concluídas',
            'Histórico das tarefas executadas.',
          ),
          const SizedBox(height: 12),
          ...completedTasks.map(
            (task) => _TaskCard(
              task: task,
              onToggle: () => toggleTask(task),
              onDelete: () => deleteTask(task),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPending() {
    final manual = openTasks
        .map((task) => '${task.title} • ${task.dueDate}')
        .toList();

    final all = [...automaticPendingItems, ...manual];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Pendências totais',
              value: '${all.length}',
              subtitle: 'Automáticas e manuais',
              icon: Icons.notification_important_outlined,
              warning: all.isNotEmpty,
            ),
            EnterpriseMetricCard(
              title: 'Documentos críticos',
              value: '${documentAlerts.length}',
              subtitle: 'Vencidos ou próximos',
              icon: Icons.description_outlined,
              warning: documentAlerts.isNotEmpty,
            ),
            EnterpriseMetricCard(
              title: 'Execução programada',
              value: '${openTasks.length}',
              subtitle: 'Tarefas com responsável',
              icon: Icons.assignment_ind_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        EnterpriseInsightCard(
          title: 'Central de atenção',
          icon: Icons.priority_high_outlined,
          items: all.isEmpty
              ? const [
                  'Nenhuma pendência prioritária foi identificada.',
                ]
              : all,
        ),
      ],
    );
  }

  Widget _buildIntegration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'API Enterprise',
              value: backendAvailable ? 'Conectada' : 'Offline',
              subtitle: backendMessage,
              icon: Icons.cloud_done_outlined,
              warning: !backendAvailable,
            ),
            EnterpriseMetricCard(
              title: 'Dados locais',
              value: 'Ativos',
              subtitle:
                  '${weights.length + health.length + reproduction.length + nutrition.length + documents.length} registros',
              icon: Icons.storage_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Escopo',
              value: widget.farm.name,
              subtitle: 'Tenant, empresa e fazenda preservados',
              icon: Icons.business_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const EnterpriseInsightCard(
          title: 'Plano de migração e sincronização',
          icon: Icons.sync_alt_outlined,
          items: [
            'Manter operação local quando a API estiver indisponível.',
            'Enviar registros pendentes com tenant, empresa, fazenda e animal.',
            'Aplicar idempotência para evitar duplicações.',
            'Registrar auditoria de criação, alteração, exclusão e sincronização.',
            'Resolver conflitos com versão, data de atualização e origem.',
            'Usar permissões Enterprise antes de qualquer escrita remota.',
          ],
        ),
      ],
    );
  }

  Widget _buildFarmDashboard() {
    final totalAnimals =
        farmAnimals.isEmpty ? 1 : farmAnimals.length;
    final activeAnimals = farmAnimals.isEmpty
        ? (_isAnimalActive(widget.animal) ? 1 : 0)
        : farmAnimals.where(_isAnimalActive).length;
    final totalWeight = farmAnimals.isEmpty
        ? latestWeight
        : farmAnimals.fold<double>(
            0,
            (total, animal) => total + animal.weight,
          );
    final averageWeight =
        totalAnimals == 0 ? 0 : totalWeight / totalAnimals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Animais',
              value: '$totalAnimals',
              subtitle: backendAvailable
                  ? 'Cadastro Enterprise da fazenda'
                  : 'Recorte local disponível',
              icon: Icons.pets_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Ativos',
              value: '$activeAnimals',
              subtitle: 'Animais em situação ativa',
              icon: Icons.check_circle_outline,
            ),
            EnterpriseMetricCard(
              title: 'Peso médio',
              value:
                  '${averageWeight.toStringAsFixed(1).replaceAll('.', ',')} kg',
              subtitle: 'Média dos registros disponíveis',
              icon: Icons.monitor_weight_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Pendências',
              value: '${automaticPendingItems.length}',
              subtitle: 'Recorte do animal selecionado',
              icon: Icons.warning_amber_outlined,
              warning: automaticPendingItems.isNotEmpty,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const EnterpriseInsightCard(
          title: 'Visão gerencial da fazenda',
          icon: Icons.agriculture_outlined,
          items: [
            'Priorizar animais com perda de peso ou dados incompletos.',
            'Consolidar calendário sanitário e reprodutivo por lote.',
            'Comparar custo nutricional com ganho observado.',
            'Acompanhar documentos, tarefas e riscos em uma única rotina.',
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Empresa ativa',
              value: 'Enterprise',
              subtitle: 'Escopo da sessão autenticada',
              icon: Icons.domain_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Fazenda atual',
              value: widget.farm.name,
              subtitle: 'Recorte operacional selecionado',
              icon: Icons.landscape_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Qualidade dos dados',
              value: '$validationScore/100',
              subtitle: 'Score do recorte analisado',
              icon: Icons.analytics_outlined,
              warning: validationScore < 60,
            ),
            EnterpriseMetricCard(
              title: 'Risco operacional',
              value: automaticPendingItems.isEmpty
                  ? 'Controlado'
                  : 'Atenção',
              subtitle:
                  '${automaticPendingItems.length} pendências automáticas',
              icon: Icons.shield_outlined,
              warning: automaticPendingItems.isNotEmpty,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const EnterpriseInsightCard(
          title: 'Visão executiva multfazendas',
          icon: Icons.account_balance_outlined,
          items: [
            'O contrato visual e de dados está preparado para consolidação de múltiplas fazendas.',
            'A API Enterprise deve fornecer indicadores agregados por empresa e tenant.',
            'Os painéis devem respeitar permissões, carteira de fazendas e escopo do usuário.',
            'A próxima evolução é persistir agenda, pendências e indicadores no PostgreSQL.',
          ],
        ),
      ],
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.selected,
    required this.onSelected,
  });

  final AnimalOperationsView selected;
  final ValueChanged<AnimalOperationsView> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        view: AnimalOperationsView.validation,
        label: 'Validação',
      ),
      (
        view: AnimalOperationsView.agenda,
        label: 'Agenda',
      ),
      (
        view: AnimalOperationsView.pending,
        label: 'Pendências',
      ),
      (
        view: AnimalOperationsView.integration,
        label: 'Integração',
      ),
      (
        view: AnimalOperationsView.farmDashboard,
        label: 'Fazenda',
      ),
      (
        view: AnimalOperationsView.companyDashboard,
        label: 'Empresa',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: items.map((item) {
            final active = item.view == selected;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item == items.last ? 0 : 8,
                ),
                child: FilledButton.tonal(
                  onPressed: () => onSelected(item.view),
                  style: FilledButton.styleFrom(
                    backgroundColor: active
                        ? const Color(0xFF1B5E20)
                        : null,
                    foregroundColor:
                        active ? Colors.white : null,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final AnimalOperationalTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (task.priority) {
      'Alta' => Colors.red.shade700,
      'Média' => Colors.orange.shade800,
      _ => Colors.green.shade800,
    };

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          '${task.category} • ${task.priority} • '
          '${task.dueDate}'
          '${task.responsible.isEmpty ? '' : ' • ${task.responsible}'}',
        ),
        trailing: IconButton(
          tooltip: 'Excluir',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
        iconColor: color,
      ),
    );
  }
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog();

  @override
  State<_TaskFormDialog> createState() =>
      _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final responsible = TextEditingController();

  String category = 'Geral';
  String priority = 'Média';
  DateTime dueDate = DateTime.now().add(
    const Duration(days: 7),
  );

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    responsible.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (selected == null) return;
    setState(() => dueDate = selected);
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      AnimalOperationalTask(
        id: 'task_${DateTime.now().microsecondsSinceEpoch}',
        title: title.text.trim(),
        description: description.text.trim(),
        category: category,
        priority: priority,
        dueDate: enterpriseDate(dueDate),
        responsible: responsible.text.trim(),
        completed: false,
        createdAt: DateTime.now().toIso8601String(),
        completedAt: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova tarefa'),
      content: SizedBox(
        width: 580,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o título.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                  ),
                  items: const [
                    'Geral',
                    'Sanidade',
                    'Reprodução',
                    'Pesagem',
                    'Nutrição',
                    'Documentos',
                  ]
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => category = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                  ),
                  items: const ['Baixa', 'Média', 'Alta']
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => priority = value);
                    }
                  },
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(
                    labelText: 'Responsável',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data prevista'),
                  subtitle: Text(enterpriseDate(dueDate)),
                  trailing: const Icon(
                    Icons.calendar_month_outlined,
                  ),
                  onTap: chooseDate,
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
        FilledButton(
          onPressed: save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}


bool _isAnimalActive(AnimalData animal) {
  final normalizedStatus = animal.status.trim().toLowerCase();

  return normalizedStatus == 'ativo' ||
      normalizedStatus == 'ativa' ||
      normalizedStatus == 'active';
}

IconData _viewIcon(AnimalOperationsView view) {
  return switch (view) {
    AnimalOperationsView.validation =>
      Icons.fact_check_outlined,
    AnimalOperationsView.agenda =>
      Icons.calendar_month_outlined,
    AnimalOperationsView.pending =>
      Icons.notification_important_outlined,
    AnimalOperationsView.integration =>
      Icons.sync_alt_outlined,
    AnimalOperationsView.farmDashboard =>
      Icons.agriculture_outlined,
    AnimalOperationsView.companyDashboard =>
      Icons.domain_outlined,
  };
}
