import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_execution_plan.dart';

class AtlasExecutionRepository {
  AtlasExecutionRepository._();
  static final AtlasExecutionRepository instance = AtlasExecutionRepository._();
  static const _key = 'atlas_strategic_execution_plans_v1';

  Future<List<AtlasExecutionPlan>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seed = _seed();
      await saveAll(seed);
      return seed;
    }
    try {
      return (jsonDecode(raw) as List)
          .map(
            (e) => AtlasExecutionPlan.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      final seed = _seed();
      await saveAll(seed);
      return seed;
    }
  }

  Future<void> saveAll(List<AtlasExecutionPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(plans.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> save(AtlasExecutionPlan plan) async {
    final plans = await loadAll();
    final index = plans.indexWhere((e) => e.id == plan.id);
    if (index < 0) {
      plans.add(plan);
    } else {
      plans[index] = plan;
    }
    await saveAll(plans);
  }

  Future<void> delete(String id) async {
    final plans = await loadAll();
    plans.removeWhere((e) => e.id == id);
    await saveAll(plans);
  }

  List<AtlasExecutionPlan> _seed() {
    final now = DateTime.now();
    AtlasExecutionTask task(
      String id,
      String title,
      int start,
      int days,
      double cost,
      double actual,
      double progress,
      AtlasExecutionPriority priority,
      AtlasExecutionTaskStatus status, {
      List<String> deps = const [],
      List<String> resources = const [],
    }) => AtlasExecutionTask(
      id: id,
      title: title,
      description: 'Atividade estratégica gerada pelo Atlas.',
      owner: 'Equipe da fazenda',
      startDate: now.add(Duration(days: start)),
      dueDate: now.add(Duration(days: start + days)),
      plannedCost: cost,
      actualCost: actual,
      progress: progress,
      priority: priority,
      status: status,
      dependencyIds: deps,
      resourceNames: resources,
    );
    return [
      AtlasExecutionPlan(
        id: 'execution_seed_1',
        farmId: '',
        title: 'Plano de intensificação produtiva',
        objective:
            'Elevar produtividade por hectare com controle de custo, prazo e capacidade operacional.',
        createdAt: now,
        tasks: [
          task(
            't1',
            'Diagnóstico de solo e pastagens',
            -18,
            12,
            18000,
            17500,
            100,
            AtlasExecutionPriority.critical,
            AtlasExecutionTaskStatus.completed,
            resources: ['Agrônomo', 'Análise de solo'],
          ),
          task(
            't2',
            'Correção e adubação de áreas prioritárias',
            -5,
            28,
            145000,
            72000,
            45,
            AtlasExecutionPriority.critical,
            AtlasExecutionTaskStatus.inProgress,
            deps: ['t1'],
            resources: ['Trator', 'Calcário', 'Adubo'],
          ),
          task(
            't3',
            'Redesenho dos piquetes',
            3,
            35,
            98000,
            8000,
            10,
            AtlasExecutionPriority.high,
            AtlasExecutionTaskStatus.inProgress,
            deps: ['t1'],
            resources: ['Cerca elétrica', 'Equipe de campo'],
          ),
          task(
            't4',
            'Implantação do manejo rotacionado',
            30,
            40,
            62000,
            0,
            0,
            AtlasExecutionPriority.high,
            AtlasExecutionTaskStatus.planned,
            deps: ['t2', 't3'],
            resources: ['Gerente', 'Equipe de manejo'],
          ),
          task(
            't5',
            'Treinamento e rotina de indicadores',
            -10,
            20,
            24000,
            9000,
            30,
            AtlasExecutionPriority.medium,
            AtlasExecutionTaskStatus.blocked,
            resources: ['Consultor', 'Equipe'],
          ),
        ],
      ),
    ];
  }
}
