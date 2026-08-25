from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
checks={
'0049': '20260825_0049' in (ROOT/'backend/alembic/versions/20260825_0049_consultancy_measurable_outcomes.py').read_text(encoding='utf-8'),
'model': 'baseline_metrics_json' in (ROOT/'backend/app/business_models.py').read_text(encoding='utf-8') and 'outcome_status' in (ROOT/'backend/app/business_models.py').read_text(encoding='utf-8'),
'backend': '/consulting/actions/outcomes' in (ROOT/'backend/app/routers/business.py').read_text(encoding='utf-8') and '_measure_action' in (ROOT/'backend/app/routers/business.py').read_text(encoding='utf-8'),
'flutter': 'loadOutcomes' in (ROOT/'lib/features/consultancy_client/data/services/atlas_consultancy_action_service.dart').read_text(encoding='utf-8'),
}
for name,ok in checks.items():
    print(('[OK] ' if ok else '[ERRO] ')+name)
if not all(checks.values()): raise SystemExit(1)
print('ATLAS POS-V21 MACROPACOTE 10A: APROVADO')
