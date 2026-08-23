# Atlas Pós-V21 — Hotfix 7E: helpers órfãos

## Falha observada no Windows

O `flutter analyze` bloqueou o Pacote 7E porque
`DrBeserraCommandGateway._taskDateKey()` não era mais utilizado.

## Causa

No 7E, a filtragem de datas foi corretamente movida para
`DrBeserraDailyRoutineService`.

O gateway, porém, preservou os helpers privados antigos de data.

A primeira falha visível era `_taskDateKey()`. Ao auditar a cadeia completa
antes de entregar o hotfix, também foi detectado que `_dateKey()` só era
referenciado pelo próprio `_taskDateKey()`. Portanto, se apenas o primeiro
fosse removido, o analyzer teria apresentado o segundo aviso na sequência.

## Correção

Foram removidos do `DrBeserraCommandGateway`:

- `_taskDateKey()`;
- `_dateKey()`.

A responsabilidade de interpretar datas permanece exclusivamente no
`DrBeserraDailyRoutineService`.

## Prevenção

Novo gate:

`tools/atlas_dart_private_helper_orphan_gate.py`

Ele audita os principais serviços do Dr. Beserra e reprova helpers privados
declarados sem qualquer referência além da própria declaração.

O gate conta também referências de métodos usadas como callback/tear-off,
evitando falso positivo em construções legítimas como:

- `sort(_compare)`;
- `onResult: _onResult`;
- `onStatus: _onStatus`.

Também há bloqueio explícito para o retorno dos dois helpers legados do gateway.

O gate foi inserido no início da homologação do Pacote 7E.

## Validação disponível neste ambiente

- novo gate de helpers órfãos: aprovado;
- gate 7E: aprovado;
- gate de deprecações: aprovado;
- colisões de intenção: aprovado;
- 7D/7C/7B/7A: aprovados;
- 6D-D até Pacote 1: aprovados;
- baseline static audit: OK;
- full project audit: OK;
- guarda estrutural Dart do arquivo alterado: OK.

O `flutter analyze` real continua sendo executado pelo script de homologação
no ambiente Windows do projeto.

## Backend e banco

Nenhuma alteração.
Nenhuma migration.
