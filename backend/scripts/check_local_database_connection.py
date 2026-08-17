from __future__ import annotations

import sys
from pathlib import Path

# Execução direta de um script define sys.path[0] como backend/scripts.
# A raiz backend precisa ser adicionada explicitamente antes de importar "app".
BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from app.config import get_settings


def main() -> int:
    settings = get_settings()
    url = make_url(settings.atlas_database_url)

    if url.get_backend_name() != "postgresql":
        raise SystemExit(
            "ATLAS_DATABASE_URL local precisa apontar para PostgreSQL antes da validação."
        )

    safe_url = url.render_as_string(hide_password=True)
    engine = create_engine(
        settings.atlas_database_url,
        pool_pre_ping=True,
        connect_args={
            "connect_timeout": settings.atlas_db_connect_timeout_seconds,
        },
    )

    row = None
    try:
        with engine.connect() as connection:
            row = connection.execute(
                text("SELECT current_database(), current_user")
            ).one()
    except Exception as exc:
        raise SystemExit(
            "Falha de autenticação/conexão com o PostgreSQL usando exatamente "
            f"a configuração do backend ({safe_url}). Detalhe: {exc}"
        ) from exc
    finally:
        engine.dispose()

    if row is None:
        raise SystemExit(
            "A conexão PostgreSQL foi encerrada sem retornar banco e usuário atuais."
        )

    database_name, user_name = row
    print(
        "ATLAS DATABASE CONNECTION: OK "
        f"database={database_name} user={user_name} url={safe_url}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
