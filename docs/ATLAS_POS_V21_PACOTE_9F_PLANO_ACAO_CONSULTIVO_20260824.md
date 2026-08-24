# Atlas Pós-V21 — Pacote 9F — Plano de Ação Consultivo Integrado

## Lacuna encontrada

O Atlas já possuía `atlas_action_plan_items` e endpoints corporativos de consultoria desde a migration 0024, além da Agenda oficial em `operational_tasks`. Porém, a Central da Consultoria apenas exibia prioridades e não transformava essas decisões em um plano persistente ligado à execução.

## Entrega

- ativa a persistência oficial de ações consultivas por fazenda;
- permite transformar as prioridades da inteligência operacional em ações;
- cada ação cria uma tarefa oficial da Agenda na mesma transação;
- reenvios da mesma recomendação são idempotentes;
- concluir na Central conclui a tarefa da Agenda;
- concluir/editar a tarefa integrada na Agenda devolve status, prazo, prioridade e evidência ao plano consultivo;
- a Central passa a mostrar as ações abertas e seu vínculo com a Agenda.

## Banco

Migration `20260824_0047` adiciona `idempotency_key` à tabela existente `atlas_action_plan_items` e cria unicidade por `company_id + farm_id + idempotency_key`.

## Princípio

O pacote não cria um segundo motor de plano de ação. Ele conecta estruturas já existentes: Inteligência Operacional → Consultoria → `atlas_action_plan_items` → Agenda (`operational_tasks`).
