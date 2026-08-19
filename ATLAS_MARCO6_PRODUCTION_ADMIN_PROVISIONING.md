# Atlas — Marco 6 — Provisionamento administrativo de produção

## Motivo

O bootstrap normal do Atlas é intencionalmente proibido em
staging/production. Isso deve permanecer assim.

Ao mesmo tempo, a primeira instalação precisa de um administrador inicial.
Foi criado um mecanismo separado, explícito e one-shot.

## Variáveis

- `ATLAS_PROVISION_ADMIN_ONCE`
- `ATLAS_PROVISION_ADMIN_EMAIL`
- `ATLAS_PROVISION_ADMIN_PASSWORD`
- `ATLAS_PROVISION_COMPANY_NAME`

Todas ficam desabilitadas por padrão.

## Fluxo

Depois de PostgreSQL/Redis/Storage, migrations e schema contract aprovados,
o startup executa `render_provision_admin_once`.

Se `ATLAS_PROVISION_ADMIN_ONCE=false`, não faz nada.

Se estiver `true` em production/staging:
- cria ou reutiliza a empresa;
- cria o administrador se necessário;
- confirma o e-mail;
- cria vínculo `companyAdministrator`;
- desbloqueia tentativas anteriores;
- não altera senha se já existir vínculo administrativo ativo.

## Pós-provisionamento obrigatório

Depois do primeiro log:

`ATLAS ADMIN PROVISION: APROVADO`

deve-se:
1. mudar `ATLAS_PROVISION_ADMIN_ONCE=false`;
2. remover `ATLAS_PROVISION_ADMIN_PASSWORD` do Render;
3. redeployar;
4. testar `/api/v1/auth/login`.

O bootstrap de desenvolvimento continua `false` em produção.
