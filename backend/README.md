# Atlas Enterprise Backend — Pacote 24D

Backend real do Projeto Atlas com:

- FastAPI;
- PostgreSQL;
- JWT;
- RBAC no servidor;
- isolamento por `tenant_id` e `company_id`;
- carteira de fazendas para consultores;
- API `/api/v1`;
- sincronização incremental push/pull;
- `baseVersion` e conflitos;
- idempotência;
- auditoria no banco;
- backup PostgreSQL/SQLite;
- documentação automática OpenAPI em `/docs`.

## Subir localmente

Copie:

```text
backend/.env.example
```

para:

```text
backend/.env
```

Depois, na raiz do Projeto Atlas:

```bash
docker compose up --build
```

API:

```text
http://localhost:8000
```

Swagger:

```text
http://localhost:8000/docs
```

Health:

```text
http://localhost:8000/api/v1/health
```

## Credenciais iniciais

Definidas no `.env`:

```text
ATLAS_BOOTSTRAP_ADMIN_EMAIL
ATLAS_BOOTSTRAP_ADMIN_PASSWORD
```

Troque a senha e o segredo JWT antes de qualquer publicação.

## Testes

Dentro de `backend/`:

```bash
pytest
```

## Backup

O `backup-worker` do Docker Compose executa um backup por dia.
O backend também expõe:

```text
GET  /api/v1/backups
POST /api/v1/backups/run
```

A publicação, monitoramento em nuvem, domínio e políticas de
produção serão finalizados no Pacote 24E.
