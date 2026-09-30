"""The restore proof must refuse non-CI targets before creating a backup."""

import os
import unittest
from unittest.mock import patch

from scripts.quality.check_postgres_backup_restore_ci import main


class PostgresBackupRestoreCiGuardTest(unittest.TestCase):
    def test_rejects_non_ci_host_without_starting_backup(self):
        with (
            patch.dict(os.environ, {
                "GITHUB_ACTIONS": "true",
                "ATLAS_ENV": "test",
                "ATLAS_DATABASE_URL": (
                    "postgresql+psycopg://atlas_ci_probe:password@db.example.com:5432/atlas_ci_probe"
                ),
            }),
            patch("scripts.quality.check_postgres_backup_restore_ci.BackupService") as backup,
        ):
            with self.assertRaisesRegex(ValueError, "PostgreSQL descartável"):
                main()
            backup.assert_not_called()

    def test_rejects_local_run_without_starting_backup(self):
        with (
            patch.dict(os.environ, {
                "GITHUB_ACTIONS": "",
                "ATLAS_ENV": "test",
                "ATLAS_DATABASE_URL": (
                    "postgresql+psycopg://atlas_ci_probe:password@127.0.0.1:5432/atlas_ci_probe"
                ),
            }),
            patch("scripts.quality.check_postgres_backup_restore_ci.BackupService") as backup,
        ):
            with self.assertRaisesRegex(ValueError, "PostgreSQL descartável"):
                main()
            backup.assert_not_called()


if __name__ == "__main__":
    unittest.main()
