from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"

errors = []

# Automatic PowerShell variable: using it as a custom forwarding collection is unsafe
# and, with array splatting, does not preserve named-parameter semantics.
for path in SCRIPTS.rglob("*.ps1"):
    text = path.read_text(encoding="utf-8-sig", errors="ignore")

    for match in re.finditer(r"(?im)^\s*\$args\s*=", text):
        line = text[:match.start()].count("\n") + 1
        errors.append(
            f"{path.relative_to(ROOT)}:{line}: não atribua a $Args; "
            "é variável automática do PowerShell."
        )

    # Detect an array that contains strings beginning with '-' and is later splatted.
    # Array splatting is positional; '-BaseUrl' can become the value of BaseUrl.
    for match in re.finditer(
        r"(?is)\$(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*@\((?P<body>.*?)\)",
        text,
    ):
        name = match.group("name")
        body = match.group("body")
        if not re.search(r"""["']-[A-Za-z][A-Za-z0-9_-]*["']""", body):
            continue
        if re.search(rf"(?i)@{re.escape(name)}\b", text):
            line = text[:match.start()].count("\n") + 1
            errors.append(
                f"{path.relative_to(ROOT)}:{line}: array @{name} contém nomes "
                "de parâmetros e é splatado. Use hashtable splatting @{{...}}."
            )

critical = {
    "scripts/quality/run_post_v21_package1_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$V21Parameters = @{",
        'BaseUrl = $BaseUrl',
        '@V21Parameters',
    ),
    "scripts/quality/run_v21_ux_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
    ),
    "scripts/quality/gate_v16_v17_production.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
    ),
    "scripts/quality/run_post_v21_package2_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package1Parameters = @{",
        "@Package1Parameters",
    ),
    "scripts/quality/check_post_v21_package2_deployed.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
    ),
    "scripts/quality/run_post_v21_package3_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package2Parameters = @{",
        "@Package2Parameters",
    ),
    "scripts/quality/run_post_v21_package3_complete_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package3Parameters = @{",
        "@Package3Parameters",
    ),
    "scripts/quality/run_post_v21_package4_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package3CompleteParameters = @{",
        "@Package3CompleteParameters",
    ),
    "scripts/quality/run_post_v21_package5_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package4Parameters = @{",
        "@Package4Parameters",
    ),
    "scripts/quality/check_post_v21_package5_deployed.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
    ),
    "scripts/quality/run_post_v21_package6a_navigation_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package5Parameters = @{",
        "@Package5Parameters",
    ),
    "scripts/quality/run_post_v21_package6c_timeline_hotfix_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$Package6BParameters = @{",
        "@Package6BParameters",
    ),

    "scripts/quality/run_post_v21_package6c_capability_homologation.ps1": (
        "function Assert-AtlasBaseUrl",
        "$BaseUrl = Assert-AtlasBaseUrl -Value $BaseUrl",
        "$PreviousParameters = @{",
        "@PreviousParameters",
    ),

    "scripts/quality/run_post_v21_package6d_b_management_centers_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package6d_c_field_analysis_reports_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package6d_d_global_ux_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package7a_dr_beserra_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package7b_dr_beserra_voice_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package7c_rural_language_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package7d_safe_operations_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package7e_daily_routine_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package7f_contextual_intelligence_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package8a_security_camera_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package8b_edge_gateway_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package8c_camera_compatibility_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

    "scripts/quality/run_post_v21_package9a_vet_contact_homologation.ps1": (
        "$Previous = @{",
        "@Previous",
    ),

}

for rel, required in critical.items():
    path = ROOT / rel
    if not path.exists():
        errors.append(f"Arquivo crítico ausente: {rel}")
        continue
    text = path.read_text(encoding="utf-8-sig", errors="ignore")
    for fragment in required:
        if fragment not in text:
            errors.append(f"{rel}: proteção obrigatória ausente: {fragment}")

deploy_checker = (
    ROOT / "scripts/quality/check_post_v21_package2_deployed.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")

if "openapi.json" in deploy_checker.lower():
    errors.append(
        "Check pós-deploy do Pacote 2 não pode depender de /openapi.json; "
        "a documentação é desabilitada em produção."
    )

wrapper = (
    ROOT / "scripts/quality/run_post_v21_package1_homologation.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")

for forbidden in (
    '$Args = @("-BaseUrl", $BaseUrl)',
    '@Args',
):
    if forbidden in wrapper:
        errors.append(
            "run_post_v21_package1_homologation.ps1 ainda contém "
            f"encaminhamento inseguro: {forbidden}"
        )

if errors:
    print("ATLAS POWERSHELL PARAMETER FORWARDING: FAIL")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POWERSHELL PARAMETER FORWARDING: OK")
