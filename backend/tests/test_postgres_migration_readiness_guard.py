import unittest

from scripts.quality.report_postgres_migration_readiness import (
    REVISION_AFTER,
    REVISION_BEFORE,
    ReadinessReport,
    validate_expected_state,
)


class ReadinessGuardTest(unittest.TestCase):
    def test_valid_before_and_after_states(self):
        validate_expected_state(ReadinessReport(REVISION_BEFORE, 100, None, False, False), REVISION_BEFORE)
        validate_expected_state(ReadinessReport(REVISION_AFTER, 100, 1000, True, True), REVISION_AFTER)

    def test_mismatch_or_invalid_index_fails_closed(self):
        cases = [
            (ReadinessReport(REVISION_BEFORE, 100, 1000, False, False), REVISION_AFTER),
            (ReadinessReport(REVISION_BEFORE, 100, 1000, True, True), REVISION_BEFORE),
            (ReadinessReport(REVISION_AFTER, 100, 1000, False, False), REVISION_AFTER),
            (ReadinessReport(REVISION_AFTER, 100, 1000, True, False), REVISION_AFTER),
        ]
        for report, expected in cases:
            with self.subTest(report=report, expected=expected):
                with self.assertRaises(ValueError):
                    validate_expected_state(report, expected)


if __name__ == "__main__":
    unittest.main()
