# Atlas Pós-V21 — Pacote 8A Release Hardening

## Descoberta da auditoria

O `render.yaml` já executa `/app/scripts/render_start.sh`.

Esse startup já contém, nesta ordem:

1. validação de imports;
2. preflight;
3. `python -m alembic upgrade head`;
4. conferência do head;
5. auditoria do schema;
6. diagnósticos de produção;
7. inicialização da API.

Portanto, uma execução manual separada de `alembic upgrade head` no Supabase
não é necessária e foi removida do procedimento do Pacote 8A.

## Fluxo oficial de publicação do 8A

1. homologação local 8A verde;
2. preflight de release;
3. git add / commit / push para `master`;
4. Render inicia o deploy;
5. `render_start.sh` aplica a migration 0043 automaticamente;
6. o mesmo startup confirma head + schema;
7. somente depois a API é iniciada;
8. `check_post_v21_package8a_security_camera_deployed.ps1` confirma produção.

## Proteção nova

`tools/atlas_post_v21_package8a_release_preflight_gate.py`

Ele falha se:
- Render deixar de usar `render_start.sh`;
- o startup deixar de executar Alembic;
- desaparecer a checagem pós-migration;
- desaparecer a auditoria do schema;
- a migration 0043 sair da cadeia 0042 → 0043;
- o checker de produção deixar de validar schema/chave IoT;
- a homologação voltar a orientar uma migration manual separada.

## Comando de preflight

`powershell -ExecutionPolicy Bypass -File ".\scripts\quality\run_post_v21_package8a_release_preflight.ps1"`

O script também executa a preparação segura do Git e `git diff --check`.

## Backend e banco

O backend continua alterado pelo Pacote 8A.
A migration continua sendo `20260823_0043`.
A mudança desta etapa é de segurança do processo de release; não cria nova
migration.
