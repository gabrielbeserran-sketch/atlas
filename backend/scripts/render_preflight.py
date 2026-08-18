from __future__ import annotations

import sys
from urllib.parse import quote

import httpx
from redis import Redis
from sqlalchemy import text

from app.config import get_settings
from app.database import build_engine


def _fail(message: str, exc: Exception | None = None) -> None:
    print(f"ATLAS PREFLIGHT: FAIL - {message}", file=sys.stderr)
    if exc is not None:
        print(
            f"ATLAS PREFLIGHT: detalhe={type(exc).__name__}: {exc}",
            file=sys.stderr,
        )
    raise SystemExit(1)


def check_database() -> None:
    settings = get_settings()
    print(f"ATLAS PREFLIGHT: banco={settings.database_target}")

    if settings.is_supabase_transaction_pooler:
        print(
            "ATLAS PREFLIGHT: aviso - Supabase Transaction Pooler (6543) "
            "detectado. O Atlas desativa prepared statements. Para um "
            "Web Service persistente, Session Pooler (5432) é preferível."
        )

    engine = build_engine(for_migrations=True)
    try:
        with engine.connect() as connection:
            row = connection.execute(
                text(
                    "SELECT current_database(), current_user, "
                    "current_setting('server_version')"
                )
            ).one()
        print(
            "ATLAS PREFLIGHT: PostgreSQL OK "
            f"(database={row[0]}, user={row[1]}, version={row[2]})"
        )
    except Exception as exc:
        message = str(exc).lower()
        if "password authentication failed" in message:
            _fail(
                "autenticação PostgreSQL recusada. Confira a senha real "
                "na ATLAS_DATABASE_URL do Render.",
                exc,
            )
        if "name or service not known" in message or "could not translate host" in message:
            _fail("DNS/host PostgreSQL não resolvido.", exc)
        if "timeout" in message or "timed out" in message:
            _fail("timeout ao conectar no PostgreSQL.", exc)
        _fail("conexão PostgreSQL falhou.", exc)
    finally:
        engine.dispose()


def check_redis() -> None:
    settings = get_settings()
    client = Redis.from_url(
        settings.atlas_redis_url,
        socket_connect_timeout=5,
        socket_timeout=5,
        decode_responses=True,
    )
    try:
        if client.ping() is not True:
            _fail("Redis respondeu sem PONG.")
        print("ATLAS PREFLIGHT: Redis/Key Value OK")
    except Exception as exc:
        _fail("Redis/Key Value indisponível.", exc)
    finally:
        try:
            client.close()
        except Exception:
            pass


def _storage_headers(key: str) -> dict[str, str]:
    normalized = key.strip()
    headers = {"apikey": normalized}
    if normalized and not normalized.startswith("sb_secret_"):
        headers["Authorization"] = f"Bearer {normalized}"
    return headers


def check_storage() -> None:
    settings = get_settings()
    if settings.atlas_attachment_backend != "supabase":
        print("ATLAS PREFLIGHT: Storage remoto não habilitado; ignorado.")
        return

    bucket = quote(settings.atlas_supabase_storage_bucket.strip(), safe="")
    url = (
        f"{settings.atlas_supabase_url.rstrip('/')}"
        f"/storage/v1/bucket/{bucket}"
    )

    try:
        response = httpx.head(
            url,
            headers=_storage_headers(
                settings.atlas_supabase_service_role_key
            ),
            timeout=10.0,
        )
    except httpx.HTTPError as exc:
        _fail("Supabase Storage não respondeu.", exc)

    if response.status_code == 404:
        _fail(
            "bucket Supabase Storage não encontrado: "
            f"{settings.atlas_supabase_storage_bucket}"
        )
    if response.status_code in {401, 403}:
        _fail(
            "chave server-side do Supabase não autorizou o Storage. "
            "Confira ATLAS_SUPABASE_SERVICE_ROLE_KEY/secret key."
        )
    if response.status_code >= 400:
        _fail(
            "Supabase Storage retornou HTTP "
            f"{response.status_code}."
        )

    print(
        "ATLAS PREFLIGHT: Supabase Storage OK "
        f"(bucket={settings.atlas_supabase_storage_bucket})"
    )


def main() -> int:
    settings = get_settings()
    print(
        "ATLAS PREFLIGHT: iniciando validação de produção "
        f"(env={settings.atlas_env})"
    )
    check_database()
    check_redis()
    check_storage()
    print("ATLAS PREFLIGHT: APROVADO")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
