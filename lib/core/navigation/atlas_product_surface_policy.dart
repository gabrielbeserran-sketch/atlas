/// Política de arquitetura de informação do Atlas.
///
/// A navegação de produção não espelha pastas, sprints ou protótipos. Recursos
/// avançados são absorvidos pelo módulo que é dono do dado ou permanecem
/// internos até possuírem contrato e utilidade operacional comprovados.
abstract final class AtlasProductSurfacePolicy {
  static const Set<String> mainMenuLabels = {
    'Dashboard',
    'Realizar manejo',
    'Agenda',
    'Dr. Beserra',
    'Rebanho',
    'Sanidade',
    'Reprodução',
    'Fazendas',
    'Nutrição',
    'Estoque',
    'Campo',
    'Financeiro',
    'Inteligência',
    'Relatórios',
    'Offline',
    'Consultoria',
  };

  static const Set<String> animalCenterSections = {
    'Resumo',
    'Histórico',
    'Desempenho',
    'Sanidade',
    'Reprodução',
    'Genealogia',
    'Arquivos',
  };

  static const Map<String, String> advancedCapabilityOwner = {
    'inteligência reprodutiva': 'Reprodução',
    'sanidade inteligente': 'Sanidade',
    'nutrição de precisão': 'Nutrição',
    'cadeia de suprimentos': 'Estoque',
    'logística de suprimentos': 'Estoque',
    'inteligência financeira': 'Financeiro',
    'alocação de capital': 'Financeiro',
    'inteligência de campo': 'Campo',
    'geoprocessamento': 'Campo',
    'clima': 'Campo',
    'business intelligence': 'Inteligência',
    'análise preditiva': 'Inteligência',
    'simulação de cenários': 'Inteligência',
    'relatórios gerenciais': 'Relatórios',
    'contato veterinário': 'Consultoria',
    'boletins mensais': 'Consultoria',
  };


  /// Quantidade de famílias especializadas já auditadas por módulo.
  ///
  /// O número não cria itens de menu. Serve para impedir que recursos antigos
  /// voltem a aparecer soltos: cada família precisa permanecer absorvida pelo
  /// módulo proprietário ou classificada como interna.
  static const Map<String, int> specializedCapabilityCountByOwner = {
    'Rebanho': 0,
    'Reprodução': 3,
    'Sanidade': 1,
    'Nutrição': 2,
    'Estoque': 5,
    'Financeiro': 4,
    'Campo': 11,
    'Inteligência': 28,
    'Análises': 28,
    'Relatórios': 3,
    'Consultoria': 2,
    'Interno': 16,
  };

  /// Fluxos que devem permanecer visíveis na central de cada módulo.
  ///
  /// A regra é tarefa primeiro, tecnologia depois: o usuário precisa saber
  /// o que consegue fazer, sem conhecer nomes de pacotes, sprints ou motores.
  static const Map<String, List<String>> moduleWorkflows = {
    'Rebanho': [
      'Localizar e acompanhar animais',
      'Ver evolução de peso e desempenho',
      'Executar manejo coletivo',
    ],
    'Reprodução': [
      'Registrar serviço ou diagnóstico',
      'Acompanhar prenhez e concepção',
      'Planejar próximas ações reprodutivas',
    ],
    'Sanidade': [
      'Registrar atendimento ou aplicação',
      'Acompanhar protocolos, retornos e carências',
      'Priorizar animais que exigem atenção',
    ],
    'Nutrição': [
      'Criar e revisar dietas',
      'Acompanhar consumo, custo e desempenho',
      'Controlar a integração com o estoque',
    ],
    'Estoque': [
      'Registrar entradas e saídas',
      'Acompanhar mínimos, validade e reposição',
      'Entender quantidade e valor armazenado',
    ],
    'Financeiro': [
      'Registrar receitas e despesas',
      'Acompanhar caixa, compromissos e vencimentos',
      'Interpretar resultado dentro do ciclo pecuário',
    ],
    'Campo': [
      'Acompanhar piquetes e ocupação',
      'Organizar operações e responsáveis',
      'Monitorar recursos, clima e execução',
    ],
    'Análises': [
      'Cruzar informações dos módulos oficiais',
      'Identificar desvios, tendências e prioridades',
      'Simular cenários antes de tomar decisões',
    ],
    'Relatórios': [
      'Consolidar resultados por fazenda e período',
      'Comparar indicadores e acompanhar ações',
      'Exportar informações em PDF ou Excel',
    ],
  };

  /// Fronteira funcional entre as três últimas áreas de gestão.
  /// Esta regra evita que execução, interpretação e documentação virem
  /// três versões da mesma tela.
  static const Map<String, String> moduleResponsibility = {
    'Campo':
        'Use Campo para registrar e acompanhar o trabalho feito na fazenda.',
    'Análises':
        'Use Análises para entender os dados e decidir o que fazer.',
    'Relatórios':
        'Use Relatórios para juntar, comparar e exportar informações.',
  };

  static const Map<String, String> moduleDoesNotReplace = {
    'Campo':
        'Para entender resultados, use Análises. Para documentos, use Relatórios.',
    'Análises':
        'Para registrar um manejo, use o módulo correspondente. Para exportar, use Relatórios.',
    'Relatórios':
        'Registros e manejos devem ser feitos nos módulos onde aconteceram.',
  };

  /// Recursos especializados sem contrato produtivo próprio continuam fora
  /// das rotas do produtor até serem absorvidos por uma central oficial.
  static const Set<String> internalOnlyCapabilityRoots = {
    'release_management',
    'release_engineering',
    'publication_center',
    'quality_center',
    'flutter_quality',
    'security_center',
    'security_privacy_continuity',
    'data_governance',
    'saas_admin',
    'enterprise_platform',
    'atlas_saas_platform',
    'ml_platform',
    'atlas_backend_foundation',
    'atlas_cloud_security_enterprise',
    'atlas_platform_resilience',
    'atlas_quality_release',
    'atlas_auth_sync_enterprise',
  };


  /// Famílias de implementação que nunca devem virar item direto do menu do
  /// produtor. Elas são infraestrutura, administração, laboratório ou legado.
  static const Set<String> internalFeatureFamilies = {
    'release_management',
    'release_engineering',
    'publication_center',
    'quality_center',
    'flutter_quality',
    'security_center',
    'security_privacy_continuity',
    'data_governance',
    'saas_admin',
    'enterprise_platform',
    'atlas_saas_platform',
    'ml_platform',
    'atlas_backend_foundation',
    'atlas_cloud_security_enterprise',
    'atlas_platform_resilience',
    'atlas_quality_release',
    'atlas_auth_sync_enterprise',
    'commercial_readiness',
    'pilot_program',
  };
}
