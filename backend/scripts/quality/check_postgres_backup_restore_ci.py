"""Prove the Atlas PostgreSQL backup can restore into a separate CI database.

This runner refuses any target other than the disposable GitHub Actions service.
It never accepts a command-line database URL or touches a production database.
"""

from __future__ import annotations

import os
import subprocess
import tarfile
import tempfile
from pathlib import Path
from uuid import uuid4

from sqlalchemy import create_engine
from sqlalchemy.engine import make_url

from app.config import get_settings
from app.services.backup import BackupService
from scripts.quality.check_postgres_ci_contract import validate_ci_target, verify


def main() -> None:
    database_url = os.environ.get("ATLAS_DATABASE_URL", "")
    validate_ci_target(
        database_url,
        actions=os.environ.get("GITHUB_ACTIONS", ""),
        environment=os.environ.get("ATLAS_ENV", ""),
    )

    parsed = make_url(database_url)
    settings = get_settings()
    previous_backup_dir = settings.atlas_backup_dir
    previous_attachment_dir = settings.atlas_attachment_dir
    with tempfile.TemporaryDirectory(prefix="atlas_ci_restore_") as root_raw:
        root = Path(root_raw)
        settings.atlas_backup_dir = str(root / "backups")
        settings.atlas_attachment_dir = str(root / "attachments")
        try:
            attachment_dir = settings.attachment_dir
            (attachment_dir / "ci-receipt.txt").write_text(
                "anexo de prova descartável", encoding="utf-8"
            )
            service = BackupService()
            bundle = service.run()
            manifest = service.verify_bundle(bundle)
            result = service.verify_restore(bundle)
            assert result["engine"] == "postgresql"
            assert result["verified"] is True
            assert result["attachments"] == 1
            assert result["tables"] > 0

            dump_path = root / "restored-source.dump"
            with tarfile.open(bundle, "r:gz") as archive:
                member = archive.getmember(manifest["database_file"])
                source = archive.extractfile(member)
                if source is None:
                    raise RuntimeError("Dump ausente no bundle de prova.")
                with source, dump_path.open("wb") as target:
                    for chunk in iter(lambda: source.read(1024 * 1024), b""):
                        target.write(chunk)

            restored_name = f"atlas_ci_restore_{uuid4().hex}"
            cli_env = os.environ.copy()
            cli_env["PGPASSWORD"] = parsed.password or ""
            cli_common = [
                "--host", parsed.host or "127.0.0.1",
                "--port", str(parsed.port or 5432),
                "--username", parsed.username or "atlas_ci_probe",
            ]
            subprocess.run(
                ["createdb", *cli_common, restored_name],
                check=True, env=cli_env, capture_output=True, text=True,
            )
            try:
                subprocess.run(
                    [
                        "pg_restore", *cli_common, "--dbname", restored_name,
                        "--no-owner", "--no-privileges", str(dump_path),
                    ],
                    check=True, env=cli_env, capture_output=True, text=True,
                )
                restored_engine = create_engine(parsed.set(database=restored_name))
                try:
                    verify(restored_engine)
                finally:
                    restored_engine.dispose()
            finally:
                subprocess.run(
                    ["dropdb", *cli_common, "--if-exists", restored_name],
                    check=True, env=cli_env, capture_output=True, text=True,
                )
        finally:
            settings.atlas_backup_dir = previous_backup_dir
            settings.atlas_attachment_dir = previous_attachment_dir

    print("Backup Atlas CI: bundle, anexo e restauração PostgreSQL 0059 aprovados.")


if __name__ == "__main__":
    main()
