from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

errors = []

def check(label, condition):
    if not condition:
        errors.append(label)

render_yaml = (ROOT / "render.yaml").read_text(encoding="utf-8", errors="ignore")
render_start = (ROOT / "backend/scripts/render_start.sh").read_text(
    encoding="utf-8", errors="ignore"
)
migration = (ROOT / "backend/alembic/versions/20260823_0043_security_camera_alerts.py")
migration_text = migration.read_text(encoding="utf-8", errors="ignore") if migration.exists() else ""
check_script = (
    ROOT / "scripts/quality/check_post_v21_package8a_security_camera_deployed.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")
homologation = (
    ROOT / "scripts/quality/run_post_v21_package8a_security_camera_homologation.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")

check(
    "Render não usa render_start.sh",
    "dockerCommand: /app/scripts/render_start.sh" in render_yaml,
)
check(
    "startup Render não aplica migrations",
    "python -m alembic upgrade head" in render_start,
)
check(
    "startup não verifica head pós-migration",
    "python -m scripts.render_post_migration_check" in render_start,
)
check(
    "startup não audita schema final",
    "python -m scripts.render_schema_contract_check" in render_start,
)
check("migration 0043 ausente", migration.exists())
check(
    "migration 0043 não encadeia 0042",
    'down_revision = "20260822_0042"' in migration_text,
)
check(
    "checker publicado não confirma schema",
    "schema_ready" in check_script
    and "Migration 0043 confirmada" in check_script,
)
check(
    "checker publicado não confirma chave IoT",
    "iot_ingest_key_configured" in check_script,
)
check(
    "homologação ainda manda rodar Alembic manualmente",
    "alembic upgrade head" not in homologation,
)

preflight_script = (
    ROOT / "scripts/quality/run_post_v21_package8a_release_preflight.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")
staged_script = (
    ROOT / "scripts/quality/check_post_v21_package8a_staged_release.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")

check(
    "preflight voltou a exigir git grep antes do staging",
    "git grep" not in preflight_script,
)
check(
    "preflight não valida migration no disco",
    "Test-Path $MigrationPath" in preflight_script
    and "revision está incorreta" in preflight_script
    and "não está encadeada à 0042" in preflight_script,
)
check(
    "preflight não verifica ignore da migration",
    "git check-ignore -q -- $MigrationPath" in preflight_script,
)
check(
    "preflight não desabilita pager",
    '$env:GIT_PAGER = "cat"' in preflight_script,
)
check(
    "preflight não neutraliza warning safecrlf no diff",
    "-c core.safecrlf=false diff --check" in preflight_script,
)
check(
    "check staged não exige migration rastreada",
    "git ls-files --error-unmatch" in staged_script,
)
check(
    "check staged não exige migration no staging",
    "diff --cached --name-only" in staged_script
    and "$StagedPaths -notcontains $MigrationPath" in staged_script,
)
check(
    "check staged não valida diff staged",
    "diff --cached --check" in staged_script,
)

if errors:
    print(f"ATLAS 8A RELEASE PREFLIGHT: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS 8A RELEASE PREFLIGHT: APROVADO")
print("Deploy: Git push -> Render startup -> Alembic head -> schema audit -> API")
print("Migration manual separada no Supabase: DESNECESSÁRIA")
