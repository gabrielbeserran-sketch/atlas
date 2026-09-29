"""Executar diretamente: nunca usa o fixture pytest/atlas_test.db."""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]


class MigratedSchemaContractTest(unittest.TestCase):
    def test_fresh_upgrade_matches_app_models(self) -> None:
        with tempfile.TemporaryDirectory(prefix="atlas-schema-disposable-") as raw:
            database = Path(raw) / "schema.sqlite3"
            environment = os.environ.copy()
            environment["ATLAS_DATABASE_URL"] = f"sqlite:///{database.as_posix()}"

            def run(*command: str) -> None:
                result = subprocess.run(
                    [sys.executable, *command], cwd=BACKEND_DIR,
                    env=environment, capture_output=True, text=True,
                    timeout=180, check=False,
                )
                self.assertEqual(
                    result.returncode, 0,
                    f"{' '.join(command)} falhou:\n"
                    f"{result.stdout[-5000:]}\n{result.stderr[-5000:]}",
                )

            run("-m", "alembic", "upgrade", "head")
            run("-m", "scripts.render_post_migration_check")
            run("-m", "scripts.render_schema_contract_check")


if __name__ == "__main__":
    unittest.main()
