# Correção de compatibilidade dos modelos pecuários

Esta pasta backend completa corrige os imports históricos que ainda esperavam
nomes como `LivestockLot` e `LivestockWeight`.

Os aliases foram centralizados em `app/models.py` e apontam para as mesmas
classes/tabelas oficiais:

- `LivestockLot = HerdLot`
- `LivestockWeight = WeightRecord`
- `LivestockHealthEvent = HealthEvent`
- `LivestockNutritionEvent = NutritionEvent`
- `LivestockReproductionEvent = ReproductionEvent`

Nenhuma tabela nova foi criada e nenhuma migration é necessária para esta
correção.

## Teste local com SQLite

```powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
```
