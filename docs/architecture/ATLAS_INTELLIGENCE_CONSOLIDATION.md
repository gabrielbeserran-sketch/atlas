# Consolidação do Atlas Intelligence

## Decisão canônica

A implementação oficial do motor de inteligência permanece em `features/atlas_intelligence`:

- `AtlasIntelligenceService`
- `AtlasIntelligenceData`
- `AtlasIntelligenceScreen`

Ela é responsável por sinais, padrões, hipóteses e recomendações.

## Camada operacional do Dashboard

A antiga implementação homônima do Dashboard foi renomeada para deixar sua responsabilidade explícita:

- `AtlasOperationsIntelligenceService`
- `AtlasOperationsIntelligenceScreen`

Essa camada recebe `ExecutiveDecisionData` e monta somente o resumo operacional usado pelo Dashboard e pelo Copiloto.
Ela não substitui nem duplica o motor canônico.

## Alterações realizadas

- Renomeado `dashboard/domain/services/atlas_intelligence_service.dart` para `atlas_operations_intelligence_service.dart`.
- Renomeado `dashboard/presentation/screens/atlas_intelligence_screen.dart` para `atlas_operations_intelligence_screen.dart`.
- Atualizados imports, instanciação e navegação no Dashboard Executivo.
- Removidas as duplicidades públicas de `AtlasIntelligenceService` e `AtlasIntelligenceScreen`.
- Preservados os modelos, cálculos, telas e fluxos já existentes.

## Regra permanente

Novos cálculos analíticos pertencem a `features/atlas_intelligence`.
O Dashboard apenas apresenta resumos e atalhos gerados pela cadeia executiva.
