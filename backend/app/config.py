from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


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
    atlas_public_base_url: str = 'http://127.0.0.1:8000'
    atlas_email_sender: str = 'no-reply@atlas.local'
    atlas_bootstrap_enabled: bool = True
    atlas_bootstrap_admin_email: str = "admin@atlas.local"
    atlas_bootstrap_admin_password: str = "Atlas@123456"
    atlas_bootstrap_company_name: str = "Empresa Atlas"
    atlas_backup_dir: str = "./backups"
    atlas_backup_retention_days: int = Field(default=30, ge=1, le=3650)
    atlas_iot_ingest_key: str = "atlas-iot-development-key"
    atlas_cors_origins: str = "http://localhost:3000,http://localhost:8080,http://localhost:5000"
    atlas_db_connect_timeout_seconds: int = Field(default=10, ge=1, le=120)
    atlas_db_pool_size: int = Field(default=10, ge=1, le=100)
    atlas_db_max_overflow: int = Field(default=20, ge=0, le=200)
    atlas_auto_create_schema: bool = True
    atlas_rate_limit_per_minute: int = Field(default=120, ge=10, le=10000)
    atlas_docs_enabled: bool = True

    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    @field_validator("atlas_database_url", "atlas_jwt_secret")
    @classmethod
    def required_text(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("valor obrigatório vazio")
        return value.strip()

    @model_validator(mode="after")
    def validate_secure_environment(self):
        if self.atlas_env in {"staging", "production"}:
            if self.atlas_database_url.startswith("sqlite"):
                raise ValueError("staging/production exigem PostgreSQL")
            if len(self.atlas_jwt_secret) < 32 or "development-only" in self.atlas_jwt_secret:
                raise ValueError("ATLAS_JWT_SECRET deve ter ao menos 32 caracteres e não pode ser o padrão")
            if self.atlas_bootstrap_admin_password == "Atlas@123456":
                raise ValueError("senha padrão de bootstrap proibida fora de desenvolvimento")
            if self.atlas_auto_create_schema:
                raise ValueError("ATLAS_AUTO_CREATE_SCHEMA deve ser false fora de desenvolvimento/test")
            if "*" in self.cors_origins:
                raise ValueError("CORS com wildcard é proibido em staging/production")
        return self

    @property
    def cors_origins(self) -> list[str]:
        return [item.strip() for item in self.atlas_cors_origins.split(",") if item.strip()]

    @property
    def backup_dir(self) -> Path:
        path = Path(self.atlas_backup_dir)
        path.mkdir(parents=True, exist_ok=True)
        return path

    @property
    def is_production_like(self) -> bool:
        return self.atlas_env in {"staging", "production"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
