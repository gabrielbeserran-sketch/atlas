# Atlas Pós-V21 Pacote 2 — correção estrutural do flutter analyze

## Causa raiz
O novo `farm_handling_screen.dart` introduziu quatro
`DropdownButtonFormField(value: ...)`. No Flutter usado no Windows do projeto,
esse parâmetro está depreciado e deve ser substituído por `initialValue:`.

O mesmo arquivo continha o getter privado `_selectionLabel`, que não era
referenciado por nenhuma parte da tela.

Como a homologação do Atlas exige `flutter analyze` sem issues, os cinco
diagnósticos bloquearam corretamente o gate.

## Correção
- 4/4 `value:` migrados para `initialValue:`.
- `_selectionLabel` removido.
- Regra de negócio, backend, banco e endpoint de manejo não foram alterados.

## Prevenção
O novo `atlas_post_v21_package2_dart_hygiene_gate.py` roda antes do analyze
global e rejeita especificamente:
- `DropdownButtonFormField(value:)` no código de produção do Pacote 2;
- reaparecimento de `_selectionLabel`;
- mojibake nos arquivos novos do Pacote 2.

O teste Dart do Pacote 2 também protege a API moderna.

## Possibilidade de erro semelhante
Sim: novas versões do Flutter podem depreciar outras APIs, e código novo pode
introduzir campos/métodos privados sem uso. Por isso a proteção do pacote não
substitui o `flutter analyze`; ela antecipa as regressões conhecidas antes de
chegar ao gate global. A homologação completa continua sendo obrigatória.
