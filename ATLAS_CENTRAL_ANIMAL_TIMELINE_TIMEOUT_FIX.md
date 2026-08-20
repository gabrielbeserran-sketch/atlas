# Atlas — Central do Animal — correção final da Timeline Enterprise

## Diagnóstico confirmado

A API foi testada diretamente em produção e retornou corretamente a Timeline
Enterprise do `TESTE-001`.

O Flutter, porém, ainda exibia:

`Timeline Enterprise indisponível`

porque `animal_detail_screen.dart` tinha uma segunda camada de timeout local:

- `_safeLoad` com timeout padrão de 8 segundos;
- Timeline Enterprise sobrescrevendo esse limite para apenas 6 segundos.

Em Render Free, a API pode responder corretamente depois desse intervalo.
Assim, o Flutter abandonava uma requisição que o backend estava processando.

## Correção

- removido o timeout local de 8 segundos da Central;
- removido o timeout especial de 6 segundos da Timeline Enterprise;
- o `AtlasHttpClient` volta a ser a única fonte de verdade para timeout;
- falhas transitórias preservam os dados já carregados em vez de zerá-los;
- adicionado log explícito da quantidade de eventos Enterprise carregados.

## Resultado esperado

Ao abrir a Central do Animal após atualizar o projeto:

- o banner `Timeline Enterprise indisponível` deve desaparecer;
- a aba Timeline deve carregar ao menos o evento `Animal cadastrado`;
- o terminal deve registrar algo como:

`ATLAS Animal Central [Timeline Enterprise]: 1 evento(s) carregado(s)`.
