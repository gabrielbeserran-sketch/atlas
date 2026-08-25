# WHERE TO CHANGE ATLAS — 11A

Este é o índice operacional para novos desenvolvedores. Antes de editar, procure a implementação existente e confirme a fonte canônica no mapa 11A.

| Necessidade | Flutter | Backend / persistência |
|---|---|---|
| Login/sessão | `lib/features/authentication`, `lib/core/session` | auth/security/dependencies |
| Fazenda/permissão | `lib/features/farm` + contexto | farms/authz/memberships |
| Rebanho/animal | `animal`, `herd`, subfeatures `animal_*` | livestock/animals; tabelas de animal/lote |
| Reprodução | `animal_reproduction` | domínio reproduction/livestock |
| Sanidade | `animal_health` | domínio health/livestock |
| Nutrição | `nutrition` | nutrition + inventory integration |
| Estoque | `farm_inventory` | inventory/movements |
| Financeiro | `farm_finance` | finance |
| Agenda | `farm_agenda` | `operational_tasks` |
| Consultoria | `consultancy_client` | saas-growth/action plan/intelligence |
| Dashboard/Inteligência | `dashboard` | Operational Intelligence canônica |
| Central do Animal | `animal` + subfeatures | agregações livestock |
| Câmera | `security_camera` | security camera services/router |
| Dr. Beserra | `dr_beserra` | adapters/intelligence autorizados |
| API Flutter | `lib/core`/data services; nunca HTTP direto em widget novo | — |
| Schema | — | `backend/alembic/versions` |
| Release/gates | `scripts/quality`, `tools` | mesmos diretórios |
| Design global | 11B: `lib/core/design_system` | — |

## Antes de alterar
1. localizar o domínio proprietário; 2. consultar `ATLAS_11A_DOMAIN_OWNERSHIP.csv`; 3. procurar duplicidades; 4. localizar testes; 5. alterar o menor conjunto; 6. rodar gates.
