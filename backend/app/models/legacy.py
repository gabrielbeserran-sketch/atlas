from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Float,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def new_id(prefix: str) -> str:
    return f"{prefix}_{uuid4().hex}"


class Company(Base):
    __tablename__ = "companies"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("company")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(180))
    document: Mapped[str] = mapped_column(String(40), default="")
    status: Mapped[str] = mapped_column(String(30), default="active")
    subscription_plan: Mapped[str] = mapped_column(
        String(50), default="enterprise"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("user")
    )
    name: Mapped[str] = mapped_column(String(180))
    email: Mapped[str] = mapped_column(String(180), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    failed_login_attempts: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    password_changed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class Membership(Base):
    __tablename__ = "memberships"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "company_id",
            name="uq_membership_user_company",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("membership")
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    company_id: Mapped[str] = mapped_column(
        ForeignKey("companies.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(50), default="viewer")
    permission_overrides: Mapped[dict] = mapped_column(JSON, default=dict)
    farm_ids: Mapped[list] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )

    user: Mapped[User] = relationship()
    company: Mapped[Company] = relationship()


class Farm(Base):
    __tablename__ = "farms"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "name",
            name="uq_farm_company_name",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("farm")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(
        ForeignKey("companies.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(180))
    city: Mapped[str] = mapped_column(String(120), default="")
    state: Mapped[str] = mapped_column(String(80), default="")
    animals: Mapped[int] = mapped_column(Integer, default=0)
    area: Mapped[int] = mapped_column(Integer, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class EntityState(Base):
    __tablename__ = "entity_states"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "entity_type",
            "entity_id",
            name="uq_entity_state_company_entity",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("entity")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    entity_type: Mapped[str] = mapped_column(String(80), index=True)
    entity_id: Mapped[str] = mapped_column(String(120), index=True)
    version: Mapped[int] = mapped_column(Integer, default=0)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    deleted: Mapped[bool] = mapped_column(Boolean, default=False)
    updated_by: Mapped[str] = mapped_column(String(80))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class SyncChange(Base):
    __tablename__ = "sync_changes"

    cursor: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    entity_type: Mapped[str] = mapped_column(String(80))
    entity_id: Mapped[str] = mapped_column(String(120))
    version: Mapped[int] = mapped_column(Integer)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    deleted: Mapped[bool] = mapped_column(Boolean, default=False)
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class ProcessedOperation(Base):
    __tablename__ = "processed_operations"

    idempotency_key: Mapped[str] = mapped_column(
        String(255), primary_key=True
    )
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    operation_id: Mapped[str] = mapped_column(String(120))
    result_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    processed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("audit")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    user_id: Mapped[str] = mapped_column(String(80), index=True)
    action: Mapped[str] = mapped_column(String(80))
    module: Mapped[str] = mapped_column(String(80))
    entity_type: Mapped[str] = mapped_column(String(80))
    entity_id: Mapped[str] = mapped_column(String(120))
    description: Mapped[str] = mapped_column(Text, default="")
    before: Mapped[dict] = mapped_column(JSON, default=dict)
    after: Mapped[dict] = mapped_column(JSON, default=dict)
    result: Mapped[str] = mapped_column(String(30), default="success")
    justification: Mapped[str] = mapped_column(Text, default="")
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )

class EmailVerificationToken(Base):
    __tablename__ = "email_verification_tokens"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("email_verify")
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class RefreshSession(Base):
    __tablename__ = "refresh_sessions"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("session")
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    company_id: Mapped[str] = mapped_column(
        ForeignKey("companies.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    device_name: Mapped[str] = mapped_column(String(180), default="")
    ip_address: Mapped[str] = mapped_column(String(80), default="")
    user_agent: Mapped[str] = mapped_column(String(500), default="")
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("password_reset")
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )


class MfaCredential(Base):
    __tablename__ = "mfa_credentials"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("mfa")
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True
    )
    secret_encrypted: Mapped[str] = mapped_column(String(255))
    recovery_code_hashes: Mapped[list] = mapped_column(JSON, default=list)
    enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class SecurityEvent(Base):
    __tablename__ = "security_events"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("security_event")
    )
    user_id: Mapped[str | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    company_id: Mapped[str | None] = mapped_column(
        ForeignKey("companies.id", ondelete="SET NULL"), nullable=True, index=True
    )
    event_type: Mapped[str] = mapped_column(String(100), index=True)
    success: Mapped[bool] = mapped_column(Boolean, default=True)
    ip_address: Mapped[str] = mapped_column(String(80), default="")
    user_agent: Mapped[str] = mapped_column(String(500), default="")
    details: Mapped[dict] = mapped_column(JSON, default=dict)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class HerdLot(Base):
    __tablename__ = "herd_lots"
    __table_args__ = (
        UniqueConstraint("company_id", "farm_id", "name", name="uq_lot_company_farm_name"),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("lot"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(180))
    category: Mapped[str] = mapped_column(String(100), default="")
    status: Mapped[str] = mapped_column(String(40), default="active")
    capacity: Mapped[int] = mapped_column(Integer, default=0)
    paddock: Mapped[str] = mapped_column(String(180), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)



class Paddock(Base):
    __tablename__ = "paddocks"
    __table_args__ = (
        UniqueConstraint("company_id", "farm_id", "name", name="uq_paddock_company_farm_name"),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("paddock"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(180))
    area: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(60), default="Descanso")
    animals: Mapped[int] = mapped_column(Integer, default=0)
    notes: Mapped[str] = mapped_column(Text, default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class LivestockAnimal(Base):
    __tablename__ = "livestock_animals"
    __table_args__ = (
        UniqueConstraint("company_id", "tag", name="uq_animal_company_tag"),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("animal"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    lot_id: Mapped[str | None] = mapped_column(ForeignKey("herd_lots.id", ondelete="SET NULL"), nullable=True, index=True)
    tag: Mapped[str] = mapped_column(String(120), index=True)
    sisbov: Mapped[str] = mapped_column(String(120), default="")
    name: Mapped[str] = mapped_column(String(180), default="")
    sex: Mapped[str] = mapped_column(String(30), default="")
    breed: Mapped[str] = mapped_column(String(100), default="")
    category: Mapped[str] = mapped_column(String(100), default="")
    birth_date: Mapped[str] = mapped_column(String(20), default="")
    status: Mapped[str] = mapped_column(String(40), default="active")
    current_weight: Mapped[float] = mapped_column(Float, default=0)
    body_condition_score: Mapped[float] = mapped_column(Float, default=0)
    mother_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    father_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    reproductive_status: Mapped[str] = mapped_column(String(60), default="unknown", index=True)
    last_reproduction_event_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expected_calving_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AnimalMedia(Base):
    __tablename__ = "animal_media"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "animal_id",
            "kind",
            "id",
            name="uq_animal_media_company_animal_kind_id",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80),
        primary_key=True,
        default=lambda: new_id("media"),
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(
        ForeignKey("companies.id", ondelete="CASCADE"),
        index=True,
    )
    farm_id: Mapped[str] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"),
        index=True,
    )
    animal_id: Mapped[str] = mapped_column(
        ForeignKey("livestock_animals.id", ondelete="CASCADE"),
        index=True,
    )
    kind: Mapped[str] = mapped_column(String(30), index=True)
    original_filename: Mapped[str] = mapped_column(String(255), default="")
    content_type: Mapped[str] = mapped_column(String(160), default="")
    size_bytes: Mapped[int] = mapped_column(Integer, default=0)
    sha256: Mapped[str] = mapped_column(String(64), default="", index=True)
    storage_key: Mapped[str] = mapped_column(String(700), default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_by: Mapped[str] = mapped_column(String(80), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AnimalMovement(Base):
    __tablename__ = "animal_movements"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("movement"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    animal_id: Mapped[str] = mapped_column(ForeignKey("livestock_animals.id", ondelete="CASCADE"), index=True)
    movement_type: Mapped[str] = mapped_column(String(60), index=True)
    from_lot_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    to_lot_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    reason: Mapped[str] = mapped_column(Text, default="")
    document_reference: Mapped[str] = mapped_column(String(180), default="")
    created_by: Mapped[str] = mapped_column(String(80))


class WeightRecord(Base):
    __tablename__ = "weight_records"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("weight"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    animal_id: Mapped[str] = mapped_column(ForeignKey("livestock_animals.id", ondelete="CASCADE"), index=True)
    weight: Mapped[float] = mapped_column(Float)
    body_condition_score: Mapped[float] = mapped_column(Float, default=0)
    source: Mapped[str] = mapped_column(String(100), default="")
    equipment: Mapped[str] = mapped_column(String(120), default="")
    measured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_by: Mapped[str] = mapped_column(String(80))


class ReproductionEvent(Base):
    __tablename__ = "reproduction_events"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("reproduction"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    animal_id: Mapped[str] = mapped_column(ForeignKey("livestock_animals.id", ondelete="CASCADE"), index=True)
    event_type: Mapped[str] = mapped_column(String(80), index=True)
    event_code: Mapped[str] = mapped_column(String(50), default="observation", index=True)
    protocol_name: Mapped[str] = mapped_column(String(180), default="")
    protocol_stage: Mapped[str] = mapped_column(String(120), default="")
    sire_reference: Mapped[str] = mapped_column(String(180), default="")
    result: Mapped[str] = mapped_column(String(100), default="")
    reproductive_status: Mapped[str] = mapped_column(String(60), default="")
    responsible: Mapped[str] = mapped_column(String(180), default="")
    attempt_number: Mapped[int] = mapped_column(Integer, default=0)
    pregnancy_days: Mapped[int] = mapped_column(Integer, default=0)
    calf_id: Mapped[str] = mapped_column(String(80), default="")
    calf_sex: Mapped[str] = mapped_column(String(30), default="")
    birth_type: Mapped[str] = mapped_column(String(60), default="")
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    expected_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_by: Mapped[str] = mapped_column(String(80))


class HealthEvent(Base):
    __tablename__ = "health_events"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("health"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    animal_id: Mapped[str | None] = mapped_column(ForeignKey("livestock_animals.id", ondelete="CASCADE"), nullable=True, index=True)
    lot_id: Mapped[str | None] = mapped_column(ForeignKey("herd_lots.id", ondelete="CASCADE"), nullable=True, index=True)
    event_type: Mapped[str] = mapped_column(String(80), index=True)
    product_name: Mapped[str] = mapped_column(String(180), default="")
    dosage: Mapped[str] = mapped_column(String(80), default="")
    route: Mapped[str] = mapped_column(String(80), default="")
    withdrawal_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    responsible: Mapped[str] = mapped_column(String(180), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    protocol_name: Mapped[str] = mapped_column(String(180), default="")
    product_batch: Mapped[str] = mapped_column(String(120), default="")
    frequency: Mapped[str] = mapped_column(String(120), default="")
    diagnosis: Mapped[str] = mapped_column(String(240), default="")
    severity: Mapped[str] = mapped_column(String(40), default="not_informed")
    next_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    status: Mapped[str] = mapped_column(String(40), default="completed", index=True)
    is_quarantine: Mapped[bool] = mapped_column(Boolean, default=False)
    is_mortality: Mapped[bool] = mapped_column(Boolean, default=False)
    necropsy_result: Mapped[str] = mapped_column(Text, default="")
    inventory_product_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    inventory_quantity: Mapped[float] = mapped_column(Float, default=0)
    treatment_cost: Mapped[float] = mapped_column(Float, default=0)
    withdrawal_meat_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    withdrawal_milk_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    created_by: Mapped[str] = mapped_column(String(80))


class HealthProtocol(Base):
    __tablename__ = "health_protocols"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("health_protocol"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    event_type: Mapped[str] = mapped_column(String(80), default="protocol")
    product_name: Mapped[str] = mapped_column(String(180), default="")
    dosage: Mapped[str] = mapped_column(String(80), default="")
    route: Mapped[str] = mapped_column(String(80), default="")
    recurrence_days: Mapped[int] = mapped_column(Integer, default=0)
    withdrawal_meat_days: Mapped[int] = mapped_column(Integer, default=0)
    withdrawal_milk_days: Mapped[int] = mapped_column(Integer, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class InventoryProduct(Base):
    __tablename__ = "inventory_products"
    __table_args__ = (UniqueConstraint("company_id", "sku", name="uq_inventory_company_sku"),)

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("product"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    sku: Mapped[str] = mapped_column(String(120))
    name: Mapped[str] = mapped_column(String(180))
    category: Mapped[str] = mapped_column(String(100), default="")
    unit: Mapped[str] = mapped_column(String(40), default="un")
    quantity: Mapped[float] = mapped_column(Float, default=0)
    minimum_quantity: Mapped[float] = mapped_column(Float, default=0)
    maximum_quantity: Mapped[float] = mapped_column(Float, default=0)
    average_cost: Mapped[float] = mapped_column(Float, default=0)
    last_purchase_cost: Mapped[float] = mapped_column(Float, default=0)
    expiry_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    manufacturing_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    batch_number: Mapped[str] = mapped_column(String(120), default="")
    supplier: Mapped[str] = mapped_column(String(180), default="")
    storage_location: Mapped[str] = mapped_column(String(180), default="")
    active_ingredient: Mapped[str] = mapped_column(String(180), default="")
    barcode: Mapped[str] = mapped_column(String(120), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("stock_move"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    product_id: Mapped[str] = mapped_column(ForeignKey("inventory_products.id", ondelete="CASCADE"), index=True)
    movement_type: Mapped[str] = mapped_column(String(40), index=True)
    quantity: Mapped[float] = mapped_column(Float)
    unit_cost: Mapped[float] = mapped_column(Float, default=0)
    balance_after: Mapped[float] = mapped_column(Float, default=0)
    reason: Mapped[str] = mapped_column(String(255), default="")
    document_number: Mapped[str] = mapped_column(String(120), default="")
    product_batch: Mapped[str] = mapped_column(String(120), default="")
    reference_type: Mapped[str] = mapped_column(String(80), default="")
    reference_id: Mapped[str] = mapped_column(String(120), default="")
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    created_by: Mapped[str] = mapped_column(String(80))


class FinancialEntry(Base):
    __tablename__ = "financial_entries"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("finance"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    animal_id: Mapped[str | None] = mapped_column(ForeignKey("livestock_animals.id", ondelete="SET NULL"), nullable=True, index=True)
    lot_id: Mapped[str | None] = mapped_column(ForeignKey("herd_lots.id", ondelete="SET NULL"), nullable=True, index=True)
    entry_type: Mapped[str] = mapped_column(String(30), index=True)
    category: Mapped[str] = mapped_column(String(100), default="")
    cost_center: Mapped[str] = mapped_column(String(120), default="Geral", index=True)
    description: Mapped[str] = mapped_column(String(255))
    amount: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(40), default="pending", index=True)
    competence_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    due_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    payment_method: Mapped[str] = mapped_column(String(80), default="")
    counterparty: Mapped[str] = mapped_column(String(180), default="")
    document_number: Mapped[str] = mapped_column(String(120), default="")
    recurring: Mapped[bool] = mapped_column(Boolean, default=False)
    recurrence_rule: Mapped[str] = mapped_column(String(120), default="")
    reference_type: Mapped[str] = mapped_column(String(80), default="")
    reference_id: Mapped[str] = mapped_column(String(120), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    created_by: Mapped[str] = mapped_column(String(80))


class NutritionIngredient(Base):
    __tablename__ = "nutrition_ingredients"
    __table_args__ = (UniqueConstraint("company_id", "farm_id", "name", name="uq_nutrition_ingredient_farm_name"),)

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("ingredient"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    inventory_product_id: Mapped[str | None] = mapped_column(ForeignKey("inventory_products.id", ondelete="SET NULL"), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(180))
    category: Mapped[str] = mapped_column(String(100), default="other")
    unit: Mapped[str] = mapped_column(String(40), default="kg")
    dry_matter_percent: Mapped[float] = mapped_column(Float, default=0)
    crude_protein_percent: Mapped[float] = mapped_column(Float, default=0)
    ndf_percent: Mapped[float] = mapped_column(Float, default=0)
    adf_percent: Mapped[float] = mapped_column(Float, default=0)
    tdn_percent: Mapped[float] = mapped_column(Float, default=0)
    cost_per_kg: Mapped[float] = mapped_column(Float, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class NutritionPlan(Base):
    __tablename__ = "nutrition_plans"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("diet"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    lot_id: Mapped[str] = mapped_column(ForeignKey("herd_lots.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(180))
    category: Mapped[str] = mapped_column(String(100), default="")
    start_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    end_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    daily_amount_per_animal_kg: Mapped[float] = mapped_column(Float, default=0)
    animal_count: Mapped[int] = mapped_column(Integer, default=0)
    average_body_weight_kg: Mapped[float] = mapped_column(Float, default=0)
    target_daily_gain_kg: Mapped[float] = mapped_column(Float, default=0)
    dry_matter_percent: Mapped[float] = mapped_column(Float, default=0)
    crude_protein_percent: Mapped[float] = mapped_column(Float, default=0)
    ndf_percent: Mapped[float] = mapped_column(Float, default=0)
    tdn_percent: Mapped[float] = mapped_column(Float, default=0)
    cost_per_kg: Mapped[float] = mapped_column(Float, default=0)
    ingredients_json: Mapped[list] = mapped_column(JSON, default=list)
    stock_integration_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    inventory_deducted: Mapped[bool] = mapped_column(Boolean, default=False)
    inventory_deduction_cost: Mapped[float] = mapped_column(Float, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_by: Mapped[str] = mapped_column(String(80))


class NutritionEvent(Base):
    __tablename__ = "nutrition_events"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("nutrition"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    lot_id: Mapped[str] = mapped_column(ForeignKey("herd_lots.id", ondelete="CASCADE"), index=True)
    nutrition_plan_id: Mapped[str | None] = mapped_column(ForeignKey("nutrition_plans.id", ondelete="SET NULL"), nullable=True, index=True)
    product_id: Mapped[str | None] = mapped_column(ForeignKey("inventory_products.id", ondelete="SET NULL"), nullable=True)
    diet_name: Mapped[str] = mapped_column(String(180))
    amount_per_animal: Mapped[float] = mapped_column(Float, default=0)
    animal_count: Mapped[int] = mapped_column(Integer, default=0)
    total_quantity: Mapped[float] = mapped_column(Float, default=0)
    planned_quantity: Mapped[float] = mapped_column(Float, default=0)
    estimated_cost: Mapped[float] = mapped_column(Float, default=0)
    observed_daily_gain_kg: Mapped[float] = mapped_column(Float, default=0)
    feed_conversion: Mapped[float] = mapped_column(Float, default=0)
    notes: Mapped[str] = mapped_column(Text, default="")
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    created_by: Mapped[str] = mapped_column(String(80))

class OperationalAlert(Base):
    __tablename__ = "operational_alerts"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("alert")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    alert_type: Mapped[str] = mapped_column(String(100), index=True)
    severity: Mapped[str] = mapped_column(String(30), default="medium", index=True)
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text, default="")
    entity_type: Mapped[str] = mapped_column(String(80), default="")
    entity_id: Mapped[str] = mapped_column(String(120), default="")
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    generated_by: Mapped[str] = mapped_column(String(100), default="atlas")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class OperationalTask(Base):
    __tablename__ = "operational_tasks"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("task")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    source_type: Mapped[str] = mapped_column(String(80), default="")
    source_id: Mapped[str] = mapped_column(String(120), default="")
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text, default="")
    responsible_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    priority: Mapped[str] = mapped_column(String(30), default="medium")
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    evidence: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class IndicatorSnapshot(Base):
    __tablename__ = "indicator_snapshots"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("indicator")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    indicator_key: Mapped[str] = mapped_column(String(120), index=True)
    indicator_name: Mapped[str] = mapped_column(String(180))
    value: Mapped[float] = mapped_column(Float)
    unit: Mapped[str] = mapped_column(String(40), default="")
    formula: Mapped[str] = mapped_column(Text, default="")
    source_tables: Mapped[list] = mapped_column(JSON, default=list)
    period_start: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    filters: Mapped[dict] = mapped_column(JSON, default=dict)
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class AnalyticsDimensionDate(Base):
    __tablename__ = "analytics_dimension_date"

    id: Mapped[str] = mapped_column(String(20), primary_key=True)
    full_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), unique=True, index=True)
    year: Mapped[int] = mapped_column(Integer, index=True)
    quarter: Mapped[int] = mapped_column(Integer)
    month: Mapped[int] = mapped_column(Integer, index=True)
    month_name: Mapped[str] = mapped_column(String(30))
    week: Mapped[int] = mapped_column(Integer)
    day: Mapped[int] = mapped_column(Integer)
    day_of_week: Mapped[int] = mapped_column(Integer)
    is_month_end: Mapped[bool] = mapped_column(Boolean, default=False)


class AnalyticsFactSnapshot(Base):
    __tablename__ = "analytics_fact_snapshots"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "farm_id",
            "metric_key",
            "period_start",
            "period_end",
            name="uq_analytics_fact_period",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("analytics_fact")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    lot_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    metric_key: Mapped[str] = mapped_column(String(120), index=True)
    metric_name: Mapped[str] = mapped_column(String(180))
    metric_group: Mapped[str] = mapped_column(String(80), index=True)
    value: Mapped[float] = mapped_column(Float)
    unit: Mapped[str] = mapped_column(String(40), default="")
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    dimensions: Mapped[dict] = mapped_column(JSON, default=dict)
    source_tables: Mapped[list] = mapped_column(JSON, default=list)
    formula: Mapped[str] = mapped_column(Text, default="")
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class AnalyticsKpiDefinition(Base):
    __tablename__ = "analytics_kpi_definitions"
    __table_args__ = (
        UniqueConstraint("company_id", "key", name="uq_analytics_kpi_company_key"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("analytics_kpi")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    key: Mapped[str] = mapped_column(String(120))
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    metric_group: Mapped[str] = mapped_column(String(80), index=True)
    formula: Mapped[str] = mapped_column(Text)
    unit: Mapped[str] = mapped_column(String(40), default="")
    target_direction: Mapped[str] = mapped_column(String(30), default="higher")
    warning_threshold: Mapped[float | None] = mapped_column(Float, nullable=True)
    critical_threshold: Mapped[float | None] = mapped_column(Float, nullable=True)
    weight: Mapped[float] = mapped_column(Float, default=1)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AnalyticsGoal(Base):
    __tablename__ = "analytics_goals"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("analytics_goal")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    kpi_key: Mapped[str] = mapped_column(String(120), index=True)
    title: Mapped[str] = mapped_column(String(220))
    baseline_value: Mapped[float] = mapped_column(Float, default=0)
    target_value: Mapped[float] = mapped_column(Float)
    current_value: Mapped[float] = mapped_column(Float, default=0)
    start_date: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    due_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    responsible_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AnalyticsBenchmarkSnapshot(Base):
    __tablename__ = "analytics_benchmark_snapshots"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("benchmark")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    metric_key: Mapped[str] = mapped_column(String(120), index=True)
    value: Mapped[float] = mapped_column(Float)
    percentile: Mapped[float] = mapped_column(Float, default=0)
    rank_position: Mapped[int] = mapped_column(Integer, default=0)
    peer_count: Mapped[int] = mapped_column(Integer, default=0)
    peer_group: Mapped[str] = mapped_column(String(120), default="company")
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AnalyticsFarmScore(Base):
    __tablename__ = "analytics_farm_scores"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("farm_score")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    score: Mapped[float] = mapped_column(Float)
    grade: Mapped[str] = mapped_column(String(10))
    component_scores: Mapped[dict] = mapped_column(JSON, default=dict)
    explanations: Mapped[list] = mapped_column(JSON, default=list)
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasAiConversation(Base):
    __tablename__ = "atlas_ai_conversations"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_conversation")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    user_id: Mapped[str] = mapped_column(String(80), index=True)
    title: Mapped[str] = mapped_column(String(220), default="Nova conversa")
    specialist_area: Mapped[str] = mapped_column(String(80), default="general", index=True)
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    context_snapshot: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AtlasAiMessage(Base):
    __tablename__ = "atlas_ai_messages"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_message")
    )
    conversation_id: Mapped[str] = mapped_column(
        ForeignKey("atlas_ai_conversations.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(30), index=True)
    content: Mapped[str] = mapped_column(Text)
    structured_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    sources: Mapped[list] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class AtlasAiOperationalRecommendation(Base):
    __tablename__ = "atlas_ai_recommendations"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_recommendation")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    animal_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    area: Mapped[str] = mapped_column(String(80), index=True)
    recommendation_type: Mapped[str] = mapped_column(String(100), index=True)
    title: Mapped[str] = mapped_column(String(220))
    summary: Mapped[str] = mapped_column(Text)
    rationale: Mapped[str] = mapped_column(Text)
    action_items: Mapped[list] = mapped_column(JSON, default=list)
    evidence: Mapped[list] = mapped_column(JSON, default=list)
    assumptions: Mapped[list] = mapped_column(JSON, default=list)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    priority: Mapped[str] = mapped_column(String(30), default="medium", index=True)
    financial_impact: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    generated_by: Mapped[str] = mapped_column(String(120), default="atlas_rule_engine")
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    reviewed_by: Mapped[str | None] = mapped_column(String(80), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AtlasAiExecution(Base):
    __tablename__ = "atlas_ai_executions"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_execution")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    area: Mapped[str] = mapped_column(String(80), index=True)
    engine_version: Mapped[str] = mapped_column(String(60), default="2.0")
    input_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    output_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    success: Mapped[bool] = mapped_column(Boolean, default=True)
    error_message: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class RealtimeNotification(Base):
    __tablename__ = "realtime_notifications"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("notification")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    user_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    channel: Mapped[str] = mapped_column(String(40), default="in_app", index=True)
    category: Mapped[str] = mapped_column(String(80), index=True)
    severity: Mapped[str] = mapped_column(String(30), default="info", index=True)
    title: Mapped[str] = mapped_column(String(220))
    message: Mapped[str] = mapped_column(Text)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    deduplication_key: Mapped[str] = mapped_column(String(180), default="", index=True)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class RealtimeEvent(Base):
    __tablename__ = "realtime_events"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("realtime_event")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    topic: Mapped[str] = mapped_column(String(120), index=True)
    event_type: Mapped[str] = mapped_column(String(120), index=True)
    entity_type: Mapped[str] = mapped_column(String(100), default="")
    entity_id: Mapped[str] = mapped_column(String(120), default="")
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    correlation_id: Mapped[str] = mapped_column(String(120), default="", index=True)
    source: Mapped[str] = mapped_column(String(120), default="atlas")
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class RealtimeSubscription(Base):
    __tablename__ = "realtime_subscriptions"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("subscription")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    user_id: Mapped[str] = mapped_column(String(80), index=True)
    topic: Mapped[str] = mapped_column(String(120), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    minimum_severity: Mapped[str] = mapped_column(String(30), default="info")
    channels: Mapped[list] = mapped_column(JSON, default=lambda: ["in_app"])
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class IotGateway(Base):
    __tablename__ = "iot_gateways"
    __table_args__ = (
        UniqueConstraint("company_id", "external_id", name="uq_iot_gateway_external_id"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("iot_gateway")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    external_id: Mapped[str] = mapped_column(String(120), index=True)
    name: Mapped[str] = mapped_column(String(180))
    protocol: Mapped[str] = mapped_column(String(40), default="mqtt")
    status: Mapped[str] = mapped_column(String(30), default="offline", index=True)
    firmware_version: Mapped[str] = mapped_column(String(80), default="")
    ip_address: Mapped[str] = mapped_column(String(80), default="")
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    reproductive_status: Mapped[str] = mapped_column(String(60), default="unknown", index=True)
    last_reproduction_event_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expected_calving_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class IotDevice(Base):
    __tablename__ = "iot_devices"
    __table_args__ = (
        UniqueConstraint("company_id", "external_id", name="uq_iot_device_external_id"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("iot_device")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    gateway_id: Mapped[str | None] = mapped_column(
        ForeignKey("iot_gateways.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    external_id: Mapped[str] = mapped_column(String(120), index=True)
    name: Mapped[str] = mapped_column(String(180))
    device_type: Mapped[str] = mapped_column(String(80), index=True)
    model: Mapped[str] = mapped_column(String(120), default="")
    manufacturer: Mapped[str] = mapped_column(String(120), default="")
    status: Mapped[str] = mapped_column(String(30), default="offline", index=True)
    battery_percent: Mapped[float | None] = mapped_column(Float, nullable=True)
    signal_strength: Mapped[float | None] = mapped_column(Float, nullable=True)
    animal_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    lot_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    installed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    configuration: Mapped[dict] = mapped_column(JSON, default=dict)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class IotTelemetry(Base):
    __tablename__ = "iot_telemetry"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("iot_telemetry")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    device_id: Mapped[str] = mapped_column(
        ForeignKey("iot_devices.id", ondelete="CASCADE"),
        index=True,
    )
    metric_key: Mapped[str] = mapped_column(String(120), index=True)
    value: Mapped[float] = mapped_column(Float)
    unit: Mapped[str] = mapped_column(String(40), default="")
    quality: Mapped[str] = mapped_column(String(30), default="good")
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )
    received_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class IotCommand(Base):
    __tablename__ = "iot_commands"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("iot_command")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    device_id: Mapped[str] = mapped_column(
        ForeignKey("iot_devices.id", ondelete="CASCADE"),
        index=True,
    )
    command_type: Mapped[str] = mapped_column(String(100), index=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    requested_by: Mapped[str] = mapped_column(String(80))
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    result_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    error_message: Mapped[str] = mapped_column(Text, default="")


class IotAutomationRule(Base):
    __tablename__ = "iot_automation_rules"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("iot_rule")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    metric_key: Mapped[str] = mapped_column(String(120), index=True)
    operator: Mapped[str] = mapped_column(String(20))
    threshold: Mapped[float] = mapped_column(Float)
    severity: Mapped[str] = mapped_column(String(30), default="warning")
    action_type: Mapped[str] = mapped_column(String(80), default="notification")
    action_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialCustomer(Base):
    __tablename__ = "commercial_customers"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("customer")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    document: Mapped[str] = mapped_column(String(40), default="", index=True)
    email: Mapped[str] = mapped_column(String(180), default="", index=True)
    phone: Mapped[str] = mapped_column(String(40), default="")
    customer_type: Mapped[str] = mapped_column(String(40), default="producer")
    status: Mapped[str] = mapped_column(String(30), default="lead", index=True)
    source: Mapped[str] = mapped_column(String(80), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialOpportunity(Base):
    __tablename__ = "commercial_opportunities"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("opportunity")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    customer_id: Mapped[str] = mapped_column(
        ForeignKey("commercial_customers.id", ondelete="CASCADE"),
        index=True,
    )
    title: Mapped[str] = mapped_column(String(220))
    stage: Mapped[str] = mapped_column(String(40), default="qualification", index=True)
    estimated_value: Mapped[float] = mapped_column(Float, default=0)
    probability_percent: Mapped[float] = mapped_column(Float, default=0)
    expected_close_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    responsible_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    loss_reason: Mapped[str] = mapped_column(Text, default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialProposal(Base):
    __tablename__ = "commercial_proposals"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("proposal")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    customer_id: Mapped[str] = mapped_column(
        ForeignKey("commercial_customers.id", ondelete="CASCADE"),
        index=True,
    )
    opportunity_id: Mapped[str | None] = mapped_column(
        ForeignKey("commercial_opportunities.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text, default="")
    items: Mapped[list] = mapped_column(JSON, default=list)
    subtotal: Mapped[float] = mapped_column(Float, default=0)
    discount: Mapped[float] = mapped_column(Float, default=0)
    total: Mapped[float] = mapped_column(Float, default=0)
    valid_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="draft", index=True)
    created_by: Mapped[str] = mapped_column(String(80))
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    rejected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialContract(Base):
    __tablename__ = "commercial_contracts"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("contract")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    customer_id: Mapped[str] = mapped_column(
        ForeignKey("commercial_customers.id", ondelete="CASCADE"),
        index=True,
    )
    proposal_id: Mapped[str | None] = mapped_column(
        ForeignKey("commercial_proposals.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(220))
    terms: Mapped[str] = mapped_column(Text)
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    end_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="draft", index=True)
    signed_by_customer_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    signed_by_company_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    signature_metadata: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialPlan(Base):
    __tablename__ = "commercial_plans"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_commercial_plan_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("plan")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    billing_cycle: Mapped[str] = mapped_column(String(30), default="monthly")
    price: Mapped[float] = mapped_column(Float, default=0)
    limits: Mapped[dict] = mapped_column(JSON, default=dict)
    features: Mapped[list] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialSubscription(Base):
    __tablename__ = "commercial_subscriptions"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("subscription")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    customer_id: Mapped[str] = mapped_column(
        ForeignKey("commercial_customers.id", ondelete="CASCADE"),
        index=True,
    )
    plan_id: Mapped[str] = mapped_column(
        ForeignKey("commercial_plans.id", ondelete="RESTRICT"),
        index=True,
    )
    status: Mapped[str] = mapped_column(String(30), default="trial", index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    trial_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    renews_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    canceled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    external_reference: Mapped[str] = mapped_column(String(120), default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class CommercialInvoice(Base):
    __tablename__ = "commercial_invoices"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("invoice")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    customer_id: Mapped[str] = mapped_column(
        ForeignKey("commercial_customers.id", ondelete="CASCADE"),
        index=True,
    )
    subscription_id: Mapped[str | None] = mapped_column(
        ForeignKey("commercial_subscriptions.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    reference: Mapped[str] = mapped_column(String(100), index=True)
    amount: Mapped[float] = mapped_column(Float)
    due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    payment_method: Mapped[str] = mapped_column(String(40), default="")
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    external_reference: Mapped[str] = mapped_column(String(120), default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class MlDataset(Base):
    __tablename__ = "ml_datasets"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_dataset")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    version: Mapped[str] = mapped_column(String(50), default="1")
    task_type: Mapped[str] = mapped_column(String(50), index=True)
    target_column: Mapped[str] = mapped_column(String(120), default="")
    source_tables: Mapped[list] = mapped_column(JSON, default=list)
    filters: Mapped[dict] = mapped_column(JSON, default=dict)
    schema_json: Mapped[dict] = mapped_column(JSON, default=dict)
    row_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(30), default="draft", index=True)
    checksum: Mapped[str] = mapped_column(String(128), default="")
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class MlFeatureDefinition(Base):
    __tablename__ = "ml_feature_definitions"
    __table_args__ = (
        UniqueConstraint("company_id", "key", name="uq_ml_feature_company_key"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_feature")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    key: Mapped[str] = mapped_column(String(120), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    data_type: Mapped[str] = mapped_column(String(40), default="float")
    source_expression: Mapped[str] = mapped_column(Text)
    default_value: Mapped[float | None] = mapped_column(Float, nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class MlTrainingRun(Base):
    __tablename__ = "ml_training_runs"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_training")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    dataset_id: Mapped[str] = mapped_column(
        ForeignKey("ml_datasets.id", ondelete="CASCADE"),
        index=True,
    )
    algorithm: Mapped[str] = mapped_column(String(80), index=True)
    parameters: Mapped[dict] = mapped_column(JSON, default=dict)
    metrics: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(30), default="queued", index=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    error_message: Mapped[str] = mapped_column(Text, default="")
    artifact_path: Mapped[str] = mapped_column(String(500), default="")
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class MlModelVersion(Base):
    __tablename__ = "ml_model_versions"
    __table_args__ = (
        UniqueConstraint("company_id", "name", "version", name="uq_ml_model_name_version"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_model")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    training_run_id: Mapped[str | None] = mapped_column(
        ForeignKey("ml_training_runs.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(180), index=True)
    version: Mapped[str] = mapped_column(String(50), index=True)
    task_type: Mapped[str] = mapped_column(String(50), index=True)
    algorithm: Mapped[str] = mapped_column(String(80))
    metrics: Mapped[dict] = mapped_column(JSON, default=dict)
    feature_keys: Mapped[list] = mapped_column(JSON, default=list)
    target_name: Mapped[str] = mapped_column(String(120), default="")
    status: Mapped[str] = mapped_column(String(30), default="candidate", index=True)
    artifact_path: Mapped[str] = mapped_column(String(500), default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class MlDeployment(Base):
    __tablename__ = "ml_deployments"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_deployment")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    model_id: Mapped[str] = mapped_column(
        ForeignKey("ml_model_versions.id", ondelete="CASCADE"),
        index=True,
    )
    environment: Mapped[str] = mapped_column(String(40), default="production", index=True)
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    traffic_percent: Mapped[float] = mapped_column(Float, default=100)
    threshold: Mapped[float | None] = mapped_column(Float, nullable=True)
    deployed_by: Mapped[str] = mapped_column(String(80))
    deployed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    retired_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class MlPrediction(Base):
    __tablename__ = "ml_predictions"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_prediction")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    deployment_id: Mapped[str] = mapped_column(
        ForeignKey("ml_deployments.id", ondelete="CASCADE"),
        index=True,
    )
    entity_type: Mapped[str] = mapped_column(String(80), default="")
    entity_id: Mapped[str] = mapped_column(String(120), default="")
    input_features: Mapped[dict] = mapped_column(JSON, default=dict)
    prediction: Mapped[dict] = mapped_column(JSON, default=dict)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    explanation: Mapped[dict] = mapped_column(JSON, default=dict)
    latency_ms: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class MlPredictionFeedback(Base):
    __tablename__ = "ml_prediction_feedback"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_feedback")
    )
    prediction_id: Mapped[str] = mapped_column(
        ForeignKey("ml_predictions.id", ondelete="CASCADE"),
        index=True,
    )
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    actual_value: Mapped[dict] = mapped_column(JSON, default=dict)
    accepted: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class MlDriftSnapshot(Base):
    __tablename__ = "ml_drift_snapshots"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ml_drift")
    )
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    deployment_id: Mapped[str] = mapped_column(
        ForeignKey("ml_deployments.id", ondelete="CASCADE"),
        index=True,
    )
    feature_drift: Mapped[dict] = mapped_column(JSON, default=dict)
    prediction_drift: Mapped[float] = mapped_column(Float, default=0)
    performance_drift: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="stable", index=True)
    recommendations: Mapped[list] = mapped_column(JSON, default=list)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class AtlasAiAgent(Base):
    __tablename__ = "atlas_ai_agents"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_atlas_ai_agent_company_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_agent")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    specialty: Mapped[str] = mapped_column(String(80), index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    instructions: Mapped[str] = mapped_column(Text, default="")
    capabilities: Mapped[list] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AtlasAiSession(Base):
    __tablename__ = "atlas_ai_sessions"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_session")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    user_id: Mapped[str] = mapped_column(String(80), index=True)
    title: Mapped[str] = mapped_column(String(220), default="Conversa Atlas")
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    context_snapshot: Mapped[dict] = mapped_column(JSON, default=dict)
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AtlasAiSessionMessage(Base):
    __tablename__ = "atlas_ai_session_messages"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_message")
    )
    session_id: Mapped[str] = mapped_column(
        ForeignKey("atlas_ai_sessions.id", ondelete="CASCADE"),
        index=True,
    )
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    role: Mapped[str] = mapped_column(String(30), index=True)
    content: Mapped[str] = mapped_column(Text)
    agent_code: Mapped[str] = mapped_column(String(80), default="")
    confidence_percent: Mapped[float] = mapped_column(Float, default=0)
    sources: Mapped[list] = mapped_column(JSON, default=list)
    evidence: Mapped[list] = mapped_column(JSON, default=list)
    limitations: Mapped[list] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class AtlasAiMemory(Base):
    __tablename__ = "atlas_ai_memories"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_memory")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    user_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    memory_type: Mapped[str] = mapped_column(String(50), index=True)
    key: Mapped[str] = mapped_column(String(160), index=True)
    content: Mapped[dict] = mapped_column(JSON, default=dict)
    importance: Mapped[float] = mapped_column(Float, default=0.5)
    source: Mapped[str] = mapped_column(String(120), default="atlas")
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AtlasAiRecommendation(Base):
    __tablename__ = "atlas_ai_recommendations_v2"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_recommendation_v2")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    agent_code: Mapped[str] = mapped_column(String(80), index=True)
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text)
    priority: Mapped[str] = mapped_column(String(30), default="medium", index=True)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    confidence_percent: Mapped[float] = mapped_column(Float, default=0)
    expected_financial_impact: Mapped[float] = mapped_column(Float, default=0)
    expected_technical_impact: Mapped[str] = mapped_column(Text, default="")
    reasoning: Mapped[list] = mapped_column(JSON, default=list)
    actions: Mapped[list] = mapped_column(JSON, default=list)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_by: Mapped[str | None] = mapped_column(String(80), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class AtlasAiPlan(Base):
    __tablename__ = "atlas_ai_plans"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("ai_plan")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    horizon: Mapped[str] = mapped_column(String(30), index=True)
    title: Mapped[str] = mapped_column(String(220))
    summary: Mapped[str] = mapped_column(Text)
    items: Mapped[list] = mapped_column(JSON, default=list)
    confidence_percent: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    generated_by: Mapped[str] = mapped_column(String(80), default="atlas_orchestrator")
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class AtlasKnowledgeDocument(Base):
    __tablename__ = "atlas_knowledge_documents"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("knowledge_document")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    title: Mapped[str] = mapped_column(String(220))
    category: Mapped[str] = mapped_column(String(80), index=True)
    content: Mapped[str] = mapped_column(Text)
    tags: Mapped[list] = mapped_column(JSON, default=list)
    source_reference: Mapped[str] = mapped_column(String(500), default="")
    checksum: Mapped[str] = mapped_column(String(128), default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AutomationRule(Base):
    __tablename__ = "automation_rules"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("automation_rule"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(180))
    event_type: Mapped[str] = mapped_column(String(120), index=True)
    conditions: Mapped[dict] = mapped_column(JSON, default=dict)
    actions: Mapped[list] = mapped_column(JSON, default=list)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    priority: Mapped[int] = mapped_column(Integer, default=50)
    last_executed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class WorkflowDefinition(Base):
    __tablename__ = "workflow_definitions"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("workflow"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(100), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    steps: Mapped[list] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class WorkflowInstance(Base):
    __tablename__ = "workflow_instances"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("workflow_instance"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    workflow_id: Mapped[str] = mapped_column(ForeignKey("workflow_definitions.id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(30), default="running", index=True)
    current_step: Mapped[int] = mapped_column(Integer, default=0)
    context: Mapped[dict] = mapped_column(JSON, default=dict)
    started_by: Mapped[str] = mapped_column(String(80))
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class CorporateCalendarEvent(Base):
    __tablename__ = "corporate_calendar_events"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("calendar_event"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    title: Mapped[str] = mapped_column(String(220))
    category: Mapped[str] = mapped_column(String(80), index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="scheduled", index=True)
    responsible_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class StrategicObjective(Base):
    __tablename__ = "strategic_objectives"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("objective"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text, default="")
    owner_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="active", index=True)
    progress_percent: Mapped[float] = mapped_column(Float, default=0)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    key_results: Mapped[list] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class ExecutiveDigest(Base):
    __tablename__ = "executive_digests"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("executive_digest"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    period: Mapped[str] = mapped_column(String(30), index=True)
    summary: Mapped[str] = mapped_column(Text)
    priorities: Mapped[list] = mapped_column(JSON, default=list)
    alerts: Mapped[list] = mapped_column(JSON, default=list)
    metrics: Mapped[dict] = mapped_column(JSON, default=dict)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class DataGovernancePolicy(Base):
    __tablename__ = "data_governance_policies"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_data_governance_policy_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("governance_policy")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(100), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    resource_type: Mapped[str] = mapped_column(String(100), index=True)
    classification: Mapped[str] = mapped_column(String(40), default="internal", index=True)
    retention_days: Mapped[int] = mapped_column(Integer, default=365)
    legal_basis: Mapped[str] = mapped_column(String(180), default="")
    access_rules: Mapped[dict] = mapped_column(JSON, default=dict)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class DataCatalogAsset(Base):
    __tablename__ = "data_catalog_assets"
    __table_args__ = (
        UniqueConstraint("company_id", "asset_key", name="uq_data_catalog_asset_key"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("data_asset")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    asset_key: Mapped[str] = mapped_column(String(160), index=True)
    name: Mapped[str] = mapped_column(String(180))
    asset_type: Mapped[str] = mapped_column(String(60), index=True)
    source_system: Mapped[str] = mapped_column(String(120), default="atlas")
    owner_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    steward_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    classification: Mapped[str] = mapped_column(String(40), default="internal", index=True)
    schema_definition: Mapped[dict] = mapped_column(JSON, default=dict)
    lineage: Mapped[list] = mapped_column(JSON, default=list)
    quality_score: Mapped[float] = mapped_column(Float, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class DataQualityRule(Base):
    __tablename__ = "data_quality_rules"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("quality_rule")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    asset_id: Mapped[str] = mapped_column(
        ForeignKey("data_catalog_assets.id", ondelete="CASCADE"),
        index=True,
    )
    name: Mapped[str] = mapped_column(String(180))
    rule_type: Mapped[str] = mapped_column(String(60), index=True)
    field_name: Mapped[str] = mapped_column(String(120), default="")
    parameters: Mapped[dict] = mapped_column(JSON, default=dict)
    severity: Mapped[str] = mapped_column(String(30), default="warning", index=True)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class DataQualityRun(Base):
    __tablename__ = "data_quality_runs"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("quality_run")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    asset_id: Mapped[str] = mapped_column(
        ForeignKey("data_catalog_assets.id", ondelete="CASCADE"),
        index=True,
    )
    status: Mapped[str] = mapped_column(String(30), default="completed", index=True)
    score: Mapped[float] = mapped_column(Float, default=0)
    checks_total: Mapped[int] = mapped_column(Integer, default=0)
    checks_passed: Mapped[int] = mapped_column(Integer, default=0)
    checks_failed: Mapped[int] = mapped_column(Integer, default=0)
    findings: Mapped[list] = mapped_column(JSON, default=list)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class ComplianceControl(Base):
    __tablename__ = "compliance_controls"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_compliance_control_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("compliance_control")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(100), index=True)
    name: Mapped[str] = mapped_column(String(180))
    framework: Mapped[str] = mapped_column(String(100), default="internal", index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    evidence_requirements: Mapped[list] = mapped_column(JSON, default=list)
    owner_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="implemented", index=True)
    last_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    next_review_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ComplianceAssessment(Base):
    __tablename__ = "compliance_assessments"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("compliance_assessment")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    control_id: Mapped[str] = mapped_column(
        ForeignKey("compliance_controls.id", ondelete="CASCADE"),
        index=True,
    )
    result: Mapped[str] = mapped_column(String(30), index=True)
    score: Mapped[float] = mapped_column(Float, default=0)
    findings: Mapped[list] = mapped_column(JSON, default=list)
    evidence: Mapped[list] = mapped_column(JSON, default=list)
    assessed_by: Mapped[str] = mapped_column(String(80))
    assessed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class ServiceHealthSnapshot(Base):
    __tablename__ = "service_health_snapshots"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("health_snapshot")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    service_name: Mapped[str] = mapped_column(String(120), index=True)
    status: Mapped[str] = mapped_column(String(30), index=True)
    latency_ms: Mapped[int] = mapped_column(Integer, default=0)
    availability_percent: Mapped[float] = mapped_column(Float, default=100)
    error_rate_percent: Mapped[float] = mapped_column(Float, default=0)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    checked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class ResilienceIncident(Base):
    __tablename__ = "resilience_incidents"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("resilience_incident")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    title: Mapped[str] = mapped_column(String(220))
    severity: Mapped[str] = mapped_column(String(30), index=True)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    affected_services: Mapped[list] = mapped_column(JSON, default=list)
    description: Mapped[str] = mapped_column(Text)
    root_cause: Mapped[str] = mapped_column(Text, default="")
    mitigation: Mapped[str] = mapped_column(Text, default="")
    opened_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class IntegrationProvider(Base):
    __tablename__ = "integration_providers"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_integration_provider_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("integration_provider")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(100), index=True)
    name: Mapped[str] = mapped_column(String(180))
    category: Mapped[str] = mapped_column(String(80), index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    base_url: Mapped[str] = mapped_column(String(500), default="")
    auth_type: Mapped[str] = mapped_column(String(40), default="api_key")
    capabilities: Mapped[list] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class IntegrationConnection(Base):
    __tablename__ = "integration_connections"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("integration_connection")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    provider_id: Mapped[str] = mapped_column(
        ForeignKey("integration_providers.id", ondelete="CASCADE"),
        index=True,
    )
    name: Mapped[str] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(30), default="inactive", index=True)
    credentials_encrypted: Mapped[str] = mapped_column(Text, default="")
    configuration: Mapped[dict] = mapped_column(JSON, default=dict)
    scopes: Mapped[list] = mapped_column(JSON, default=list)
    last_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_error: Mapped[str] = mapped_column(Text, default="")
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class IntegrationSyncJob(Base):
    __tablename__ = "integration_sync_jobs"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("integration_job")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    connection_id: Mapped[str] = mapped_column(
        ForeignKey("integration_connections.id", ondelete="CASCADE"),
        index=True,
    )
    job_type: Mapped[str] = mapped_column(String(80), index=True)
    direction: Mapped[str] = mapped_column(String(30), default="pull", index=True)
    status: Mapped[str] = mapped_column(String(30), default="queued", index=True)
    cursor: Mapped[str] = mapped_column(String(500), default="")
    records_processed: Mapped[int] = mapped_column(Integer, default=0)
    records_failed: Mapped[int] = mapped_column(Integer, default=0)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    result: Mapped[dict] = mapped_column(JSON, default=dict)
    error_message: Mapped[str] = mapped_column(Text, default="")
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class OutboundWebhook(Base):
    __tablename__ = "outbound_webhooks"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("webhook")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(180))
    target_url: Mapped[str] = mapped_column(String(700))
    secret_hash: Mapped[str] = mapped_column(String(128), default="")
    event_types: Mapped[list] = mapped_column(JSON, default=list)
    headers: Mapped[dict] = mapped_column(JSON, default=dict)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    retry_policy: Mapped[dict] = mapped_column(JSON, default=dict)
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class WebhookDelivery(Base):
    __tablename__ = "webhook_deliveries"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("webhook_delivery")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    webhook_id: Mapped[str] = mapped_column(
        ForeignKey("outbound_webhooks.id", ondelete="CASCADE"),
        index=True,
    )
    event_type: Mapped[str] = mapped_column(String(120), index=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    attempt_count: Mapped[int] = mapped_column(Integer, default=0)
    response_status: Mapped[int | None] = mapped_column(Integer, nullable=True)
    response_body: Mapped[str] = mapped_column(Text, default="")
    error_message: Mapped[str] = mapped_column(Text, default="")
    next_attempt_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class PartnerApplication(Base):
    __tablename__ = "partner_applications"
    __table_args__ = (
        UniqueConstraint("company_id", "client_id", name="uq_partner_application_client_id"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("partner_app")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    partner_name: Mapped[str] = mapped_column(String(180))
    client_id: Mapped[str] = mapped_column(String(120), index=True)
    client_secret_hash: Mapped[str] = mapped_column(String(128))
    scopes: Mapped[list] = mapped_column(JSON, default=list)
    allowed_origins: Mapped[list] = mapped_column(JSON, default=list)
    rate_limit_per_minute: Mapped[int] = mapped_column(Integer, default=60)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ApiUsageRecord(Base):
    __tablename__ = "api_usage_records"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("api_usage")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    partner_application_id: Mapped[str | None] = mapped_column(
        ForeignKey("partner_applications.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    endpoint: Mapped[str] = mapped_column(String(300), index=True)
    method: Mapped[str] = mapped_column(String(20))
    status_code: Mapped[int] = mapped_column(Integer)
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    request_units: Mapped[int] = mapped_column(Integer, default=1)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class SecurityPolicy(Base):
    __tablename__ = "security_policies"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_security_policy_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("security_policy")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(100), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    policy_type: Mapped[str] = mapped_column(String(80), index=True)
    rules: Mapped[dict] = mapped_column(JSON, default=dict)
    enforcement_mode: Mapped[str] = mapped_column(String(30), default="monitor", index=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class AccessReview(Base):
    __tablename__ = "access_reviews"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("access_review")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    review_type: Mapped[str] = mapped_column(String(60), index=True)
    subject_user_id: Mapped[str] = mapped_column(String(80), index=True)
    reviewer_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    permissions_snapshot: Mapped[dict] = mapped_column(JSON, default=dict)
    findings: Mapped[list] = mapped_column(JSON, default=list)
    decision: Mapped[str] = mapped_column(String(30), default="")
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class PrivacyConsent(Base):
    __tablename__ = "privacy_consents"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("privacy_consent")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    data_subject_type: Mapped[str] = mapped_column(String(60), index=True)
    data_subject_id: Mapped[str] = mapped_column(String(120), index=True)
    purpose: Mapped[str] = mapped_column(String(180), index=True)
    legal_basis: Mapped[str] = mapped_column(String(120), default="")
    granted: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    granted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    evidence: Mapped[dict] = mapped_column(JSON, default=dict)


class PrivacyRequest(Base):
    __tablename__ = "privacy_requests"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("privacy_request")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    request_type: Mapped[str] = mapped_column(String(60), index=True)
    data_subject_type: Mapped[str] = mapped_column(String(60))
    data_subject_id: Mapped[str] = mapped_column(String(120), index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    response_summary: Mapped[str] = mapped_column(Text, default="")


class SecurityRisk(Base):
    __tablename__ = "security_risks"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("security_risk")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    title: Mapped[str] = mapped_column(String(220))
    category: Mapped[str] = mapped_column(String(80), index=True)
    likelihood: Mapped[float] = mapped_column(Float, default=0)
    impact: Mapped[float] = mapped_column(Float, default=0)
    score: Mapped[float] = mapped_column(Float, default=0, index=True)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    treatment: Mapped[str] = mapped_column(Text, default="")
    owner_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class BusinessContinuityPlan(Base):
    __tablename__ = "business_continuity_plans"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("continuity_plan")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    scenario: Mapped[str] = mapped_column(String(120), index=True)
    critical_services: Mapped[list] = mapped_column(JSON, default=list)
    recovery_steps: Mapped[list] = mapped_column(JSON, default=list)
    rto_minutes: Mapped[int] = mapped_column(Integer, default=240)
    rpo_minutes: Mapped[int] = mapped_column(Integer, default=60)
    owner_user_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_tested_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ContinuityExercise(Base):
    __tablename__ = "continuity_exercises"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("continuity_exercise")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    plan_id: Mapped[str] = mapped_column(
        ForeignKey("business_continuity_plans.id", ondelete="CASCADE"),
        index=True,
    )
    status: Mapped[str] = mapped_column(String(30), default="planned", index=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    actual_rto_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    actual_rpo_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    findings: Mapped[list] = mapped_column(JSON, default=list)
    result: Mapped[str] = mapped_column(String(30), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class SecurityPostureSnapshot(Base):
    __tablename__ = "security_posture_snapshots"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("security_posture")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    posture_score: Mapped[float] = mapped_column(Float, default=0)
    active_policies: Mapped[int] = mapped_column(Integer, default=0)
    open_risks: Mapped[int] = mapped_column(Integer, default=0)
    overdue_reviews: Mapped[int] = mapped_column(Integer, default=0)
    open_privacy_requests: Mapped[int] = mapped_column(Integer, default=0)
    untested_continuity_plans: Mapped[int] = mapped_column(Integer, default=0)
    findings: Mapped[list] = mapped_column(JSON, default=list)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class ReleasePipeline(Base):
    __tablename__ = "release_pipelines"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_release_pipeline_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("release_pipeline")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(100), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    stages: Mapped[list] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class ReleaseBuild(Base):
    __tablename__ = "release_builds"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("release_build")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    pipeline_id: Mapped[str] = mapped_column(
        ForeignKey("release_pipelines.id", ondelete="CASCADE"),
        index=True,
    )
    version: Mapped[str] = mapped_column(String(80), index=True)
    commit_sha: Mapped[str] = mapped_column(String(80), default="")
    branch: Mapped[str] = mapped_column(String(120), default="main")
    status: Mapped[str] = mapped_column(String(30), default="queued", index=True)
    artifacts: Mapped[list] = mapped_column(JSON, default=list)
    test_summary: Mapped[dict] = mapped_column(JSON, default=dict)
    created_by: Mapped[str] = mapped_column(String(80))
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class DeploymentEnvironment(Base):
    __tablename__ = "deployment_environments"
    __table_args__ = (
        UniqueConstraint("company_id", "code", name="uq_deployment_environment_code"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("deployment_environment")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    environment_type: Mapped[str] = mapped_column(String(40), index=True)
    base_url: Mapped[str] = mapped_column(String(500), default="")
    configuration: Mapped[dict] = mapped_column(JSON, default=dict)
    protected: Mapped[bool] = mapped_column(Boolean, default=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class DeploymentRelease(Base):
    __tablename__ = "deployment_releases"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("deployment_release")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    build_id: Mapped[str] = mapped_column(
        ForeignKey("release_builds.id", ondelete="CASCADE"),
        index=True,
    )
    environment_id: Mapped[str] = mapped_column(
        ForeignKey("deployment_environments.id", ondelete="CASCADE"),
        index=True,
    )
    strategy: Mapped[str] = mapped_column(String(40), default="rolling")
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    approval_status: Mapped[str] = mapped_column(String(30), default="not_required", index=True)
    approved_by: Mapped[str | None] = mapped_column(String(80), nullable=True)
    health_checks: Mapped[list] = mapped_column(JSON, default=list)
    rollback_build_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    deployed_by: Mapped[str] = mapped_column(String(80))
    deployed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class FeatureFlag(Base):
    __tablename__ = "feature_flags"
    __table_args__ = (
        UniqueConstraint("company_id", "key", name="uq_feature_flag_key"),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("feature_flag")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    key: Mapped[str] = mapped_column(String(160), index=True)
    name: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    enabled: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    rollout_percent: Mapped[float] = mapped_column(Float, default=0)
    targeting_rules: Mapped[list] = mapped_column(JSON, default=list)
    environments: Mapped[list] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class ChangeApproval(Base):
    __tablename__ = "change_approvals"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("change_approval")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    change_type: Mapped[str] = mapped_column(String(60), index=True)
    reference_id: Mapped[str] = mapped_column(String(100), index=True)
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text, default="")
    risk_level: Mapped[str] = mapped_column(String(30), default="medium", index=True)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    requested_by: Mapped[str] = mapped_column(String(80))
    approved_by: Mapped[str | None] = mapped_column(String(80), nullable=True)
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    decision_notes: Mapped[str] = mapped_column(Text, default="")


class ProductionReadinessCheck(Base):
    __tablename__ = "production_readiness_checks"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("readiness_check")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    release_id: Mapped[str | None] = mapped_column(
        ForeignKey("deployment_releases.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    check_type: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    required: Mapped[bool] = mapped_column(Boolean, default=True)
    evidence: Mapped[dict] = mapped_column(JSON, default=dict)
    findings: Mapped[list] = mapped_column(JSON, default=list)
    checked_by: Mapped[str | None] = mapped_column(String(80), nullable=True)
    checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ReleaseMetricSnapshot(Base):
    __tablename__ = "release_metric_snapshots"

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("release_metric")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    environment_id: Mapped[str | None] = mapped_column(
        ForeignKey("deployment_environments.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    deployment_frequency: Mapped[float] = mapped_column(Float, default=0)
    lead_time_hours: Mapped[float] = mapped_column(Float, default=0)
    change_failure_rate_percent: Mapped[float] = mapped_column(Float, default=0)
    mean_time_to_recovery_minutes: Mapped[float] = mapped_column(Float, default=0)
    successful_deployments: Mapped[int] = mapped_column(Integer, default=0)
    failed_deployments: Mapped[int] = mapped_column(Integer, default=0)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)

# ---------------------------------------------------------------------------
# Compatibilidade de nomenclatura do domínio pecuário
# ---------------------------------------------------------------------------
# Alguns módulos entregues em fases diferentes usavam nomes de classes com o
# prefixo ``Livestock``. O domínio oficial, porém, utiliza HerdLot,
# WeightRecord, HealthEvent, NutritionEvent e ReproductionEvent. Estes aliases
# mantêm todos os imports apontando para as MESMAS classes/tabelas SQLAlchemy,
# sem criar modelos ou cadastros paralelos.
LivestockLot = HerdLot
LivestockWeight = WeightRecord
LivestockHealthEvent = HealthEvent
LivestockNutritionEvent = NutritionEvent
LivestockReproductionEvent = ReproductionEvent


class BulletinSchedule(Base):
    __tablename__ = "bulletin_schedules"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "farm_id",
            "bulletin_type",
            name="uq_bulletin_schedule_company_farm_type",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("bulletin_schedule")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"), index=True
    )
    bulletin_type: Mapped[str] = mapped_column(String(40), index=True)
    recipient_whatsapp: Mapped[str] = mapped_column(String(30), default="")
    whatsapp_opt_in_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    enabled: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    day_of_month: Mapped[int] = mapped_column(Integer, default=1)
    hour: Mapped[int] = mapped_column(Integer, default=8)
    minute: Mapped[int] = mapped_column(Integer, default=0)
    timezone_name: Mapped[str] = mapped_column(
        String(80), default="America/Sao_Paulo"
    )
    last_run_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    next_run_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class BulletinDispatch(Base):
    __tablename__ = "bulletin_dispatches"
    __table_args__ = (
        UniqueConstraint(
            "idempotency_key",
            name="uq_bulletin_dispatch_idempotency",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80), primary_key=True, default=lambda: new_id("bulletin_dispatch")
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"), index=True
    )
    schedule_id: Mapped[str | None] = mapped_column(
        ForeignKey("bulletin_schedules.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    bulletin_type: Mapped[str] = mapped_column(String(40), index=True)
    recipient_whatsapp: Mapped[str] = mapped_column(String(30))
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    content: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(40), default="queued", index=True)
    provider: Mapped[str] = mapped_column(String(40), default="meta_cloud")
    provider_message_id: Mapped[str] = mapped_column(String(180), default="")
    idempotency_key: Mapped[str] = mapped_column(String(180), unique=True, index=True)
    attempt_count: Mapped[int] = mapped_column(Integer, default=0)
    scheduled_for: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_attempt_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    error_message: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class SecurityCameraEvent(Base):
    __tablename__ = "security_camera_events"
    __table_args__ = (
        UniqueConstraint(
            "device_id",
            "event_external_id",
            name="uq_security_camera_event_device_external",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80),
        primary_key=True,
        default=lambda: new_id("security_camera_event"),
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(String(80), index=True)
    device_id: Mapped[str] = mapped_column(
        ForeignKey("atlas_iot_devices_v2.id", ondelete="CASCADE"),
        index=True,
    )
    event_external_id: Mapped[str] = mapped_column(String(180))
    event_type: Mapped[str] = mapped_column(String(30), index=True)
    confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    captured_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        index=True,
    )
    received_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        index=True,
    )
    storage_key: Mapped[str] = mapped_column(String(900), default="")
    sha256: Mapped[str] = mapped_column(String(64), default="")
    file_size: Mapped[int] = mapped_column(Integer, default=0)
    recipient_whatsapp: Mapped[str] = mapped_column(String(30), default="")
    alert_status: Mapped[str] = mapped_column(
        String(40),
        default="pending",
        index=True,
    )
    provider_message_id: Mapped[str] = mapped_column(
        String(180),
        default="",
        index=True,
    )
    attempt_count: Mapped[int] = mapped_column(Integer, default=0)
    last_attempt_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    error_message: Mapped[str] = mapped_column(Text, default="")
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        index=True,
    )


class ConsultancyContact(Base):
    __tablename__ = "consultancy_contacts"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "farm_id",
            name="uq_consultancy_contact_company_farm",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(80),
        primary_key=True,
        default=lambda: new_id("consultancy_contact"),
    )
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(
        ForeignKey("companies.id", ondelete="CASCADE"),
        index=True,
    )
    farm_id: Mapped[str] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"),
        index=True,
    )
    display_name: Mapped[str] = mapped_column(String(180), default="")
    role: Mapped[str] = mapped_column(
        String(120),
        default="Veterinário responsável",
    )
    whatsapp_number: Mapped[str] = mapped_column(String(30), default="")
    company_label: Mapped[str] = mapped_column(String(180), default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    updated_by: Mapped[str] = mapped_column(String(80), default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        onupdate=utcnow,
    )


class FarmHandlingOperation(Base):
    __tablename__ = "farm_handling_operations"
    __table_args__ = (
        UniqueConstraint(
            "company_id",
            "farm_id",
            "idempotency_key",
            name="uq_farm_handling_company_farm_idempotency",
        ),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(
        ForeignKey("companies.id", ondelete="CASCADE"),
        index=True,
    )
    farm_id: Mapped[str] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"),
        index=True,
    )
    idempotency_key: Mapped[str] = mapped_column(String(180))
    action: Mapped[str] = mapped_column(String(60), index=True)
    status: Mapped[str] = mapped_column(String(30), default="completed", index=True)
    affected_count: Mapped[int] = mapped_column(Integer, default=0)
    animal_ids_json: Mapped[list] = mapped_column(JSON, default=list)
    created_ids_json: Mapped[list] = mapped_column(JSON, default=list)
    finance_entry_id: Mapped[str] = mapped_column(String(80), default="")
    summary: Mapped[str] = mapped_column(Text, default="")
    responsible: Mapped[str] = mapped_column(String(180), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    created_by: Mapped[str] = mapped_column(String(80), default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        index=True,
    )
