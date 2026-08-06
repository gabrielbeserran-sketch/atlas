# Projeto Atlas — Backend completo consolidado

Esta entrega contém a pasta `backend` completa, consolidada até os Sprints 26 a 30.

## Arquitetura corrigida
Os arquivos genéricos `sprint_models.py`, `sprints_16_20_models.py` e `sprints_21_25_models.py` foram substituídos por:
- `innovation_models.py`
- `enterprise_product_models.py`
- `operations_intelligence_models.py`
- `enterprise_growth_models.py`

## Sprints 26–30
- Financeiro Enterprise: `/api/v1/finance-enterprise`
- Estoque Enterprise: `/api/v1/inventory-enterprise`
- Ecossistema Atlas: `/api/v1/ecosystem`
- Inteligência Corporativa: `/api/v1/corporate-intelligence`
- Plataforma Global: `/api/v1/global-platform`

## Aplicação
Substitua a pasta `backend` inteira pela pasta desta entrega. Faça backup do banco antes.

```powershell
cd "C:\caminho\para\Projetos Atlas\backend"
python -m pip install -r requirements.txt
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
```

A migration nova é `20260806_0028`, dependente de `20260806_0027`.
