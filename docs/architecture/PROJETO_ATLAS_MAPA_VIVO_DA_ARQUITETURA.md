# Projeto Atlas — Mapa Vivo da Arquitetura

Este documento foi gerado automaticamente a partir do código Dart presente na pasta `lib`.
Ele deve ser regenerado antes de alterações estruturais importantes.

## Resumo

- **Dart Files:** 466
- **Modules:** 79
- **Screens Widgets:** 142
- **Services Engines:** 172
- **Models Contracts:** 115
- **Local Dependency Edges:** 1390
- **Duplicate Public Declarations:** 12
- **Likely Orphans:** 14
- **Pontos de entrada analisados:** app.dart, main.dart

## Regra arquitetural oficial

```text
Dados dos módulos → BI/indicadores → Decision Engine V2 → Executive Brain → Plano de Ação/Alertas → Copiloto/Painéis → Memória
```

Os painéis apresentam resultados; não devem criar motores decisórios paralelos. Adaptadores canônicos devem traduzir estruturas existentes, sem repetir regras de negócio.

## Maiores módulos por quantidade de arquivos

| Módulo | Arquivos | Telas/widgets | Serviços/motores | Modelos/contratos | Linhas |
|---|---:|---:|---:|---:|---:|
| core | 51 | 9 | 8 | 2 | 7469 |
| dashboard | 23 | 7 | 13 | 3 | 30777 |
| copilot | 18 | 8 | 5 | 5 | 5701 |
| reports | 17 | 9 | 6 | 2 | 15691 |
| atlas_ai | 15 | 2 | 8 | 5 | 8606 |
| atlas_bi | 14 | 5 | 5 | 4 | 7350 |
| technical_dashboard | 13 | 1 | 1 | 11 | 4365 |
| executive_brain | 10 | 3 | 4 | 2 | 5247 |
| executive_alerts | 8 | 1 | 5 | 2 | 3779 |
| executive_goals | 8 | 2 | 4 | 2 | 3344 |
| executive_kpis | 8 | 2 | 4 | 2 | 4813 |
| animal_health | 7 | 3 | 3 | 1 | 2041 |
| diagnostics | 7 | 2 | 3 | 2 | 4512 |
| digital_twin | 7 | 1 | 3 | 2 | 1753 |
| farm | 7 | 4 | 2 | 1 | 6496 |
| investment_capital_allocation | 7 | 1 | 2 | 4 | 1214 |
| scenario_simulator | 7 | 2 | 2 | 2 | 2335 |
| animal | 6 | 3 | 2 | 1 | 2664 |
| animal_reproduction | 6 | 3 | 2 | 1 | 2099 |
| farm_finance | 6 | 3 | 2 | 1 | 2022 |

## Declarações públicas repetidas

Estas repetições exigem revisão humana. Uma repetição pode ser legítima em bibliotecas isoladas, mas também pode indicar versões concorrentes do mesmo recurso.

- **AtlasCopilotAction**: `features/atlas_copilot/domain/models/atlas_copilot_data.dart`; `features/dashboard/domain/services/atlas_copilot_service.dart`
- **AtlasDecisionRisk**: `features/decision_engine/domain/models/atlas_decision_engine_data.dart`; `features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart`
- **AtlasInsightCard**: `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`; `features/dashboard/presentation/screens/dashboard_screen.dart`
- **AtlasPerformanceAlert**: `features/performance_center/domain/models/atlas_performance_snapshot.dart`; `features/performance_intelligence/domain/models/atlas_performance_analysis.dart`
- **AtlasPerformanceAlertSeverity**: `features/performance_center/domain/models/atlas_performance_snapshot.dart`; `features/performance_intelligence/domain/models/atlas_performance_analysis.dart`
- **AtlasPerformanceEngine**: `features/performance_center/domain/services/atlas_performance_engine.dart`; `features/performance_intelligence/domain/services/atlas_performance_engine.dart`
- **AtlasPerformanceKpi**: `features/performance_center/domain/models/atlas_performance_snapshot.dart`; `features/performance_intelligence/domain/models/atlas_performance_kpi.dart`
- **AtlasPredictiveScenario**: `features/predictive_ai/domain/models/atlas_predictive_scenario.dart`; `features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart`
- **AtlasPredictiveScenarioType**: `features/predictive/domain/models/atlas_predictive_scenario.dart`; `features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart`
- **ExecutiveAlertData**: `features/dashboard/domain/models/executive_dashboard_data.dart`; `features/dashboard/presentation/screens/executive_dashboard_screen.dart`
- **HeaderMetric**: `features/farm/presentation/screens/farm_detail_screen.dart`; `features/indicators/presentation/screens/indicators_screen.dart`
- **SectionTitle**: `features/dashboard/presentation/screens/dashboard_screen.dart`; `features/farm/presentation/screens/farm_detail_screen.dart`

## Arquivos possivelmente órfãos

A lista abaixo é heurística: arquivos carregados dinamicamente ou usados fora da pasta `lib` podem aparecer como órfãos. Eles não devem ser apagados automaticamente.

- `core/auth/atlas_auth_models.dart`
- `core/contracts/atlas_intelligence_contracts.dart`
- `core/database/atlas_database.dart`
- `core/events/atlas_event_examples.dart`
- `core/events/atlas_event_observer.dart`
- `core/presentation/layouts/atlas_main_layout.dart`
- `features/atlas_copilot/domain/services/atlas_legacy_copilot_service.dart`
- `features/atlas_copilot/presentation/screens/atlas_legacy_copilot_screen.dart`
- `features/atlas_intelligence/presentation/screens/atlas_intelligence_screen.dart`
- `features/authentication/presentation/screens/welcome_screen.dart`
- `features/dashboard/data/services/executive_dashboard_pdf_service.dart`
- `features/decision_tracking/presentation/screens/atlas_decision_tracking_screen.dart`
- `features/executive_core/presentation/screens/atlas_executive_core_screen.dart`
- `features/workflow_engine/presentation/screens/atlas_workflow_screen.dart`

## Procedimento obrigatório antes de cada nova funcionalidade

1. Procurar modelo, serviço, tela e regra equivalentes no inventário.
2. Verificar dependências recebidas e consumidores do módulo afetado.
3. Reutilizar ou ampliar a implementação existente.
4. Criar adaptador quando os formatos forem diferentes.
5. Executar `flutter analyze` antes de registrar a entrega como concluída.
6. Regenerar este mapa e comparar o resultado com a versão anterior.

## Arquivos complementares

- `atlas_architecture_map.json`: visão completa, adequada para comparação automática.
- `atlas_module_matrix.csv`: matriz de módulos e dependências.
- `atlas_file_inventory.csv`: inventário de todos os arquivos Dart.
- `atlas_dependency_edges.csv`: relações de importação/exportação.
- `atlas_duplicate_public_declarations.csv`: declarações públicas repetidas.