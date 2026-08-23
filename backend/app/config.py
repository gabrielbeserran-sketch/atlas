from __future__ import annotations

from functools import lru_cache
import os
import re
from ipaddress import ip_network
from pathlib import Path
from typing import Literal
from urllib.parse import urlparse

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError


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

    # Provisionamento administrativo controlado para staging/production.
    # É separado do bootstrap de desenvolvimento e deve ser habilitado
    # somente por um deploy, depois desabilitado novamente.
    atlas_provision_admin_once: bool = False
    atlas_provision_admin_email: str = ""
    atlas_provision_admin_password: str = ""
    atlas_provision_company_name: str = ""

    # Diagnóstico controlado da autenticação de um administrador existente.
    atlas_auth_diagnostic_enabled: bool = False
    atlas_auth_diagnostic_email: str = ""
    atlas_auth_diagnostic_password: str = ""

    # Reset administrativo one-shot para uma conta já existente.
    atlas_reset_admin_password_once: bool = False
    atlas_reset_admin_email: str = ""
    atlas_reset_admin_password: str = ""

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

    # Boletins mensais e WhatsApp Business Cloud API.
    # O envio permanece desabilitado até existir uma conta oficial configurada.
    atlas_bulletin_scheduler_enabled: bool = True
    atlas_bulletin_poll_seconds: int = Field(default=300, ge=60, le=3600)
    atlas_bulletin_cron_secret: str = ""
    atlas_whatsapp_enabled: bool = False
    atlas_whatsapp_access_token: str = ""
    atlas_whatsapp_phone_number_id: str = ""
    atlas_whatsapp_graph_version: str = ""
    atlas_whatsapp_template_language: str = "pt_BR"
    atlas_whatsapp_template_zootechnical: str = ""
    atlas_whatsapp_template_operations: str = ""
    atlas_whatsapp_template_financial: str = ""
    atlas_whatsapp_template_security_alert: str = ""
    atlas_whatsapp_webhook_verify_token: str = ""
    atlas_whatsapp_app_secret: str = ""

    # Forwarded headers are untrusted by default. They are only honored when
    # the direct peer belongs to one of the explicitly configured proxy CIDRs.
    atlas_trust_proxy_headers: bool = False
    atlas_trusted_proxy_cidrs: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        case_sensitive=False,
    )

    @field_validator("atlas_database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: object) -> str:
        """Normaliza e valida a URL PostgreSQL usada pelo Atlas.

        A rotina usa o parser do próprio SQLAlchemy em vez de ``urllib``.
        Isso evita que caracteres reservados da senha sejam confundidos com
        sintaxe de host/IPv6 e permite hostnames DNS normais do Supavisor.

        Também:
        - converte ``postgres://`` e ``postgresql://`` para psycopg v3;
        - rejeita placeholders de senha antes do deploy;
        - remove parâmetros pertencentes a outros ORMs/clientes;
        - preserva parâmetros PostgreSQL válidos;
        - renderiza novamente credenciais com escaping seguro.
        """
        raw = str(value or "").strip()
        if not raw:
            return raw

        if raw.startswith("postgres://"):
            raw = "postgresql://" + raw[len("postgres://"):]

        if not raw.startswith(("postgresql://", "postgresql+")):
            return raw

        placeholder_markers = (
            "[YOUR-PASSWORD]",
            "YOUR-PASSWORD",
            "YOUR_PASSWORD",
            "<PASSWORD>",
            "CHANGE_ME_DATABASE_PASSWORD",
        )
        upper_raw = raw.upper()
        if any(marker in upper_raw for marker in placeholder_markers):
            raise ValueError(
                "ATLAS_DATABASE_URL ainda contém placeholder de senha. "
                "No Supabase, substitua [YOUR-PASSWORD] pela senha real "
                "antes de salvar a variável no Render."
            )

        try:
            parsed = make_url(raw)
        except (ArgumentError, ValueError) as exc:
            raise ValueError(
                "ATLAS_DATABASE_URL inválida. Use a connection string "
                "PostgreSQL do Supabase e, se a senha tiver caracteres "
                "reservados, mantenha o valor percent-encoded."
            ) from exc

        if parsed.get_backend_name() != "postgresql":
            return raw

        if parsed.drivername != "postgresql+psycopg":
            parsed = parsed.set(drivername="postgresql+psycopg")

        if not parsed.username:
            raise ValueError("ATLAS_DATABASE_URL não contém usuário PostgreSQL")
        if parsed.password in {None, ""}:
            raise ValueError("ATLAS_DATABASE_URL não contém senha PostgreSQL")
        if not parsed.host:
            raise ValueError("ATLAS_DATABASE_URL não contém host PostgreSQL")
        if not parsed.database:
            raise ValueError("ATLAS_DATABASE_URL não contém nome do banco")

        password_upper = str(parsed.password).upper()
        if any(marker in password_upper for marker in placeholder_markers):
            raise ValueError(
                "ATLAS_DATABASE_URL ainda contém placeholder de senha. "
                "Substitua-o pela senha real do banco Supabase."
            )

        # Parâmetros usados por Prisma/asyncpg/outros clientes e que não são
        # opções de conexão válidas para psycopg3.
        incompatible_query_keys = {
            "pgbouncer",
            "connection_limit",
            "pool_timeout",
            "statement_cache_size",
            "prepared_statements",
        }
        query = {
            key: item_value
            for key, item_value in parsed.query.items()
            if key.lower() not in incompatible_query_keys
        }
        parsed = parsed.set(query=query)

        return parsed.render_as_string(hide_password=False)

    @field_validator("atlas_public_base_url", mode="before")
    @classmethod
    def normalize_public_base_url(cls, value: object) -> str:
        configured = str(value or "").strip().rstrip("/")
        render_url = os.environ.get("RENDER_EXTERNAL_URL", "").strip().rstrip("/")

        # Se o serviço estiver no Render e a URL configurada também for um
        # endereço onrender.com, a URL fornecida pelo próprio runtime é a
        # autoridade. Isso evita hostname manual incorreto.
        if (
            render_url.startswith("https://")
            and configured.startswith("https://")
            and configured.lower().endswith(".onrender.com")
        ):
            return render_url

        return configured

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

    @model_validator(mode="after")
    def validate_whatsapp_provider(self) -> "Settings":
        if not self.atlas_whatsapp_enabled:
            return self

        missing = [
            name
            for name, value in (
                ("ATLAS_WHATSAPP_ACCESS_TOKEN", self.atlas_whatsapp_access_token),
                ("ATLAS_WHATSAPP_PHONE_NUMBER_ID", self.atlas_whatsapp_phone_number_id),
                ("ATLAS_WHATSAPP_GRAPH_VERSION", self.atlas_whatsapp_graph_version),
                (
                    "ATLAS_WHATSAPP_TEMPLATE_ZOOTECHNICAL",
                    self.atlas_whatsapp_template_zootechnical,
                ),
                (
                    "ATLAS_WHATSAPP_TEMPLATE_OPERATIONS",
                    self.atlas_whatsapp_template_operations,
                ),
                (
                    "ATLAS_WHATSAPP_TEMPLATE_FINANCIAL",
                    self.atlas_whatsapp_template_financial,
                ),
                (
                    "ATLAS_WHATSAPP_WEBHOOK_VERIFY_TOKEN",
                    self.atlas_whatsapp_webhook_verify_token,
                ),
                (
                    "ATLAS_WHATSAPP_APP_SECRET",
                    self.atlas_whatsapp_app_secret,
                ),
            )
            if not value.strip()
        ]
        if missing:
            raise ValueError(
                "WhatsApp automático ativado sem configuração completa: "
                + ", ".join(missing)
            )

        version = self.atlas_whatsapp_graph_version.strip()
        if not re.fullmatch(r"v\d+\.\d+", version):
            raise ValueError(
                "ATLAS_WHATSAPP_GRAPH_VERSION deve usar o formato vNN.N."
            )
        return self

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

        self._validate_database_contract()

        if self._secret_is_weak(self.atlas_jwt_secret, minimum=32):
            raise ValueError(
                "ATLAS_JWT_SECRET deve ter ao menos 32 caracteres "
                "e não pode conter marcador inseguro/padrão"
            )

        if self.atlas_bootstrap_enabled:
            raise ValueError(
                "ATLAS_BOOTSTRAP_ENABLED deve ser false em staging/production"
            )

        if self.atlas_auth_diagnostic_enabled:
            email = self.atlas_auth_diagnostic_email.strip().lower()
            password = self.atlas_auth_diagnostic_password
            if "@" not in email:
                raise ValueError(
                    "ATLAS_AUTH_DIAGNOSTIC_EMAIL deve ser um e-mail válido"
                )
            if not password:
                raise ValueError(
                    "ATLAS_AUTH_DIAGNOSTIC_PASSWORD é obrigatório quando "
                    "ATLAS_AUTH_DIAGNOSTIC_ENABLED=true"
                )

        if self.atlas_reset_admin_password_once:
            email = self.atlas_reset_admin_email.strip().lower()
            password = self.atlas_reset_admin_password
            if "@" not in email:
                raise ValueError(
                    "ATLAS_RESET_ADMIN_EMAIL deve ser um e-mail válido"
                )
            if self._secret_is_weak(password, minimum=12):
                raise ValueError(
                    "ATLAS_RESET_ADMIN_PASSWORD deve ter ao menos "
                    "12 caracteres e não pode usar valor inseguro"
                )

        if self.atlas_provision_admin_once:
            email = self.atlas_provision_admin_email.strip().lower()
            password = self.atlas_provision_admin_password
            company_name = self.atlas_provision_company_name.strip()

            if "@" not in email or "." not in email.rsplit("@", 1)[-1]:
                raise ValueError(
                    "ATLAS_PROVISION_ADMIN_EMAIL deve ser um e-mail válido"
                )

            if self._secret_is_weak(password, minimum=12):
                raise ValueError(
                    "ATLAS_PROVISION_ADMIN_PASSWORD deve ter ao menos "
                    "12 caracteres e não pode usar valor padrão/inseguro"
                )

            if len(company_name) < 2:
                raise ValueError(
                    "ATLAS_PROVISION_COMPANY_NAME é obrigatório quando "
                    "ATLAS_PROVISION_ADMIN_ONCE=true"
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

    def _validate_database_contract(self) -> None:
        try:
            parsed = make_url(self.atlas_database_url)
        except (ArgumentError, ValueError) as exc:
            raise ValueError("ATLAS_DATABASE_URL PostgreSQL inválida") from exc

        if parsed.drivername != "postgresql+psycopg":
            raise ValueError(
                "ATLAS_DATABASE_URL deve usar o driver psycopg3 em produção"
            )

        host = (parsed.host or "").strip().lower()
        if not host:
            raise ValueError("ATLAS_DATABASE_URL exige host PostgreSQL")

        # Hostname DNS é válido. O erro anterior que citava IPv4/IPv6 era
        # causado pelos colchetes do placeholder [YOUR-PASSWORD], não pelo
        # hostname do Supabase.
        if host in {"localhost", "127.0.0.1", "::1"}:
            raise ValueError(
                "ATLAS_DATABASE_URL não pode apontar para banco local "
                "em staging/production"
            )

        if host.endswith(".pooler.supabase.com"):
            port = parsed.port or 5432
            if port not in {5432, 6543}:
                raise ValueError(
                    "Pooler Supabase deve usar porta 5432 (Session) "
                    "ou 6543 (Transaction)"
                )

    @property
    def database_target(self) -> str:
        """Destino do banco sem senha, seguro para logs."""
        try:
            parsed = make_url(self.atlas_database_url)
        except Exception:
            return "database-url-invalid"

        username = parsed.username or "?"
        host = parsed.host or "?"
        port = parsed.port or 5432
        database = parsed.database or "?"
        return f"{username}@{host}:{port}/{database}"

    @property
    def is_supabase_transaction_pooler(self) -> bool:
        try:
            parsed = make_url(self.atlas_database_url)
        except Exception:
            return False
        return (
            (parsed.host or "").lower().endswith(".pooler.supabase.com")
            and parsed.port == 6543
        )

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
        origins = [
            item.strip().rstrip("/")
            for item in self.atlas_cors_origins.split(",")
            if item.strip()
        ]

        render_url = os.environ.get("RENDER_EXTERNAL_URL", "").strip().rstrip("/")
        if render_url.startswith("https://") and render_url not in origins:
            origins.append(render_url)

        return origins

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
