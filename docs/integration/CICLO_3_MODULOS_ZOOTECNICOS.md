# Ciclo 3 — Módulos zootécnicos integrados

## Escopo

- Sprint 141: Reprodução por fazenda ativa.
- Sprint 142: Sanidade por fazenda ativa.
- Sprint 143: Nutrição por fazenda ativa.
- Sprint 144: Estoque por fazenda ativa.
- Sprint 145: Financeiro por fazenda ativa.

## Contratos oficiais

| Módulo | Endpoints principais |
|---|---|
| Reprodução | `GET /api/v1/livestock/reproduction/summary` |
| Sanidade | `GET /api/v1/livestock/health`, `/health/protocols`, `/health/alerts` |
| Nutrição | `GET /api/v1/livestock/nutrition/performance`, `/ingredients`, `/plans` |
| Estoque | `GET /api/v1/livestock/inventory/products`, `/inventory/alerts` |
| Financeiro | `GET /api/v1/livestock/finance/summary`, `/finance/v2` |

Todas as consultas usam o `farm_id` da fazenda ativa e os headers de empresa, tenant e fazenda fornecidos pelo `AtlasHttpClient`.

## Estados obrigatórios

Cada módulo possui carregamento, erro com nova tentativa, vazio, dados carregados, busca e atualização manual/por gesto.
