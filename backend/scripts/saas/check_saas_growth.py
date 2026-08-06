from pathlib import Path
root=Path(__file__).resolve().parents[2]
required=['app/saas_growth_models.py','app/routers/saas_growth.py','alembic/versions/20260806_0033_saas_growth.py']
missing=[x for x in required if not (root/x).exists()]
if missing: raise SystemExit('Arquivos ausentes: '+', '.join(missing))
print('SaaS Growth 91-100: estrutura aprovada.')
