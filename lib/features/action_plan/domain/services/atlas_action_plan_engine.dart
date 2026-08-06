import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasActionPlanEngine {
  const AtlasActionPlanEngine();

  AtlasActionPlan generate(AtlasFarmAudit audit) {
    final now = DateTime.now();
    final missions = <AtlasActionMission>[];
    var sequence = 0;

    for (final problem in audit.problems) {
      sequence++;
      missions.add(AtlasActionMission(
        id: 'mission_problem_${problem.id}',
        title: problem.title,
        description: problem.description,
        area: problem.area,
        priority: problem.priority,
        status: AtlasMissionStatus.pending,
        responsible: _responsible(problem.area),
        startDate: now.add(Duration(days: _startOffset(problem.priority, sequence))),
        dueDate: now.add(Duration(days: problem.recommendedDeadlineDays)),
        expectedImpact: problem.estimatedAnnualImpact,
        checklist: _checklist(problem.area, 'problem_${problem.id}'),
      ));
    }

    for (final opportunity in audit.opportunities.take(4)) {
      sequence++;
      missions.add(AtlasActionMission(
        id: 'mission_opportunity_${opportunity.id}',
        title: opportunity.title,
        description: opportunity.description,
        area: opportunity.area,
        priority: opportunity.priority,
        status: AtlasMissionStatus.pending,
        responsible: _responsible(opportunity.area),
        startDate: now.add(Duration(days: 7 + sequence)),
        dueDate: now.add(Duration(days: 30 + sequence * 3)),
        expectedImpact: opportunity.estimatedReturn - opportunity.estimatedInvestment,
        checklist: _checklist(opportunity.area, 'opportunity_${opportunity.id}'),
      ));
    }

    missions.sort((a, b) {
      final byPriority = _weight(b.priority).compareTo(_weight(a.priority));
      return byPriority != 0 ? byPriority : a.dueDate.compareTo(b.dueDate);
    });

    return AtlasActionPlan(
      id: 'action_plan_${audit.farmId}_${now.microsecondsSinceEpoch}',
      farmId: audit.farmId,
      farmName: audit.farmName,
      auditId: audit.id,
      createdAt: now,
      updatedAt: now,
      missions: missions,
    );
  }

  int _weight(AtlasFarmAuditPriority p) {
    switch (p) {
      case AtlasFarmAuditPriority.critical: return 4;
      case AtlasFarmAuditPriority.high: return 3;
      case AtlasFarmAuditPriority.moderate: return 2;
      case AtlasFarmAuditPriority.low: return 1;
    }
  }

  int _startOffset(AtlasFarmAuditPriority p, int sequence) {
    switch (p) {
      case AtlasFarmAuditPriority.critical: return 0;
      case AtlasFarmAuditPriority.high: return 2 + sequence;
      case AtlasFarmAuditPriority.moderate: return 5 + sequence;
      case AtlasFarmAuditPriority.low: return 10 + sequence;
    }
  }

  String _responsible(AtlasFarmAuditArea area) {
    switch (area) {
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.reproduction:
      case AtlasFarmAuditArea.biosecurity:
      case AtlasFarmAuditArea.animalWelfare:
        return 'Médico-veterinário';
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return 'Responsável técnico';
      case AtlasFarmAuditArea.financial:
      case AtlasFarmAuditArea.inventory:
        return 'Gestor da fazenda';
      default:
        return 'Equipe operacional';
    }
  }

  List<AtlasMissionChecklistItem> _checklist(AtlasFarmAuditArea area, String prefix) {
    final specific = switch (area) {
      AtlasFarmAuditArea.sanitary => 'Revisar protocolos sanitários',
      AtlasFarmAuditArea.reproduction => 'Revisar calendário reprodutivo',
      AtlasFarmAuditArea.nutrition => 'Avaliar dieta e suplementação',
      AtlasFarmAuditArea.pastures => 'Inspecionar oferta e qualidade do pasto',
      AtlasFarmAuditArea.financial => 'Validar custo, orçamento e retorno',
      AtlasFarmAuditArea.inventory => 'Conferir estoque e pontos de reposição',
      AtlasFarmAuditArea.biosecurity => 'Revisar barreiras e fluxo de entrada',
      AtlasFarmAuditArea.people => 'Alinhar e treinar a equipe',
      _ => 'Realizar diagnóstico detalhado da área',
    };

    final titles = <String>[
      specific,
      'Definir responsável e recursos necessários',
      'Executar a intervenção planejada',
      'Registrar evidências e indicadores',
      'Reavaliar o resultado alcançado',
    ];

    return List.generate(titles.length, (i) => AtlasMissionChecklistItem(id: '${prefix}_$i', title: titles[i], completed: false));
  }
}
