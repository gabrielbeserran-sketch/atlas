from logging.config import fileConfig

from alembic import context

from app import models  # noqa: F401
from app.database import Base, build_engine
from app.migrations.reconciliation import install_reconciliation_guards

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    from app.config import get_settings

    context.configure(
        url=get_settings().atlas_database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = build_engine(for_migrations=True)
    try:
        with connectable.connect() as connection:
            context.configure(
                connection=connection,
                target_metadata=target_metadata,
                compare_type=True,
            )
            with install_reconciliation_guards():
                with context.begin_transaction():
                    context.run_migrations()
    finally:
        connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
