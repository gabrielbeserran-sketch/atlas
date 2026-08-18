# Atlas — Marco 6 — Reconciliação Alembic v4

## Erro atual tratado

O PostgreSQL retornou:

`relation "ix_atlas_ai_recommendations_company" already exists`

mesmo com `op.create_index` protegido. Isso indica uma rota de criação de índice
que escapava do guard explícito, como índice declarativo associado a uma tabela
ou SQL cru em migration histórica.

## Proteções adicionadas

### Objetos declarativos em tabela já existente

Ao preservar uma tabela já existente, o reconciliador agora filtra índices e
constraints declarativos que já existam no PostgreSQL antes de continuar.

### SQL cru CREATE INDEX

`op.execute` agora recebe um guard conservador apenas para `CREATE INDEX` e
`CREATE UNIQUE INDEX` nomeados. Se o índice já existir na tabela alvo, a
operação é ignorada. Outros SQL continuam executando normalmente.

## Próximos erros previstos

Depois de eliminar DuplicateTable/DuplicateIndex, os próximos riscos mais
prováveis são:

1. constraint duplicada por rota declarativa;
2. operação raw SQL de índice;
3. coluna NOT NULL ausente em tabela com dados;
4. `batch_alter_table` tentando remover constraint já ausente;
5. divergência final ORM x PostgreSQL;
6. Alembic atingir head e Uvicorn iniciar;
7. health check público revelar erro de startup da aplicação.

A v4 cobre os itens 1, 2 e 4 antecipadamente. O item 3 permanece bloqueante
de propósito para proteger dados, e o item 5 continua sendo auditado pelo
schema contract.
