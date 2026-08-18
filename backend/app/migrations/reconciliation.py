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


def _relation_owner(
    relation_name: str,
    *,
    schema: str | None = None,
) -> tuple[str, str, str] | None:
    """Retorna (schema, relation, kind) para um nome PostgreSQL já ocupado.

    Índices vivem no mesmo namespace de relações que tabelas/sequences.
    Portanto, consultar apenas os índices da tabela alvo não detecta colisões
    globais de nome — exatamente o caso observado no Render.
    """
    target_schema = schema or "public"
    row = _bind().execute(
        sa.text(
            """
            SELECT n.nspname, c.relname, c.relkind
            FROM pg_catalog.pg_class AS c
            JOIN pg_catalog.pg_namespace AS n
              ON n.oid = c.relnamespace
            WHERE n.nspname = :schema
              AND c.relname = :name
            LIMIT 1
            """
        ),
        {"schema": target_schema, "name": relation_name},
    ).first()

    if row is None:
        return None

    return str(row[0]), str(row[1]), str(row[2])


def _index_table_for_name(
    index_name: str,
    *,
    schema: str | None = None,
) -> str | None:
    target_schema = schema or "public"
    row = _bind().execute(
        sa.text(
            """
            SELECT tbl.relname
            FROM pg_catalog.pg_class AS idx
            JOIN pg_catalog.pg_namespace AS n
              ON n.oid = idx.relnamespace
            JOIN pg_catalog.pg_index AS pi
              ON pi.indexrelid = idx.oid
            JOIN pg_catalog.pg_class AS tbl
              ON tbl.oid = pi.indrelid
            WHERE n.nspname = :schema
              AND idx.relname = :name
            LIMIT 1
            """
        ),
        {"schema": target_schema, "name": index_name},
    ).scalar_one_or_none()

    return str(row) if row is not None else None


def _postgres_identifier(value: str) -> str:
    """Limita identificadores à regra PostgreSQL de 63 bytes de forma estável."""
    encoded = value.encode("utf-8")
    if len(encoded) <= 63:
        return value

    import hashlib

    digest = hashlib.sha1(encoded).hexdigest()[:10]
    prefix_bytes = encoded[: 63 - 11]
    while True:
        try:
            prefix = prefix_bytes.decode("utf-8")
            break
        except UnicodeDecodeError:
            prefix_bytes = prefix_bytes[:-1]

    return f"{prefix}_{digest}"


def _collision_safe_index_name(
    requested_name: str,
    table_name: str,
    columns: Sequence[str] | None,
) -> str:
    """Nome alternativo determinístico quando o nome pedido já pertence a outra tabela."""
    column_suffix = "_".join(columns or ()) or "expr"
    candidate = f"{requested_name}__{table_name}__{column_suffix}"
    return _postgres_identifier(candidate)


def _resolve_index_name(
    requested_name: str,
    table_name: str,
    columns: Sequence[str] | None,
    *,
    schema: str | None = None,
) -> tuple[str, bool]:
    """Resolve colisão schema-global sem deixar a tabela alvo sem índice.

    Retorna (nome_a_usar, já_existe_na_tabela_alvo).
    """
    owner_table = _index_table_for_name(requested_name, schema=schema)

    if owner_table == table_name:
        return requested_name, True

    relation = _relation_owner(requested_name, schema=schema)
    if relation is None:
        return requested_name, False

    # O nome está ocupado em outra relação/tabela. Criamos um índice equivalente
    # na tabela correta com nome determinístico alternativo.
    safe_name = _collision_safe_index_name(
        requested_name,
        table_name,
        columns,
    )

    safe_owner = _index_table_for_name(safe_name, schema=schema)
    if safe_owner == table_name:
        return safe_name, True

    if _relation_owner(safe_name, schema=schema) is not None:
        raise UnsafeSchemaReconciliation(
            "ATLAS ALEMBIC RECONCILE: colisao global de nomes PostgreSQL "
            "tambem atingiu o nome alternativo do indice: "
            f"requested={requested_name}, alternate={safe_name}, "
            f"target_table={table_name}."
        )

    print(
        "ATLAS ALEMBIC RECONCILE: colisao global de nome de indice detectada: "
        f"requested={requested_name}, owner_table={owner_table or relation[1]}, "
        f"target_table={table_name}, alternate={safe_name}"
    )
    return safe_name, False


def _existing_index_names(
    table_name: str,
    *,
    schema: str | None = None,
) -> set[str]:
    if not _table_exists(table_name, schema=schema):
        return set()

    return {
        item["name"]
        for item in _inspector().get_indexes(table_name, schema=schema)
        if item.get("name")
    }


def _existing_constraint_names(
    table_name: str,
    *,
    schema: str | None = None,
) -> set[str]:
    if not _table_exists(table_name, schema=schema):
        return set()

    names: set[str] = set()

    for item in _inspector().get_unique_constraints(
        table_name,
        schema=schema,
    ):
        if item.get("name"):
            names.add(item["name"])

    for item in _inspector().get_foreign_keys(
        table_name,
        schema=schema,
    ):
        if item.get("name"):
            names.add(item["name"])

    for item in _inspector().get_check_constraints(
        table_name,
        schema=schema,
    ):
        if item.get("name"):
            names.add(item["name"])

    pk = _inspector().get_pk_constraint(table_name, schema=schema)
    if pk.get("name"):
        names.add(pk["name"])

    return names


def _filter_existing_table_elements(
    table_name: str,
    elements: Sequence[Any],
    *,
    schema: str | None = None,
) -> tuple[list[Any], list[str]]:
    """Remove de uma definição elementos declarativos que já existem.

    Em algumas migrations históricas, índices/constraints podem nascer junto
    da definição SQLAlchemy da tabela, escapando de um `op.create_index`
    explícito. Quando a tabela já existe, não precisamos reaplicar esses
    objetos declarativos; apenas garantimos colunas e deixamos os guards
    explícitos cuidarem das operações subsequentes.
    """
    existing_indexes = _existing_index_names(table_name, schema=schema)
    existing_constraints = _existing_constraint_names(
        table_name,
        schema=schema,
    )

    filtered: list[Any] = []
    skipped: list[str] = []

    for element in elements:
        if isinstance(element, sa.Index):
            if element.name and element.name in existing_indexes:
                skipped.append(f"index:{element.name}")
                continue

        if isinstance(
            element,
            (
                sa.UniqueConstraint,
                sa.ForeignKeyConstraint,
                sa.CheckConstraint,
                sa.PrimaryKeyConstraint,
            ),
        ):
            if element.name and element.name in existing_constraints:
                skipped.append(
                    f"constraint:{element.name}"
                )
                continue

        filtered.append(element)

    return filtered, skipped


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
        names = _column_names_from_index_spec(columns)

        if names is not None:
            _assert_columns_exist(
                self._table_name,
                names,
                schema=self._schema,
                operation=f"batch_create_index:{index_name}",
            )

        resolved_name, already_exists = _resolve_index_name(
            index_name,
            self._table_name,
            names,
            schema=self._schema,
        )

        if already_exists:
            print(
                "ATLAS ALEMBIC RECONCILE: batch indice existente preservado: "
                f"{resolved_name} em {self._table_name}"
            )
            return None

        return self._ops.create_index(
            resolved_name,
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
    original_execute = op.execute

    def safe_create_table(
        table_name: str,
        *elements: Any,
        **kwargs: Any,
    ) -> sa.Table:
        schema = kwargs.get("schema")

        if _table_exists(table_name, schema=schema):
            filtered_elements, skipped = _filter_existing_table_elements(
                table_name,
                elements,
                schema=schema,
            )

            _sync_existing_table_columns(
                table_name,
                filtered_elements,
                add_column_fn=original_add_column,
                schema=schema,
            )

            for item in skipped:
                print(
                    "ATLAS ALEMBIC RECONCILE: objeto declarativo existente "
                    f"preservado: {item} em {_qualified(table_name, schema)}"
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
        names = _column_names_from_index_spec(columns)

        if names is not None:
            _assert_columns_exist(
                table_name,
                names,
                schema=schema,
                operation=f"create_index:{index_name}",
            )

        resolved_name, already_exists = _resolve_index_name(
            index_name,
            table_name,
            names,
            schema=schema,
        )

        if already_exists:
            print(
                "ATLAS ALEMBIC RECONCILE: indice existente preservado: "
                f"{resolved_name} em {table_name}"
            )
            return None

        return original_create_index(
            resolved_name,
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

    def safe_execute(
        sqltext: Any,
        *args: Any,
        **kwargs: Any,
    ) -> Any:
        raw = str(sqltext).strip()
        normalized = " ".join(raw.split())
        upper = normalized.upper()

        # Cobre SQL cru do tipo:
        # CREATE INDEX ix_name ON table (...);
        # CREATE UNIQUE INDEX ix_name ON table (...);
        # É uma rota histórica que pode escapar de op.create_index().
        if upper.startswith("CREATE INDEX ") or upper.startswith(
            "CREATE UNIQUE INDEX "
        ):
            tokens = normalized.replace(";", "").split()

            if upper.startswith("CREATE UNIQUE INDEX "):
                name_pos = 3
            else:
                name_pos = 2

            if len(tokens) > name_pos + 2:
                index_name = tokens[name_pos].strip('"')
                try:
                    on_pos = next(
                        i for i, token in enumerate(tokens)
                        if token.upper() == "ON"
                    )
                    table_name = tokens[on_pos + 1].strip('"')
                except (StopIteration, IndexError):
                    table_name = ""

                if table_name and index_name:
                    resolved_name, already_exists = _resolve_index_name(
                        index_name,
                        table_name,
                        None,
                    )

                    if already_exists:
                        print(
                            "ATLAS ALEMBIC RECONCILE: raw SQL indice existente "
                            f"preservado: {resolved_name} em {table_name}"
                        )
                        return None

                    if resolved_name != index_name:
                        # Para SQL cru, reescrever nomes exige parser SQL real.
                        # Falhamos de forma explícita em vez de executar SQL
                        # ambíguo ou deixar a transação abortar.
                        raise UnsafeSchemaReconciliation(
                            "ATLAS ALEMBIC RECONCILE: CREATE INDEX via SQL cru "
                            "teve colisao global de nome e requer migration "
                            "explicita com nome alternativo: "
                            f"requested={index_name}, alternate={resolved_name}, "
                            f"table={table_name}"
                        )

        return original_execute(sqltext, *args, **kwargs)

    op.create_table = safe_create_table
    op.create_index = safe_create_index
    op.add_column = safe_add_column
    op.alter_column = safe_alter_column
    op.create_unique_constraint = safe_create_unique_constraint
    op.create_foreign_key = safe_create_foreign_key
    op.create_check_constraint = safe_create_check_constraint
    op.batch_alter_table = safe_batch_alter_table
    op.execute = safe_execute

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
        op.execute = original_execute
