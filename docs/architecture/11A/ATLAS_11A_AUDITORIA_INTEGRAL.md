# Atlas 11A — Auditoria Integral de Arquitetura e Governança

## Baseline auditada

- Snapshot físico: **2.487 arquivos**, 0 erros de leitura.
- Git HEAD do snapshot: `644f44cf48a8bc08f077bea7204fddad9e057485`.
- Dart atual: **1009 arquivos**.
- Módulos Dart detectados: **169**.
- Diretórios imediatos em `lib/features`: **167**.
- Dependências Dart locais: **3129**.
- Declarações públicas repetidas: **47**.
- Candidatos heurísticos a órfãos: **62**.
- Rotas backend (audit global): **543**.
- Alembic: **50 revisions**, head único `20260825_0050`.

Esta é a primeira auditoria 11A baseada no snapshot físico integral da V1 RC, e não em reconstrução parcial.

## Conclusão executiva

A aplicação está funcionalmente madura, mas a arquitetura reflete crescimento incremental acelerado. A prioridade não é um "big bang refactor". A prioridade é **governar a arquitetura existente, congelar o crescimento de dívida estrutural e migrar por domínio quando houver alteração material**.

### Achados P0

1. **`lib/features` possui 167 diretórios**, o que exige ownership explícito. O mapa atualizado detectou 169 módulos Dart incluindo `core`/app.
2. **`dashboard` soma ~34 mil linhas** e contém o maior arquivo Flutter (`executive_dashboard_screen.dart`, ~9,7 mil linhas). Deve ser decomposto por composição, não reescrito de uma vez.
3. **`lib/core` contém telas de negócio extensas** em `core/operational_intelligence/action_plan`. `core` deve convergir para infraestrutura transversal; telas de domínio devem migrar gradualmente para features proprietárias.
4. **Backend `livestock.py` possui ~4.084 linhas** e concentra múltiplos subdomínios. É principal candidato a extração para um modular monolith por domínio.
5. **`backend/app/models/legacy.py` (~2.796 linhas) e `schemas/legacy.py` (~2.400)** são hubs legados. Não remover; reduzir progressivamente por extração de domínio.
6. Há **47 declarações públicas repetidas**. O maior foco é Dashboard/Inteligência, com famílias concorrentes de Copilot, Intelligence, Performance, Predictive e Enterprise Operations.
7. Há **62 candidatos a órfãos**. São apenas candidatos: remoção automática é proibida.
8. O mapa de arquitetura versionado no repositório estava defasado (972 Dart/165 módulos) contra o snapshot atual (1009/169). O 11A passa a exigir regeneração antes de mudança estrutural.

## Classificação das features

- **ADVANCED_CAPABILITY**: 69
- **CANONICAL_COMPOSITION**: 7
- **CANONICAL_DOMAIN**: 33
- **DUPLICATE_FAMILY_REVIEW**: 16
- **LEGACY_OR_PHASE_REVIEW**: 6
- **PLATFORM_INFRA**: 14
- **SUPPORTING_FEATURE**: 24

A classificação completa está em `ATLAS_11A_DOMAIN_OWNERSHIP.csv` e foi feita para orientar ownership, não para autorizar remoção.

## Princípio de migração

```text
BASELINE V1 RC VERDE
        ↓
MAPEAR OWNERSHIP
        ↓
CRIAR FACHADA/ADAPTADOR CANÔNICO
        ↓
MOVER UM SUBDOMÍNIO POR VEZ
        ↓
MANTER COMPATIBILIDADE DE IMPORTS/ROTAS
        ↓
REGRESSÃO INTEGRAL
        ↓
REMOVER LEGADO SOMENTE COM PROVA DE NÃO-USO
```

## Ordem recomendada de refatoração pós-governança

### P0 — antes de crescer funcionalidade
- Consolidar famílias duplicadas de **Intelligence/Copilot/Performance/Predictive**.
- Bloquear novos arquivos de negócio dentro de `core`.
- Bloquear novos routers monolíticos; novas regras devem entrar em services/modules.
- Criar ownership explícito para todos os 169 módulos.

### P1 — durante 11B/11C e pós-V1
- Decompor `dashboard` por widgets/sections/application services.
- Migrar gradualmente `core/operational_intelligence/action_plan` para domínios proprietários.
- Extrair de `livestock.py`: herd/animal, reproduction, health, nutrition, inventory/handling conforme fronteiras transacionais existentes.
- Extrair modelos/schemas de `legacy.py` ao tocar nos respectivos domínios.

### P2 — pós-publicação
- Revisar módulos avançados e fases históricas sem consumidores.
- Arquivar documentação histórica por índice, sem apagar evidência de decisões.
- Eliminar duplicidades comprovadas após telemetria/piloto.

## Estado Git no snapshot

```text
M ATLAS_AUDITORIA_RECUPERACAO_FINAL.json
 M ATLAS_POWERSHELL_STATIC_AUDIT.json
 M backend/atlas_test.db
?? ATLAS_10D_FAILURES.zip
?? _atlas_snapshot_meta/
?? criar_snapshot_integral_atlas_v1_rc.ps1
?? sanitize_atlas_post_9c_worktree.ps1
```

Esses itens não são automaticamente parte do runtime. Devem ser classificados antes de qualquer limpeza. O 11A não os remove.

## Regra de remoção

Nenhum arquivo pode ser removido apenas por aparecer como órfão. Exigir simultaneamente:

- ausência no grafo de imports;
- ausência em rotas/navegação/configuração;
- ausência em scripts/build/deploy;
- ausência em testes;
- ausência de carga dinâmica/reflexiva;
- ausência de obrigação histórica/migration;
- aprovação em regressão integral.
