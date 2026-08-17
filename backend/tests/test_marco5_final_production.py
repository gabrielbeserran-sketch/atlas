from __future__ import annotations

from pathlib import Path

from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.services.concurrency import advisory_transaction_lock
from app.services.backup import BackupService


def test_advisory_lock_is_safe_noop_on_sqlite() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:")
    with Session(engine) as db:
        advisory_transaction_lock(db, "company:resource:123")


def test_backup_bundle_sqlite_roundtrip(tmp_path, monkeypatch) -> None:
    from app.config import get_settings

    settings = get_settings()
    database = tmp_path / "source.sqlite3"
    engine = create_engine(f"sqlite:///{database}")
    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE demo (id INTEGER PRIMARY KEY)"))
        connection.execute(text("INSERT INTO demo (id) VALUES (1)"))
    engine.dispose()

    attachment_dir = tmp_path / "attachments"
    attachment_dir.mkdir()
    (attachment_dir / "proof.txt").write_text("atlas", encoding="utf-8")

    backup_dir = tmp_path / "backups"
    monkeypatch.setattr(
        settings,
        "atlas_database_url",
        f"sqlite:///{database}",
    )
    monkeypatch.setattr(settings, "atlas_backup_dir", str(backup_dir))
    monkeypatch.setattr(settings, "atlas_attachment_dir", str(attachment_dir))

    service = BackupService()
    # __init__ reads backup_dir via property, after monkeypatch.
    service.backup_dir = settings.backup_dir

    bundle = service.run()
    assert bundle.suffix == ".atlasbackup"
    assert service.verify_bundle(bundle)["format"] == "atlasbackup-v1"

    result = service.verify_restore(bundle)
    assert result["verified"] is True
    assert result["tables"] >= 1
