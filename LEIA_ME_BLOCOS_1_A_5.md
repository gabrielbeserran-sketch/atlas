# ATLAS — BLOCOS 1 A 5

Entrega integrada dos passos 51 a 100: IA, georreferenciamento, pastagens, agricultura integrada e genética.

## Arquivos novos
- backend/app/advanced_models.py
- backend/app/routers/advanced.py
- backend/alembic/versions/20260806_0023_advanced_blocks_1_5.py
- backend/tests/test_advanced_blocks_1_5_contract.py
- lib/features/atlas_advanced/domain/models/atlas_advanced_data.dart
- lib/features/atlas_advanced/data/services/atlas_advanced_service.dart
- lib/features/atlas_advanced/presentation/screens/atlas_advanced_dashboard_screen.dart

## Arquivo substituído
- backend/app/main.py

## Aplicação
1. Copie os arquivos mantendo os caminhos.
2. Execute no backend: `python -m alembic upgrade head`.
3. Execute: `python -m pytest -q` e `python -m uvicorn app.main:app --reload`.
4. No Flutter: `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter run -d windows`.

## Observações
- KML, KMZ e shapefile são aceitos por conversão para GeoJSON; o backend não finge interpretar binários sem biblioteca geoespacial.
- IA climática recebe dados climáticos no payload até que um provedor oficial seja configurado.
- DEP e registros genealógicos podem ser importados manualmente ou por futura integração com associações oficiais.
