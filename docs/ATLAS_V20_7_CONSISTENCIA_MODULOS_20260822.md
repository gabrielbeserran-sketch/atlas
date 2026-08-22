# Atlas V20.7 — Consistência completa dos módulos

Base: V20.6

## Escopo
Padronização da ação principal dos sete módulos operacionais:
Rebanho, Sanidade, Reprodução, Nutrição, Estoque, Financeiro e Agenda.

## Alterações
- Criado `AtlasOperationalActionBar`, responsivo.
- Ação principal passa a ocupar a mesma hierarquia e posição no conteúdo.
- Atualização passa a ter ação explícita `Atualizar` no mesmo componente.
- FABs concorrentes foram removidos dos sete módulos.
- Rebanho mantém `Novo lote` como ação secundária, ao lado de `Novo animal`.
- Pull-to-refresh foi preservado em todos os módulos.
- AppBar externa continua disponível quando a tela é aberta fora do shell.
- Estados vazios, falhas com `Tentar novamente`, filtros e formulários existentes foram preservados.
- Nenhum endpoint, DTO, serviço de persistência, migration ou regra pecuária foi alterado.
- Varredura de arquivos de apresentação continua sem padrões conhecidos de mojibake.

## Gates
- V20.5 UX: 253/253
- V20.6 fluxo: 16/16
- V20.7 consistência: 32/32
- Python compileall backend/app + alembic + tools: OK
- Delimitadores dos 8 arquivos Dart alterados: OK

## Validação obrigatória no Windows
Executar:
`flutter pub get`
`flutter analyze`
`flutter test`
`flutter build windows --debug`

O ambiente de empacotamento não possui Flutter SDK; portanto esses gates não são declarados como executados aqui.
