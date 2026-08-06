import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_document/data/services/animal_document_storage_service.dart';
import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_enterprise_timeline_service.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_event_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_movement/data/services/animal_movement_storage_service.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/data/services/animal_nutrition_storage_service.dart';
import 'package:projeto_atlas/features/animal_operations_center/data/services/animal_operational_task_storage_service.dart';
import 'package:projeto_atlas/features/animal_operations_center/domain/models/animal_operational_task.dart';
import 'package:projeto_atlas/features/animal_photo/data/services/animal_photo_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_intelligence_360/data/services/animal_intelligence_export_service.dart';
import 'package:projeto_atlas/features/animal_intelligence_360/domain/services/animal_intelligence_engine.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

/// Os seis grupos abaixo materializam, em ordem, os 20 passos estratégicos.
enum AnimalIntelligence360View {
  intelligence,
  operations,
  reports,
  governance,
  platform,
  farmExecutive,
}

class AnimalIntelligence360Screen extends StatefulWidget {
  const AnimalIntelligence360Screen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialView,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AnimalIntelligence360View initialView;

  @override
  State<AnimalIntelligence360Screen> createState() =>
      _AnimalIntelligence360ScreenState();
}

class _AnimalIntelligence360ScreenState
    extends State<AnimalIntelligence360Screen> {
  final AnimalWeightStorageService weightStorage =
      AnimalWeightStorageService();
  final AnimalHealthStorageService healthStorage =
      AnimalHealthStorageService();
  final AnimalReproductionStorageService reproductionStorage =
      AnimalReproductionStorageService();
  final AnimalMovementStorageService movementStorage =
      AnimalMovementStorageService();
  final AnimalDocumentStorageService documentStorage =
      AnimalDocumentStorageService();
  final AnimalPhotoStorageService photoStorage =
      AnimalPhotoStorageService();
  final AnimalEventStorageService eventStorage =
      AnimalEventStorageService();
  final AnimalNutritionStorageService nutritionStorage =
      AnimalNutritionStorageService();
  final AnimalOperationalTaskStorageService taskStorage =
      AnimalOperationalTaskStorageService();
  final AnimalEnterpriseTimelineService timelineService =
      AnimalEnterpriseTimelineService();
  final AnimalEnterpriseService animalEnterpriseService =
      AnimalEnterpriseService();
  final AnimalIntelligenceExportService exportService =
      const AnimalIntelligenceExportService();

  late AnimalIntelligence360View selectedView;

  List<AnimalWeightData> weights = [];
  List<AnimalDocumentData> documents = [];
  List<AnimalOperationalTask> tasks = [];
  List<AnimalData> farmAnimals = [];

  int healthCount = 0;
  int reproductionCount = 0;
  int movementCount = 0;
  int photoCount = 0;
  int eventCount = 0;
  int nutritionCount = 0;
  int auditCount = 0;

  bool loading = true;
  bool backendAvailable = false;
  String backendStatus = 'Não verificado';

  @override
  void initState() {
    super.initState();
    selectedView = widget.initialView;
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    final local = await Future.wait<dynamic>([
      weightStorage.loadWeights(
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
      movementStorage.loadRecords(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      documentStorage.loadDocuments(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      photoStorage.loadPhotos(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      eventStorage.loadEvents(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      nutritionStorage.load(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
      taskStorage.load(
        farmName: widget.farm.name,
        groupName: widget.group.name,
        animalId: widget.animal.id,
      ),
    ]);

    var audit = 0;
    var animals = <AnimalData>[];
    var apiOk = false;
    var status = 'Operação local ativa; API indisponível';

    try {
      final timeline = await timelineService.loadTimeline(widget.animal.id);
      audit = timeline.length;
    } catch (_) {
      audit = 0;
    }

    try {
      final farmId = widget.farm.id?.trim() ?? '';
      if (farmId.isEmpty) {
        throw StateError('Fazenda sem identificador Enterprise.');
      }
      animals = await animalEnterpriseService.listAnimals(
        farmId: farmId,
        lotId: '',
      );
      apiOk = true;
      status = 'API Enterprise conectada';
    } catch (_) {
      apiOk = false;
    }

    final loadedWeights = local[0] as List<AnimalWeightData>;
    loadedWeights.sort(
      (a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)),
    );

    if (!mounted) return;

    setState(() {
      weights = loadedWeights;
      healthCount = (local[1] as List<dynamic>).length;
      reproductionCount = (local[2] as List<dynamic>).length;
      movementCount = (local[3] as List<dynamic>).length;
      documents = local[4] as List<AnimalDocumentData>;
      photoCount = (local[5] as List<dynamic>).length;
      eventCount = (local[6] as List<dynamic>).length;
      nutritionCount = (local[7] as List<dynamic>).length;
      tasks = local[8] as List<AnimalOperationalTask>;
      auditCount = audit;
      farmAnimals = animals;
      backendAvailable = apiOk;
      backendStatus = status;
      loading = false;
    });
  }

  double get currentWeight =>
      weights.isEmpty ? widget.animal.weight : weights.last.weight;

  double? get gmd {
    if (weights.length < 2) return null;
    return AnimalIntelligenceEngine.calculateGmd(
      firstWeight: weights.first.weight,
      lastWeight: weights.last.weight,
      firstDate: _parseDate(weights.first.date),
      lastDate: _parseDate(weights.last.date),
    );
  }

  int get expiredDocuments =>
      documents.where((document) => document.isExpired).length;

  int get expiringDocuments =>
      documents.where((document) => document.expiresSoon).length;

  int get openTasks => tasks.where((task) => !task.completed).length;

  int get criticalAlerts {
    var count = expiredDocuments;
    if (gmd != null && gmd! < 0) count += 1;
    if (healthCount == 0) count += 1;
    if (nutritionCount == 0) count += 1;
    return count;
  }

  int get score => AnimalIntelligenceEngine.score360(
        weightCount: weights.length,
        healthCount: healthCount,
        reproductionCount: reproductionCount,
        nutritionCount: nutritionCount,
        documentCount: documents.length,
        photoCount: photoCount,
        movementCount: movementCount,
        gmd: gmd,
        bodyConditionScore: widget.animal.bodyConditionScore,
        criticalAlerts: criticalAlerts,
      );

  List<String> get recommendations =>
      AnimalIntelligenceEngine.recommendations(
        weightCount: weights.length,
        healthCount: healthCount,
        reproductionCount: reproductionCount,
        nutritionCount: nutritionCount,
        documentCount: documents.length,
        gmd: gmd,
        bodyConditionScore: widget.animal.bodyConditionScore,
        female: widget.animal.sex.toLowerCase().contains('f'),
        expiredDocuments: expiredDocuments,
        openTasks: openTasks,
      );

  String get diagnosis => AnimalIntelligenceEngine.diagnosis(
        score: score,
        gmd: gmd,
        criticalAlerts: criticalAlerts,
      );

  double get farmAverageWeight {
    if (farmAnimals.isEmpty) return widget.animal.weight;
    final total = farmAnimals.fold<double>(
      0,
      (sum, animal) => sum + animal.weight,
    );
    return farmAnimals.isEmpty ? 0 : total / farmAnimals.length;
  }

  Map<String, dynamic> get snapshot => {
        'Animal': widget.animal.displayName,
        'Brinco': widget.animal.tag,
        'Fazenda': widget.farm.name,
        'Lote': widget.group.name,
        'Score Atlas 360': score,
        'Peso atual (kg)': _decimal(currentWeight, 1),
        'GMD (kg/dia)': gmd == null ? 'Dados insuficientes' : _decimal(gmd!, 3),
        'Média da fazenda (kg)': _decimal(farmAverageWeight, 1),
        'Registros sanitários': healthCount,
        'Registros reprodutivos': reproductionCount,
        'Planos nutricionais': nutritionCount,
        'Pesagens': weights.length,
        'Documentos': documents.length,
        'Fotos': photoCount,
        'Movimentações': movementCount,
        'Eventos manuais': eventCount,
        'Auditorias Enterprise': auditCount,
        'Tarefas abertas': openTasks,
        'Alertas críticos': criticalAlerts,
        'Status da API': backendStatus,
        'Diagnóstico': diagnosis,
      };

  Map<String, dynamic> get backupPayload => {
        'generated_at': DateTime.now().toIso8601String(),
        'animal': widget.animal.toMap(),
        'farm': widget.farm.toMap(),
        'group': widget.group.toMap(),
        'snapshot': snapshot,
        'weights': weights
            .map((item) => item.toMap())
            .toList(growable: false),
        'documents': documents
            .map((item) => item.toMap())
            .toList(growable: false),
        'tasks': tasks
            .map((item) => item.toMap())
            .toList(growable: false),
        'recommendations': recommendations,
      };

  Future<void> exportPdf() async {
    try {
      final file = await exportService.savePdf(
        animalName: widget.animal.displayName,
        snapshot: snapshot,
        recommendations: recommendations,
      );
      _message('PDF salvo em ${file.path}');
    } catch (error) {
      _message('Não foi possível gerar o PDF: $error');
    }
  }

  Future<void> exportCsv() async {
    try {
      final file = await exportService.saveCsv(
        animalName: widget.animal.displayName,
        snapshot: snapshot,
      );
      _message('CSV compatível com Excel salvo em ${file.path}');
    } catch (error) {
      _message('Não foi possível gerar o CSV: $error');
    }
  }

  Future<void> createBackup() async {
    try {
      final file = await exportService.saveBackup(
        animalName: widget.animal.displayName,
        backup: backupPayload,
      );
      _message('Backup salvo em ${file.path}');
    } catch (error) {
      _message('Não foi possível gerar o backup: $error');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Inteligência 360'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                        title: 'Inteligência 360 — ${widget.animal.displayName}',
                        subtitle:
                            'Vinte capacidades integradas em análise, operação, relatórios, governança e plataforma.',
                        icon: Icons.hub_outlined,
                      ),
                      const SizedBox(height: 18),
                      _SectionSelector(
                        selected: selectedView,
                        onSelected: (value) {
                          setState(() => selectedView = value);
                        },
                      ),
                      const SizedBox(height: 22),
                      _selectedContent(),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _selectedContent() {
    return switch (selectedView) {
      AnimalIntelligence360View.intelligence => _intelligence(),
      AnimalIntelligence360View.operations => _operations(),
      AnimalIntelligence360View.reports => _reports(),
      AnimalIntelligence360View.governance => _governance(),
      AnimalIntelligence360View.platform => _platform(),
      AnimalIntelligence360View.farmExecutive => _farmExecutive(),
    };
  }

  Widget _intelligence() {
    final projection30 = AnimalIntelligenceEngine.projectWeight(
      currentWeight: currentWeight,
      gmd: gmd,
      days: 30,
    );
    final projection90 = AnimalIntelligenceEngine.projectWeight(
      currentWeight: currentWeight,
      gmd: gmd,
      days: 90,
    );
    final projection180 = AnimalIntelligenceEngine.projectWeight(
      currentWeight: currentWeight,
      gmd: gmd,
      days: 180,
    );
    final difference = currentWeight - farmAverageWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(number: 1, title: 'Painel Executivo do Animal'),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Score geral',
              value: '$score/100',
              subtitle: diagnosis,
              icon: Icons.speed_outlined,
              warning: score < 60,
            ),
            EnterpriseMetricCard(
              title: 'Peso atual',
              value: '${_decimal(currentWeight, 1)} kg',
              subtitle: 'Último valor disponível',
              icon: Icons.monitor_weight_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Alertas críticos',
              value: '$criticalAlerts',
              subtitle: 'Risco e pendências prioritárias',
              icon: Icons.warning_amber_outlined,
              warning: criticalAlerts > 0,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 2, title: 'Dashboard Zootécnico Completo'),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'GMD',
              value: gmd == null
                  ? 'Dados insuficientes'
                  : '${_decimal(gmd!, 3)} kg/dia',
              subtitle: '${weights.length} pesagens',
              icon: Icons.auto_graph_outlined,
              warning: gmd != null && gmd! < 0,
            ),
            EnterpriseMetricCard(
              title: 'Escore corporal',
              value: widget.animal.bodyConditionScore <= 0
                  ? 'Não informado'
                  : _decimal(widget.animal.bodyConditionScore, 1),
              subtitle: 'Condição corporal atual',
              icon: Icons.analytics_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Base técnica',
              value: '${healthCount + reproductionCount + nutritionCount}',
              subtitle: 'Sanidade, reprodução e nutrição',
              icon: Icons.fact_check_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 3, title: 'Central Inteligente de Alertas'),
        EnterpriseInsightCard(
          title: 'Alertas detectados',
          icon: Icons.notifications_active_outlined,
          items: [
            if (expiredDocuments > 0)
              '$expiredDocuments documento(s) vencido(s).',
            if (expiringDocuments > 0)
              '$expiringDocuments documento(s) vencendo em breve.',
            if (gmd != null && gmd! < 0)
              'A série de pesagens indica perda de peso.',
            if (openTasks > 0)
              '$openTasks tarefa(s) aberta(s) na agenda.',
            if (criticalAlerts == 0)
              'Nenhum alerta crítico foi identificado.',
          ],
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 4, title: 'Timeline Enterprise Completa'),
        _CountGrid(items: [
          ('Pesagens', weights.length),
          ('Sanidade', healthCount),
          ('Reprodução', reproductionCount),
          ('Nutrição', nutritionCount),
          ('Fotos', photoCount),
          ('Documentos', documents.length),
          ('Movimentações', movementCount),
          ('Eventos', eventCount),
          ('Auditoria', auditCount),
        ]),
        const SizedBox(height: 22),
        _StepTitle(number: 5, title: 'Comparador Inteligente'),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.compare_arrows_outlined),
            ),
            title: Text(
              difference >= 0
                  ? 'Animal ${_decimal(difference.abs(), 1)} kg acima da média'
                  : 'Animal ${_decimal(difference.abs(), 1)} kg abaixo da média',
            ),
            subtitle: Text(
              'Animal: ${_decimal(currentWeight, 1)} kg • '
              'Fazenda/lote: ${_decimal(farmAverageWeight, 1)} kg',
            ),
          ),
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 6, title: 'Atlas Score 360°'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                LinearProgressIndicator(value: score / 100, minHeight: 14),
                const SizedBox(height: 10),
                Text(
                  '$score pontos — ${score >= 80 ? 'Excelente' : score >= 60 ? 'Bom' : score >= 40 ? 'Atenção' : 'Crítico'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 7, title: 'IA de Recomendações'),
        EnterpriseInsightCard(
          title: 'O que fazer com este animal agora',
          icon: Icons.psychology_outlined,
          items: recommendations,
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 8, title: 'Diagnóstico Automático'),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.biotech_outlined),
            ),
            title: const Text('Diagnóstico consolidado'),
            subtitle: Text(diagnosis),
          ),
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 9, title: 'Projeções Futuras'),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _ProjectionCard(label: '30 dias', value: projection30),
            _ProjectionCard(label: '90 dias', value: projection90),
            _ProjectionCard(label: '180 dias', value: projection180),
          ],
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 10, title: 'Benchmark Automático'),
        EnterpriseInsightCard(
          title: 'Referências internas',
          icon: Icons.leaderboard_outlined,
          items: [
            'Peso do animal: ${_decimal(currentWeight, 1)} kg.',
            'Média disponível da fazenda/lote: ${_decimal(farmAverageWeight, 1)} kg.',
            'Diferença: ${_decimal(difference, 1)} kg.',
            'A comparação usa a carteira Enterprise quando a API está conectada e o lote como fallback.',
          ],
        ),
      ],
    );
  }

  Widget _operations() {
    final open = tasks.where((task) => !task.completed).toList()
      ..sort((a, b) => _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(number: 11, title: 'Agenda Inteligente'),
        if (open.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Nenhuma tarefa aberta.'),
              subtitle: Text('A agenda operacional do animal está em dia.'),
            ),
          )
        else
          ...open.take(12).map(
                (task) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.event_note_outlined),
                    ),
                    title: Text(task.title),
                    subtitle: Text(
                      '${task.category} • ${task.priority} • ${task.dueDate}',
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 22),
        _StepTitle(number: 12, title: 'Centro Operacional'),
        EnterpriseInsightCard(
          title: 'O que precisa ser feito hoje',
          icon: Icons.assignment_turned_in_outlined,
          items: [
            ...recommendations.take(5),
            if (openTasks > 0) '$openTasks tarefa(s) aguardando execução.',
            if (openTasks == 0 && criticalAlerts == 0)
              'Operação sem pendências críticas imediatas.',
          ],
        ),
      ],
    );
  }

  Widget _reports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(number: 13, title: 'Relatórios PDF Premium'),
        _ActionCard(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Gerar relatório executivo em PDF',
          subtitle: 'Score, indicadores, diagnóstico e recomendações.',
          button: 'Gerar PDF',
          onPressed: exportPdf,
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 14, title: 'Exportações'),
        _ActionCard(
          icon: Icons.table_view_outlined,
          title: 'Exportar dados para Excel/CSV',
          subtitle: 'Arquivo CSV com separador compatível com Excel.',
          button: 'Exportar CSV',
          onPressed: exportCsv,
        ),
      ],
    );
  }

  Widget _governance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(number: 15, title: 'Auditoria Completa'),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Eventos auditados',
              value: '$auditCount',
              subtitle: 'Timeline Enterprise',
              icon: Icons.manage_history_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Versão do animal',
              value: '${widget.animal.version}',
              subtitle: widget.animal.updatedAt.isEmpty
                  ? 'Sem data remota'
                  : widget.animal.updatedAt,
              icon: Icons.history_toggle_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 19, title: 'Permissões Avançadas'),
        const _PermissionMatrix(),
      ],
    );
  }

  Widget _platform() {
    final localRecords = weights.length +
        healthCount +
        reproductionCount +
        nutritionCount +
        movementCount +
        photoCount +
        documents.length +
        tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(number: 16, title: 'Offline Completo'),
        EnterpriseMetricCard(
          title: 'Base local disponível',
          value: '$localRecords registros',
          subtitle: 'SharedPreferences e arquivos continuam disponíveis sem internet.',
          icon: Icons.offline_bolt_outlined,
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 17, title: 'Sincronização Inteligente'),
        _ActionCard(
          icon: backendAvailable
              ? Icons.cloud_done_outlined
              : Icons.cloud_off_outlined,
          title: backendStatus,
          subtitle: backendAvailable
              ? 'Carteira Enterprise carregada com ${farmAnimals.length} animais.'
              : 'A operação permanece local e será reconciliada quando a API retornar.',
          button: 'Verificar agora',
          onPressed: load,
        ),
        const SizedBox(height: 22),
        _StepTitle(number: 18, title: 'Backup Automático'),
        _ActionCard(
          icon: Icons.backup_outlined,
          title: 'Gerar backup completo do animal',
          subtitle: 'Cadastro, indicadores, pesagens, documentos, tarefas e recomendações em JSON.',
          button: 'Criar backup',
          onPressed: createBackup,
        ),
      ],
    );
  }

  Widget _farmExecutive() {
    final animalCount = farmAnimals.isEmpty ? widget.farm.animals : farmAnimals.length;
    final activeCount = farmAnimals.isEmpty
        ? (_active(widget.animal) ? 1 : 0)
        : farmAnimals.where(_active).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(number: 20, title: 'Dashboard Executivo da Fazenda'),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            EnterpriseMetricCard(
              title: 'Animais',
              value: '$animalCount',
              subtitle: backendAvailable ? 'Carteira Enterprise' : 'Cadastro da fazenda',
              icon: Icons.pets_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Ativos',
              value: '$activeCount',
              subtitle: 'Situação ativa',
              icon: Icons.check_circle_outline,
            ),
            EnterpriseMetricCard(
              title: 'Área',
              value: '${widget.farm.area} ha',
              subtitle: '${widget.farm.city} - ${widget.farm.state}',
              icon: Icons.landscape_outlined,
            ),
            EnterpriseMetricCard(
              title: 'Score do recorte',
              value: '$score/100',
              subtitle: widget.animal.displayName,
              icon: Icons.dashboard_outlined,
              warning: score < 60,
            ),
          ],
        ),
        const SizedBox(height: 20),
        EnterpriseInsightCard(
          title: 'Decisões executivas sugeridas',
          icon: Icons.business_center_outlined,
          items: [
            'Priorizar animais com alertas críticos e GMD negativo.',
            'Consolidar metas e comparações por lote, categoria e fazenda.',
            'Cruzar custo nutricional, sanidade e desempenho econômico.',
            'Usar a agenda para transformar recomendações em execução auditável.',
            'Acompanhar a qualidade dos dados antes de automatizar decisões de alto impacto.',
          ],
        ),
      ],
    );
  }

  DateTime _parseDate(String value) {
    final normalized = value.trim();
    final iso = DateTime.tryParse(normalized);
    if (iso != null) return iso;
    final parts = normalized.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[2]) ?? 1900,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[0]) ?? 1,
      );
    }
    return DateTime(1900);
  }

  String _decimal(double value, int places) =>
      value.toStringAsFixed(places).replaceAll('.', ',');

  bool _active(AnimalData animal) {
    final status = animal.status.trim().toLowerCase();
    return status == 'ativo' || status == 'ativa' || status == 'active';
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({
    required this.selected,
    required this.onSelected,
  });

  final AnimalIntelligence360View selected;
  final ValueChanged<AnimalIntelligence360View> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (view: AnimalIntelligence360View.intelligence, label: 'Inteligência'),
      (view: AnimalIntelligence360View.operations, label: 'Operações'),
      (view: AnimalIntelligence360View.reports, label: 'Relatórios'),
      (view: AnimalIntelligence360View.governance, label: 'Governança'),
      (view: AnimalIntelligence360View.platform, label: 'Plataforma'),
      (view: AnimalIntelligence360View.farmExecutive, label: 'Fazenda 360'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: items.map((item) {
            final active = item.view == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item == items.last ? 0 : 8),
                child: FilledButton.tonal(
                  onPressed: () => onSelected(item.view),
                  style: FilledButton.styleFrom(
                    backgroundColor: active ? const Color(0xFF1B5E20) : null,
                    foregroundColor: active ? Colors.white : null,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.title});
  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            child: Text('$number'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.label, required this.value});
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return EnterpriseMetricCard(
      title: label,
      value: value == null
          ? 'Dados insuficientes'
          : '${value!.toStringAsFixed(1).replaceAll('.', ',')} kg',
      subtitle: 'Projeção linear baseada no GMD',
      icon: Icons.query_stats_outlined,
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.items});
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Chip(
              avatar: const Icon(Icons.circle, size: 10),
              label: Text('${item.$1}: ${item.$2}'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.open_in_new_outlined),
              label: Text(button),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Administrador', 'Leitura, escrita, permissões, auditoria e exportação'),
      ('Veterinário', 'Sanidade, reprodução, documentos e relatórios'),
      ('Consultor', 'Análises, recomendações, agenda e relatórios'),
      ('Funcionário', 'Execução de tarefas e registros autorizados'),
      ('Visualizador', 'Somente leitura no escopo liberado'),
    ];

    return Card(
      child: Column(
        children: rows
            .map(
              (row) => ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text(row.$1),
                subtitle: Text(row.$2),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
