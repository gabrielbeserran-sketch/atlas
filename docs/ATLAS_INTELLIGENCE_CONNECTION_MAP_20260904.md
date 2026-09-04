# Atlas — Mapa de conexões da Inteligência

**Data:** 04/09/2026  
**Fase:** 6.5.3 — arquitetura de Inteligência  
**Base auditada:** `master` em `a62e526` antes desta documentação

## Decisão de arquitetura

O produto tem uma única porta de entrada de Inteligência no menu principal:

`Análises` → rota interna `Inteligência` → `AtlasIntelligenceCenterScreen`.

Os nomes históricos (Atlas IA, Copiloto, Diagnóstico Inteligente, Inteligência
Preditiva e Inteligência da Fazenda) descrevem capacidades e implementações;
não descrevem produtos ou itens concorrentes de menu. Nenhum pacote listado
neste documento pode ser removido apenas por não aparecer no menu: primeiro é
necessário migrar seus consumidores, dados persistidos e testes.

## Grafo de entrada comprovado

| Origem | Destino | Papel | Estado |
|---|---|---|---|
| `atlas_home_shell.dart` | `AtlasIntelligenceCenterScreen` | única rota direta do menu, rótulo visível **Análises** | oficial |
| `farm_detail_screen.dart` | `AtlasIntelligenceCenterScreen` | acesso contextual da fazenda selecionada | oficial |
| `finance_overview_screen.dart` | Central, aba 3 | atalho para simulação financeira | oficial |
| Central, abas 0–4 | resumo, prioridades, áreas, simulação, decisões | experiência nativa baseada em `/ai-operational/...` | oficial |
| detalhe da fazenda | Atlas IA, diagnóstico, predição, Copiloto e visão da fazenda | ferramentas legadas, acionadas por conectores explícitos | compatibilidade controlada |

O `atlas_home_shell.dart` não importa telas legadas de IA. O contrato
`test/phase653/intelligence_connection_map_contract_test.dart` protege esta
propriedade e também evita que um mesmo pacote seja simultaneamente absorvido
pela Central e por um módulo dono do dado.

## Capacidades canônicas e implementações

| Capacidade do usuário | Acesso canônico | Implementações preservadas |
|---|---|---|
| Conversação Atlas | Central; conector contextual quando a tela de fazenda possui o contexto local completo | `atlas_ai`, `atlas_ai_2`, `atlas_ai_enterprise`, `atlas_advanced_ai`, `copilot` |
| Diagnóstico e risco | Central, aba **O que fazer** | `diagnostics` |
| Predição e simulação | Central, aba **Simular** | `predictive`, `predictive_ai`, `predictive_analytics`, `atlas_predictive_ai_suite`, `scenario_simulator`, `strategic_scenario_planning`, `optimization_engine` |
| Decisão e recomendação | Central, aba **Decisões** | `decision_intelligence_lab`, `recommendation_intelligence`, `command_center`, `atlas_autonomous_enterprise`, `autonomous_consultant` |
| Inteligência executiva | Central, aba **Resumo** | `atlas_intelligence`, `atlas_intelligence_reports_experience`, `atlas_executive_intelligence`, `executive_intelligence`, `executive_brain`, `executive_ai_advisor`, `data_intelligence`, `performance_intelligence` |

## Inteligências que pertencem ao módulo do dado

Esses pacotes são especializados. Eles não devem ganhar uma rota própria de
menu nem ser copiados para a Central. A Central poderá apontar para o módulo
dono quando houver um fluxo operacional comprovado.

| Pacote | Dono | Conexão funcional esperada |
|---|---|---|
| `animal_intelligence_360`, `animal_weight_intelligence` | Rebanho | acompanhamento individual e desempenho |
| `atlas_reproductive_ai` | Reprodução | decisão baseada em serviços, cio e prenhez |
| `atlas_veterinary_ai` | Sanidade | risco, protocolos e assistência veterinária |
| `atlas_supply_chain` | Estoque | suprimentos, validade e reposição |
| `atlas_land_intelligence`, `atlas_environmental_ai`, `atlas_sustainability_ecosystem`, `atlas_sustainability_enterprise` | Campo | pasto, clima, ambiente e execução |

## Serviços e dados que a Central usa hoje

`AtlasIntelligenceService` é o adaptador de produção para os seguintes
contratos de API:

- `POST /ai-operational/farms/{farmId}/context`
- `POST /ai-operational/farms/{farmId}/recommendations`
- `POST /ai-operational/farms/{farmId}/simulate`
- `POST /ai-operational/recommendations/{recommendationId}/decision`
- `POST /ai-operational/farms/{farmId}/memory`
- `POST /ai-operational/farms/{farmId}/automations`

As automações são criadas com `requires_approval: true`; a Central não deve
executar uma ação de manejo ou financeira sem aprovação explícita. Relatórios
continuam no módulo Relatórios e a execução continua nos módulos que possuem
o dado de origem.

## Conectores legados e condição para aposentadoria

O detalhe de uma fazenda ainda monta dados locais por meio de rebanho,
animais, piquetes, financeiro, estoque e agenda; então produz diagnóstico,
predição e contexto conversacional. Por isso ele ainda abre telas legadas por
callbacks. Aposentar esses callbacks só será seguro quando a Central conseguir
formar o mesmo contexto — ou quando o backend expuser contrato equivalente — e
os fluxos abaixo tiverem testes de regressão:

1. abrir cada uma das cinco capacidades com uma fazenda ativa;
2. navegar da recomendação para o módulo dono do dado;
3. manter memória, cenários e ações rastreadas por fazenda;
4. voltar à Central sem criar tela em branco;
5. validar indisponibilidade de dados com mensagem visível, nunca com área vazia.

## Alterações futuras permitidas

1. Antes de adicionar uma nova “IA”, classificá-la em uma das cinco capacidades
   ou em um módulo dono do dado.
2. Antes de remover pacote, gerar a lista de importadores e executar a suíte
   direcionada; ausência de item de menu não é evidência de código morto.
3. Novos atalhos devem abrir a Central ou o módulo dono. Não criar rota lateral
   para telas de engine, laboratório ou protótipo.
4. Cada lote de alteração deve ter `flutter analyze`, testes direcionados,
   `git status`, commit e tag de checkpoint após homologação.

## Próximo gate

Com a taxonomia e o mapa de conexões protegidos, o próximo trabalho desta fase
é tornar a abertura contextual da **Conversação Atlas** disponível pela Central
sem duplicar o agregador de dados da fazenda. Isso exige extrair o carregamento
que hoje está no detalhe da fazenda para um serviço compartilhado e cobri-lo
com testes antes de qualquer mudança de interface.
