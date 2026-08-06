from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
required=['app/data_platform_models.py','app/routers/data_platform.py','app/services/data_platform_service.py','alembic/versions/20260806_0034_data_platform.py']
missing=[p for p in required if not (ROOT/p).exists()]
if missing: raise SystemExit('Ausentes: '+', '.join(missing))
text=(ROOT/'app/main.py').read_text(encoding='utf-8')
if 'data_platform.router' not in text: raise SystemExit('Router não registrado.')
print('Data Platform 101-110: estrutura aprovada.')
