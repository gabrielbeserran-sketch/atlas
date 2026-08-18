# Atlas — Marco 6 — Reconciliação Alembic v5

## Causa estrutural confirmada

O erro persistente:

`relation "ix_atlas_ai_recommendations_company" already exists`

não era uma falha do guard local da tabela. Em PostgreSQL, nomes de índices são
relações do schema e precisam ser únicos no namespace do schema. Portanto, um
índice com esse nome em OUTRA tabela também bloqueia:

`CREATE INDEX ix_atlas_ai_recommendations_company ON atlas_ai_recommendations_v2 (...)`

A v5 consulta `pg_catalog.pg_class`, `pg_namespace` e `pg_index` antes de criar
índices.

## Comportamento da v5

- se o índice pedido já existe na tabela alvo: preserva;
- se o nome está livre no schema: cria com o nome original;
- se o mesmo nome pertence a outra tabela: cria o índice correto na tabela alvo
  com nome alternativo determinístico;
- nomes alternativos respeitam o limite PostgreSQL de 63 bytes;
- se até o nome alternativo colidir: bloqueia com diagnóstico explícito.

Isso evita simplesmente "pular" o índice, o que deixaria a tabela alvo sem a
estrutura de performance esperada.

## Previsão dos próximos riscos

Inventário das migrations:
{
  "op_create_table": 203,
  "op_create_index": 157,
  "op_add_column": 15,
  "op_batch_alter_table": 10,
  "op_alter_column": 1,
  "op_execute": 0,
  "sa_enum": 0,
  "postgresql_enum": 0,
  "unique_constraint": 41,
  "foreign_key_constraint": 3,
  "check_constraint": 0,
  "index_declarative": 0
}

Próximos candidatos, em ordem provável:

1. colisão schema-global de outro índice — agora coberta;
2. coluna NOT NULL ausente em tabela com dados — bloqueio seguro já existente;
3. `batch_alter_table`/constraint histórica — guard v3 preservado;
4. schema contract encontrar tabela/coluna atual ausente;
5. Alembic atingir head;
6. Uvicorn iniciar e o `/health/ready` testar dependências da aplicação.

Índices com mesmo nome explícito declarados para tabelas diferentes no próprio
histórico: {
  "ix_atlas_ai_recommendations_company": [
    {
      "file": "20260805_0006_atlas_ai_2.py",
      "table": "atlas_ai_recommendations"
    },
    {
      "file": "20260805_0011_atlas_ai_enterprise.py",
      "table": "atlas_ai_recommendations_v2"
    }
  ],
  "ix_atlas_ai_recommendations_status": [
    {
      "file": "20260805_0006_atlas_ai_2.py",
      "table": "atlas_ai_recommendations"
    },
    {
      "file": "20260805_0011_atlas_ai_enterprise.py",
      "table": "atlas_ai_recommendations_v2"
    }
  ]
}.
