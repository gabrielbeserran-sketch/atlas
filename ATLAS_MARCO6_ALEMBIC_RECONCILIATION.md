# Atlas — Marco 6 — Reconciliação Alembic / Supabase

## Problema encontrado

O PostgreSQL do Supabase já continha `email_verification_tokens`, enquanto o
histórico Alembic tentava executar novamente `CREATE TABLE`. Isso causava:

`psycopg.errors.DuplicateTable: relation "email_verification_tokens" already exists`

O risco não estava restrito a essa tabela: as 40 migrations históricas do
Atlas contêm mais de 200 operações `create_table`, além de índices e colunas.
Corrigir apenas uma migration poderia apenas deslocar a falha para o próximo
objeto já existente.

## Estratégia aplicada

Foi criada uma camada de reconciliação em `backend/alembic/reconcile.py`.

Durante migrations online:

- `create_table`: preserva a tabela quando ela já existe;
- `create_index`: preserva o índice quando já existe;
- `add_column`: preserva a coluna quando já existe;
- `create_unique_constraint`: preserva a unique quando equivalente já existe;
- objetos ausentes continuam sendo criados normalmente.

Nenhuma tabela é apagada e nenhum dado existente é removido.

## Proteção contra falso sucesso

Ignorar um `CREATE TABLE` existente poderia esconder uma tabela incompleta.
Por isso, após `alembic upgrade head`, o startup agora executa:

1. verificação do head real do Alembic;
2. auditoria `Base.metadata` x schema PostgreSQL;
3. bloqueio da API se faltar tabela ou coluna esperada pelo ORM.

Diferenças de tipo equivalentes/ambíguas são relatadas como aviso, não como
bloqueio automático.

## Próximos erros antecipados

A nova cadeia reduz os próximos riscos prováveis:

- outra `DuplicateTable`;
- `DuplicateObject` de índices;
- `DuplicateColumn`;
- unique constraint já existente;
- Alembic marcado como head sem schema suficiente;
- tabela/coluna ORM ausente após reconciliação.

O startup só libera Uvicorn depois de:

`preflight -> Alembic -> head check -> schema contract -> API`.
