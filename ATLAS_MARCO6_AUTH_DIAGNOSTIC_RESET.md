# Atlas — Diagnóstico de autenticação e reset administrativo

## Objetivo

Distinguir de forma objetiva:
- usuário inexistente;
- usuário inativo;
- e-mail não confirmado;
- conta bloqueada;
- ausência de membership;
- senha divergente.

O diagnóstico nunca imprime senha ou hash.

## Variáveis de diagnóstico

ATLAS_AUTH_DIAGNOSTIC_ENABLED
ATLAS_AUTH_DIAGNOSTIC_EMAIL
ATLAS_AUTH_DIAGNOSTIC_PASSWORD

O log retorna apenas flags e contagens.

## Reset one-shot

ATLAS_RESET_ADMIN_PASSWORD_ONCE
ATLAS_RESET_ADMIN_EMAIL
ATLAS_RESET_ADMIN_PASSWORD

O reset só funciona para usuário já existente com membership
`companyAdministrator` ativa. Ele redefine o hash, confirma a conta, zera
tentativas e bloqueio, e verifica o novo hash antes do commit.

Depois do uso:
- ATLAS_AUTH_DIAGNOSTIC_ENABLED=false
- ATLAS_RESET_ADMIN_PASSWORD_ONCE=false
- remover as duas variáveis que contêm senha do Render.
