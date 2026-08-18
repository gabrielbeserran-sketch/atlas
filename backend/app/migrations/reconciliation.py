from __future__ import annotations

from contextlib import contextmanager
from typing import Any, Iterator

import sqlalchemy as sa
from alembic import op


def _inspector() -> sa.Inspector:
    return sa.inspect(op.get_bind())


def _table_exists(table_name: str, *, schema: str | None = None) -> bool:
    return _inspector().has_table(table_name, schema=schema)


def _column_exists(
    table_name: str,
    column_name: str,
    *,
    schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=schema):
        return False

    return column_name in {
        column["name"]
        for column in _inspector().get_columns(table_name, schema=schema)
    }


def _index_exists(
    table_name: str,
    index_name: str,
    *,
    schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=schema):
        return False

    names = {
        index["name"]
        for index in _inspector().get_indexes(table_name, schema=schema)
        if index.get("name")
    }
    return index_name in names


def _unique_constraint_exists(
    table_name: str,
    constraint_name: str | None,
    columns: list[str] | tuple[str, ...] | None,
    *,
    schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=schema):
        return False

    requested_columns = tuple(columns or ())
    for constraint in _inspector().get_unique_constraints(
        table_name,
        schema=schema,
    ):
        current_name = constraint.get("name")
        current_columns = tuple(constraint.get("column_names") or ())
        if constraint_name and current_name == constraint_name:
            return True
        if requested_columns and current_columns == requested_columns:
            return True
    return False


def _reflect_existing_table(
    table_name: str,
    *,
    schema: str | None = None,
) -> sa.Table:
    metadata = sa.MetaData()
    return sa.Table(
        table_name,
        metadata,
        schema=schema,
        autoload_with=op.get_bind(),
    )


@contextmanager
def install_reconciliation_guards() -> Iterator[None]:
    """Torna migrations históricas seguras em bancos já parcialmente criados.

    O Atlas passou por fases em que tabelas podiam existir antes de o histórico
    Alembic estar completamente reconciliado. Em produção, repetir
    ``CREATE TABLE``/``CREATE INDEX``/``ADD COLUMN`` não deve derrubar o
    startup quando o objeto equivalente já existe.

    Os guards só ignoram operações quando o objeto alvo já existe. Objetos
    ausentes continuam sendo criados normalmente. Após as migrations, o
    contrato de schema do startup verifica tabelas/colunas do ORM para impedir
    que uma reconciliação silencie um schema incompleto.
    """

    original_create_table = op.create_table
    original_create_index = op.create_index
    original_add_column = op.add_column
    original_create_unique_constraint = op.create_unique_constraint

    def safe_create_table(
        table_name: str,
        *columns: Any,
        **kwargs: Any,
    ) -> sa.Table:
        schema = kwargs.get("schema")
        if _table_exists(table_name, schema=schema):
            print(
                "ATLAS ALEMBIC RECONCILE: "
                f"tabela existente preservada: {table_name}"
            )
            return _reflect_existing_table(table_name, schema=schema)

        return original_create_table(table_name, *columns, **kwargs)

    def safe_create_index(
        index_name: str,
        table_name: str,
        columns: Any,
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        schema = kwargs.get("schema")
        if _index_exists(table_name, index_name, schema=schema):
            print(
                "ATLAS ALEMBIC RECONCILE: "
                f"índice existente preservado: {index_name}"
            )
            return None

        return original_create_index(
            index_name,
            table_name,
            columns,
            *args,
            **kwargs,
        )

    def safe_add_column(
        table_name: str,
        column: sa.Column[Any],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        schema = kwargs.get("schema")
        if _column_exists(table_name, column.name, schema=schema):
            print(
                "ATLAS ALEMBIC RECONCILE: "
                f"coluna existente preservada: {table_name}.{column.name}"
            )
            return None

        return original_add_column(table_name, column, *args, **kwargs)

    def safe_create_unique_constraint(
        constraint_name: str | None,
        table_name: str,
        columns: list[str] | tuple[str, ...],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        schema = kwargs.get("schema")
        if _unique_constraint_exists(
            table_name,
            constraint_name,
            columns,
            schema=schema,
        ):
            label = constraint_name or f"{table_name}{tuple(columns)}"
            print(
                "ATLAS ALEMBIC RECONCILE: "
                f"unique existente preservada: {label}"
            )
            return None

        return original_create_unique_constraint(
            constraint_name,
            table_name,
            columns,
            *args,
            **kwargs,
        )

    op.create_table = safe_create_table
    op.create_index = safe_create_index
    op.add_column = safe_add_column
    op.create_unique_constraint = safe_create_unique_constraint

    try:
        yield
    finally:
        op.create_table = original_create_table
        op.create_index = original_create_index
        op.add_column = original_add_column
        op.create_unique_constraint = original_create_unique_constraint
