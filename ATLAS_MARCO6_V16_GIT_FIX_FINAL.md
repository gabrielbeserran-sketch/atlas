# Projeto Atlas — Marco 6 v16 — correção Git consolidada

## Problema corrigido
`backend/.env` podia continuar rastreado pelo Git mesmo depois de ser incluído
no `.gitignore`. Arquivos já rastreados não passam a ser ignorados apenas pela
adição de uma regra no `.gitignore`.

## Correção incorporada
- `.gitignore` reforçado.
- `scripts/quality/fix_git_tracked_secrets.ps1`:
  remove segredos apenas do índice Git via `git rm --cached`, preservando os
  arquivos físicos locais.
- `scripts/quality/audit_git_secrets.ps1`:
  verifica segredos rastreados, staged, presentes no status e valida que
  `backend/.env` esteja efetivamente ignorado.
- `scripts/quality/prepare_git_for_render.ps1`:
  executa correção + auditoria + conferência de branch/origin.

## Comando recomendado
Na raiz do projeto:

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\scripts\quality\prepare_git_for_render.ps1
```

Resultado esperado:

```text
ATLAS GIT TRACKED-SECRETS FIX: APROVADO
ATLAS GIT SECRET AUDIT: APROVADO
ATLAS GIT PREPARE: APROVADO
```

O script não executa `git add`, `git commit` ou `git push`.
