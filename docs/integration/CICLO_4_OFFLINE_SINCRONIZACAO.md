# Ciclo 4 — Offline e sincronização

## Escopo

O Ciclo 4 consolida os Sprints 146 a 150:

- banco local com isolamento por empresa e fazenda;
- fila idempotente com retentativa e backoff;
- pull incremental por cursor;
- push em lotes de até 200 operações;
- conflitos explícitos com decisão humana.

## Contratos utilizados

- `POST /api/v1/offline/devices/register`
- `POST /api/v1/offline/push-batch`
- `GET /api/v1/offline/pull-page`
- `GET /api/v1/offline/conflicts`
- `POST /api/v1/offline/conflicts/{id}/resolve`
- `POST /api/v1/offline/diagnostics`
- `GET /api/v1/offline/status`

## Regras de segurança

Tokens não são armazenados no SQLite. A fila local mantém apenas o contexto necessário da operação. O cache usa escopo de empresa, tenant e fazenda e nunca deve ser consultado fora desse escopo.

## Estratégia de falha

Operações transitórias voltam para `retry` com backoff exponencial. Rejeições permanentes ficam em `failed`. Divergências de versão ficam em `conflict` e exigem resolução humana.
