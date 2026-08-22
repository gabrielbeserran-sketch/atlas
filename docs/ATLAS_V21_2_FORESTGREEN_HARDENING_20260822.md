# Atlas V21.2 — correção definitiva do `forestGreen`

## Falha encontrada
O Flutter Analyzer apontou:
`nutrition_overview_screen.dart:32:16 - unused_field`

O campo real era:
`static const forestGreen = Color(0xFF1B5E20);`

A tentativa V21.1 verificava incorretamente `forceGreen`, portanto o preflight não protegia contra a falha real.

## Correção
- `forestGreen` removido do State de Nutrição.
- Auditoria de todos os campos do `_NutritionOverviewScreenState`: `forestGreen` era o único declarado sem uso.
- Varredura adicional de `static const` sem uso dentro de classes privadas em todo `lib`: zero ocorrências após a correção.
- Novo gate `tools/atlas_v21_2_dart_hygiene_gate.py`.
- Gate Windows passa a procurar `forestGreen` corretamente antes de `flutter analyze`.
- Gate Windows salvo em UTF-8 com BOM para Windows PowerShell exibir acentos corretamente.
- O gate continua formatando antes de analisar, sem transformar formatação automática em falso erro.

## Regra
A V21.2 continua sendo candidata até `flutter analyze`, `flutter test`, build Windows, smoke Render/Supabase e 14/14 fluxos visuais passarem no Windows.
