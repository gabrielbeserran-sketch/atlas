"""Reconcilia schema local antigo com modelos + Alembic.

Somente development/test.

Fluxo:
1. cria tabelas ausentes;
2. adiciona, de forma aditiva, colunas ausentes em tabelas existentes;
3. verifica novamente todas as tabelas/colunas esperadas pelos modelos;
4. somente após a verificação bem-sucedida marca o banco no head Alembic.

Staging/production continuam usando somente `alembic upgrade`.
"""
from __future__ import annotations

from pathlib import Path
import sys

from alembic import command
from alembic.config import Config
from sqlalchemy import inspect

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in sys.path:
    sys.path.insert(0, str(BACKEND))

from app import models  # noqa: F401,E402
from app.config import get_settings  # noqa: E402
from app.database import (  # noqa: E402
    Base,
    engine,
    ensure_development_schema_compatibility,
)


def _verify_schema() -> list[str]:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    problems: list[str] = []

    for table_name, table in Base.metadata.tables.items():
        if table_name not in existing_tables:
            problems.append(f"tabela ausente: {table_name}")
            continue

        existing_columns = {
            item["name"]
            for item in inspector.get_columns(table_name)
        }
        for column in table.columns:
            if column.name not in existing_columns:
                problems.append(
                    f"coluna ausente: {table_name}.{column.name}"
                )

    return problems


def _alembic_config(database_url: str) -> Config:
    cfg = Config(str(BACKEND / "alembic.ini"))
    cfg.set_main_option(
        "script_location",
        str(BACKEND / "alembic"),
    )
    cfg.set_main_option("sqlalchemy.url", database_url)
    return cfg


def main() -> int:
    settings = get_settings()

    if settings.atlas_env not in {"development", "test"}:
        print(
            "RECUSADO: reconcile_local_alembic só pode rodar "
            "em development/test."
        )
        return 2

    Base.metadata.create_all(bind=engine)

    try:
        repaired = ensure_development_schema_compatibility()
    except Exception as exc:
        print(
            "FALHA: reparo aditivo do schema local não pôde ser concluído: "
            f"{exc}"
        )
        return 1

    if repaired:
        print(
            f"REPARO LOCAL: {len(repaired)} coluna(s) adicionada(s) "
            "sem apagar dados."
        )
        for item in repaired:
            print(f" + {item}")
    else:
        print("REPARO LOCAL: nenhuma coluna ausente.")

    remaining = _verify_schema()
    if remaining:
        print(
            "FALHA: após o reparo ainda existem divergências "
            "estruturais:"
        )
        for item in remaining[:200]:
            print(f" - {item}")
        if len(remaining) > 200:
            print(
                f" - ... e mais {len(remaining) - 200} pendências"
            )
        return 1

    command.stamp(
        _alembic_config(settings.atlas_database_url),
        "head",
        purge=True,
    )

    print("OK: schema local compatível com os modelos Atlas.")
    print("OK: histórico Alembic reconciliado com o head atual.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
