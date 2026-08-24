from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []


def check(label: str, condition: bool) -> None:
    if not condition:
        errors.append(label)


migration = ROOT / "backend/alembic/versions/20260824_0045_farm_handling_operations.py"
migration_text = migration.read_text(encoding="utf-8", errors="ignore") if migration.exists() else ""
render_yaml = (ROOT / "render.yaml").read_text(encoding="utf-8", errors="ignore")
render_start = (ROOT / "backend/scripts/render_start.sh").read_text(
    encoding="utf-8",
    errors="ignore",
)
router = (ROOT / "backend/app/routers/livestock.py").read_text(
    encoding="utf-8",
    errors="ignore",
)

check("migration 0045 ausente", migration.exists())
check(
    "migration 0045 fora da cadeia",
    'revision = "20260824_0045"' in migration_text
    and 'down_revision = "20260823_0044"' in migration_text,
)
check(
    "Render não usa startup oficial",
    "dockerCommand: /app/scripts/render_start.sh" in render_yaml,
)
check(
    "startup não aplica Alembic automaticamente",
    "python -m alembic upgrade head" in render_start,
)
check(
    "startup não confere migration/schema",
    "python -m scripts.render_post_migration_check" in render_start
    and "python -m scripts.render_schema_contract_check" in render_start,
)
check(
    "readiness 9B ausente",
    '"/handling/deployment-readiness"' in router
    and '"schema_ready": True' in router,
)

if errors:
    print(f"ATLAS 9B RELEASE GATE: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS 9B RELEASE GATE: APROVADO")
print("Migration: 0044 -> 0045")
print("Alembic produção: automático no Render")
