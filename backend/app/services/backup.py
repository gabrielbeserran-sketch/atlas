from __future__ import annotations

import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import tarfile
import tempfile
from contextlib import closing
from datetime import datetime, timedelta, timezone
from pathlib import Path
from pathlib import PurePosixPath

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DatabaseError

from ..config import get_settings

settings = get_settings()


class BackupService:
    def __init__(self) -> None:
        self.backup_dir = settings.backup_dir

    def run(self) -> Path:
        """Cria backup completo: banco + anexos + manifesto SHA-256."""
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
        bundle = self.backup_dir / f"atlas_{timestamp}.atlasbackup"

        with tempfile.TemporaryDirectory(prefix="atlas_backup_") as tmp_raw:
            tmp = Path(tmp_raw)
            database_file = self._create_database_backup(tmp, timestamp)
            attachments_file = tmp / "attachments.tar.gz"
            self._archive_attachments(attachments_file)

            manifest = {
                "format": "atlasbackup-v1",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "database_file": database_file.name,
                "database_sha256": self._sha256(database_file),
                "attachments_file": attachments_file.name,
                "attachments_sha256": self._sha256(attachments_file),
            }
            (tmp / "manifest.json").write_text(
                json.dumps(manifest, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

            with tarfile.open(bundle, "x:gz") as archive:
                archive.add(database_file, arcname=database_file.name)
                archive.add(attachments_file, arcname=attachments_file.name)
                archive.add(tmp / "manifest.json", arcname="manifest.json")

        self.cleanup()
        return bundle

    def list_backups(self) -> list[Path]:
        return sorted(
            [
                path
                for path in self.backup_dir.iterdir()
                if path.is_file()
                and path.suffix in {".atlasbackup", ".dump", ".sqlite3"}
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

    def verify_bundle(self, bundle: Path) -> dict:
        with tempfile.TemporaryDirectory(prefix="atlas_verify_") as tmp_raw:
            tmp = Path(tmp_raw)
            self._extract_bundle(bundle, tmp)
            manifest = json.loads(
                (tmp / "manifest.json").read_text(encoding="utf-8")
            )

            database_file = tmp / manifest["database_file"]
            attachments_file = tmp / manifest["attachments_file"]

            if database_file.resolve().parent != tmp.resolve() or attachments_file.resolve().parent != tmp.resolve():
                raise RuntimeError("Caminho inválido no manifesto do backup.")

            if self._sha256(database_file) != manifest["database_sha256"]:
                raise RuntimeError("Checksum do backup do banco inválido.")
            if self._sha256(attachments_file) != manifest["attachments_sha256"]:
                raise RuntimeError("Checksum do backup de anexos inválido.")

            return manifest

    def verify_restore(self, bundle: Path) -> dict:
        """Prova restauração sem tocar no banco principal.

        PostgreSQL: cria um banco temporário, restaura o dump, valida conexão
        e presença de tabelas, e remove o banco temporário.
        SQLite: restaura para arquivo temporário e valida abertura.
        """
        with tempfile.TemporaryDirectory(prefix="atlas_restore_") as tmp_raw:
            tmp = Path(tmp_raw)
            self._extract_bundle(bundle, tmp)
            manifest = self.verify_bundle(bundle)
            database_file = tmp / manifest["database_file"]
            attachments_file = tmp / manifest["attachments_file"]
            attachments = self._verify_attachments(attachments_file)

            if database_file.suffix == ".sqlite3":
                restored = tmp / "restored.sqlite3"
                shutil.copy2(database_file, restored)
                engine = create_engine(f"sqlite:///{restored}")
                try:
                    try:
                        with engine.connect() as connection:
                            integrity = connection.execute(text("PRAGMA integrity_check")).scalar()
                    except DatabaseError as exc:
                        raise RuntimeError("Banco restaurado ilegível.") from exc
                    if integrity != "ok":
                        raise RuntimeError("Integridade do banco restaurado inválida.")
                    tables = inspect(engine).get_table_names()
                    if not tables:
                        raise RuntimeError("Banco restaurado sem tabelas.")
                finally:
                    engine.dispose()
                return {
                    "engine": "sqlite",
                    "tables": len(tables),
                    "attachments": attachments,
                    "verified": True,
                }

            result = self._verify_postgres_restore(database_file)
            result["attachments"] = attachments
            return result

    def _verify_attachments(self, archive_path: Path) -> int:
        count = 0
        with tarfile.open(archive_path, "r:gz") as archive:
            for member in archive:
                path = PurePosixPath(member.name)
                if path.is_absolute() or ".." in path.parts or "\\" in member.name:
                    raise RuntimeError("Caminho de anexo inválido no backup.")
                if not member.isfile():
                    if member.isdir():
                        continue
                    raise RuntimeError("Anexo com tipo inválido no backup.")
                handle = archive.extractfile(member)
                if handle is None:
                    raise RuntimeError("Anexo ilegível no backup.")
                with handle:
                    for _chunk in iter(lambda: handle.read(1024 * 1024), b""):
                        pass
                count += 1
        return count

    def _create_database_backup(
        self,
        target_dir: Path,
        timestamp: str,
    ) -> Path:
        url = settings.atlas_database_url
        if url.startswith("sqlite"):
            source = self._sqlite_path(url)
            target = target_dir / f"atlas_{timestamp}.sqlite3"
            if not source.exists():
                raise RuntimeError(f"Banco SQLite não encontrado: {source}")
            # A API online inclui páginas ainda no WAL sem interromper escritas.
            with closing(sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True)) as origin:
                with closing(sqlite3.connect(target)) as snapshot:
                    origin.backup(snapshot)
            return target

        target = target_dir / f"atlas_{timestamp}.dump"
        self._pg_dump(url, target)
        return target

    def _archive_attachments(self, target: Path) -> None:
        root = settings.attachment_dir
        root.mkdir(parents=True, exist_ok=True)
        with tarfile.open(target, "w:gz") as archive:
            for path in root.rglob("*"):
                if path.is_file():
                    archive.add(path, arcname=str(path.relative_to(root)))

    def _extract_bundle(self, bundle: Path, target: Path) -> None:
        if bundle.suffix != ".atlasbackup":
            raise RuntimeError("Formato de backup não suportado para restore.")
        with tarfile.open(bundle, "r:gz") as archive:
            for member in archive.getmembers():
                destination = (target / member.name).resolve()
                destination.relative_to(target.resolve())
            # Python 3.14 changes tar extraction defaults.  Be explicit and
            # retain the path-containment check above so restore remains both
            # warning-free and protected against unsafe archive members.
            archive.extractall(target, filter="data")

    def _verify_postgres_restore(self, dump_file: Path) -> dict:
        parsed = self._postgres_url(settings.atlas_database_url)
        temp_database = (
            f"atlas_restore_verify_"
            f"{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S%f')}"
        )

        env = self._pg_env(parsed)
        common = [
            "--host", parsed.host or "localhost",
            "--port", str(parsed.port or 5432),
            "--username", parsed.username or "postgres",
        ]

        subprocess.run(
            ["createdb", *common, temp_database],
            check=True,
            env=env,
            capture_output=True,
            text=True,
        )

        try:
            subprocess.run(
                [
                    "pg_restore",
                    *common,
                    "--dbname",
                    temp_database,
                    "--no-owner",
                    "--no-privileges",
                    str(dump_file),
                ],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )

            engine = create_engine(
                parsed.set(database=temp_database), pool_pre_ping=True,
            )
            try:
                with engine.connect() as connection:
                    connection.execute(text("SELECT 1"))
                tables = inspect(engine).get_table_names()
                if not tables:
                    raise RuntimeError(
                        "Restore PostgreSQL abriu, mas não restaurou tabelas."
                    )
            finally:
                engine.dispose()

            return {
                "engine": "postgresql",
                "database": temp_database,
                "tables": len(tables),
                "verified": True,
            }
        finally:
            try:
                subprocess.run(
                    ["dropdb", *common, "--if-exists", temp_database],
                    check=True,
                    env=env,
                    capture_output=True,
                    text=True,
                )
            except (subprocess.CalledProcessError, OSError) as exc:
                raise RuntimeError(
                    "Não foi possível confirmar a remoção do banco temporário "
                    f"{temp_database}; revisão operacional necessária."
                ) from exc

    def _sqlite_path(self, url: str) -> Path:
        return Path(url.removeprefix("sqlite:///"))

    def _postgres_url(self, database_url: str):
        parsed = make_url(database_url)
        if (
            parsed.drivername != "postgresql+psycopg"
            or not parsed.host
            or not parsed.username
            or not parsed.database
        ):
            raise RuntimeError("Destino PostgreSQL do backup incompleto.")
        return parsed

    def _pg_env(self, parsed) -> dict[str, str]:
        env = os.environ.copy()
        if parsed.password:
            env["PGPASSWORD"] = parsed.password
        return env

    def _pg_dump(self, database_url: str, target: Path) -> None:
        parsed = self._postgres_url(database_url)
        env = self._pg_env(parsed)

        subprocess.run(
            [
                "pg_dump",
                "--format=custom",
                "--file",
                str(target),
                "--host",
                parsed.host or "localhost",
                "--port",
                str(parsed.port or 5432),
                "--username",
                parsed.username or "postgres",
                parsed.database,
            ],
            check=True,
            env=env,
            capture_output=True,
            text=True,
        )

    def _sha256(self, path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()
