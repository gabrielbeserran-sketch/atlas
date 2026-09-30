"""The authenticated HTTP proof must refuse execution outside disposable CI."""

import os
import unittest
from unittest.mock import patch

from scripts.quality.check_postgres_grazing_http_ci import main


class GrazingHttpCiGuardTest(unittest.TestCase):
    def test_local_run_is_rejected_before_database_import(self):
        with patch.dict(os.environ, {
            "ATLAS_ENV": "test",
            "GITHUB_ACTIONS": "",
            "ATLAS_DATABASE_URL": (
                "postgresql+psycopg://atlas_ci_probe:password@127.0.0.1:5432/atlas_ci_probe"
            ),
        }):
            with self.assertRaisesRegex(ValueError, "PostgreSQL descartável"):
                main()

    def test_external_host_is_rejected(self):
        with patch.dict(os.environ, {
            "ATLAS_ENV": "test",
            "GITHUB_ACTIONS": "true",
            "ATLAS_DATABASE_URL": (
                "postgresql+psycopg://atlas_ci_probe:password@db.example.com:5432/atlas_ci_probe"
            ),
        }):
            with self.assertRaisesRegex(ValueError, "PostgreSQL descartável"):
                main()


if __name__ == "__main__":
    unittest.main()
