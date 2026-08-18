# Atlas — Marco 6 — Reconciliação Estrutural Alembic v2

## Erro que motivou esta evolução

Após preservar tabelas já existentes, uma migration tentou criar índice em
coluna ausente:

`CREATE INDEX ... ON atlas_ml_messages (session_id)`

e o PostgreSQL respondeu que uma coluna esperada não existia.

Isso demonstrou que algumas tabelas pré-existentes não estavam estruturalmente
iguais à definição histórica da migration.

## Comportamento v2

Quando uma migration executa `create_table()` e a tabela já existe, o Atlas
agora compara as colunas declaradas pela migration com o schema real.

### Coluna ausente segura

É adicionada automaticamente quando:
- a tabela está vazia; ou
- a coluna aceita NULL; ou
- existe default/server_default apropriado.

### Coluna ausente perigosa

Se a tabela contém dados e a migration exige coluna `NOT NULL` sem default, o
startup é bloqueado com mensagem explícita. O Atlas NÃO inventa valores e NÃO
apaga dados.

## Operações protegidas

- create_table
- add_column
- create_index
- create_unique_constraint
- create_foreign_key
- create_check_constraint

Índices, uniques e FKs só são criados depois da confirmação de que as colunas
necessárias existem.

## Pós-migração

Mesmo quando as migrations chegam ao head, a API só inicia após a comparação:

`Base.metadata <-> PostgreSQL`

Falta de tabela ou coluna do ORM continua sendo erro bloqueante.

## Objetivo

Eliminar a sequência de falhas por objetos duplicados/incompletos sem usar:
- DROP TABLE;
- DELETE de dados;
- `alembic stamp head` indiscriminado;
- criação silenciosa de valores obrigatórios desconhecidos.
