$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

Write-Host "=== ATLAS POS-V21 PACOTE 9C - PREFLIGHT DE RELEASE ===" -ForegroundColor Cyan

$RequiredPaths = @(
    "backend/app/routers/saas_growth.py",
    "lib/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart",
    "lib/features/consultancy_client/data/services/atlas_client_onboarding_service.dart",
    "lib/features/consultancy_client/presentation/widgets/atlas_client_onboarding_card.dart",
    "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart",
    "scripts/quality/run_post_v21_package9c_onboarding_homologation.ps1",
    "scripts/quality/run_post_v21_package9c_release_preflight.ps1",
    "scripts/quality/stage_post_v21_package9c_release.ps1",
    "scripts/quality/check_post_v21_package9c_staged_release.ps1",
    "scripts/quality/check_post_v21_package9c_onboarding_deployed.ps1",
    "scripts/quality/check_post_v21_package9b_staged_release.ps1",
    "tools/atlas_post_v21_package9c_onboarding_gate.py",
    "docs/ATLAS_POS_V21_PACOTE_9C_IMPLANTACAO_ATLAS_20260824.md",
    "docs/ATLAS_POS_V21_PACOTE_9C_MANIFEST.json",
    "ATLAS_REGISTRO_MESTRE.md"
)

foreach ($Path in $RequiredPaths) {
    if (-not (Test-Path $Path -PathType Leaf)) {
        throw "Arquivo obrigatório ausente: $Path"
    }
}

$ReleaseScripts = $RequiredPaths | Where-Object { $_ -like "*.ps1" }
foreach ($ScriptPath in $ReleaseScripts) {
    try {
        $ScriptText = Get-Content -LiteralPath $ScriptPath -Raw -Encoding UTF8
        [void][ScriptBlock]::Create($ScriptText)
    }
    catch {
        throw "PowerShell inválido em ${ScriptPath}: $($_.Exception.Message)"
    }
}
Write-Host "[OK] Sintaxe PowerShell dos scripts de release validada." -ForegroundColor Green

python ".\tools\atlas_post_v21_package9c_onboarding_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate estrutural 9C reprovado." }

$DiffOutput = & git -c core.pager=cat -c core.safecrlf=false diff --check 2>$null
if ($LASTEXITCODE -ne 0) {
    if ($DiffOutput) { $DiffOutput | Write-Host }
    throw "git diff --check encontrou inconsistências."
}

Write-Host ""
Write-Host "ATLAS 9C RELEASE PREFLIGHT: APROVADO" -ForegroundColor Green
Write-Host "Próxima ordem:" -ForegroundColor Yellow
Write-Host '  powershell -ExecutionPolicy Bypass -File ".\scripts\quality\stage_post_v21_package9c_release.ps1"'
Write-Host '  powershell -ExecutionPolicy Bypass -File ".\scripts\quality\check_post_v21_package9c_staged_release.ps1"'
