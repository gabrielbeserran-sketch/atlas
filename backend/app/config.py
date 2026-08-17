from __future__ import annotations

from functools import lru_cache
from ipaddress import ip_network
from pathlib import Path
from typing import Literal
from urllib.parse import urlparse

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


INSECURE_SECRET_MARKERS = (
    "development",
    "change-me",
    "changeme",
    "default",
    "example",
)


class Settings(BaseSettings):
    atlas_env: Literal["development", "test", "staging", "production"] = "development"
    atlas_database_url: str = "sqlite:///./atlas_dev.db"
    atlas_jwt_secret: str = "development-only-secret-change-me"
    atlas_access_token_minutes: int = Field(default=60, ge=5, le=1440)
    atlas_refresh_token_days: int = Field(default=30, ge=1, le=365)
    atlas_email_token_minutes: int = Field(default=30, ge=5, le=1440)
    atlas_password_reset_minutes: int = Field(default=20, ge=5, le=240)
    atlas_max_failed_logins: int = Field(default=5, ge=3, le=20)
    atlas_lockout_minutes: int = Field(default=15, ge=1, le=1440)

    atlas_public_base_url: str = "http://127.0.0.1:8000"
    atlas_email_sender: str = "no-reply@atlas.local"

    atlas_bootstrap_enabled: bool = True
    atlas_bootstrap_admin_email: str = "admin@atlas.local"
    atlas_bootstrap_admin_password: str = "Atlas@123456"
    atlas_bootstrap_company_name: str = "Empresa Atlas"

    atlas_backup_dir: str = "./backups"
    atlas_backup_retention_days: int = Field(default=30, ge=1, le=3650)
    atlas_attachment_dir: str = "./attachments"
    atlas_attachment_max_mb: int = Field(default=25, ge=1, le=250)
    atlas_attachment_backend: Literal["local", "supabase"] = "local"
    atlas_supabase_url: str = ""
    atlas_supabase_service_role_key: str = ""
    atlas_supabase_storage_bucket: str = "atlas-animal-media"

    atlas_iot_ingest_key: str = "atlas-iot-development-key"
    atlas_mfa_encryption_key: str = "development-only-mfa-encryption-key"

    atlas_cors_origins: str = (
        "http://localhost:3000,"
        "http://localhost:8080,"
        "http://localhost:5000"
    )

    atlas_db_connect_timeout_seconds: int = Field(default=10, ge=1, le=120)
    atlas_db_pool_size: int = Field(default=10, ge=1, le=100)
    atlas_db_max_overflow: int = Field(default=20, ge=0, le=200)

    atlas_auto_create_schema: bool = True
    atlas_rate_limit_per_minute: int = Field(default=120, ge=10, le=10000)
    atlas_redis_url: str = ""
    atlas_docs_enabled: bool = True

    # Forwarded headers are untrusted by default. They are only honored when
    # the direct peer belongs to one of the explicitly configured proxy CIDRs.
    atlas_trust_proxy_headers: bool = False
    atlas_trusted_proxy_cidrs: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        case_sensitive=False,
    )

    @field_validator(
        "atlas_database_url",
        "atlas_jwt_secret",
        "atlas_public_base_url",
        "atlas_iot_ingest_key",
        "atlas_mfa_encryption_key",
    )
    @classmethod
    def required_text(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("valor obrigatório vazio")
        return value.strip()

    @field_validator(
        "atlas_cors_origins",
        "atlas_trusted_proxy_cidrs",
        mode="before",
    )
    @classmethod
    def normalize_csv_text(cls, value: object) -> str:
        return str(value or "").strip()

    @model_validator(mode="after")
    def validate_secure_environment(self) -> "Settings":
        if self.atlas_env not in {"staging", "production"}:
            # Mesmo em desenvolvimento, se forwarded headers forem ativados,
            # exige-se uma lista explícita para evitar confiança acidental.
            self._validate_proxy_contract()
            return self

        if self.atlas_database_url.startswith("sqlite"):
            raise ValueError("staging/production exigem PostgreSQL")

        if self._secret_is_weak(self.atlas_jwt_secret, minimum=32):
            raise ValueError(
                "ATLAS_JWT_SECRET deve ter ao menos 32 caracteres "
                "e não pode conter marcador inseguro/padrão"
            )

        if self.atlas_bootstrap_enabled:
            raise ValueError(
                "ATLAS_BOOTSTRAP_ENABLED deve ser false em staging/production"
            )

        if self.atlas_auto_create_schema:
            raise ValueError(
                "ATLAS_AUTO_CREATE_SCHEMA deve ser false fora de "
                "development/test"
            )

        if self.atlas_env == "production" and self.atlas_docs_enabled:
            raise ValueError(
                "ATLAS_DOCS_ENABLED deve ser false em production"
            )

        if self.atlas_attachment_backend == "supabase":
            if not self.atlas_supabase_url.startswith("https://"):
                raise ValueError("ATLAS_SUPABASE_URL deve usar https://")
            if len(self.atlas_supabase_service_role_key.strip()) < 32:
                raise ValueError("ATLAS_SUPABASE_SERVICE_ROLE_KEY é obrigatório para Storage")
            if not self.atlas_supabase_storage_bucket.strip():
                raise ValueError("ATLAS_SUPABASE_STORAGE_BUCKET é obrigatório")

        self._validate_public_base_url()
        self._validate_cors()
        self._validate_proxy_contract()

        if not self.atlas_redis_url.strip():
            raise ValueError(
                "ATLAS_REDIS_URL é obrigatório em staging/production "
                "para rate limit compartilhado."
            )
        if not self.atlas_redis_url.strip().startswith(("redis://", "rediss://")):
            raise ValueError(
                "ATLAS_REDIS_URL deve usar redis:// ou rediss://."
            )

        if self._secret_is_weak(self.atlas_iot_ingest_key, minimum=32):
            raise ValueError(
                "ATLAS_IOT_INGEST_KEY deve ter ao menos 32 caracteres "
                "e não pode usar chave padrão/insegura em staging/production"
            )

        if self._secret_is_weak(self.atlas_mfa_encryption_key, minimum=32):
            raise ValueError(
                "ATLAS_MFA_ENCRYPTION_KEY deve ter ao menos 32 caracteres "
                "e não pode usar chave padrão/insegura em staging/production"
            )

        if (
            self.atlas_env == "production"
            and self.atlas_email_sender.lower().endswith("@atlas.local")
        ):
            raise ValueError(
                "ATLAS_EMAIL_SENDER não pode usar domínio atlas.local "
                "em production"
            )

        return self

    @staticmethod
    def _secret_is_weak(value: str, *, minimum: int) -> bool:
        normalized = value.strip().lower()
        if len(normalized) < minimum:
            return True
        return any(marker in normalized for marker in INSECURE_SECRET_MARKERS)

    def _validate_public_base_url(self) -> None:
        parsed = urlparse(self.atlas_public_base_url)
        if parsed.scheme.lower() != "https" or not parsed.hostname:
            raise ValueError(
                "ATLAS_PUBLIC_BASE_URL deve usar https:// "
                "em staging/production"
            )

        if self.atlas_env == "production" and parsed.hostname.lower() in {
            "localhost",
            "127.0.0.1",
            "::1",
        }:
            raise ValueError(
                "ATLAS_PUBLIC_BASE_URL não pode apontar para host local "
                "em production"
            )

    def _validate_cors(self) -> None:
        origins = self.cors_origins
        if not origins:
            raise ValueError(
                "ATLAS_CORS_ORIGINS deve declarar ao menos uma origem "
                "em staging/production"
            )

        if "*" in origins:
            raise ValueError(
                "CORS com wildcard é proibido em staging/production"
            )

        for origin in origins:
            parsed = urlparse(origin)
            if parsed.scheme.lower() != "https" or not parsed.hostname:
                raise ValueError(
                    "Todas as origens CORS devem usar https:// "
                    "em staging/production"
                )

            if self.atlas_env == "production" and parsed.hostname.lower() in {
                "localhost",
                "127.0.0.1",
                "::1",
            }:
                raise ValueError(
                    "CORS não pode autorizar host local em production"
                )

    def _validate_proxy_contract(self) -> None:
        raw_cidrs = self.trusted_proxy_cidrs
        if self.atlas_trust_proxy_headers and not raw_cidrs:
            raise ValueError(
                "ATLAS_TRUST_PROXY_HEADERS=true exige "
                "ATLAS_TRUSTED_PROXY_CIDRS explícito"
            )

        for cidr in raw_cidrs:
            try:
                ip_network(cidr, strict=False)
            except ValueError as exc:
                raise ValueError(
                    f"CIDR de proxy confiável inválido: {cidr}"
                ) from exc

    @property
    def cors_origins(self) -> list[str]:
        return [
            item.strip()
            for item in self.atlas_cors_origins.split(",")
            if item.strip()
        ]

    @property
    def trusted_proxy_cidrs(self) -> list[str]:
        return [
            item.strip()
            for item in self.atlas_trusted_proxy_cidrs.split(",")
            if item.strip()
        ]

    @property
    def backup_dir(self) -> Path:
        path = Path(self.atlas_backup_dir)
        path.mkdir(parents=True, exist_ok=True)
        return path

    @property
    def attachment_dir(self) -> Path:
        path = Path(self.atlas_attachment_dir)
        path.mkdir(parents=True, exist_ok=True)
        return path

    @property
    def is_production_like(self) -> bool:
        return self.atlas_env in {"staging", "production"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
