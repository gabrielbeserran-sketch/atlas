# Correção da camada de dependências

Esta entrega corrige o erro:

```text
ModuleNotFoundError: No module named 'app.dependencies'
```

Foi criado o arquivo completo:

```text
backend/app/dependencies.py
```

Ele utiliza a fonte oficial de autenticação em `app.authz`:

- `get_current_context()` retorna `Principal`;
- `get_current_user()` retorna `principal.user` para compatibilidade.

## Aplicação

Substitua a pasta `backend` atual pela pasta completa desta entrega.
Preserve o arquivo `.env` atual, caso ele contenha configurações próprias.

## Teste com SQLite

```powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
```
