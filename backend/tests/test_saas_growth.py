from pathlib import Path

def test_saas_growth_files_and_router():
    root=Path(__file__).resolve().parents[1]
    assert (root/'app/saas_growth_models.py').exists()
    router=(root/'app/routers/saas_growth.py').read_text(encoding='utf-8')
    for path in ['/plans','/subscriptions','/invoices','/feature-flags','/onboarding','/imports','/exports','/client-portal','/admin/dashboard']:
        assert path in router

def test_migration_chain():
    text=(Path(__file__).resolve().parents[1]/'alembic/versions/20260806_0033_saas_growth.py').read_text(encoding='utf-8')
    assert "revision='20260806_0033'" in text
    assert "down_revision='20260806_0032'" in text
