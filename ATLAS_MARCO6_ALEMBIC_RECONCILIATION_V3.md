# Atlas — Marco 6 — Reconciliação Alembic v3

## Recursão corrigida

A v2 interceptava `op.add_column`, mas o helper interno voltava a chamar a
mesma operação já interceptada. Isso produzia recursão.

A v3 captura a referência ORIGINAL de `op.add_column` antes do monkeypatch e
a passa como callback para `_apply_missing_column`.

## Próximos riscos previstos e já cobertos

A auditoria das migrations de upgrade encontrou também:
- `batch_alter_table`;
- `alter_column`;
- `drop_constraint`.

Essas operações eram candidatas naturais a serem os próximos erros após a
recursão. A v3 inclui proxy seguro para batch que protege:

- `batch.add_column`;
- `batch.create_index`;
- `batch.create_foreign_key`;
- `batch.drop_constraint`.

`op.alter_column` também verifica previamente se a coluna alvo existe.

## Proteções preservadas

- sem DROP TABLE automático;
- sem DELETE de dados;
- sem `alembic stamp head` automático;
- sem inventar valores para NOT NULL sem default em tabela com dados;
- auditoria final ORM x PostgreSQL antes de liberar Uvicorn.

## Barreira anti-regressão

`backend/scripts/audit_alembic_reconciler_contract.py` inspeciona o AST do
reconciliador e impede que os helpers críticos voltem a chamar diretamente
operações Alembic interceptadas.
