"""Regressão isolada do histórico Alembic sem usar o banco de testes do app.

Execute diretamente com ``.venv/Scripts/python tests/test_alembic_empty_bootstrap.py``.
Não depende de pytest/conftest.py, que usa atlas_test.db.
"""

from __future__ import annotations

import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from contextlib import closing
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]


class EmptyDatabaseBootstrapTest(unittest.TestCase):
    def test_sqlite_onboarding_keeps_legacy_state_and_expands_farms(self) -> None:
        with tempfile.TemporaryDirectory(prefix="atlas-onboarding-") as temp_dir:
            database_path = Path(temp_dir) / "legacy.db"
            env = os.environ.copy()
            env["ATLAS_DATABASE_URL"] = f"sqlite:///{database_path.as_posix()}"

            def upgrade(revision: str) -> None:
                result = subprocess.run(
                    [sys.executable, "-m", "alembic", "upgrade", revision],
                    cwd=BACKEND_DIR, env=env, capture_output=True, text=True,
                    timeout=90, check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr[-3000:])

            upgrade("20260824_0045")
            with closing(sqlite3.connect(database_path)) as connection:
                for company_id in ("company-a", "company-b"):
                    connection.execute(
                        "INSERT INTO companies "
                        "(id, tenant_id, name, document, status, subscription_plan, created_at) "
                        "VALUES (?, ?, ?, '', 'active', 'enterprise', '2026-09-25')",
                        (company_id, company_id, company_id),
                    )
                for farm_id in ("farm-1", "farm-2"):
                    connection.execute(
                        "INSERT INTO farms "
                        "(id, tenant_id, company_id, name, city, state, animals, area, "
                        "active, created_at, updated_at) "
                        "VALUES (?, 'company-a', 'company-a', ?, '', '', 0, 0, "
                        "1, '2026-09-25', '2026-09-25')",
                        (farm_id, farm_id),
                    )
                for company_id in ("company-a", "company-b"):
                    connection.execute(
                        "INSERT INTO onboarding_progress "
                        "(id, tenant_id, company_id, steps_json, completion_percent, completed_at) "
                        "VALUES (?, ?, ?, ?, 20, NULL)",
                        (f"onboarding-{company_id}", company_id, company_id,
                         '{"initial_training":true}'),
                    )
                connection.commit()

            upgrade("20260824_0046")
            with closing(sqlite3.connect(database_path)) as connection:
                rows = connection.execute(
                    "SELECT company_id, farm_id, steps_json FROM onboarding_progress "
                    "ORDER BY company_id, farm_id"
                ).fetchall()
                self.assertEqual(len(rows), 3)
                self.assertEqual({row[1] for row in rows if row[0] == "company-a"},
                                 {"farm-1", "farm-2"})
                self.assertEqual([row[1] for row in rows if row[0] == "company-b"],
                                 [None])
                self.assertTrue(all('"initial_training":true' in row[2] for row in rows))

    def test_upgrade_head_from_empty_sqlite_is_repeatable(self) -> None:
        with tempfile.TemporaryDirectory(prefix="atlas-alembic-") as temp_dir:
            database_path = Path(temp_dir) / "fresh.db"
            env = os.environ.copy()
            env["ATLAS_DATABASE_URL"] = f"sqlite:///{database_path.as_posix()}"

            for attempt in (1, 2):
                result = subprocess.run(
                    [sys.executable, "-m", "alembic", "upgrade", "head"],
                    cwd=BACKEND_DIR,
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=90,
                    check=False,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"Alembic falhou na execução {attempt}:\n"
                    f"{result.stdout[-3000:]}\n{result.stderr[-3000:]}",
                )

            with closing(sqlite3.connect(database_path)) as connection:
                version = connection.execute(
                    "SELECT version_num FROM alembic_version"
                ).fetchone()
                self.assertEqual(version, ("20260923_0056",))

                tables = {
                    row[0]
                    for row in connection.execute(
                        "SELECT name FROM sqlite_master WHERE type = 'table'"
                    )
                }
                self.assertTrue(
                    {"companies", "farms", "weight_records", "onboarding_progress",
                     "operational_note_folders"}.issubset(tables)
                )

                farm_columns = {
                    row[1] for row in connection.execute("PRAGMA table_info(farms)")
                }
                self.assertTrue(
                    {"production_profile", "production_system"}.issubset(farm_columns)
                )
                weight_columns = {
                    row[1]
                    for row in connection.execute("PRAGMA table_info(weight_records)")
                }
                self.assertIn("client_operation_id", weight_columns)

                unique_indexes = [
                    row[1]
                    for row in connection.execute("PRAGMA index_list(weight_records)")
                    if row[2]
                ]
                indexed_columns = [
                    tuple(
                        row[2]
                        for row in connection.execute(f'PRAGMA index_info("{name}")')
                    )
                    for name in unique_indexes
                ]
                self.assertIn(
                    ("company_id", "client_operation_id"), indexed_columns
                )


if __name__ == "__main__":
    unittest.main()
