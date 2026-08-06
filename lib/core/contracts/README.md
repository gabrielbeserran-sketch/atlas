# Contratos canônicos de inteligência do Atlas

Esta pasta define a linguagem comum entre os módulos de inteligência e gestão.
Ela não implementa regras de negócio e não substitui os motores existentes.

Fontes canônicas:

- decisão: `decision_engine_v2`
- recomendação: `recommendation_intelligence`
- alerta: `executive_alerts`
- ação: `action_plan` e executores estratégicos
- cenário: `digital_twin` e `scenario_simulator`
- orquestração executiva: `executive_brain`

Os módulos legados devem ser conectados gradualmente por adaptadores, sem criar
novos modelos concorrentes.

## Adaptadores oficiais implementados

- `decision_engine_v2` → `AtlasDecisionContract`
  - Arquivo: `features/decision_engine_v2/domain/adapters/atlas_decision_engine_v2_contract_adapter.dart`
  - Regra: o adaptador apenas traduz o resultado do motor; não recalcula score,
    prioridade, risco, prazo ou impacto.

## Alinhamento operacional canônico

A partir desta versão:

- `Decision Engine V2` continua sendo a fonte das decisões priorizadas.
- `AtlasActionPlanCanonicalAdapter` converte essas decisões em missões do módulo `action_plan`, sem recalcular prioridades.
- `Executive Alerts` continua sendo a fonte dos alertas operacionais.
- `AtlasExecutiveAlertContractAdapter` converte os alertas existentes em `AtlasAlertContract`, sem criar regras paralelas.
- `AtlasCanonicalOperationsService` reúne decisões, ações e alertas para consumo por painéis, Copiloto e Cérebro Executivo.

A regra obrigatória é: adaptar e integrar o que já existe antes de criar qualquer novo motor.
