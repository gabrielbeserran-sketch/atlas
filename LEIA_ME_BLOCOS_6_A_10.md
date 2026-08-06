# ATLAS — BLOCOS 6 A 10

Esta entrega implementa os passos 101 a 150: comercialização, consultoria, plataforma Enterprise, BI e produto comercial.

## Aplicação
1. Faça backup do projeto e banco.
2. Substitua todos os arquivos mantendo os caminhos.
3. No backend: `python -m alembic upgrade head`, `python -m pytest -q`, `python -m uvicorn app.main:app --reload`.
4. No Flutter: `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter run -d windows`.

## Migration
`20260806_0024`, dependente de `20260806_0023`.

## Limites honestos
Nota fiscal, assinatura digital, gateways de pagamento, envio real de webhooks, publicação nas lojas e Power BI exigem credenciais, homologação e provedores externos. Esta entrega cria contratos, persistência, segurança e estados operacionais para essas integrações, sem simular serviços externos.
