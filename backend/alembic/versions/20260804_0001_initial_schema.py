"""initial schema

Revision ID: 20260804_0001
Revises:
"""
from alembic import op
import sqlalchemy as sa
from app.database import Base
from app import models  # noqa: F401

# A revisão inicial contém somente o núcleo anterior aos módulos criados
# nas revisões seguintes. Criar todo o Base.metadata atual aqui antecipa
# tabelas posteriores, inclusive chaves estrangeiras ainda não registradas.
INITIAL_TABLES = (
    "companies",
    "users",
    "memberships",
    "entity_states",
    "sync_changes",
    "processed_operations",
    "audit_logs",
)

revision = "20260804_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(
        bind=bind,
        tables=[Base.metadata.tables[name] for name in INITIAL_TABLES],
    )
    # A estrutura de farms deve representar a revisão 0001. O modelo atual
    # já inclui production_profile/system, que pertencem somente à 0055.
    op.create_table(
        "farms",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("city", sa.String(120), nullable=False),
        sa.Column("state", sa.String(80), nullable=False),
        sa.Column("animals", sa.Integer(), nullable=False),
        sa.Column("area", sa.Integer(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "name", name="uq_farm_company_name"),
    )
    op.create_index("ix_farms_tenant_id", "farms", ["tenant_id"])
    op.create_index("ix_farms_company_id", "farms", ["company_id"])


def downgrade() -> None:
    bind = op.get_bind()
    op.drop_table("farms")
    Base.metadata.drop_all(
        bind=bind,
        tables=[Base.metadata.tables[name] for name in INITIAL_TABLES],
    )
