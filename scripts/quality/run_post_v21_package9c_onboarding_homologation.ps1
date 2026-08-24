$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $ProjectRoot

Write-Host "=== ATLAS POS-V21 PACOTE 9C - HOMOLOGACAO ===" -ForegroundColor Cyan

$ReleaseScripts = @(
    ".\scripts\quality\run_post_v21_package9c_onboarding_homologation.ps1",
    ".\scripts\quality\run_post_v21_package9c_release_preflight.ps1",
    ".\scripts\quality\stage_post_v21_package9c_release.ps1",
    ".\scripts\quality\check_post_v21_package9c_staged_release.ps1",
    ".\scripts\quality\check_post_v21_package9c_onboarding_deployed.ps1",
    ".\scripts\quality\check_post_v21_package9b_staged_release.ps1"
)

foreach ($ScriptPath in $ReleaseScripts) {
    if (-not (Test-Path $ScriptPath -PathType Leaf)) {
        throw "Script de release ausente: $ScriptPath"
    }

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

python -c "from pathlib import Path; p=Path(r'.\backend\app\routers\saas_growth.py'); compile(p.read_text(encoding='utf-8-sig'), str(p), 'exec')"
if ($LASTEXITCODE -ne 0) { throw "Backend 9C não compilou." }
Write-Host "[OK] Backend validado sem gerar cache Python." -ForegroundColor Green

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter test ".\test\features\consultancy_client\post_v21_package9c_onboarding_contract_test.dart"
    if ($LASTEXITCODE -ne 0) { throw "Contrato Flutter 9C reprovado." }
} else {
    Write-Host "[AVISO] Flutter não encontrado neste terminal; contrato Flutter será validado no ambiente Windows do projeto." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ATLAS POS-V21 PACOTE 9C: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: nenhuma (reutiliza onboarding_progress existente)" -ForegroundColor Green
