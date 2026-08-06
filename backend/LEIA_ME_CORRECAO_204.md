# Correção das rotas HTTP 204

Esta entrega corrige as rotas de exclusão lógica do núcleo pecuário que impediam o FastAPI de iniciar.

## Problema corrigido

O FastAPI não permite corpo de resposta em rotas com status `204 No Content`. As rotas abaixo declaravam `204`, mas a assinatura permitia inferência de modelo de resposta:

- `DELETE /api/v1/livestock/lots/{lot_id}`
- `DELETE /api/v1/livestock/animals/{animal_id}`

Agora ambas usam explicitamente:

```python
response_class=Response
response_model=None
```

e retornam:

```python
Response(status_code=status.HTTP_204_NO_CONTENT)
```

## Como substituir

1. Pare o servidor com `Ctrl + C`.
2. Renomeie a pasta atual `backend` para backup.
3. Extraia este ZIP diretamente na raiz do Projeto Atlas.
4. Entre na nova pasta `backend`.
5. Recrie ou ative a `.venv`.
6. Instale `requirements.txt`.
7. Inicie o servidor novamente.

```powershell
cd "C:\Projetos\Projetos Atlas\backend"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
```
