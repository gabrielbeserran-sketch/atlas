# Atlas — Marco 6 v16 — Render + Supabase

## Arquitetura homologada para a próxima etapa
Android -> HTTPS Render -> FastAPI -> Supabase PostgreSQL.
Rate limit distribuído -> Render Key Value.
Fotos/documentos -> bucket privado `atlas-animal-media` no Supabase Storage.

## O que mudou
- `render.yaml` cria a API e o Key Value gratuitos.
- A API executa Alembic antes de iniciar.
- O servidor usa a porta `$PORT` fornecida pelo Render.
- `ATLAS_DATABASE_URL` aponta para o **Session pooler** do Supabase (porta 5432), adequado ao backend persistente quando IPv4 é necessário.
- anexos deixam de depender do filesystem efêmero do Render.
- o bucket permanece privado; a chave service-role fica somente no backend/Render.
- desenvolvimento local continua usando armazenamento local por padrão.

## Dados que você NÃO deve enviar no chat
Senha do banco, connection string completa, JWT secret, MFA key, IoT key e service-role key.

## Próxima execução no Render
1. Suba esta versão para o GitHub.
2. Render -> New -> Blueprint -> selecione o repositório -> `render.yaml`.
3. Nos campos secretos solicitados, preencha no próprio Render:
   - `ATLAS_DATABASE_URL`: copie no Supabase em **Connect** a string do **Session pooler**, porta 5432, e troque `[YOUR-PASSWORD]` pela senha do banco. Para SQLAlchemy, o prefixo deve ficar `postgresql+psycopg://`.
   - `ATLAS_PUBLIC_BASE_URL`: URL HTTPS que o Render atribuir à API.
   - `ATLAS_CORS_ORIGINS`: a mesma URL HTTPS da API nesta V1.
   - `ATLAS_SUPABASE_URL`: URL do projeto Supabase.
   - `ATLAS_SUPABASE_SERVICE_ROLE_KEY`: chave service-role, inserida apenas no painel do Render.
4. Confirme que o bucket `atlas-animal-media` continua privado.
5. Faça Deploy.
6. O deploy só é aceito quando `/api/v1/health/ready` responder `ready`.

## Observação importante
O plano gratuito do Render é adequado para homologação/preview, não para uma produção comercial com SLA: o web service pode hibernar por inatividade e o Key Value gratuito é volátil. O PostgreSQL e os anexos oficiais permanecem no Supabase; o Key Value é usado apenas para rate limit e pode ser reconstruído.
