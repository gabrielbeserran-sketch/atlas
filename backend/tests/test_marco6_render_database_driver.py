from __future__ import annotations

import os

import pytest

from app.config import Settings


def _settings(database_url: str, **overrides) -> Settings:
    data = {
        "_env_file": None,
        "atlas_env": "development",
        "atlas_database_url": database_url,
    }
    data.update(overrides)
    return Settings(**data)


def test_supabase_dns_hostname_is_valid() -> None:
    settings = _settings(
        "postgresql://postgres.project:real-password"
        "@aws-0-ca-central-1.pooler.supabase.com:5432/postgres"
    )
    assert (
        "aws-0-ca-central-1.pooler.supabase.com"
        in settings.atlas_database_url
    )


def test_placeholder_password_is_rejected_with_clear_error() -> None:
    with pytest.raises(ValueError, match="placeholder de senha"):
        _settings(
            "postgresql://postgres.project:[YOUR-PASSWORD]"
            "@aws-0-ca-central-1.pooler.supabase.com:5432/postgres"
        )


def test_reserved_password_characters_are_preserved_encoded() -> None:
    settings = _settings(
        "postgresql://postgres.project:p%40ss%5Bword%5D"
        "@aws-0-ca-central-1.pooler.supabase.com:5432/postgres"
    )
    assert "p%40ss%5Bword%5D" in settings.atlas_database_url


def test_plain_postgresql_url_uses_psycopg3() -> None:
    settings = _settings(
        "postgresql://user:pass@db.example.com:5432/atlas"
    )
    assert settings.atlas_database_url.startswith("postgresql+psycopg://")


def test_prisma_pooler_parameters_are_removed() -> None:
    settings = _settings(
        "postgresql://user:pass@db.example.com:6543/atlas"
        "?pgbouncer=true&connection_limit=1&pool_timeout=20"
        "&sslmode=require"
    )
    lowered = settings.atlas_database_url.lower()
    assert "pgbouncer=" not in lowered
    assert "connection_limit=" not in lowered
    assert "pool_timeout=" not in lowered
    assert "sslmode=require" in lowered


def test_sqlite_is_preserved() -> None:
    settings = _settings("sqlite:///./atlas_dev.db")
    assert settings.atlas_database_url == "sqlite:///./atlas_dev.db"


def test_render_external_url_becomes_authority_for_onrender_fallback(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv(
        "RENDER_EXTERNAL_URL",
        "https://atlas-api-xyz.onrender.com",
    )
    settings = _settings(
        "sqlite:///./atlas_dev.db",
        atlas_public_base_url="https://atlas-api.onrender.com",
    )
    assert (
        settings.atlas_public_base_url
        == "https://atlas-api-xyz.onrender.com"
    )
    assert "https://atlas-api-xyz.onrender.com" in settings.cors_origins
