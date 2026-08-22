"""Repair legacy mojibake in persisted text columns.

Revision ID: 20260821_0041
Revises: 20260815_0040
"""
from alembic import op


revision = "20260821_0041"
down_revision = "20260815_0040"
branch_labels = None
depends_on = None


_REPAIR_FUNCTION = r"""
CREATE OR REPLACE FUNCTION atlas_repair_mojibake_v204(input_text text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    current_text text := input_text;
    candidate text;
    attempt integer;
BEGIN
    IF current_text IS NULL OR current_text !~ '(Ã.|Â.|â.|ð.|�)' THEN
        RETURN current_text;
    END IF;

    FOR attempt IN 1..2 LOOP
        EXIT WHEN current_text !~ '(Ã.|Â.|â.|ð.|�)';
        BEGIN
            candidate := convert_from(convert_to(current_text, 'LATIN1'), 'UTF8');
        EXCEPTION WHEN others THEN
            RETURN current_text;
        END;
        EXIT WHEN candidate = current_text;
        current_text := candidate;
    END LOOP;
    RETURN current_text;
END;
$$;
"""


_REPAIR_ALL_TEXT_COLUMNS = r"""
DO $$
DECLARE
    col record;
BEGIN
    FOR col IN
        SELECT table_schema, table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND data_type IN ('text', 'character varying', 'character')
          AND table_name <> 'alembic_version'
    LOOP
        EXECUTE format(
            'UPDATE %I.%I SET %I = atlas_repair_mojibake_v204(%I) '
            'WHERE %I ~ %L',
            col.table_schema,
            col.table_name,
            col.column_name,
            col.column_name,
            col.column_name,
            '(Ã.|Â.|â.|ð.|�)'
        );
    END LOOP;
END;
$$;
"""


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return
    op.execute(_REPAIR_FUNCTION)
    op.execute(_REPAIR_ALL_TEXT_COLUMNS)
    op.execute("DROP FUNCTION IF EXISTS atlas_repair_mojibake_v204(text)")


def downgrade() -> None:
    # Data repair is intentionally irreversible.
    pass
