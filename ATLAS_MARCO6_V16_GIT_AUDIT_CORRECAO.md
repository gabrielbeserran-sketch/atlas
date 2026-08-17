# Projeto Atlas — correção do auditor Git

## Causa do falso FAIL

Depois de `git rm --cached backend/.env`, o Git mostra intencionalmente:

`D  backend/.env`

Essa linha significa que o arquivo será removido do repositório no próximo
commit, mas continuará existente no computador. O auditor anterior interpretava
qualquer caminho secreto visível no `git status` como falha, inclusive essa
deleção segura.

## Correção

O auditor agora distingue:

- ADD/COPY/MODIFY/RENAME de segredo: **FAIL**;
- segredo ainda rastreado: **FAIL**;
- segredo local não protegido: **FAIL**;
- DELETE staged de segredo anteriormente rastreado: **PERMITIDO**.

A verificação de `.gitignore` também usa `git check-ignore --no-index`, evitando
falso negativo enquanto a remoção de `backend/.env` ainda está staged.

## Comando oficial

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\scripts\quality\prepare_git_for_render.ps1
```

Resultado esperado:

```text
ATLAS GIT TRACKED-SECRETS FIX: APROVADO
Segredos sendo removidos do Git (ação segura):
 - backend/.env
ATLAS GIT SECRET AUDIT: APROVADO
ATLAS GIT PREPARE: APROVADO
```
