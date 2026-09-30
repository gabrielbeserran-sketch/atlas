"""Read-only migration facts for a human release decision.

Usage: python -m scripts.quality.report_postgres_migration_readiness
       --readonly --expect-revision 20260929_0058

Never migrates, creates an index, exports rows, or prints a connection URL.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass

from sqlalchemy import text


REVISION_BEFORE = "20260929_0058"
REVISION_AFTER = "20260929_0059"


@dataclass(frozen=True)
class ReadinessReport:
    revision: str
    table_bytes: int | None
    estimated_rows: int | None
    index_exists: bool
    index_valid: bool
    index_matches_contract: bool


def validate_expected_state(report: ReadinessReport, expected: str) -> None:
    if expected not in {REVISION_BEFORE, REVISION_AFTER}:
        raise ValueError("Revisão esperada não permitida para esta prova.")
    if report.revision != expected:
        raise ValueError("Revisão encontrada difere da esperada.")
    if report.index_exists != (expected == REVISION_AFTER):
        raise ValueError("Presença do índice não corresponde à revisão.")
    if report.index_exists and not report.index_valid:
        raise ValueError("Índice 0059 ainda não está válido/pronto.")
    if report.index_exists and not report.index_matches_contract:
        raise ValueError("Definição do índice 0059 difere do contrato esperado.")


def read_report(connection) -> ReadinessReport:
    """Call only inside a PostgreSQL READ ONLY transaction with timeouts."""
    revision = connection.scalar(text("SELECT version_num FROM alembic_version"))
    table_bytes, estimated_rows = connection.execute(text("""
        SELECT pg_total_relation_size(c.oid), c.reltuples::bigint
        FROM pg_class c
        WHERE c.oid = to_regclass('public.pasture_grazing_bases')
    """)).one()
    index_state = connection.execute(text("""
        SELECT i.indisvalid, i.indisready,
               i.indnkeyatts = 5 AND i.indnatts = 5
               AND i.indexprs IS NULL AND i.indpred IS NULL
               AND NOT i.indisunique AND am.amname = 'btree'
               AND (
                   SELECT array_agg(att.attname::text ORDER BY keys.ordinality)
                   FROM unnest(i.indkey) WITH ORDINALITY AS keys(attnum, ordinality)
                   JOIN pg_attribute att
                     ON att.attrelid = i.indrelid AND att.attnum = keys.attnum
               ) = ARRAY['tenant_id', 'company_id', 'farm_id', 'created_at', 'id']::text[]
        FROM pg_index i
        JOIN pg_class idx ON idx.oid = i.indexrelid
        JOIN pg_am am ON am.oid = idx.relam
        WHERE i.indrelid = to_regclass('public.pasture_grazing_bases')
          AND i.indexrelid = to_regclass('public.ix_pasture_grazing_scope_created_id')
    """)).one_or_none()
    return ReadinessReport(
        revision=revision,
        table_bytes=table_bytes,
        estimated_rows=estimated_rows if estimated_rows is not None and estimated_rows >= 0 else None,
        index_exists=index_state is not None,
        index_valid=bool(index_state[0] and index_state[1]) if index_state else False,
        index_matches_contract=bool(index_state[2]) if index_state else False,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Relatório somente de leitura da migração 0059")
    parser.add_argument("--readonly", action="store_true", required=True)
    parser.add_argument("--expect-revision", choices=[REVISION_BEFORE, REVISION_AFTER], required=True)
    args = parser.parse_args()
    if not args.readonly:
        return 2

    engine = None
    try:
        from app.database import build_engine

        engine = build_engine(for_migrations=True)
        if engine.dialect.name != "postgresql":
            raise ValueError("Relatório exige PostgreSQL.")
        with engine.connect() as connection:
            with connection.begin():
                connection.execute(text("SET TRANSACTION READ ONLY"))
                connection.execute(text("SET LOCAL statement_timeout = '5s'"))
                connection.execute(text("SET LOCAL lock_timeout = '1s'"))
                report = read_report(connection)
                validate_expected_state(report, args.expect_revision)
        print(json.dumps(asdict(report), sort_keys=True))
        return 0
    except Exception as exc:
        # Never print a driver exception: it may contain credentials/hostnames.
        print(f"ATLAS READINESS: falhou ({type(exc).__name__}).", file=sys.stderr)
        return 1
    finally:
        if engine is not None:
            engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
