"""PostgreSQL restore verification must not hide a leftover temporary database."""

import subprocess
from unittest.mock import MagicMock

import pytest

from app.services import backup as backup_module


@pytest.fixture
def service(monkeypatch):
    monkeypatch.setattr(
        backup_module.settings,
        "atlas_database_url",
        "postgresql+psycopg://ci-user:ci-test-password@127.0.0.1:5432/ci-db",
    )
    return backup_module.BackupService()


def test_restore_error_still_requires_confirmed_cleanup(service, monkeypatch, tmp_path):
    calls = []

    def run(command, **kwargs):
        calls.append((command, kwargs))
        if command[0] == "pg_restore":
            raise subprocess.CalledProcessError(1, command)
        return subprocess.CompletedProcess(command, 0)

    monkeypatch.setattr(backup_module.subprocess, "run", run)
    with pytest.raises(subprocess.CalledProcessError):
        service._verify_postgres_restore(tmp_path / "dummy.dump")

    assert [command[0] for command, _ in calls] == [
        "createdb", "pg_restore", "dropdb",
    ]
    assert calls[-1][1]["check"] is True
    assert calls[-1][0][-1] == calls[0][0][-1]


def test_cleanup_error_is_reported_without_password(service, monkeypatch, tmp_path):
    monkeypatch.setattr(
        backup_module.settings,
        "atlas_database_url",
        "postgresql+psycopg://ci-user:p%40ss%3Aword@127.0.0.1:5432/ci-db",
    )
    engine = MagicMock()
    inspector = MagicMock()
    inspector.get_table_names.return_value = ["alembic_version", "demo"]
    restored_urls = []

    def create_engine(url, **kwargs):
        restored_urls.append(url)
        return engine

    monkeypatch.setattr(backup_module, "create_engine", create_engine)
    monkeypatch.setattr(backup_module, "inspect", lambda _engine: inspector)
    calls = []

    def run(command, **kwargs):
        calls.append((command, kwargs))
        if command[0] == "dropdb":
            raise subprocess.CalledProcessError(1, command)
        return subprocess.CompletedProcess(command, 0)

    monkeypatch.setattr(backup_module.subprocess, "run", run)
    with pytest.raises(RuntimeError, match="remoção do banco temporário") as error:
        service._verify_postgres_restore(tmp_path / "dummy.dump")

    assert calls[-1][1]["check"] is True
    assert calls[-1][0][-1] in str(error.value)
    assert "p@ss:word" not in str(error.value)
    assert restored_urls[0].password == "p@ss:word"
    assert restored_urls[0].database == calls[0][0][-1]
    engine.dispose.assert_called_once()


def test_dump_decodes_percent_encoded_password_without_putting_it_in_args(
    service, monkeypatch, tmp_path,
):
    calls = []

    def run(command, **kwargs):
        calls.append((command, kwargs))
        return subprocess.CompletedProcess(command, 0)

    monkeypatch.setattr(backup_module.subprocess, "run", run)
    service._pg_dump(
        "postgresql+psycopg://ci-user:p%40ss%3Aword@127.0.0.1:5432/ci-db",
        tmp_path / "dummy.dump",
    )

    assert len(calls) == 1
    command, options = calls[0]
    assert command[-1] == "ci-db"
    assert "p@ss:word" not in command
    assert "p%40ss%3Aword" not in command
    assert options["env"]["PGPASSWORD"] == "p@ss:word"


def test_incomplete_destination_is_rejected_before_dump(service, monkeypatch, tmp_path):
    run = MagicMock()
    monkeypatch.setattr(backup_module.subprocess, "run", run)
    with pytest.raises(RuntimeError, match="Destino PostgreSQL"):
        service._pg_dump(
            "postgresql+psycopg://ci-user:password@127.0.0.1:5432",
            tmp_path / "dummy.dump",
        )
    run.assert_not_called()
