# Atlas — V10 — Motor de Alertas e Inteligência Operacional

## Objetivo

A V10 transforma os dados integrados e reconciliados pelas V6–V9 em sinais
automáticos de decisão. O motor é **read-only**: ele não corrige nem altera a
produção sem uma ação explícita do usuário.

## Endpoints

### Alertas operacionais

`GET /api/v1/livestock/intelligence/operational-alerts?farm_id=<ID>`

Consolida alertas de:

- Integridade V9;
- estoque mínimo, ruptura e vencimento;
- manejos sanitários vencidos/próximos;
- carência sanitária ativa;
- ECC baixo;
- pesagem desatualizada ou ausente;
- GMD negativo/perda de peso;
- parto próximo ou data prevista ultrapassada;
- plano nutricional próximo do fim ou vencido;
- contas vencidas;
- tarefas vencidas ou próximas.

Cada alerta recebe severidade, `priority_score`, entidade de origem, prazo e
`recommended_action`.

### Resumo executivo

`GET /api/v1/livestock/intelligence/operational-summary?farm_id=<ID>`

Retorna:

- `operational_score` de 0 a 100;
- `operational_level`;
- resumo do rebanho;
- receitas, despesas e saldo;
- contagem de alertas por severidade/área;
- cinco ações prioritárias.

## Regra de segurança

Os endpoints respeitam empresa e fazenda, exigem `livestock.read` e não usam
`db.add`, `db.delete` ou `db.commit`.

## Próxima etapa

A V11 deve conectar este motor ao Dashboard/Command Center do Flutter, com
cards de prioridade, filtros e navegação direta para o registro de origem.
