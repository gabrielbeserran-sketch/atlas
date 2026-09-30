"""Reject a wrong-column 0059 index in the disposable CI PostgreSQL only.

DDL is rolled back so the existing CI schema remains unchanged. The target guard
must run before a database connection is opened.
"""

from __future__ import annotations

import os

from sqlalchemy import text

from scripts.quality.check_postgres_ci_contract import validate_ci_target
from scripts.quality.report_postgres_migration_readiness import (
    REVISION_AFTER,
    read_report,
    validate_expected_state,
)


def main() -> None:
    validate_ci_target(
        os.environ.get("ATLAS_DATABASE_URL", ""),
        actions=os.environ.get("GITHUB_ACTIONS", ""),
        environment=os.environ.get("ATLAS_ENV", ""),
    )
    from app.database import build_engine

    engine = build_engine(for_migrations=True)
    try:
        with engine.connect() as connection:
            with connection.begin() as transaction:
                validate_expected_state(read_report(connection), REVISION_AFTER)
                connection.execute(text(
                    "DROP INDEX public.ix_pasture_grazing_scope_created_id"
                ))
                connection.execute(text(
                    "CREATE INDEX ix_pasture_grazing_scope_created_id "
                    "ON public.pasture_grazing_bases "
                    "(tenant_id, company_id, farm_id, id, created_at)"
                ))
                drifted = read_report(connection)
                assert drifted.index_exists and drifted.index_valid
                assert not drifted.index_matches_contract
                try:
                    validate_expected_state(drifted, REVISION_AFTER)
                except ValueError:
                    pass
                else:
                    raise AssertionError("Relatório aceitou índice com ordem incorreta.")
                transaction.rollback()
            with connection.begin():
                validate_expected_state(read_report(connection), REVISION_AFTER)
    finally:
        engine.dispose()
    print("PostgreSQL CI: índice divergente recusado e esquema original preservado.")


if __name__ == "__main__":
    main()
