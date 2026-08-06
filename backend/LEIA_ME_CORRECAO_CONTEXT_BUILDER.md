# Correção do contexto da IA

## Erro corrigido

O arquivo `app/ai/context_builder.py` importava a classe inexistente `Animal`.
A arquitetura oficial usa `LivestockAnimal`, da tabela `livestock_animals`.

A consulta do contexto da IA agora utiliza `LivestockAnimal.company_id` e
`LivestockAnimal.farm_id`.

## Banco de dados local

O arquivo `.env` atual aponta para PostgreSQL em `127.0.0.1:5432`.
O PostgreSQL precisa estar ativo antes de executar Alembic ou a API.

Para validar temporariamente com SQLite no PowerShell:

```powershell
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
```

Essas variáveis valem somente para a janela atual do terminal.

Para usar PostgreSQL, inicie o serviço ou o Docker Compose antes:

```powershell
docker compose up -d postgres
python -m alembic upgrade head
python -m uvicorn app.main:app --reload
```

## Validação

```powershell
python -m compileall app
```
