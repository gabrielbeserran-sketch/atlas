# Atlas — V14 + V15

## V14 — Agenda Inteligente

A Agenda passa a ser reconciliada automaticamente a partir das fontes
operacionais oficiais.

Fontes:

- Pesagens: próxima pesagem em 30 dias.
- Sanidade: `next_date` do evento sanitário.
- Reprodução: `expected_date` do evento reprodutivo.
- Nutrição: data final do plano nutricional.

Cada tarefa possui `source_type/source_id`, portanto a sincronização é
idempotente e cancela duplicidades históricas.

Endpoint de backfill/reconciliação:

`POST /api/v1/livestock/intelligence/smart-agenda/reconcile?farm_id=...`

O Dashboard chama a reconciliação em background antes de carregar a Agenda.
Falha nessa sincronização não impede o Dashboard de abrir.

## V15 — Indicadores Executivos

O resumo operacional passa a incluir:

- taxa de prenhez;
- fêmeas prenhes / elegíveis;
- peso médio;
- GMD médio;
- custo por animal ativo;
- itens em estoque crítico;
- tarefas abertas e atrasadas;
- custo nutricional mensal projetado.

O Flutter apresenta esses indicadores em um card executivo independente,
imediatamente abaixo da Inteligência Operacional.
