# Atlas — Sprints 21 a 25 e correção arquitetural

## Correção obrigatória de nomes

Depois de copiar os arquivos, EXCLUA estes routers genéricos antigos:

- `backend/app/routers/sprints_11_15.py`
- `backend/app/routers/sprints_16_20.py`

O novo `backend/app/main.py` não os importa mais.

Os routers passam a usar nomes de domínio:

- `atlas_brain.py`
- `atlas_vision.py`
- `iot_platform.py`
- `cloud_operations.py`
- `web_platform.py`
- `billing.py`
- `public_api.py`
- `enterprise_analytics.py`
- `machine_learning_registry.py`
- `enterprise_release.py`
- `innovation_platform.py` (preserva integralmente os endpoints anteriores dos Sprints 11 a 15)
- `enterprise_product.py` (preserva integralmente os endpoints anteriores dos Sprints 16 a 20)
- `precision_livestock.py`
- `reproduction_advanced.py`
- `health_intelligence.py`
- `nutrition_intelligence.py`
- `farm_operations.py`

## Migration

`20260806_0027`, dependente de `20260806_0026`.

## Aplicação

```powershell
cd "C:\caminho\para\Projetos Atlas\backend"
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
```

```powershell
cd "C:\caminho\para\Projetos Atlas"
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
```
