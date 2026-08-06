# Projeto Atlas — Sprints 41 a 50

Entrega completa do backend consolidado, com validação operacional dos módulos oficiais de fazenda, lote, animal, pesagem, movimentação, reprodução, sanidade, nutrição, estoque e financeiro.

## Aplicação

Preserve seu `.env` e sua `.venv`. Substitua a pasta backend pela pasta deste pacote ou copie os arquivos completos mantendo os caminhos.

## Comandos

```powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_core_validation.db"
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
```

Abra `/docs` e consulte `GET /api/v1/core-validation/farms/{farm_id}`.

Nenhuma migration nova é necessária: a entrega utiliza apenas tabelas oficiais existentes.
