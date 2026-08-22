from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

main = (ROOT / "backend/app/main.py").read_text(
    encoding="utf-8",
    errors="ignore",
)
prod_env = (ROOT / "backend/.env.production.example").read_text(
    encoding="utf-8",
    errors="ignore",
)
checker = (
    ROOT / "scripts/quality/check_post_v21_package2_deployed.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")

checks = {}

def check(name, condition):
    checks[name] = bool(condition)

check(
    "produção desativa documentação",
    "ATLAS_DOCS_ENABLED=false" in prod_env,
)
check(
    "openapi depende da flag de docs",
    'openapi_url="/openapi.json" if settings.atlas_docs_enabled else None'
    in main,
)
check(
    "checker não depende de openapi",
    "openapi.json" not in checker.lower(),
)
check(
    "checker não depende de docs",
    '"/docs"' not in checker.lower()
    and '"/redoc"' not in checker.lower(),
)
check(
    "checker aquece health ready",
    '$HealthUrl = "$BaseUrl/health/ready"' in checker
    and "Invoke-AtlasWarmup" in checker,
)
check(
    "checker testa endpoint real",
    '$HandlingUrl = "$BaseUrl/livestock/handling/batch"' in checker,
)
check(
    "checker usa POST",
    "-Method POST" in checker,
)
check(
    "401 prova rota protegida",
    "$Code -in @(401, 403, 422)" in checker,
)
check(
    "404 permanece falha",
    "$Code -eq 404" in checker,
)
check(
    "405 é erro de contrato",
    "$Code -eq 405" in checker,
)
check(
    "checker possui retries",
    "Attempts = 6" in checker
    and "Attempts = 4" in checker,
)
check(
    "baseurl validada",
    "Assert-AtlasBaseUrl" in checker
    and "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl" in checker,
)

failed = [name for name, ok in checks.items() if not ok]
print(
    "ATLAS POST-V21 PACKAGE 2 DEPLOY CHECK: "
    f"{len(checks)-len(failed)}/{len(checks)}"
)
for name in failed:
    print("FAIL:", name)

sys.exit(1 if failed else 0)
