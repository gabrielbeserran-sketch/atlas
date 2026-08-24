$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9F - HOMOLOGACAO ===" -ForegroundColor Cyan

$releaseScripts = @(
    ".\scripts\quality\run_post_v21_package9f_consultancy_action_plan_homologation.ps1",
    ".\scripts\quality\run_post_v21_package9f_release_preflight.ps1",
    ".\scripts\quality\stage_post_v21_package9f_release.ps1",
    ".\scripts\quality\check_post_v21_package9f_staged_release.ps1",
    ".\scripts\quality\check_post_v21_package9f_consultancy_action_plan_deployed.ps1"
)
foreach ($script in $releaseScripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script), [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        throw "Sintaxe PowerShell invalida em $script : $($errors[0].Message)"
    }
}
Write-Host "[OK] Sintaxe PowerShell dos scripts 9F validada." -ForegroundColor Green

python ".\tools\atlas_post_v21_package9f_consultancy_action_plan_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate estrutural 9F reprovado." }

@'
from pathlib import Path
for name in [
    Path('backend/app/business_models.py'),
    Path('backend/app/routers/business.py'),
    Path('backend/app/routers/operations.py'),
    Path('backend/alembic/versions/20260824_0047_consultancy_action_idempotency.py'),
]:
    source = name.read_text(encoding='utf-8-sig')
    compile(source, str(name), 'exec')
print('[OK] Sintaxe Python validada sem gerar cache.')
'@ | python -
if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python 9F reprovada." }

flutter test ".\test\features\consultancy_client\post_v21_package9c_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Regressao 9C reprovada." }
flutter test ".\test\features\consultancy_client\post_v21_package9d_verified_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Regressao 9D reprovada." }
flutter test ".\test\features\consultancy_client\post_v21_package9e_farm_scoped_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Regressao 9E reprovada." }
flutter test ".\test\features\consultancy_client\post_v21_package9f_consultancy_action_plan_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Contrato Flutter 9F reprovado." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }

Write-Host "ATLAS POS-V21 PACOTE 9F: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: 0046 -> 0047" -ForegroundColor Green
Write-Host "Alembic producao: automatico no Render" -ForegroundColor Green
