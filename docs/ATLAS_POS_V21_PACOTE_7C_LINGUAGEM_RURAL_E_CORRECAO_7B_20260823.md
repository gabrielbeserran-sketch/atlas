# Atlas Pós-V21 — Pacote 7C

## Correção definitiva dos dois apontamentos do 7B

1. `lib/main.dart`
   - removido `import 'dart:ui';`, que se tornou redundante depois da inclusão
     de `package:flutter/foundation.dart`.

2. `dr_beserra_voice_service.dart`
   - `localeId` deixou de ser passado pelo parâmetro antigo de `listen`;
   - passou a ficar dentro de `SpeechListenOptions`;
   - o reconhecimento usa `ListenMode.dictation`, resultados parciais e
     cancelamento em erro.

## Prevenção de regressão

Criado `tools/atlas_dart_deprecation_regression_gate.py`.

A homologação 7C falha antes dos demais testes se:
- `dart:ui` redundante voltar ao `main.dart`;
- o padrão antigo de `localeId` direto em `SpeechToText.listen` reaparecer;
- `SpeechListenOptions` for removido;
- a seleção do locale em português deixar de existir.

Além disso, a homologação continua executando a cadeia completa anterior,
incluindo `flutter analyze`. Assim, aviso de analyzer não é tratado como
detalhe: impede a aprovação.

## Pacote 7C — linguagem rural/contextual

O Dr. Beserra passa a reconhecer mais formas naturais de pedir informação,
sem ampliar permissões de escrita.

Exemplos:
- “qual a lida de hoje?”
- “qual a lida de amanhã?”
- “preciso pesar o lote”
- “vamos fazer diagnóstico de gestação”
- “como está o consumo no cocho?”
- “quero ver os custos”
- “como está o estoque de insumos?”
- “quero ver os piquetes”
- “quero ver os indicadores”
- “quero falar com o veterinário”
- “quero exportar o relatório”

Destinos oficiais acrescentados:
Nutrição, Financeiro, Estoque, Campo, Inteligência, Relatórios e Consultoria.

Amanhã é consultado na Agenda oficial com filtro de data real.

## Segurança

Novas permissões de escrita no 7C: zero.

A escrita conversacional permanece limitada à conclusão de tarefa da Agenda
após confirmação explícita, exatamente como no 7A.

## Backend e banco

Nenhuma alteração.
Nenhuma migration.
