# Atlas Pós-V21 — Macropacote 10C — Rastreabilidade, Dados e UX

Data: 2026-08-25

## Objetivo

Fechar o bloco de rastreabilidade individual, qualidade de dados e consistência de apresentação antes do Production Candidate 10D.

## Entregas

1. A Central do Animal passa a exibir cobertura explícita de rastreabilidade, calculada sobre checkpoints reais do animal.
2. Caches locais de peso, movimentação, eventos, fotos e documentos são normalizados antes da reconstrução dos modelos, evitando reexposição de mojibake legado em contingência offline.
3. A migration `0050` refaz o saneamento global de texto persistido e amplia a cobertura para JSON/JSONB.
4. O estado de saneamento fica comprovável em produção por `atlas_data_quality_state` e pelo endpoint público `/livestock/data-quality/deployment-readiness`.
5. Entrada e saída Flutter continuam normalizadas por `AtlasHttpClient`; persistência ORM continua protegida pelo `before_flush` do SQLAlchemy.
6. Categorias internas comuns permanecem traduzidas por `AtlasUiText` e um gate bloqueia retorno de códigos técnicos como rótulos literais de UI.
7. O gate 10C varre superfícies de produção em busca de sequências inequívocas de mojibake e reprova o release antes do commit.
8. A auditoria global do projeto deve continuar com head Alembic único e sem erros de contrato da Central do Animal ou dos módulos essenciais.

## Migration

`20260825_0049` → `20260825_0050`

A migration é de saneamento e prova de qualidade. A reversão remove apenas a tabela de estado; o reparo dos dados é deliberadamente irreversível.

## Critérios de saída

- contrato Flutter 10C aprovado;
- gate estrutural 10C aprovado;
- auditoria global aprovada;
- auditoria preventiva da baseline 10C aprovada;
- `git diff --check` e `git diff --cached --check` aprovados;
- Render aplica `0050` automaticamente;
- readiness remoto confirma `schema_ready`, `utf8_sanitized`, `runtime_normalization`, `animal_traceability` e `farm_scope_guard`.
