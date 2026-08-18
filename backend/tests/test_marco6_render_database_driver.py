from __future__ import annotations

from app.config import Settings


def _base_settings(database_url: str) -> Settings:
    return Settings(
        _env_file=None,
        atlas_env="development",
        atlas_database_url=database_url,
    )


def test_supabase_plain_postgresql_url_uses_psycopg3() -> None:
    settings = _base_settings(
        "postgresql://postgres.project:password@pooler.example:6543/postgres"
    )
    assert settings.atlas_database_url == (
        "postgresql+psycopg://"
        "postgres.project:password@pooler.example:6543/postgres"
    )


def test_legacy_postgres_alias_is_normalized() -> None:
    settings = _base_settings(
        "postgres://postgres.project:password@pooler.example:6543/postgres"
    )
    assert settings.atlas_database_url == (
        "postgresql+psycopg://"
        "postgres.project:password@pooler.example:6543/postgres"
    )


def test_explicit_psycopg_url_is_preserved() -> None:
    url = (
        "postgresql+psycopg://"
        "postgres.project:password@pooler.example:6543/postgres"
    )
    settings = _base_settings(url)
    assert settings.atlas_database_url == url


def test_sqlite_development_url_is_preserved() -> None:
    settings = _base_settings("sqlite:///./atlas_dev.db")
    assert settings.atlas_database_url == "sqlite:///./atlas_dev.db"


def test_supabase_pgbouncer_parameter_is_removed() -> None:
    settings = _base_settings(
        "postgresql://postgres.project:password@pooler.example:6543/postgres"
        "?pgbouncer=true"
    )
    assert settings.atlas_database_url == (
        "postgresql+psycopg://"
        "postgres.project:password@pooler.example:6543/postgres"
    )


def test_legitimate_postgresql_query_parameters_are_preserved() -> None:
    settings = _base_settings(
        "postgresql://postgres.project:password@pooler.example:6543/postgres"
        "?sslmode=require&application_name=atlas&pgbouncer=true"
    )
    assert settings.atlas_database_url.startswith(
        "postgresql+psycopg://"
        "postgres.project:password@pooler.example:6543/postgres?"
    )
    assert "pgbouncer=" not in settings.atlas_database_url.lower()
    assert "sslmode=require" in settings.atlas_database_url
    assert "application_name=atlas" in settings.atlas_database_url


def test_pgbouncer_parameter_is_removed_case_insensitively() -> None:
    settings = _base_settings(
        "postgresql+psycopg://"
        "postgres.project:password@pooler.example:6543/postgres"
        "?PgBouncer=true&sslmode=require"
    )
    assert "pgbouncer" not in settings.atlas_database_url.lower()
    assert "sslmode=require" in settings.atlas_database_url
