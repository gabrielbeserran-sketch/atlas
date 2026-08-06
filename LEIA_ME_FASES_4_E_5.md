# ATLAS — Fases 4 e 5

## Arquivos completos
Copie todos os arquivos preservando os caminhos. Esta entrega não cria tabelas novas, portanto não há migration adicional.

## Fase 4
31. Dashboard do rebanho consolidado no endpoint `/platform/dashboard/farms/{farm_id}`.
32. Indicadores reprodutivos oficiais agregados.
33. Indicadores sanitários oficiais agregados.
34. Indicadores nutricionais oficiais agregados.
35. Indicadores financeiros oficiais agregados.
36. Dashboard multifazenda em `/platform/dashboard/company`.
37. Atlas Brain revisado por recomendações determinísticas baseadas no snapshot oficial.
38. Contexto único da IA em `/platform/ai/context/farms/{farm_id}` com proveniência e limitações.
39. Recomendações explicáveis com evidências, confiança, impacto, prazo e decisão auditável.
40. Automações padrão, simulação segura e execução auditada.

## Fase 5
41. Permissões pecuárias incluídas no RBAC e distribuídas por papel.
42. Consultas da plataforma filtram `company_id` e validam fazendas permitidas.
43. Readiness verifica exclusão lógica dos registros operacionais.
44. Decisões e execuções da plataforma são registradas em `audit_logs`.
45. A plataforma usa a infraestrutura existente de `entity_states`, `sync_changes` e idempotência.
46. Readiness verifica integridade de versões; conflitos continuam tratados pelo `/sync/push`.
47. Smoke E2E em `backend/scripts/run_e2e_phase5.py`.
48. Tela Flutter executiva centralizada criada para auditoria visual e usabilidade.
49. Ambiente de homologação criado em `deploy/homologacao`.
50. Checklist de produção disponível em `/platform/production/readiness` para orientar o piloto.

## Aplicação
1. Faça backup do projeto e banco.
2. Substitua os arquivos completos deste pacote.
3. Backend:
   `cd backend`
   `python -m pip install -r requirements.txt`
   `python -m alembic upgrade head`
   `python -m pytest -q`
   `python -m uvicorn app.main:app --reload`
4. Flutter:
   `flutter clean`
   `flutter pub get`
   `flutter analyze`
   `flutter run -d windows`

## E2E
No PowerShell:
`$env:ATLAS_BASE_URL="http://127.0.0.1:8000/api/v1"`
`$env:ATLAS_ACCESS_TOKEN="SEU_TOKEN"`
`$env:ATLAS_FARM_ID="ID_DA_FAZENDA"`
`python backend/scripts/run_e2e_phase5.py`

## Observação
A tela `AtlasPlatformDashboardScreen` foi criada completa, mas deve ser ligada ao ponto de navegação que você escolher, passando `farmId` e `farmName`. Não substituí uma rota visual existente sem saber qual delas você deseja tornar oficial.
