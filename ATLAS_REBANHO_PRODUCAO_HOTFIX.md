# Atlas — Hotfix Rebanho em produção

## Causa confirmada

`herd_overview_screen.dart` aplicava um timeout local de 8 segundos em paralelo
para Lotes e Animais:

- `_safeLoad(...).timeout(Duration(seconds: 8))`

O `AtlasHttpClient` já possui timeout centralizado por ambiente e usa
`receiveTimeout = 30s` em production. O timeout local de 8s encerrava as
requisições antes da camada oficial de rede, especialmente no Render Free.

## Alterações

1. Removido o timeout local de 8s do Rebanho.
2. O AtlasHttpClient volta a ser a única fonte de verdade para timeout.
3. Se uma atualização temporária falhar, o Rebanho preserva a última carteira
   carregada em vez de zerar Lotes/Animais.
4. Dropdown de Lote recebe `isExpanded: true` e ellipsis.
5. Dropdowns Situação/Sexo recebem `isExpanded: true`.

## Comportamento esperado

- Rebanho não deve mais falhar exatamente em 8 segundos.
- Em produção, a chamada pode aguardar até o timeout oficial do cliente.
- Uma falha transitória não apaga visualmente dados já carregados.
- O aviso `RIGHT OVERFLOWED BY ... PIXELS` no filtro de lote deve desaparecer.

## Observação sobre Secure Storage

O log de `CryptUnprotectData()` é uma segunda questão, independente do timeout
do Rebanho. Este hotfix não altera a criptografia/sessão porque o login e
`/auth/me` já foram validados. Essa camada deve ser corrigida separadamente
para evitar misturar um problema de sessão local com a falha de carregamento.
