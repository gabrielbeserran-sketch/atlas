from __future__ import annotations

from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from alembic.script import ScriptDirectory

from app.database import build_engine


def main() -> int:
    config = Config("alembic.ini")
    scripts = ScriptDirectory.from_config(config)
    expected = set(scripts.get_heads())

    engine = build_engine(for_migrations=True)
    try:
        with engine.connect() as connection:
            current = set(
                MigrationContext.configure(connection).get_current_heads()
            )
    finally:
        engine.dispose()

    if current != expected:
        raise RuntimeError(
            "Alembic não atingiu o head esperado. "
            f"current={sorted(current)} expected={sorted(expected)}"
        )

    print(
        "ATLAS MIGRATIONS: APROVADO "
        f"(heads={','.join(sorted(current))})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
