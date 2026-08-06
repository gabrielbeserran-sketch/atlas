from collections.abc import Generator
from contextlib import contextmanager

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import get_settings

settings = get_settings()


def build_engine() -> Engine:
    if settings.atlas_database_url.startswith("sqlite"):
        return create_engine(
            settings.atlas_database_url,
            pool_pre_ping=True,
            connect_args={"check_same_thread": False},
        )
    return create_engine(
        settings.atlas_database_url,
        pool_pre_ping=True,
        pool_size=settings.atlas_db_pool_size,
        max_overflow=settings.atlas_db_max_overflow,
        pool_recycle=1800,
        connect_args={"connect_timeout": settings.atlas_db_connect_timeout_seconds},
    )


engine = build_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


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


def database_health() -> dict:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
    pool = engine.pool
    result = {"status": "ok", "dialect": engine.dialect.name}
    for name in ("size", "checkedin", "checkedout", "overflow"):
        fn = getattr(pool, name, None)
        if callable(fn):
            try: result[name] = fn()
            except Exception: pass
    return result
