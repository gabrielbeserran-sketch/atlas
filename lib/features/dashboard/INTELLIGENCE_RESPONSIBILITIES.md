# Responsabilidades de inteligência no Dashboard

## Motor canônico

A inteligência analítica central do Atlas permanece em:

- `lib/features/atlas_intelligence/`
- `AtlasIntelligenceService`
- `AtlasIntelligenceData`
- `AtlasIntelligenceScreen`

Essa camada interpreta sinais, padrões, hipóteses e recomendações a partir do Atlas OS.

## Resumo operacional do Dashboard

A camada localizada em `lib/features/dashboard/` não é um segundo motor de inteligência.
Ela transforma `ExecutiveDecisionData` em um resumo operacional para navegação e leitura rápida:

- `AtlasOperationsIntelligenceService`
- `AtlasIntelligenceBrief`
- `AtlasOperationsIntelligenceScreen`

Essa camada não deve criar novas regras analíticas independentes. Ela apenas apresenta prioridades,
riscos, oportunidades, pontos positivos e orientações já consolidadas pela cadeia executiva.

## Regra permanente

- Novos cálculos de sinais, padrões, hipóteses ou recomendações pertencem a `features/atlas_intelligence`.
- Resumos visuais e atalhos do Dashboard pertencem a `features/dashboard`.
- O Dashboard não deve competir com o motor canônico nem recalcular decisões oficiais.
