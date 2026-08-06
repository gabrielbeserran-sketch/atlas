from pathlib import Path


def test_offline_router_registered():
    from app.main import app
    paths = {route.path for route in app.routes}
    assert "/api/v1/offline/push-batch" in paths
    assert "/api/v1/offline/pull-page" in paths
    assert "/api/v1/offline/conflicts/{conflict_id}/resolve" in paths


def test_offline_models_have_expected_tables():
    from app.offline_models import OfflineDevice, OfflineDiagnostic, SyncConflict
    assert OfflineDevice.__tablename__ == "offline_devices"
    assert SyncConflict.__tablename__ == "sync_conflicts"
    assert OfflineDiagnostic.__tablename__ == "offline_diagnostics"


def test_migration_0029_exists():
    root = Path(__file__).resolve().parents[1]
    migration = root / "alembic" / "versions" / "20260806_0029_offline_sync_foundation.py"
    assert migration.exists()
    text = migration.read_text(encoding="utf-8")
    assert 'down_revision = "20260806_0028"' in text
