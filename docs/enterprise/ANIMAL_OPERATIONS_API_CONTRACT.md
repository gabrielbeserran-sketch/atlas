# Contrato Enterprise — Agenda e Pendências

## Recursos planejados

- `GET /api/v1/animals/{animal_id}/tasks`
- `POST /api/v1/animals/{animal_id}/tasks`
- `PATCH /api/v1/animals/{animal_id}/tasks/{task_id}`
- `DELETE /api/v1/animals/{animal_id}/tasks/{task_id}`
- `GET /api/v1/farms/{farm_id}/operational-dashboard`
- `GET /api/v1/companies/{company_id}/executive-dashboard`

## Campos obrigatórios

Toda escrita deve preservar:

- `tenant_id`
- `company_id`
- `farm_id`
- `animal_id`
- `created_by`
- `updated_by`
- `version`
- `created_at`
- `updated_at`

## Segurança

Permissões sugeridas:

- `animal_tasks.read`
- `animal_tasks.create`
- `animal_tasks.update`
- `animal_tasks.delete`
- `farm_dashboard.read`
- `company_dashboard.read`

## Sincronização

1. Criar localmente com UUID.
2. Registrar estado `pending`.
3. Enviar à API com chave de idempotência.
4. Salvar versão remota.
5. Resolver conflito por versão e `updated_at`.
6. Registrar auditoria.
