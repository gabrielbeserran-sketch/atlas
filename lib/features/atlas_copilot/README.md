# Atlas Copilot legado

Este módulo foi preservado apenas para compatibilidade histórica e consulta de recursos visuais.

## Implementação canônica

A implementação oficial do Copiloto está em:

- `lib/features/copilot/`
- tela: `features/copilot/presentation/screens/atlas_copilot_screen.dart`
- controlador: `features/copilot/presentation/controllers/atlas_copilot_controller.dart`
- serviço de resposta: `features/dashboard/domain/services/atlas_copilot_service.dart`
- contexto operacional: `core/services/atlas_canonical_operations_service.dart`

## Regra

Não adicionar novas funcionalidades neste módulo legado. Recursos úteis devem ser migrados para `features/copilot` e consumidos pelos contratos canônicos.
