# Atlas V21.1 — Correção do gate de homologação

## Causa 1 — `dart format` retornava código 1
O gate V21 usava `dart format --set-exit-if-changed lib test`. Esse modo retorna código 1 quando encontra qualquer arquivo que precisa de formatação, mesmo após formatá-lo. No Windows do projeto foram encontrados 1050 arquivos, dos quais 69 precisavam de formatação. Isso interrompia a homologação antes de `flutter analyze`.

A V21.1 usa `dart format lib test` como etapa de preparação e somente falha se o formatter realmente falhar.

## Causa 2 — aviso `forceGreen`
O arquivo canônico incluído no pacote V21.1 não possui `forceGreen`.
SHA-256 antes de formatar:
`800f4b46ebb5b23a5f79a37385f5a87f69179666eda3c474b885dde9d278ff77`

O novo preflight lê a árvore instalada antes de qualquer gate e bloqueia imediatamente se encontrar `forceGreen`, identificando instalação parcial ou arquivo antigo.

## Regra de homologação
A candidata só vira baseline após:
- preflight da árvore;
- pub get;
- format;
- analyze;
- tests;
- build Windows;
- gates V20.7–V20.10;
- baseline audit;
- full project audit;
- smoke Render/Supabase;
- 14/14 fluxos visuais.
