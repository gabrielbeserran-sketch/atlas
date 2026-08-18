from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Callable, Iterable, Iterator, Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.sql.elements import ColumnElement


class UnsafeSchemaReconciliation(RuntimeError):
    """Divergência de schema que não pode ser corrigida sem risco de dados."""


@dataclass(frozen=True)
class MissingColumnPlan:
    table_name: str
    column: sa.Column[Any]
    schema: str | None
    existing_rows: int


def _bind() -> sa.engine.Connection:
    return op.get_bind()


def _inspector() -> sa.Inspector:
    return sa.inspect(_bind())


def _qualified(table_name: str, schema: str | None = None) -> str:
    return f"{schema}.{table_name}" if schema else table_name


def _table_exists(table_name: str, *, schema: str | None = None) -> bool:
    return _inspector().has_table(table_name, schema=schema)


def _table_columns(
    table_name: str,
    *,
    schema: str | None = None,
) -> dict[str, dict[str, Any]]:
    if not _table_exists(table_name, schema=schema):
        return {}

    return {
        column["name"]: column
        for column in _inspector().get_columns(table_name, schema=schema)
    }


def _column_exists(
    table_name: str,
    column_name: str,
    *,
    schema: str | None = None,
) -> bool:
    return column_name in _table_columns(table_name, schema=schema)


def _table_row_count(
    table_name: str,
    *,
    schema: str | None = None,
) -> int:
    preparer = _bind().dialect.identifier_preparer
    quoted_table = preparer.quote(table_name)

    if schema:
        quoted_schema = preparer.quote_schema(schema)
        target = f"{quoted_schema}.{quoted_table}"
    else:
        target = quoted_table

    return int(
        _bind()
        .execute(sa.text(f"SELECT COUNT(*) FROM {target}"))
        .scalar_one()
    )


def _index_exists(
    table_name: str,
    index_name: str,
    *,
    schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=schema):
        return False

    return index_name in {
        index["name"]
        for index in _inspector().get_indexes(table_name, schema=schema)
        if index.get("name")
    }


def _unique_constraint_exists(
    table_name: str,
    constraint_name: str | None,
    columns: Sequence[str],
    *,
    schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=schema):
        return False

    requested = tuple(columns)
    for constraint in _inspector().get_unique_constraints(
        table_name,
        schema=schema,
    ):
        if constraint_name and constraint.get("name") == constraint_name:
            return True
        if tuple(constraint.get("column_names") or ()) == requested:
            return True

    return False


def _foreign_key_exists(
    table_name: str,
    constraint_name: str | None,
    local_columns: Sequence[str],
    remote_table: str,
    remote_columns: Sequence[str],
    *,
    source_schema: str | None = None,
    referent_schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=source_schema):
        return False

    local_tuple = tuple(local_columns)
    remote_tuple = tuple(remote_columns)

    for fk in _inspector().get_foreign_keys(
        table_name,
        schema=source_schema,
    ):
        if constraint_name and fk.get("name") == constraint_name:
            return True

        if (
            tuple(fk.get("constrained_columns") or ()) == local_tuple
            and (fk.get("referred_table") or "") == remote_table
            and tuple(fk.get("referred_columns") or ()) == remote_tuple
            and (fk.get("referred_schema") or None) == referent_schema
        ):
            return True

    return False


def _check_constraint_exists(
    table_name: str,
    constraint_name: str | None,
    *,
    schema: str | None = None,
) -> bool:
    if not constraint_name or not _table_exists(table_name, schema=schema):
        return False

    return constraint_name in {
        constraint["name"]
        for constraint in _inspector().get_check_constraints(
            table_name,
            schema=schema,
        )
        if constraint.get("name")
    }


def _constraint_name_exists(
    table_name: str,
    constraint_name: str,
    *,
    schema: str | None = None,
) -> bool:
    if not _table_exists(table_name, schema=schema):
        return False

    names: set[str | None] = set()

    names.update(
        item.get("name")
        for item in _inspector().get_unique_constraints(
            table_name,
            schema=schema,
        )
    )
    names.update(
        item.get("name")
        for item in _inspector().get_foreign_keys(
            table_name,
            schema=schema,
        )
    )
    names.update(
        item.get("name")
        for item in _inspector().get_check_constraints(
            table_name,
            schema=schema,
        )
    )
    names.add(
        _inspector()
        .get_pk_constraint(table_name, schema=schema)
        .get("name")
    )

    return constraint_name in names


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
        autoload_with=_bind(),
    )


def _column_has_server_value(column: sa.Column[Any]) -> bool:
    return (
        column.server_default is not None
        or column.default is not None
        or column.autoincrement is True
    )


def _copy_column_for_add(column: sa.Column[Any]) -> sa.Column[Any]:
    return sa.Column(
        column.name,
        column.type,
        nullable=column.nullable,
        server_default=column.server_default,
        comment=column.comment,
    )


def _plan_missing_column(
    table_name: str,
    column: sa.Column[Any],
    *,
    schema: str | None = None,
) -> MissingColumnPlan:
    rows = _table_row_count(table_name, schema=schema)

    if (
        rows > 0
        and column.nullable is False
        and not _column_has_server_value(column)
    ):
        raise UnsafeSchemaReconciliation(
            "ATLAS ALEMBIC RECONCILE: coluna obrigatoria ausente nao pode "
            "ser adicionada automaticamente em tabela com dados: "
            f"{_qualified(table_name, schema)}.{column.name} "
            f"(rows={rows}, nullable=False, sem default). "
            "E necessaria migration de backfill explicita."
        )

    return MissingColumnPlan(
        table_name=table_name,
        column=column,
        schema=schema,
        existing_rows=rows,
    )


def _apply_missing_column(
    plan: MissingColumnPlan,
    add_column_fn: Callable[..., Any],
) -> None:
    """Aplica coluna usando a operação ORIGINAL recebida por callback."""
    column = _copy_column_for_add(plan.column)

    if plan.schema is None:
        add_column_fn(plan.table_name, column)
    else:
        add_column_fn(
            plan.table_name,
            column,
            schema=plan.schema,
        )

    print(
        "ATLAS ALEMBIC RECONCILE: coluna ausente criada: "
        f"{_qualified(plan.table_name, plan.schema)}.{column.name} "
        f"(rows_before={plan.existing_rows})"
    )


def _column_names_from_index_spec(
    columns: Iterable[Any],
) -> list[str] | None:
    names: list[str] = []

    for item in columns:
        if isinstance(item, str):
            names.append(item)
            continue

        if isinstance(item, sa.Column):
            names.append(item.name)
            continue

        if isinstance(item, ColumnElement):
            return None

        return None

    return names


def _assert_columns_exist(
    table_name: str,
    columns: Sequence[str],
    *,
    schema: str | None = None,
    operation: str,
) -> None:
    existing = set(_table_columns(table_name, schema=schema))
    missing = [name for name in columns if name not in existing]

    if missing:
        raise UnsafeSchemaReconciliation(
            "ATLAS ALEMBIC RECONCILE: operacao bloqueada porque depende "
            "de coluna(s) ausente(s): "
            f"operation={operation}, "
            f"table={_qualified(table_name, schema)}, "
            f"missing={missing}. "
            "A tabela esta em estado incompativel e exige "
            "reconciliacao/backfill explicito."
        )


def _sync_existing_table_columns(
    table_name: str,
    elements: Sequence[Any],
    *,
    add_column_fn: Callable[..., Any],
    schema: str | None = None,
) -> None:
    existing = set(_table_columns(table_name, schema=schema))

    for element in elements:
        if not isinstance(element, sa.Column):
            continue
        if element.name in existing:
            continue

        plan = _plan_missing_column(
            table_name,
            element,
            schema=schema,
        )
        _apply_missing_column(plan, add_column_fn)
        existing.add(element.name)


class _SafeBatchOperations:
    """Proxy seguro para operações executadas em batch_alter_table()."""

    def __init__(
        self,
        batch_ops: Any,
        table_name: str,
        schema: str | None,
    ) -> None:
        self._ops = batch_ops
        self._table_name = table_name
        self._schema = schema

    def __getattr__(self, name: str) -> Any:
        return getattr(self._ops, name)

    def add_column(
        self,
        column: sa.Column[Any],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        if _column_exists(
            self._table_name,
            column.name,
            schema=self._schema,
        ):
            print(
                "ATLAS ALEMBIC RECONCILE: batch coluna existente preservada: "
                f"{_qualified(self._table_name, self._schema)}.{column.name}"
            )
            return None

        plan = _plan_missing_column(
            self._table_name,
            column,
            schema=self._schema,
        )
        _apply_missing_column(plan, self._ops.add_column)
        return None

    def create_index(
        self,
        index_name: str,
        columns: Sequence[Any],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        if _index_exists(
            self._table_name,
            index_name,
            schema=self._schema,
        ):
            print(
                "ATLAS ALEMBIC RECONCILE: batch indice existente preservado: "
                f"{index_name}"
            )
            return None

        names = _column_names_from_index_spec(columns)
        if names is not None:
            _assert_columns_exist(
                self._table_name,
                names,
                schema=self._schema,
                operation=f"batch_create_index:{index_name}",
            )

        return self._ops.create_index(
            index_name,
            columns,
            *args,
            **kwargs,
        )

    def create_foreign_key(
        self,
        constraint_name: str | None,
        referent_table: str,
        local_cols: Sequence[str],
        remote_cols: Sequence[str],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        referent_schema = kwargs.get("referent_schema")

        if _foreign_key_exists(
            self._table_name,
            constraint_name,
            local_cols,
            referent_table,
            remote_cols,
            source_schema=self._schema,
            referent_schema=referent_schema,
        ):
            print(
                "ATLAS ALEMBIC RECONCILE: batch foreign key existente "
                f"preservada: {constraint_name or self._table_name}"
            )
            return None

        _assert_columns_exist(
            self._table_name,
            list(local_cols),
            schema=self._schema,
            operation=f"batch_create_foreign_key:{constraint_name}",
        )
        _assert_columns_exist(
            referent_table,
            list(remote_cols),
            schema=referent_schema,
            operation=f"batch_foreign_key_target:{constraint_name}",
        )

        return self._ops.create_foreign_key(
            constraint_name,
            referent_table,
            local_cols,
            remote_cols,
            *args,
            **kwargs,
        )

    def drop_constraint(
        self,
        constraint_name: str,
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        if not _constraint_name_exists(
            self._table_name,
            constraint_name,
            schema=self._schema,
        ):
            print(
                "ATLAS ALEMBIC RECONCILE: batch constraint ja ausente; "
                f"drop ignorado: {constraint_name}"
            )
            return None

        return self._ops.drop_constraint(
            constraint_name,
            *args,
            **kwargs,
        )


class _SafeBatchContext:
    def __init__(
        self,
        context_manager: Any,
        table_name: str,
        schema: str | None,
    ) -> None:
        self._context_manager = context_manager
        self._table_name = table_name
        self._schema = schema

    def __enter__(self) -> _SafeBatchOperations:
        batch_ops = self._context_manager.__enter__()
        return _SafeBatchOperations(
            batch_ops,
            self._table_name,
            self._schema,
        )

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> Any:
        return self._context_manager.__exit__(exc_type, exc, tb)


@contextmanager
def install_reconciliation_guards() -> Iterator[None]:
    original_create_table = op.create_table
    original_create_index = op.create_index
    original_add_column = op.add_column
    original_alter_column = op.alter_column
    original_create_unique_constraint = op.create_unique_constraint
    original_create_foreign_key = op.create_foreign_key
    original_create_check_constraint = op.create_check_constraint
    original_batch_alter_table = op.batch_alter_table

    def safe_create_table(
        table_name: str,
        *elements: Any,
        **kwargs: Any,
    ) -> sa.Table:
        schema = kwargs.get("schema")

        if _table_exists(table_name, schema=schema):
            _sync_existing_table_columns(
                table_name,
                elements,
                add_column_fn=original_add_column,
                schema=schema,
            )
            print(
                "ATLAS ALEMBIC RECONCILE: tabela existente preservada: "
                f"{_qualified(table_name, schema)}"
            )
            return _reflect_existing_table(table_name, schema=schema)

        return original_create_table(table_name, *elements, **kwargs)

    def safe_add_column(
        table_name: str,
        column: sa.Column[Any],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        schema = kwargs.get("schema")

        if _column_exists(table_name, column.name, schema=schema):
            print(
                "ATLAS ALEMBIC RECONCILE: coluna existente preservada: "
                f"{_qualified(table_name, schema)}.{column.name}"
            )
            return None

        plan = _plan_missing_column(
            table_name,
            column,
            schema=schema,
        )

        # Importante: usa a referência ORIGINAL capturada antes do monkeypatch.
        _apply_missing_column(plan, original_add_column)
        return None

    def safe_alter_column(
        table_name: str,
        column_name: str,
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        schema = kwargs.get("schema")

        _assert_columns_exist(
            table_name,
            [column_name],
            schema=schema,
            operation=f"alter_column:{column_name}",
        )

        return original_alter_column(
            table_name,
            column_name,
            *args,
            **kwargs,
        )

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
                "ATLAS ALEMBIC RECONCILE: indice existente preservado: "
                f"{index_name}"
            )
            return None

        names = _column_names_from_index_spec(columns)
        if names is not None:
            _assert_columns_exist(
                table_name,
                names,
                schema=schema,
                operation=f"create_index:{index_name}",
            )

        return original_create_index(
            index_name,
            table_name,
            columns,
            *args,
            **kwargs,
        )

    def safe_create_unique_constraint(
        constraint_name: str | None,
        table_name: str,
        columns: Sequence[str],
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
            print(
                "ATLAS ALEMBIC RECONCILE: unique existente preservada: "
                f"{constraint_name or tuple(columns)}"
            )
            return None

        _assert_columns_exist(
            table_name,
            list(columns),
            schema=schema,
            operation=f"create_unique_constraint:{constraint_name}",
        )

        return original_create_unique_constraint(
            constraint_name,
            table_name,
            columns,
            *args,
            **kwargs,
        )

    def safe_create_foreign_key(
        constraint_name: str | None,
        source_table: str,
        referent_table: str,
        local_cols: Sequence[str],
        remote_cols: Sequence[str],
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        source_schema = kwargs.get("source_schema")
        referent_schema = kwargs.get("referent_schema")

        if _foreign_key_exists(
            source_table,
            constraint_name,
            local_cols,
            referent_table,
            remote_cols,
            source_schema=source_schema,
            referent_schema=referent_schema,
        ):
            print(
                "ATLAS ALEMBIC RECONCILE: foreign key existente preservada: "
                f"{constraint_name or source_table}"
            )
            return None

        _assert_columns_exist(
            source_table,
            list(local_cols),
            schema=source_schema,
            operation=f"create_foreign_key:{constraint_name}",
        )
        _assert_columns_exist(
            referent_table,
            list(remote_cols),
            schema=referent_schema,
            operation=f"foreign_key_target:{constraint_name}",
        )

        return original_create_foreign_key(
            constraint_name,
            source_table,
            referent_table,
            local_cols,
            remote_cols,
            *args,
            **kwargs,
        )

    def safe_create_check_constraint(
        constraint_name: str | None,
        table_name: str,
        condition: Any,
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        schema = kwargs.get("schema")

        if _check_constraint_exists(
            table_name,
            constraint_name,
            schema=schema,
        ):
            print(
                "ATLAS ALEMBIC RECONCILE: check existente preservado: "
                f"{constraint_name}"
            )
            return None

        return original_create_check_constraint(
            constraint_name,
            table_name,
            condition,
            *args,
            **kwargs,
        )

    def safe_batch_alter_table(
        table_name: str,
        *args: Any,
        **kwargs: Any,
    ) -> _SafeBatchContext:
        schema = kwargs.get("schema")
        original_context = original_batch_alter_table(
            table_name,
            *args,
            **kwargs,
        )
        return _SafeBatchContext(
            original_context,
            table_name,
            schema,
        )

    op.create_table = safe_create_table
    op.create_index = safe_create_index
    op.add_column = safe_add_column
    op.alter_column = safe_alter_column
    op.create_unique_constraint = safe_create_unique_constraint
    op.create_foreign_key = safe_create_foreign_key
    op.create_check_constraint = safe_create_check_constraint
    op.batch_alter_table = safe_batch_alter_table

    try:
        yield
    finally:
        op.create_table = original_create_table
        op.create_index = original_create_index
        op.add_column = original_add_column
        op.alter_column = original_alter_column
        op.create_unique_constraint = original_create_unique_constraint
        op.create_foreign_key = original_create_foreign_key
        op.create_check_constraint = original_create_check_constraint
        op.batch_alter_table = original_batch_alter_table
