from pathlib import Path

def test_sprints_16_20_contract_files():
    root=Path(__file__).resolve().parents[2]
    assert (root/'backend/app/enterprise_product_models.py').exists()
    text=(root/'backend/app/routers/sprints_16_20.py').read_text(encoding='utf-8')
    for path in ['/billing/subscriptions','/public-api/apps','/analytics/kpis','/ml/models','/enterprise/readiness']:
        assert path in text

def test_migration_chain():
    root=Path(__file__).resolve().parents[2]
    text=(root/'backend/alembic/versions/20260806_0026_sprints_16_20.py').read_text(encoding='utf-8')
    assert "revision='20260806_0026'" in text
    assert "down_revision='20260806_0025'" in text

def test_no_fake_ml_inference():
    root=Path(__file__).resolve().parents[2]
    text=(root/'backend/app/routers/sprints_16_20.py').read_text(encoding='utf-8')
    assert 'Inference adapter must be configured' in text
    assert "model.status!='approved'" in text
