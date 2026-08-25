# Projeto Atlas — Mapa Vivo da Arquitetura

Este documento foi gerado automaticamente a partir do código Dart presente na pasta `lib`.
Ele deve ser regenerado antes de alterações estruturais importantes.

## Resumo

- **Dart Files:** 1009
- **Modules:** 169
- **Screens Widgets:** 294
- **Services Engines:** 383
- **Models Contracts:** 224
- **Local Dependency Edges:** 3129
- **Duplicate Public Declarations:** 47
- **Likely Orphans:** 62
- **Pontos de entrada analisados:** app.dart, core/navigation/atlas_route_definition.dart, main.dart

## Regra arquitetural oficial

```text
Dados dos módulos → BI/indicadores → Decision Engine V2 → Executive Brain → Plano de Ação/Alertas → Copiloto/Painéis → Memória
```

Os painéis apresentam resultados; não devem criar motores decisórios paralelos. Adaptadores canônicos devem traduzir estruturas existentes, sem repetir regras de negócio.

## Maiores módulos por quantidade de arquivos

| Módulo | Arquivos | Telas/widgets | Serviços/motores | Modelos/contratos | Linhas |
|---|---:|---:|---:|---:|---:|
| core | 251 | 57 | 74 | 24 | 52843 |
| enterprise_platform | 33 | 6 | 16 | 8 | 8224 |
| dashboard | 30 | 11 | 15 | 4 | 34220 |
| reports | 19 | 9 | 6 | 2 | 15918 |
| copilot | 18 | 8 | 5 | 5 | 5046 |
| atlas_ai | 15 | 2 | 8 | 5 | 6995 |
| atlas_bi | 14 | 5 | 5 | 4 | 6392 |
| consultancy_client | 13 | 4 | 5 | 4 | 2485 |
| technical_dashboard | 13 | 1 | 1 | 11 | 2857 |
| dr_beserra | 11 | 1 | 4 | 4 | 3057 |
| executive_brain | 10 | 3 | 4 | 2 | 4532 |
| animal | 8 | 3 | 4 | 1 | 8526 |
| animal_reproduction | 8 | 3 | 4 | 1 | 2692 |
| executive_alerts | 8 | 1 | 5 | 2 | 3337 |
| executive_goals | 8 | 2 | 4 | 2 | 2606 |
| executive_kpis | 8 | 2 | 4 | 2 | 3746 |
| farm | 8 | 4 | 2 | 2 | 7187 |
| animal_event | 7 | 2 | 2 | 3 | 1960 |
| diagnostics | 7 | 2 | 3 | 2 | 3825 |
| digital_twin | 7 | 1 | 3 | 2 | 1734 |

## Declarações públicas repetidas

Estas repetições exigem revisão humana. Uma repetição pode ser legítima em bibliotecas isoladas, mas também pode indicar versões concorrentes do mesmo recurso.

- **AtlasCommandCenterState**: `core/operational_intelligence/atlas_command_center_state.dart`; `features/command_center/domain/models/atlas_command_center_data.dart`
- **AtlasConsultancyAction**: `features/consultancy_client/domain/models/atlas_consultancy_action.dart`; `features/consultancy_workflow/domain/models/atlas_consultancy_case.dart`
- **AtlasCopilotAction**: `features/atlas_copilot/domain/models/atlas_copilot_data.dart`; `features/dashboard/domain/services/atlas_copilot_service.dart`
- **AtlasCopilotIntelligenceCard**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasCopilotScreen**: `features/atlas_copilot/presentation/screens/atlas_copilot_screen.dart`; `features/copilot/presentation/screens/atlas_copilot_screen.dart`
- **AtlasCopilotService**: `features/atlas_copilot/domain/services/atlas_copilot_service.dart`; `features/dashboard/domain/services/atlas_copilot_service.dart`
- **AtlasDecisionBadge**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasDecisionRisk**: `features/decision_engine/domain/models/atlas_decision_engine_data.dart`; `features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart`
- **AtlasEnterpriseOperationsScreen**: `features/atlas_enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart`; `features/enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart`
- **AtlasExecutiveIntelligenceScreen**: `core/operational_intelligence/action_plan/atlas_executive_intelligence_screen.dart`; `features/atlas_executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart`; `features/executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart`
- **AtlasExecutiveIntelligenceService**: `core/operational_intelligence/action_plan/atlas_executive_intelligence_service.dart`; `features/executive_intelligence/domain/services/atlas_executive_intelligence_service.dart`
- **AtlasExecutiveKpi**: `core/operational_intelligence/action_plan/atlas_executive_intelligence.dart`; `features/executive_kpis/domain/models/atlas_executive_kpi.dart`
- **AtlasGroupAnalysis**: `features/dashboard/domain/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_operations_intelligence_service.dart`
- **AtlasGroupAnalysisList**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasGroupAnalysisTabs**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasGroupType**: `features/dashboard/domain/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_operations_intelligence_service.dart`
- **AtlasInsightCard**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`; `features/dashboard/presentation/screens/dashboard_screen.dart`
- **AtlasInsightGrid**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasInsightIconType**: `features/dashboard/domain/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_operations_intelligence_service.dart`
- **AtlasIntelligenceBadge**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasIntelligenceBrief**: `features/dashboard/domain/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_operations_intelligence_service.dart`
- **AtlasIntelligenceHero**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasIntelligenceInsight**: `features/dashboard/domain/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_operations_intelligence_service.dart`
- **AtlasIntelligenceLevel**: `features/dashboard/domain/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_operations_intelligence_service.dart`
- **AtlasIntelligenceScreen**: `features/atlas_intelligence/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`
- **AtlasIntelligenceService**: `features/atlas_intelligence/domain/services/atlas_intelligence_service.dart`; `features/atlas_intelligence_center/data/services/atlas_intelligence_service.dart`; `features/dashboard/domain/services/atlas_intelligence_service.dart`
- **AtlasOperationScorePanel**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasOperationsRepository**: `features/farm_operations/data/services/atlas_operations_repository.dart`; `features/operations/data/atlas_operations_repository.dart`
- **AtlasPerformanceAlert**: `features/performance_center/domain/models/atlas_performance_snapshot.dart`; `features/performance_intelligence/domain/models/atlas_performance_analysis.dart`
- **AtlasPerformanceAlertSeverity**: `features/performance_center/domain/models/atlas_performance_snapshot.dart`; `features/performance_intelligence/domain/models/atlas_performance_analysis.dart`
- **AtlasPerformanceEngine**: `features/performance_center/domain/services/atlas_performance_engine.dart`; `features/performance_intelligence/domain/services/atlas_performance_engine.dart`
- **AtlasPerformanceKpi**: `features/performance_center/domain/models/atlas_performance_snapshot.dart`; `features/performance_intelligence/domain/models/atlas_performance_kpi.dart`
- **AtlasPredictiveAiScreen**: `features/atlas_predictive_ai_suite/presentation/screens/atlas_predictive_ai_screen.dart`; `features/predictive_ai/presentation/screens/atlas_predictive_ai_screen.dart`
- **AtlasPredictiveScenario**: `features/predictive_ai/domain/models/atlas_predictive_scenario.dart`; `features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart`
- **AtlasPredictiveScenarioType**: `features/predictive/domain/models/atlas_predictive_scenario.dart`; `features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart`
- **AtlasPriorityList**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasReleaseCheck**: `core/release_candidate/atlas_release_candidate_models.dart`; `features/release_management/domain/models/atlas_release_plan.dart`
- **AtlasSectionTitle**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasSituationSummaryGrid**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasSmallMetric**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasSummaryCard**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **AtlasSyncEngine**: `core/sync/atlas_sync_engine.dart`; `features/sync_platform/domain/services/atlas_sync_engine.dart`
- **AtlasSyncSummary**: `core/sync/atlas_sync_engine.dart`; `features/sync_platform/domain/models/atlas_sync_data.dart`
- **AtlasTodayGuidanceCard**: `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`; `features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- **ExecutiveAlertData**: `features/dashboard/domain/models/executive_dashboard_data.dart`; `features/dashboard/presentation/screens/executive_dashboard_screen.dart`
- **HeaderMetric**: `features/farm/presentation/screens/farm_detail_screen.dart`; `features/indicators/presentation/screens/indicators_screen.dart`
- **SectionTitle**: `features/animal/presentation/screens/animal_detail_screen.dart`; `features/dashboard/presentation/screens/dashboard_screen.dart`; `features/farm/presentation/screens/farm_detail_screen.dart`

## Arquivos possivelmente órfãos

A lista abaixo é heurística: arquivos carregados dinamicamente ou usados fora da pasta `lib` podem aparecer como órfãos. Eles não devem ser apagados automaticamente.

- `core/auth/atlas_auth_models.dart`
- `core/contracts/atlas_intelligence_contracts.dart`
- `core/database/atlas_database.dart`
- `core/events/atlas_event_observer.dart`
- `core/network/atlas_android_endpoint.dart`
- `core/operational_intelligence/adapters/atlas_command_center_adapters.dart`
- `core/operational_intelligence/atlas_operational_intelligence.dart`
- `core/presentation/layouts/atlas_main_layout.dart`
- `core/sync/atlas_conflict_resolver.dart`
- `core/sync/atlas_sync_operation.dart`
- `core/sync/atlas_sync_status_button.dart`
- `core/widgets/atlas_loading_state.dart`
- `features/analytics/presentation/screens/atlas_bi_dashboard_screen.dart`
- `features/animal_reproduction/data/repositories/atlas_remote_reproduction_repository.dart`
- `features/animal_reproduction/domain/services/reproduction_metrics_service.dart`
- `features/atlas_advanced/presentation/screens/atlas_advanced_dashboard_screen.dart`
- `features/atlas_ai_2/presentation/screens/atlas_ai_conversation_screen.dart`
- `features/atlas_ai_2/presentation/screens/atlas_executive_ai_screen.dart`
- `features/atlas_ai_enterprise/presentation/screens/atlas_ai_enterprise_screen.dart`
- `features/atlas_business/presentation/screens/atlas_business_dashboard_screen.dart`
- `features/atlas_copilot/domain/services/atlas_copilot_service.dart`
- `features/atlas_copilot/presentation/screens/atlas_copilot_screen.dart`
- `features/atlas_intelligence/presentation/screens/atlas_intelligence_screen.dart`
- `features/atlas_scale/presentation/screens/atlas_scale_center_screen.dart`
- `features/atlas_sprints_11_15/presentation/screens/atlas_sprints_dashboard_screen.dart`
- `features/atlas_sprints_16_20/presentation/screens/atlas_sprints_16_20_dashboard_screen.dart`
- `features/atlas_sprints_21_25/presentation/screens/atlas_sprints_21_25_dashboard_screen.dart`
- `features/automation_strategy/presentation/screens/atlas_automation_strategy_screen.dart`
- `features/commercial_platform/presentation/screens/atlas_commercial_dashboard_screen.dart`
- `features/commercial_readiness/presentation/screens/atlas_commercial_readiness_screen.dart`
- `features/dashboard/data/services/executive_dashboard_pdf_service.dart`
- `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`
- `features/data_intelligence/presentation/screens/atlas_data_intelligence_screen.dart`
- `features/decision_tracking/presentation/screens/atlas_decision_tracking_screen.dart`
- `features/enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart`
- `features/enterprise_platform/domain/services/atlas_enterprise_scope_guard.dart`
- `features/enterprise_platform/presentation/screens/atlas_enterprise_platform_screen.dart`
- `features/enterprise_platform/presentation/widgets/atlas_permission_gate.dart`
- `features/farm_handling/domain/models/farm_handling_draft.dart`
- `features/flutter_quality/presentation/screens/atlas_flutter_quality_screen.dart`
- `features/governance_resilience/presentation/screens/atlas_governance_resilience_screen.dart`
- `features/herd/presentation/screens/herd_list_screen.dart`
- `features/integration_ecosystem/presentation/screens/atlas_integration_ecosystem_screen.dart`
- `features/iot_enterprise/presentation/screens/atlas_iot_enterprise_screen.dart`
- `features/livestock_integration/data/services/atlas_phases_2_3_service.dart`
- `features/livestock_operations/presentation/screens/atlas_livestock_module_screen.dart`
- `features/ml_platform/presentation/screens/atlas_ml_platform_screen.dart`
- `features/operational_readiness/presentation/screens/atlas_operational_readiness_screen.dart`
- `features/operations/data/atlas_operations_repository.dart`
- `features/pilot_program/presentation/screens/atlas_pilot_program_screen.dart`
- `features/platform_v1/presentation/screens/atlas_platform_dashboard_screen.dart`
- `features/precision_hub/presentation/screens/atlas_precision_hub_screen.dart`
- `features/publication_center/presentation/screens/atlas_publication_center_screen.dart`
- `features/realtime/presentation/screens/atlas_realtime_center_screen.dart`
- `features/release_engineering/presentation/screens/atlas_release_engineering_screen.dart`
- `features/release_management/presentation/screens/atlas_release_center_screen.dart`
- `features/reports/data/atlas_csv_exporter.dart`
- `features/reports/data/atlas_report_generator.dart`
- `features/saas_admin/presentation/screens/atlas_saas_admin_screen.dart`
- `features/security_center/presentation/screens/atlas_security_center_screen.dart`
- `features/security_privacy_continuity/presentation/screens/atlas_security_privacy_continuity_screen.dart`
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