import unittest

from scripts.quality.check_postgres_ci_contract import validate_ci_target


URL = (
    "postgresql+psycopg://atlas_ci_probe:ci-password@127.0.0.1:5432/atlas_ci_probe"
)


class PostgresCiGuardTest(unittest.TestCase):
    def test_only_ci_test_database_is_accepted(self):
        validate_ci_target(URL, actions="true", environment="test")

    def test_other_targets_are_rejected(self):
        cases = [
            (URL, "", "test"),
            (URL, "true", "production"),
            (URL.replace("127.0.0.1", "db.example.com"), "true", "test"),
            (URL.replace(":5432", ":5433"), "true", "test"),
            (URL.replace("atlas_ci_probe", "atlas_prod", 1), "true", "test"),
            (URL.replace("/atlas_ci_probe", "/atlas_prod"), "true", "test"),
            (URL + "?host=db.example.com", "true", "test"),
            ("", "true", "test"),
            ("sqlite:///./atlas_test.db", "true", "test"),
        ]
        for url, actions, environment in cases:
            with self.subTest(url=url, actions=actions, environment=environment):
                with self.assertRaisesRegex(ValueError, "PostgreSQL descartável"):
                    validate_ci_target(url, actions=actions, environment=environment)


if __name__ == "__main__":
    unittest.main()
