# Pacote 50 — Contrato planejado da Plataforma Atlas Global

## Multiempresa
- `GET /api/v1/global/companies`
- `POST /api/v1/global/companies`
- `GET /api/v1/global/portfolio`
- `POST /api/v1/global/switch-context`

## Multiusuário
- `GET /api/v1/global/users`
- `POST /api/v1/global/users`
- `PATCH /api/v1/global/users/{membership_id}`
- `GET /api/v1/global/roles`
- `POST /api/v1/global/permissions/evaluate`

## Marketplace
- `GET /api/v1/integrations/catalog`
- `POST /api/v1/integrations/install`
- `PATCH /api/v1/integrations/{installation_id}`
- `GET /api/v1/integrations/health`

## API pública
- `POST /api/v1/partners`
- `POST /api/v1/partners/{partner_id}/credentials`
- `GET /api/v1/partners/{partner_id}/usage`
- `POST /api/v1/partners/{partner_id}/rotate-secret`

## Command Center
- `GET /api/v1/global/command-center`
- `GET /api/v1/global/alerts`
- `GET /api/v1/global/sync-health`
- `GET /api/v1/global/audit-summary`

## Requisitos de segurança
- segregação obrigatória por tenant;
- carteira de empresas e fazendas;
- RBAC e permissões efetivas;
- credenciais com expiração e rotação;
- limites por parceiro;
- auditoria de toda mudança;
- idempotência;
- logs sem exposição de segredos.
