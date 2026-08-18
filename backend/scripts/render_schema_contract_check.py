from __future__ import annotations

import sys

import sqlalchemy as sa

from app import models  # noqa: F401
from app.database import Base, build_engine


def _normalized_type(value: sa.types.TypeEngine) -> str:
    return value.__class__.__name__.lower()


def _compatible_type(model_type: str, database_type: str) -> bool:
    if model_type == database_type:
        return True

    compatible_groups = (
        {"string", "varchar", "text"},
        {"integer", "biginteger", "smallinteger"},
        {"json", "jsonb"},
        {"datetime", "timestamp", "datetimetz"},
        {"boolean", "bool"},
        {"float", "real", "double", "numeric", "decimal"},
    )
    return any(
        {model_type, database_type} <= group
        for group in compatible_groups
    )


def main() -> int:
    engine = build_engine(for_migrations=True)

    errors: list[str] = []
    warnings: list[str] = []

    try:
        inspector = sa.inspect(engine)
        database_tables = set(inspector.get_table_names())
        model_tables = set(Base.metadata.tables.keys())

        for table_name in sorted(model_tables - database_tables):
            errors.append(f"tabela ausente: {table_name}")

        for table_name in sorted(database_tables - model_tables):
            if table_name != "alembic_version":
                warnings.append(f"tabela extra no banco: {table_name}")

        for table_name in sorted(model_tables & database_tables):
            model_table = Base.metadata.tables[table_name]

            database_columns = {
                column["name"]: column
                for column in inspector.get_columns(table_name)
            }
            model_columns = {
                column.name: column
                for column in model_table.columns
            }

            for column_name in sorted(
                set(model_columns) - set(database_columns)
            ):
                errors.append(
                    f"coluna ausente: {table_name}.{column_name}"
                )

            for column_name in sorted(
                set(database_columns) - set(model_columns)
            ):
                warnings.append(
                    f"coluna extra no banco: {table_name}.{column_name}"
                )

            for column_name in sorted(
                set(model_columns) & set(database_columns)
            ):
                model_type = _normalized_type(
                    model_columns[column_name].type
                )
                database_type = _normalized_type(
                    database_columns[column_name]["type"]
                )

                if not _compatible_type(model_type, database_type):
                    warnings.append(
                        "tipo divergente: "
                        f"{table_name}.{column_name} "
                        f"modelo={model_type} banco={database_type}"
                    )

        if errors:
            print("ATLAS SCHEMA CONTRACT: FAIL", file=sys.stderr)
            for error in errors:
                print(f" - {error}", file=sys.stderr)

            if warnings:
                print("ATLAS SCHEMA CONTRACT: avisos:", file=sys.stderr)
                for warning in warnings[:100]:
                    print(f" - {warning}", file=sys.stderr)

            return 1

        print(
            "ATLAS SCHEMA CONTRACT: APROVADO "
            f"(model_tables={len(model_tables)}, "
            f"database_tables={len(database_tables)}, "
            f"warnings={len(warnings)})"
        )

        for warning in warnings[:50]:
            print(f"ATLAS SCHEMA CONTRACT: WARN - {warning}")

        return 0
    finally:
        engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
