"""Prova de recuperação somente com SQLite e anexos descartáveis."""

import hashlib
import io
import json
import sqlite3
import tarfile
from pathlib import Path
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.config import get_settings
from app.database import Base, get_db
from app.models import AuditLog, Company, Membership, RefreshSession, User
from app.routers import backups
from app.security import create_access_token
from app.services.backup import BackupService


def service_for(tmp_path, monkeypatch):
    settings = get_settings()
    database = tmp_path / "source.sqlite3"
    attachments = tmp_path / "attachments"
    attachments.mkdir()
    (attachments / "receipt.txt").write_text("comprovante descartável", encoding="utf-8")
    monkeypatch.setattr(settings, "atlas_database_url", f"sqlite:///{database}")
    monkeypatch.setattr(settings, "atlas_backup_dir", str(tmp_path / "backups"))
    monkeypatch.setattr(settings, "atlas_attachment_dir", str(attachments))
    return BackupService(), database


def test_online_snapshot_contains_committed_wal_without_touching_source(tmp_path, monkeypatch):
    service, database = service_for(tmp_path, monkeypatch)
    source = sqlite3.connect(database)
    try:
        assert source.execute("PRAGMA journal_mode=WAL").fetchone()[0] == "wal"
        source.execute("CREATE TABLE demo (id INTEGER PRIMARY KEY, value TEXT)")
        source.execute("INSERT INTO demo VALUES (1, 'primeiro')")
        source.commit()
        source.execute("INSERT INTO demo VALUES (2, 'ainda no WAL')")
        source.commit()
        assert Path(f"{database}-wal").exists()

        bundle = service.run()
        result = service.verify_restore(bundle)
        assert result == {"engine": "sqlite", "tables": 1,
                          "attachments": 1, "verified": True}
        with tarfile.open(bundle, "r:gz") as archive:
            database_member = next(
                member for member in archive if member.name.endswith(".sqlite3")
            )
            snapshot = tmp_path / "inspect.sqlite3"
            snapshot.write_bytes(archive.extractfile(database_member).read())
        with sqlite3.connect(snapshot) as restored:
            assert restored.execute("SELECT id, value FROM demo ORDER BY id").fetchall() == [
                (1, "primeiro"), (2, "ainda no WAL"),
            ]
        assert source.execute("SELECT count(*) FROM demo").fetchone()[0] == 2
    finally:
        source.close()


def rewrite_bundle(bundle, replacement_name, replacement_bytes, target):
    with tarfile.open(bundle, "r:gz") as original:
        files = {
            member.name: original.extractfile(member).read()
            for member in original if member.isfile()
        }
    files[replacement_name] = replacement_bytes
    manifest = json.loads(files["manifest.json"])
    key = "database_sha256" if replacement_name == manifest["database_file"] else "attachments_sha256"
    manifest[key] = hashlib.sha256(replacement_bytes).hexdigest()
    files["manifest.json"] = json.dumps(manifest).encode()
    with tarfile.open(target, "w:gz") as rewritten:
        for name, data in files.items():
            member = tarfile.TarInfo(name)
            member.size = len(data)
            rewritten.addfile(member, io.BytesIO(data))


def test_restore_rejects_corrupt_database_even_with_matching_manifest(tmp_path, monkeypatch):
    service, database = service_for(tmp_path, monkeypatch)
    with sqlite3.connect(database) as source:
        source.execute("CREATE TABLE demo (id INTEGER)")
        source.execute("INSERT INTO demo VALUES (1)")
    bundle = service.run()
    manifest = service.verify_bundle(bundle)
    changed = tmp_path / "corrupt.atlasbackup"
    rewrite_bundle(bundle, manifest["database_file"], b"not a sqlite database", changed)
    assert service.verify_bundle(changed)["format"] == "atlasbackup-v1"
    with pytest.raises((sqlite3.DatabaseError, RuntimeError)):
        service.verify_restore(changed)


def test_restore_rejects_corrupt_attachment_archive_with_matching_manifest(tmp_path, monkeypatch):
    service, database = service_for(tmp_path, monkeypatch)
    with sqlite3.connect(database) as source:
        source.execute("CREATE TABLE demo (id INTEGER)")
    bundle = service.run()
    manifest = service.verify_bundle(bundle)
    changed = tmp_path / "bad-attachments.atlasbackup"
    rewrite_bundle(bundle, manifest["attachments_file"], b"not a tar archive", changed)
    assert service.verify_bundle(changed)["format"] == "atlasbackup-v1"
    with pytest.raises((tarfile.TarError, OSError)):
        service.verify_restore(changed)


def test_missing_restore_file_returns_not_found(tmp_path, monkeypatch):
    monkeypatch.setattr(backups.service, "backup_dir", tmp_path)
    with pytest.raises(HTTPException) as error:
        backups.verify_restore("missing.atlasbackup", principal=None, db=None)
    assert error.value.status_code == 404


def test_two_immediate_backups_keep_both_snapshots(tmp_path, monkeypatch):
    service, database = service_for(tmp_path, monkeypatch)
    with sqlite3.connect(database) as source:
        source.execute("CREATE TABLE demo (id INTEGER)")
        source.execute("INSERT INTO demo VALUES (1)")
    first = service.run()
    with sqlite3.connect(database) as source:
        source.execute("INSERT INTO demo VALUES (2)")
    second = service.run()
    assert first != second
    assert first.is_file() and second.is_file()
    assert service.verify_restore(first)["verified"]
    assert service.verify_restore(second)["verified"]


def test_authenticated_backup_route_verifies_restore_and_audits(tmp_path, monkeypatch):
    service, database = service_for(tmp_path, monkeypatch)
    with sqlite3.connect(database) as source:
        source.execute("CREATE TABLE demo (id INTEGER)")
    monkeypatch.setattr(backups, "service", service)
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(engine, tables=[
        Company.__table__, User.__table__, Membership.__table__,
        RefreshSession.__table__, AuditLog.__table__,
    ])
    with Session(engine) as db:
        db.add(Company(id="company", tenant_id="tenant", name="Descartável"))
        for role in ("owner", "viewer"):
            db.add(User(id=role, name=role, email=f"{role}@test.invalid",
                        password_hash="unused"))
            db.add(Membership(id=f"membership-{role}", user_id=role,
                              company_id="company", role=role))
            db.add(RefreshSession(
                id=f"session-{role}", user_id=role, company_id="company",
                token_hash=f"unused-{role}",
                expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            ))
        db.commit()
    app = FastAPI()
    app.include_router(backups.router)

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db

    def headers(role):
        token = create_access_token(
            user_id=role, company_id="company", tenant_id="tenant", role=role,
            extra={"session_id": f"session-{role}"},
        )
        return {"Authorization": f"Bearer {token}"}

    try:
        with TestClient(app) as client:
            assert client.post("/backups/run", headers=headers("viewer")).status_code == 403
            created = client.post("/backups/run", headers=headers("owner"))
            assert created.status_code == 200, created.text
            name = created.json()["filename"]
            assert client.post(
                f"/backups/{name}/verify-restore", headers=headers("viewer"),
            ).status_code == 403
            verified = client.post(
                f"/backups/{name}/verify-restore", headers=headers("owner"),
            )
            assert verified.status_code == 200, verified.text
            assert verified.json()["verified"] is True
        with Session(engine) as db:
            assert {item.action for item in db.query(AuditLog).all()} == {
                "backup_run", "backup_restore_verified",
            }
    finally:
        engine.dispose()
