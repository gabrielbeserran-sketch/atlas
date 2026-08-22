from __future__ import annotations

from collections.abc import Generator
from contextlib import contextmanager
from typing import Any

from sqlalchemy import JSON, String, Text, create_engine, event, inspect, literal, text
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy.sql.schema import Column, MetaData

from .config import get_settings
from .text_normalization import normalize_text_payload, repair_mojibake_text

settings = get_settings()


def postgres_connect_args() -> dict[str, Any]:
    args: dict[str, Any] = {
        "connect_timeout": settings.atlas_db_connect_timeout_seconds,
    }

    # Transaction Pooler do Supabase não suporta prepared statements.
    # O valor None também é seguro no Session Pooler e mantém um único
    # contrato entre API e Alembic.
    if settings.atlas_database_url.startswith("postgresql+psycopg://"):
        args["prepare_threshold"] = None

    return args


def build_engine(*, for_migrations: bool = False) -> Engine:
    if settings.atlas_database_url.startswith("sqlite"):
        kwargs: dict[str, Any] = {
            "pool_pre_ping": True,
            "connect_args": {"check_same_thread": False},
        }
        if for_migrations:
            kwargs["poolclass"] = NullPool
        return create_engine(settings.atlas_database_url, **kwargs)

    kwargs = {
        "pool_pre_ping": True,
        "pool_recycle": 1800,
        "connect_args": postgres_connect_args(),
    }

    if for_migrations:
        kwargs["poolclass"] = NullPool
    else:
        kwargs["pool_size"] = settings.atlas_db_pool_size
        kwargs["max_overflow"] = settings.atlas_db_max_overflow

    return create_engine(settings.atlas_database_url, **kwargs)


engine = build_engine()
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


@event.listens_for(Session, "before_flush")
def _normalize_text_before_flush(
    session: Session,
    flush_context: object,
    instances: object,
) -> None:
    """Impede que mojibake volte a ser persistido no banco.

    A regra atua na borda de persistência e preserva códigos internos: apenas
    strings com marcadores inequívocos de codificação quebrada são reparadas.
    Estruturas JSON também são normalizadas recursivamente.
    """
    for item in set(session.new).union(session.dirty):
        mapper = getattr(item, "__mapper__", None)
        if mapper is None:
            continue
        for attribute in mapper.column_attrs:
            columns = getattr(attribute, "columns", ())
            if not columns:
                continue
            column_type = columns[0].type
            key = attribute.key
            value = getattr(item, key, None)
            if value is None:
                continue
            if isinstance(column_type, (String, Text)) and isinstance(value, str):
                repaired = repair_mojibake_text(value)
                if repaired != value:
                    setattr(item, key, repaired)
            elif isinstance(column_type, JSON):
                normalized = normalize_text_payload(value)
                if normalized != value:
                    setattr(item, key, normalized)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


@contextmanager
def transaction() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        with db.begin():
            yield db
    finally:
        db.close()


def database_health() -> dict[str, Any]:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))

    pool = engine.pool
    result: dict[str, Any] = {
        "status": "ok",
        "dialect": engine.dialect.name,
    }
    for name in ("size", "checkedin", "checkedout", "overflow"):
        fn = getattr(pool, name, None)
        if callable(fn):
            try:
                result[name] = fn()
            except Exception:
                pass
    return result


def _quote_identifier(connection: Connection, value: str) -> str:
    return connection.dialect.identifier_preparer.quote(value)


def _compiled_type_sql(connection: Connection, column: Column[Any]) -> str:
    return column.type.compile(dialect=connection.dialect)


def _scalar_default_sql(
    connection: Connection,
    column: Column[Any],
) -> str | None:
    default = column.default
    if default is None or not getattr(default, "is_scalar", False):
        return None

    try:
        return str(
            literal(default.arg, type_=column.type).compile(
                dialect=connection.dialect,
                compile_kwargs={"literal_binds": True},
            )
        )
    except Exception:
        return None


def _table_has_rows(connection: Connection, table_name: str) -> bool:
    quoted_table = _quote_identifier(connection, table_name)
    return (
        connection.execute(
            text(f"SELECT 1 FROM {quoted_table} LIMIT 1")
        ).first()
        is not None
    )


def _add_missing_column(
    connection: Connection,
    *,
    table_name: str,
    column: Column[Any],
    table_has_rows: bool,
) -> str:
    """Adiciona uma coluna ausente sem remover ou sobrescrever dados.

    Exclusivo de development/test.

    Para uma coluna NOT NULL com default escalar no modelo, o default é usado
    temporariamente para preencher as linhas antigas. No PostgreSQL, quando o
    modelo não define server_default, esse DEFAULT temporário é removido logo
    depois, preservando a semântica do modelo.

    Se uma coluna obrigatória não possui um default seguro e a tabela já tem
    dados, não inventamos um valor de domínio: ela é criada nullable para
    preservar os registros locais existentes.
    """
    if column.primary_key:
        raise RuntimeError(
            "reparo automático recusado para chave primária ausente: "
            f"{table_name}.{column.name}"
        )

    quoted_table = _quote_identifier(connection, table_name)
    quoted_column = _quote_identifier(connection, column.name)
    type_sql = _compiled_type_sql(connection, column)
    scalar_default = _scalar_default_sql(connection, column)

    ddl = (
        f"ALTER TABLE {quoted_table} "
        f"ADD COLUMN {quoted_column} {type_sql}"
    )

    temporary_default = False

    if column.nullable:
        pass
    elif scalar_default is not None:
        ddl += f" DEFAULT {scalar_default} NOT NULL"
        temporary_default = column.server_default is None
    elif not table_has_rows:
        ddl += " NOT NULL"

    connection.execute(text(ddl))

    if temporary_default and connection.dialect.name == "postgresql":
        connection.execute(
            text(
                f"ALTER TABLE {quoted_table} "
                f"ALTER COLUMN {quoted_column} DROP DEFAULT"
            )
        )

    if (
        not column.nullable
        and scalar_default is None
        and table_has_rows
    ):
        return (
            f"{table_name}.{column.name} "
            "(nullable local para preservar linhas antigas)"
        )

    return f"{table_name}.{column.name}"


def repair_missing_development_columns(
    connection: Connection,
    metadata: MetaData,
) -> list[str]:
    """Repara somente colunas ausentes em tabelas que já existem.

    A rotina é estritamente aditiva: não remove tabela/coluna, não renomeia,
    não muda tipo existente e não apaga dados.
    """
    existing_tables = set(inspect(connection).get_table_names())
    repaired: list[str] = []

    for table_name, table in metadata.tables.items():
        if table_name not in existing_tables:
            continue

        current_columns = {
            item["name"]
            for item in inspect(connection).get_columns(table_name)
        }
        missing = [
            column
            for column in table.columns
            if column.name not in current_columns
        ]
        if not missing:
            continue

        has_rows = _table_has_rows(connection, table_name)
        for column in missing:
            repaired.append(
                _add_missing_column(
                    connection,
                    table_name=table_name,
                    column=column,
                    table_has_rows=has_rows,
                )
            )

    return repaired


def ensure_development_schema_compatibility() -> list[str]:
    """Fecha a lacuna de `create_all()` em bancos locais antigos.

    `create_all()` cria tabelas ausentes, mas não adiciona colunas novas a
    tabelas existentes. Em development/test este helper adiciona apenas as
    colunas ausentes. Fora desses ambientes não realiza nenhuma alteração.
    """
    if settings.atlas_env not in {"development", "test"}:
        return []

    with engine.begin() as connection:
        return repair_missing_development_columns(
            connection,
            Base.metadata,
        )
