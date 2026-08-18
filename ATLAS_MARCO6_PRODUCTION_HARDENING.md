# Atlas — Marco 6 Production Hardening

## Causa real do erro de IPv4/IPv6

A auditoria reproduziu o erro:

`'aws-0-ca-central-1.pooler.supabase.com' does not appear to be an IPv4 or IPv6 address`

O hostname DNS do Supabase é válido. O erro era provocado pelo uso literal de
`[YOUR-PASSWORD]` (ou por colchetes não escapados) dentro da URL passada ao
parser `urllib`. O Atlas agora usa o parser oficial do SQLAlchemy e rejeita
placeholders com uma mensagem direta.

## Próximos riscos tratados antecipadamente

1. **Senha placeholder ou caracteres reservados**
   - parser SQLAlchemy;
   - erro explícito;
   - escaping seguro da URL.

2. **Prisma/Transaction Pooler**
   - remove `pgbouncer`, `connection_limit`, `pool_timeout`,
     `statement_cache_size` e `prepared_statements`;
   - mantém parâmetros PostgreSQL válidos.

3. **Prepared statements no Transaction Pooler**
   - psycopg3 usa `prepare_threshold=None`;
   - Alembic e API compartilham o mesmo contrato.

4. **Divergência entre Alembic e API**
   - migrations usam `build_engine(for_migrations=True)`;
   - pós-migração compara `alembic_version` com os heads reais.

5. **Redis/Key Value incorreto**
   - preflight executa `PING` antes de abrir a API.

6. **Supabase Storage/key incorreto**
   - preflight verifica o bucket privado;
   - suporta legacy `service_role` e nova `sb_secret_*`.

7. **URL pública Render digitada manualmente**
   - `RENDER_EXTERNAL_URL` passa a ser autoridade para domínio onrender.com;
   - também é incluída automaticamente no CORS.

## Recomendação de conexão

Para o Web Service Render, prefira o **Supabase Session Pooler (porta 5432)**,
mostrado como `DIRECT_URL` no fluxo Prisma/Connect. Transaction Pooler (6543)
continua suportado pelo Atlas, mas exige prepared statements desativados.


## Correção Render — import dos scripts de startup

O Render chegou corretamente ao `render_preflight.py`, porém a execução direta:

`python /app/scripts/render_preflight.py`

colocava `/app/scripts` como primeiro caminho de importação. Com isso, o pacote
principal `/app/app` não era encontrado e o startup falhava com:

`ModuleNotFoundError: No module named 'app'`

A cadeia de produção agora usa execução modular a partir de `/app`:

- `python -m scripts.render_preflight`
- `python -m alembic upgrade head`
- `python -m scripts.render_post_migration_check`
- `python -m uvicorn app.main:app`

Também foi criado `backend/scripts/__init__.py` para tornar o contrato de pacote
explícito e reduzir diferenças entre execução local e container.
