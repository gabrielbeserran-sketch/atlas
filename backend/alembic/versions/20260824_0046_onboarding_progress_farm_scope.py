"""Scope onboarding progress by farm without losing legacy training state.

Revision ID: 20260824_0046
Revises: 20260824_0045
"""
from alembic import op
import sqlalchemy as sa


revision = "20260824_0046"
down_revision = "20260824_0045"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "onboarding_progress",
        sa.Column("farm_id", sa.String(length=80), nullable=True),
    )
    op.create_foreign_key(
        "fk_onboarding_progress_farm_id_farms",
        "onboarding_progress",
        "farms",
        ["farm_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(
        "ix_onboarding_progress_farm_id",
        "onboarding_progress",
        ["farm_id"],
        unique=False,
    )

    # A coluna company_id nasceu unique no 0033. O onboarding agora precisa de
    # um registro independente por fazenda.
    op.drop_constraint(
        "onboarding_progress_company_id_key",
        "onboarding_progress",
        type_="unique",
    )

    # Replica o único estado legado da empresa para cada fazenda já existente.
    # O id determinístico evita colisões e mantém o limite de 80 caracteres.
    op.execute(
        sa.text(
            """
            INSERT INTO onboarding_progress (
                id, tenant_id, company_id, farm_id, steps_json,
                completion_percent, completed_at
            )
            SELECT
                'onboarding_' || md5(opg.company_id || ':' || f.id),
                opg.tenant_id,
                opg.company_id,
                f.id,
                opg.steps_json,
                opg.completion_percent,
                opg.completed_at
            FROM onboarding_progress AS opg
            JOIN farms AS f ON f.company_id = opg.company_id
            WHERE opg.farm_id IS NULL
            """
        )
    )

    # Remove o registro company-scoped somente quando ele foi expandido para
    # pelo menos uma fazenda. Empresas ainda sem fazenda preservam o legado;
    # o backend o vincula à primeira fazenda quando ela for usada.
    op.execute(
        sa.text(
            """
            DELETE FROM onboarding_progress AS opg
            WHERE opg.farm_id IS NULL
              AND EXISTS (
                  SELECT 1 FROM farms AS f
                  WHERE f.company_id = opg.company_id
              )
            """
        )
    )

    op.create_unique_constraint(
        "uq_onboarding_progress_company_farm",
        "onboarding_progress",
        ["company_id", "farm_id"],
    )
    op.execute(
        sa.text(
            """
            CREATE UNIQUE INDEX uq_onboarding_progress_company_legacy
            ON onboarding_progress (company_id)
            WHERE farm_id IS NULL
            """
        )
    )


def downgrade() -> None:
    # Consolida, por empresa, a confirmação manual antes de voltar ao modelo
    # legado. Se qualquer fazenda tinha treinamento concluído, o estado é
    # preservado como concluído para a empresa.
    op.execute(
        sa.text(
            """
            UPDATE onboarding_progress AS target
            SET steps_json = json_build_object(
                    'initial_training', COALESCE(source.trained, FALSE)
                ),
                completion_percent = CASE
                    WHEN COALESCE(source.trained, FALSE) THEN 20.0 ELSE 0.0
                END,
                completed_at = NULL
            FROM (
                SELECT company_id,
                       bool_or(COALESCE((steps_json ->> 'initial_training')::boolean, FALSE)) AS trained
                FROM onboarding_progress
                GROUP BY company_id
            ) AS source
            WHERE target.company_id = source.company_id
              AND target.id = (
                  SELECT MIN(x.id)
                  FROM onboarding_progress AS x
                  WHERE x.company_id = target.company_id
              )
            """
        )
    )
    op.execute(
        sa.text(
            """
            DELETE FROM onboarding_progress AS extra
            WHERE extra.id <> (
                SELECT MIN(keep.id)
                FROM onboarding_progress AS keep
                WHERE keep.company_id = extra.company_id
            )
            """
        )
    )
    op.execute(sa.text("DROP INDEX IF EXISTS uq_onboarding_progress_company_legacy"))
    op.drop_constraint(
        "uq_onboarding_progress_company_farm",
        "onboarding_progress",
        type_="unique",
    )
    op.create_unique_constraint(
        "onboarding_progress_company_id_key",
        "onboarding_progress",
        ["company_id"],
    )
    op.drop_index("ix_onboarding_progress_farm_id", table_name="onboarding_progress")
    op.drop_constraint(
        "fk_onboarding_progress_farm_id_farms",
        "onboarding_progress",
        type_="foreignkey",
    )
    op.drop_column("onboarding_progress", "farm_id")
