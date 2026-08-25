"""Consolidate UTF-8 sanitation and data-quality proof for Macro 10C.

Revision ID: 20260825_0050
Revises: 20260825_0049
"""
from alembic import op

revision = "20260825_0050"
down_revision = "20260825_0049"
branch_labels = None
depends_on = None

_REPAIR_TEXT_FUNCTION = r"""
CREATE OR REPLACE FUNCTION atlas_repair_mojibake_10c(input_text text)
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

    current_text := replace(current_text, 'â€“', '–');
    current_text := replace(current_text, 'â€”', '—');
    current_text := replace(current_text, 'â€™', '’');
    current_text := replace(current_text, 'â€œ', '“');
    current_text := replace(current_text, 'â€', '”');
    current_text := replace(current_text, 'Â·', '·');
    current_text := replace(current_text, 'Âº', 'º');
    current_text := replace(current_text, 'Âª', 'ª');
    current_text := replace(current_text, 'Â ', ' ');

    FOR attempt IN 1..2 LOOP
        EXIT WHEN current_text !~ '(Ã.|Â.|â.|ð.|�)';
        candidate := NULL;
        BEGIN
            candidate := convert_from(convert_to(current_text, 'LATIN1'), 'UTF8');
        EXCEPTION WHEN others THEN
            candidate := NULL;
        END;
        EXIT WHEN candidate IS NULL OR candidate = current_text;
        EXIT WHEN length(regexp_replace(candidate, '[^ÃÂâð�]', '', 'g')) >=
                  length(regexp_replace(current_text, '[^ÃÂâð�]', '', 'g'));
        current_text := candidate;
    END LOOP;
    RETURN current_text;
END;
$$;
"""

_REPAIR_JSONB_FUNCTION = r"""
CREATE OR REPLACE FUNCTION atlas_repair_mojibake_jsonb_10c(input_json jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    kind text;
    output jsonb;
BEGIN
    IF input_json IS NULL THEN
        RETURN NULL;
    END IF;
    kind := jsonb_typeof(input_json);
    IF kind = 'string' THEN
        RETURN to_jsonb(atlas_repair_mojibake_10c(input_json #>> '{}'));
    ELSIF kind = 'array' THEN
        SELECT COALESCE(jsonb_agg(atlas_repair_mojibake_jsonb_10c(value)), '[]'::jsonb)
        INTO output
        FROM jsonb_array_elements(input_json);
        RETURN output;
    ELSIF kind = 'object' THEN
        SELECT COALESCE(
            jsonb_object_agg(key, atlas_repair_mojibake_jsonb_10c(value)),
            '{}'::jsonb
        )
        INTO output
        FROM jsonb_each(input_json);
        RETURN output;
    END IF;
    RETURN input_json;
END;
$$;
"""

_REPAIR_ALL_COLUMNS = r"""
DO $$
DECLARE
    col record;
BEGIN
    FOR col IN
        SELECT table_schema, table_name, column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name NOT IN ('alembic_version', 'atlas_data_quality_state')
          AND data_type IN (
              'text', 'character varying', 'character', 'json', 'jsonb'
          )
    LOOP
        IF col.data_type IN ('text', 'character varying', 'character') THEN
            EXECUTE format(
                'UPDATE %I.%I SET %I = atlas_repair_mojibake_10c(%I) '
                'WHERE %I ~ %L',
                col.table_schema,
                col.table_name,
                col.column_name,
                col.column_name,
                col.column_name,
                '(Ã.|Â.|â.|ð.|�)'
            );
        ELSIF col.data_type = 'jsonb' THEN
            EXECUTE format(
                'UPDATE %I.%I SET %I = atlas_repair_mojibake_jsonb_10c(%I) '
                'WHERE %I::text ~ %L',
                col.table_schema,
                col.table_name,
                col.column_name,
                col.column_name,
                col.column_name,
                '(Ã.|Â.|â.|ð.|�)'
            );
        ELSE
            EXECUTE format(
                'UPDATE %I.%I SET %I = '
                'atlas_repair_mojibake_jsonb_10c(%I::jsonb)::json '
                'WHERE %I::text ~ %L',
                col.table_schema,
                col.table_name,
                col.column_name,
                col.column_name,
                col.column_name,
                '(Ã.|Â.|â.|ð.|�)'
            );
        END IF;
    END LOOP;
END;
$$;
"""


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    op.execute(
        """
        CREATE TABLE IF NOT EXISTS atlas_data_quality_state (
            id varchar(32) PRIMARY KEY,
            version varchar(32) NOT NULL,
            sanitized_at timestamptz NOT NULL DEFAULT now()
        )
        """
    )
    op.execute(_REPAIR_TEXT_FUNCTION)
    op.execute(_REPAIR_JSONB_FUNCTION)
    op.execute(_REPAIR_ALL_COLUMNS)
    op.execute(
        """
        INSERT INTO atlas_data_quality_state (id, version, sanitized_at)
        VALUES ('global', '10C', now())
        ON CONFLICT (id) DO UPDATE
        SET version = EXCLUDED.version,
            sanitized_at = EXCLUDED.sanitized_at
        """
    )
    op.execute("DROP FUNCTION IF EXISTS atlas_repair_mojibake_jsonb_10c(jsonb)")
    op.execute("DROP FUNCTION IF EXISTS atlas_repair_mojibake_10c(text)")


def downgrade() -> None:
    # O saneamento dos dados é deliberadamente irreversível.
    op.execute("DROP TABLE IF EXISTS atlas_data_quality_state")
