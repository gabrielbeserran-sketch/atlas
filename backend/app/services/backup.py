from __future__ import annotations

import os
import shutil
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlparse

from ..config import get_settings

settings = get_settings()


class BackupService:
    def __init__(self) -> None:
        self.backup_dir = settings.backup_dir

    def run(self) -> Path:
        timestamp = datetime.now(timezone.utc).strftime(
            "%Y%m%dT%H%M%SZ"
        )
        url = settings.atlas_database_url

        if url.startswith("sqlite"):
            source = self._sqlite_path(url)
            target = self.backup_dir / f"atlas_{timestamp}.sqlite3"
            if not source.exists():
                raise RuntimeError(
                    f"Banco SQLite não encontrado: {source}"
                )
            shutil.copy2(source, target)
        else:
            target = self.backup_dir / f"atlas_{timestamp}.dump"
            self._pg_dump(url, target)

        self.cleanup()
        return target

    def list_backups(self) -> list[Path]:
        return sorted(
            [
                path
                for path in self.backup_dir.iterdir()
                if path.is_file()
            ],
            key=lambda path: path.stat().st_mtime,
            reverse=True,
        )

    def cleanup(self) -> None:
        cutoff = datetime.now(timezone.utc) - timedelta(
            days=settings.atlas_backup_retention_days
        )
        for path in self.list_backups():
            modified = datetime.fromtimestamp(
                path.stat().st_mtime,
                tz=timezone.utc,
            )
            if modified < cutoff:
                path.unlink(missing_ok=True)

    def _sqlite_path(self, url: str) -> Path:
        raw = url.removeprefix("sqlite:///")
        return Path(raw)

    def _pg_dump(self, database_url: str, target: Path) -> None:
        parsed = urlparse(
            database_url.replace(
                "postgresql+psycopg://",
                "postgresql://",
            )
        )
        env = os.environ.copy()
        if parsed.password:
            env["PGPASSWORD"] = parsed.password

        command = [
            "pg_dump",
            "--format=custom",
            "--file",
            str(target),
            "--host",
            parsed.hostname or "localhost",
            "--port",
            str(parsed.port or 5432),
            "--username",
            parsed.username or "postgres",
            parsed.path.lstrip("/"),
        ]
        subprocess.run(
            command,
            check=True,
            env=env,
            capture_output=True,
            text=True,
        )
