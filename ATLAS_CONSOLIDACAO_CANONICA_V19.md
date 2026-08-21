# Atlas V19 — Consolidação canônica de navegação e contexto

Data: 21/08/2026
Baseline de entrada: V18 homologação integrada.

## Objetivo
Eliminar caminhos visuais paralelos entre Fazenda/Dashboard e os módulos pecuários oficiais, preservando a API como autoridade e reutilizando os serviços remote-first já existentes.

## Auditoria antes da alteração
- Piquetes: CRUD remoto oficial já existente em `/livestock/paddocks`; não recriado.
- Financeiro: API-first com cache SharedPreferences de contingência.
- Estoque: API-first com cache de contingência.
- Agenda: API-first com confirmação após POST/PATCH e cache offline.
- Rebanho/animais: serviços Enterprise oficiais existentes.
- Módulos Sanidade/Reprodução/Nutrição/Financeiro/Estoque: `AtlasLivestockModuleScreen` é a entrada canônica do menu principal.

## Alterações
1. `FarmDetailScreen`
   - Rebanho abre `HerdOverviewScreen` oficial.
   - Sanidade, Reprodução, Nutrição, Financeiro e Estoque abrem `AtlasLivestockModuleScreen` oficial.
   - Lotes, Financeiro, Estoque e Agenda recebem `farmId` explícito, evitando resolução por nome.
   - Animais do resumo da fazenda são carregados diretamente por `AnimalEnterpriseService` usando o `farmId` ativo.
   - Piquetes permanecem na tela CRUD oficial existente, que já usa backend remoto.

2. `DashboardScreen`
   - Fallbacks fora do shell também passam a abrir os módulos canônicos, evitando retorno silencioso às telas legadas.

3. `AtlasHomeShell`
   - Removidos imports legados sem uso para deixar explícito o contrato canônico.

4. Gate de regressão
   - Criado `scripts/quality/audit_v19_canonical_navigation_static.py`.

## Validação executada
- Auditoria V8: 17/17.
- V9: 9/9.
- V10: 15/15.
- V11: 13/13.
- V12/V13: 14/14.
- V14/V15: 16/16.
- V16/V17: 17/17.
- V18 UX: 9/9.
- V18 estabilização: 11/11.
- V19 navegação canônica: 32/32.
- `atlas_full_project_audit.py`: OK, 510 rotas backend, sem duplicidade, sem imports Dart internos ausentes, Alembic com head único.
- `compileall` Python: OK.

## Gate externo ainda necessário
O ambiente desta geração não possui Flutter/Dart executável; após substituição no Windows devem ser executados `flutter analyze`, `flutter test` e `flutter build windows --debug` antes de promover a V19 para Render.
