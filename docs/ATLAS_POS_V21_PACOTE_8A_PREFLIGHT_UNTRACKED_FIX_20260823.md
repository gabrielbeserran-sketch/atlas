# Atlas Pós-V21 — Hotfix do preflight 8A

## Causa confirmada no Windows

A migration `20260823_0043_security_camera_alerts.py` existia corretamente no
disco, mas aparecia como `??` no `git status`.

O preflight anterior usava `git grep`, que só pesquisa arquivos já rastreados.
Isso criava uma contradição: o script exigia a migration rastreada antes da
etapa `git add` que ele próprio mandava executar depois.

## Correção

O preflight agora, antes do staging:

1. verifica se a migration existe;
2. valida `revision = "20260823_0043"`;
3. valida `down_revision = "20260822_0042"`;
4. confirma que o arquivo não está ignorado;
5. aceita corretamente o estado `untracked`;
6. roda `git diff --check` sem pager e sem ruído de `safecrlf`.

Depois do `git add -A`, um segundo checker confirma:

- migration realmente rastreada;
- migration realmente presente no staging;
- router da câmera presente no staging;
- interface da câmera presente no staging;
- `git diff --cached --check` aprovado.

## Pager / LF-CRLF

Os scripts agora definem temporariamente:

- `GIT_PAGER=cat`;
- `PAGER=cat`;
- `LESS=FRX`.

O `diff --check` usa `core.safecrlf=false` somente nessa validação para não
encher o terminal com avisos de conversão LF/CRLF. Erros reais de whitespace
continuam falhando pelo código de saída.

## Ordem correta de release

1. preflight;
2. `git add -A`;
3. check do staging;
4. commit;
5. push;
6. Render aplica Alembic automaticamente;
7. checker de produção.

Nenhuma migration manual separada no Supabase.
