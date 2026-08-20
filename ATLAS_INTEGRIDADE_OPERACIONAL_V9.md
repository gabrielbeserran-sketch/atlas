# Atlas V9 — Integridade Operacional Integrada

A V9 adiciona reconciliação cruzada somente leitura em `GET /livestock/integrity/reconciliation?farm_id=...`.

Ela detecta automaticamente: lançamentos financeiros órfãos/duplicados; movimentações de estoque órfãs; tarefas órfãs; peso atual divergente da última pesagem; estado reprodutivo divergente do último evento.

Também corrige o isolamento multiempresa em `_refresh_animal_reproduction_state`, incluindo `company_id` na consulta do último evento.

Nenhuma inconsistência é corrigida silenciosamente: a V9 primeiro mede e reporta, preservando rastreabilidade.
