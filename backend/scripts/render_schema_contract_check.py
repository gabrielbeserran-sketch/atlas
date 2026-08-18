from __future__ import annotations

import sys
from collections import defaultdict

import sqlalchemy as sa

from app import models  # noqa: F401
from app.database import Base, build_engine


def _normalized_type(value: sa.types.TypeEngine) -> str:
    return value.__class__.__name__.lower()


def main() -> int:
    engine = build_engine(for_migrations=True)
    errors: list[str] = []
    warnings: list[str] = []

    try:
        inspector = sa.inspect(engine)
        database_tables = set(inspector.get_table_names())
        model_tables = set(Base.metadata.tables.keys())

        missing_tables = sorted(model_tables - database_tables)
        for table_name in missing_tables:
            errors.append(f"tabela ausente: {table_name}")

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
                set(model_columns) & set(database_columns)
            ):
                model_column = model_columns[column_name]
                database_column = database_columns[column_name]

                # Tipos podem variar em representação entre SQLAlchemy e
                # PostgreSQL; diferenças são avisos para não bloquear produção
                # por aliases equivalentes (VARCHAR/String, JSON/JSONB etc.).
                model_type = _normalized_type(model_column.type)
                database_type = _normalized_type(database_column["type"])

                compatible = (
                    model_type == database_type
                    or {model_type, database_type}
                    <= {"string", "varchar", "text"}
                    or {model_type, database_type}
                    <= {"integer", "biginteger", "smallinteger"}
                    or {model_type, database_type}
                    <= {"json", "jsonb"}
                    or {model_type, database_type}
                    <= {"datetime", "timestamp"}
                )

                if not compatible:
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
                for warning in warnings[:50]:
                    print(f" - {warning}", file=sys.stderr)
            return 1

        print(
            "ATLAS SCHEMA CONTRACT: APROVADO "
            f"(model_tables={len(model_tables)}, "
            f"database_tables={len(database_tables)})"
        )

        if warnings:
            print(
                "ATLAS SCHEMA CONTRACT: "
                f"{len(warnings)} aviso(s) de tipo não bloqueante"
            )
            for warning in warnings[:20]:
                print(f" - {warning}")

        return 0
    finally:
        engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
