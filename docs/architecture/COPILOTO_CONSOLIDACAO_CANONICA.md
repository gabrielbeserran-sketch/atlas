# Consolidação canônica do Copiloto Atlas

## Implementação oficial

A implementação oficial é `features/copilot`. Ela é utilizada pelo Dashboard Executivo e pela tela de detalhes da fazenda, possui conversa, histórico, feedback, reatividade e contexto operacional canônico.

## Implementação legada preservada

O antigo módulo `features/atlas_copilot` foi mantido para evitar perda de recursos visuais, mas suas classes públicas foram renomeadas para:

- `AtlasLegacyCopilotScreen`
- `AtlasLegacyCopilotService`

As classes receberam `@Deprecated` e não devem receber novas funcionalidades.

## Fonte única de execução

`Decision Engine V2 -> contratos canônicos -> Executive Brain -> operações canônicas -> Copiloto oficial`.

## Próximas migrações

1. Comparar os cartões do Copiloto legado com a interface oficial.
2. Migrar apenas recursos exclusivos e úteis.
3. Remover o módulo legado somente depois de confirmar ausência de imports e equivalência funcional.
