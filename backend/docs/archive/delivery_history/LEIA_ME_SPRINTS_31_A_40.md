# Aplicação — Sprints 31 a 40

Esta entrega contém a pasta `backend` completa, baseada na versão que já iniciou com sucesso.

## Substituição

1. Pare o Uvicorn.
2. Renomeie a pasta atual para backup.
3. Extraia o ZIP na raiz do Projeto Atlas.
4. Reaproveite a `.venv` anterior ou crie uma nova.

## Execução

```powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_quality.db"
$env:ATLAS_JWT_SECRET="quality-gate-secret-with-at-least-32-characters"
python scripts/quality/run_quality_gate.py
```

## Flutter

```powershell
powershell -ExecutionPolicy Bypass -File backend/scripts/quality/run_flutter_quality.ps1
```
