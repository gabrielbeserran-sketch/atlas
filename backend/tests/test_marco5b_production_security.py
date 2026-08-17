from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.config import Settings
from app.services.security_middleware import resolve_client_ip


def secure_production_settings(**overrides) -> dict:
    data = {
        "atlas_env": "production",
        "atlas_database_url": (
            "postgresql+psycopg://atlas:strong-password@db.internal:5432/atlas"
        ),
        "atlas_jwt_secret": "J" * 64,
        "atlas_iot_ingest_key": "I" * 64,
        "atlas_mfa_encryption_key": "M" * 64,
        "atlas_public_base_url": "https://api.atlas.example",
        "atlas_email_sender": "no-reply@atlas.example",
        "atlas_bootstrap_enabled": False,
        "atlas_auto_create_schema": False,
        "atlas_docs_enabled": False,
        "atlas_cors_origins": "https://app.atlas.example",
        "atlas_trust_proxy_headers": False,
        "atlas_trusted_proxy_cidrs": "",
        "atlas_redis_url": "rediss://redis.atlas.example:6379/0",
    }
    data.update(overrides)
    return data


def build_settings(**overrides) -> Settings:
    return Settings(
        _env_file=None,
        **secure_production_settings(**overrides),
    )


def test_secure_production_contract_is_accepted() -> None:
    settings = build_settings()
    assert settings.atlas_env == "production"
    assert settings.atlas_docs_enabled is False
    assert settings.atlas_bootstrap_enabled is False


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("atlas_bootstrap_enabled", True),
        ("atlas_docs_enabled", True),
        ("atlas_public_base_url", "http://api.atlas.example"),
        ("atlas_public_base_url", "https://127.0.0.1"),
        ("atlas_iot_ingest_key", "atlas-iot-development-key"),
        ("atlas_iot_ingest_key", "short-key"),
        ("atlas_mfa_encryption_key", "development-only-mfa-encryption-key"),
        ("atlas_mfa_encryption_key", "short-key"),
        ("atlas_cors_origins", "*"),
        ("atlas_cors_origins", "http://app.atlas.example"),
        ("atlas_cors_origins", "https://localhost:8080"),
        ("atlas_redis_url", ""),
        ("atlas_redis_url", "http://redis.invalid"),
    ],
)
def test_production_rejects_insecure_configuration(
    field: str,
    value: object,
) -> None:
    with pytest.raises(ValidationError):
        build_settings(**{field: value})


def test_proxy_headers_require_explicit_trusted_cidrs() -> None:
    with pytest.raises(ValidationError):
        build_settings(
            atlas_trust_proxy_headers=True,
            atlas_trusted_proxy_cidrs="",
        )


def test_proxy_cidr_must_be_valid() -> None:
    with pytest.raises(ValidationError):
        build_settings(
            atlas_trust_proxy_headers=True,
            atlas_trusted_proxy_cidrs="not-a-cidr",
        )


def test_untrusted_peer_cannot_spoof_x_forwarded_for() -> None:
    settings = build_settings(
        atlas_trust_proxy_headers=True,
        atlas_trusted_proxy_cidrs="10.0.0.0/8",
    )
    assert (
        resolve_client_ip(
            remote_host="203.0.113.10",
            forwarded_for="198.51.100.7",
            config=settings,
        )
        == "203.0.113.10"
    )


def test_trusted_proxy_can_forward_valid_client_ip() -> None:
    settings = build_settings(
        atlas_trust_proxy_headers=True,
        atlas_trusted_proxy_cidrs="10.0.0.0/8,192.168.50.10/32",
    )
    assert (
        resolve_client_ip(
            remote_host="10.5.0.9",
            forwarded_for="198.51.100.7, 10.5.0.9",
            config=settings,
        )
        == "198.51.100.7"
    )


def test_invalid_forwarded_value_falls_back_to_direct_peer() -> None:
    settings = build_settings(
        atlas_trust_proxy_headers=True,
        atlas_trusted_proxy_cidrs="10.0.0.0/8",
    )
    assert (
        resolve_client_ip(
            remote_host="10.5.0.9",
            forwarded_for="spoofed-value",
            config=settings,
        )
        == "10.5.0.9"
    )
