import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/consultancy_workflow/domain/models/atlas_consultancy_case.dart';

class AtlasConsultancyWorkflowRepository {
  static const String _key = 'atlas_consultancy_workflow_cases_v1';

  Future<List<AtlasConsultancyCase>> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> raw = preferences.getStringList(_key) ?? <String>[];
    if (raw.isEmpty) {
      final List<AtlasConsultancyCase> seed = _seed();
      await save(seed);
      return seed;
    }
    return raw.map(AtlasConsultancyCase.fromJson).toList();
  }

  Future<void> save(List<AtlasConsultancyCase> cases) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      cases.map((item) => item.toJson()).toList(),
    );
  }

  List<AtlasConsultancyCase> _seed() {
    final DateTime now = DateTime.now();
    return <AtlasConsultancyCase>[
      AtlasConsultancyCase(
        id: 'case_demo_1',
        clientName: 'João da Silva',
        farmName: 'Fazenda Boa Vista',
        stage: AtlasConsultancyStage.execution,
        createdAt: now.subtract(const Duration(days: 40)),
        visits: <AtlasConsultancyVisit>[
          AtlasConsultancyVisit(
            id: 'visit_1',
            date: now.subtract(const Duration(days: 20)),
            summary: 'Diagnóstico inicial e levantamento dos indicadores.',
            completed: true,
          ),
          AtlasConsultancyVisit(
            id: 'visit_2',
            date: now.add(const Duration(days: 7)),
            summary: 'Revisão do plano reprodutivo e sanitário.',
            completed: false,
          ),
        ],
        actions: <AtlasConsultancyAction>[
          AtlasConsultancyAction(
            id: 'action_1',
            title: 'Revisar protocolo reprodutivo do lote A',
            responsible: 'Veterinário',
            deadline: now.add(const Duration(days: 10)),
            completed: false,
          ),
          AtlasConsultancyAction(
            id: 'action_2',
            title: 'Atualizar inventário de medicamentos',
            responsible: 'Gerente da fazenda',
            deadline: now.subtract(const Duration(days: 2)),
            completed: true,
          ),
        ],
        notes: 'Caso demonstrativo para validar o fluxo completo de consultoria.',
      ),
    ];
  }
}
