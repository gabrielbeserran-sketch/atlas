from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = {
    "backend/app/routers/saas_growth.py": [
        "@router.get('/onboarding')",
        "@router.post('/onboarding')",
        "@router.get('/onboarding/deployment-readiness')",
        "'persistent_progress': True",
    ],
    "lib/features/consultancy_client/data/services/atlas_client_onboarding_service.dart": [
        "'/saas-growth/onboarding'",
        "Future<AtlasClientOnboardingProgress> load()",
        "Future<AtlasClientOnboardingProgress> save(",
    ],
    "lib/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart": [
        "canonicalSteps",
        "farm_context",
        "herd_baseline",
        "technical_contact",
        "agenda_routine",
        "initial_training",
    ],
    "lib/features/consultancy_client/presentation/widgets/atlas_client_onboarding_card.dart": [
        "Implantação Atlas",
        "LinearProgressIndicator",
        "CheckboxListTile",
    ],
    "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart": [
        "AtlasClientOnboardingCard(",
        "onboardingService.load()",
        "onboardingService.save(optimistic)",
    ],
    "scripts/quality/check_post_v21_package9b_staged_release.ps1": [
        "RELEASE STATE: JA COMMITADO",
        "git cat-file -e",
    ],
}

errors: list[str] = []
for relative, markers in required.items():
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"arquivo ausente: {relative}")
        continue
    content = path.read_text(encoding="utf-8-sig")
    for marker in markers:
        if marker not in content:
            errors.append(f"{relative}: marcador ausente: {marker}")


contract = (ROOT / "test/features/consultancy_client/post_v21_package9c_onboarding_contract_test.dart").read_text(encoding="utf-8")
if "RegExp" not in contract or "compactService" not in contract:
    errors.append("contrato Flutter 9C deve validar chamadas HTTP de forma tolerante a formatacao")
if "service.contains(\"'POST', '/saas-growth/onboarding'\")" in contract:
    errors.append("contrato Flutter 9C voltou a depender de formatacao exata da chamada POST")


# Hygiene gate: release artifacts must not carry trailing whitespace.
release_text_files = [
    "ATLAS_REGISTRO_MESTRE.md",
    "backend/app/routers/saas_growth.py",
    "docs/ATLAS_POS_V21_PACOTE_9C_IMPLANTACAO_ATLAS_20260824.md",
    "docs/ATLAS_POS_V21_PACOTE_9C_MANIFEST.json",
    "lib/features/consultancy_client/data/services/atlas_client_onboarding_service.dart",
    "lib/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart",
    "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart",
    "lib/features/consultancy_client/presentation/widgets/atlas_client_onboarding_card.dart",
    "scripts/quality/check_post_v21_package9b_staged_release.ps1",
    "scripts/quality/check_post_v21_package9c_onboarding_deployed.ps1",
    "scripts/quality/check_post_v21_package9c_staged_release.ps1",
    "scripts/quality/run_post_v21_package9c_onboarding_homologation.ps1",
    "scripts/quality/run_post_v21_package9c_release_preflight.ps1",
    "scripts/quality/stage_post_v21_package9c_release.ps1",
    "test/features/consultancy_client/post_v21_package9c_onboarding_contract_test.dart",
    "tools/atlas_post_v21_package9c_onboarding_gate.py",
]
for relative in release_text_files:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"artefato de release ausente: {relative}")
        continue
    for line_number, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        if line.endswith((" ", "\t")):
            errors.append(f"{relative}:{line_number}: whitespace ao final da linha")

# Release hygiene must validate what can be versioned/published, not transient
# workstation files. Python execution legitimately creates ignored __pycache__/pyc
# files in a developer checkout. Treat them as a release problem only if Git tracks
# them. This avoids false negatives caused by local caches while still preventing
# compiled artifacts from entering a commit/package.
import subprocess

gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8-sig")
if "__pycache__/" not in gitignore:
    errors.append(".gitignore deve ignorar __pycache__/")
if "*.py[cod]" not in gitignore and "*.pyc" not in gitignore:
    errors.append(".gitignore deve ignorar artefatos Python compilados")

def _tracked_paths() -> list[str]:
    try:
        result = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files"],
            check=True, capture_output=True, text=True, encoding="utf-8", errors="replace"
        )
        return [line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()]
    except (OSError, subprocess.CalledProcessError):
        # Artifact-build environments may not contain .git. The distributable ZIP is
        # independently checked before delivery; do not classify local caches there.
        return []

for tracked in _tracked_paths():
    lower = tracked.lower()
    if "/__pycache__/" in f"/{lower}/" or lower.endswith(".pyc") or lower.endswith(".pyo"):
        errors.append(f"artefato Python compilado indevidamente rastreado pelo Git: {tracked}")


stage_script = (ROOT / "scripts/quality/stage_post_v21_package9c_release.ps1").read_text(encoding="utf-8-sig")
import re
if re.search(r"(?mi)^\s*(?:&\s*)?git\s+add\s+-A(?:\s|$)", stage_script):
    errors.append("staging 9C não pode executar git add -A")
if "git add -- $ReleasePaths" not in stage_script:
    errors.append("staging 9C deve limitar git add ao manifesto do pacote")
if "$Unexpected" not in stage_script:
    errors.append("staging 9C deve bloquear arquivos inesperados")

router = (ROOT / "backend/app/routers/saas_growth.py").read_text(encoding="utf-8")
if "require_permission('farms.read')" not in router:
    errors.append("GET onboarding não usa farms.read")
if "require_permission('farms.update')" not in router:
    errors.append("POST onboarding não usa farms.update")

if errors:
    print("ATLAS POS-V21 PACOTE 9C: REPROVADO")
    for error in errors:
        print(f"[ERRO] {error}")
    raise SystemExit(1)

print("ATLAS POS-V21 PACOTE 9C: APROVADO")
print("[OK] Progresso de implantação persistente.")
print("[OK] Central da Consultoria integrada.")
print("[OK] Permissões alinhadas a fazendas.")
print("[OK] Gate 9B endurecido para estado pós-commit.")
print("[OK] Higiene de release: caches locais ignorados; artefatos compilados rastreados bloqueados.")
