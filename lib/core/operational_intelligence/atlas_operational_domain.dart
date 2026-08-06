enum AtlasOperationalDomain {
  animal,
  reproduction,
  health,
  finance,
  inventory,
  goals,
  tasks,
  decisions,
  workflows,
  executive,
  system,
  unknown,
}

String atlasOperationalDomainLabel(
  AtlasOperationalDomain domain,
) {
  switch (domain) {
    case AtlasOperationalDomain.animal:
      return 'Rebanho';
    case AtlasOperationalDomain.reproduction:
      return 'Reprodução';
    case AtlasOperationalDomain.health:
      return 'Sanidade';
    case AtlasOperationalDomain.finance:
      return 'Financeiro';
    case AtlasOperationalDomain.inventory:
      return 'Estoque';
    case AtlasOperationalDomain.goals:
      return 'Metas';
    case AtlasOperationalDomain.tasks:
      return 'Tarefas';
    case AtlasOperationalDomain.decisions:
      return 'Decisões';
    case AtlasOperationalDomain.workflows:
      return 'Fluxos';
    case AtlasOperationalDomain.executive:
      return 'Inteligência executiva';
    case AtlasOperationalDomain.system:
      return 'Sistema';
    case AtlasOperationalDomain.unknown:
      return 'Não identificado';
  }
}
