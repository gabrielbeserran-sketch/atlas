# Atlas — Sprints 16 a 20

Entrega consolidada dos passos 201 a 250.

## Aplicação
1. Faça backup do projeto e banco.
2. Copie os arquivos completos mantendo os caminhos.
3. Execute `python -m alembic upgrade head` no backend.
4. Execute `python -m pytest -q`.
5. Execute `flutter clean`, `flutter pub get`, `flutter analyze` e `flutter run -d windows`.

## Migration
- revision: `20260806_0026`
- down_revision: `20260806_0025`

## Limites externos
Stripe, Mercado Pago, Pix, lojas Android/iOS, Power BI e inferência ML real exigem credenciais, homologação e adaptadores oficiais. Os contratos desta entrega não simulam uma integração externa ativa.

## Endpoints principais
- `GET /api/v1/sprints-16-20/dashboard`
- `POST /api/v1/sprints-16-20/billing/subscriptions`
- `POST /api/v1/sprints-16-20/public-api/apps`
- `GET /api/v1/sprints-16-20/public-api/openapi-contract`
- `POST /api/v1/sprints-16-20/analytics/datasets`
- `GET /api/v1/sprints-16-20/analytics/kpis`
- `POST /api/v1/sprints-16-20/ml/models`
- `PATCH /api/v1/sprints-16-20/ml/models/{id}/approve`
- `GET /api/v1/sprints-16-20/enterprise/readiness`
