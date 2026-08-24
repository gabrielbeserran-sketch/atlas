$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))

Write-Host "=== ATLAS POS-V21 PACOTE 9E - HOMOLOGACAO ===" -ForegroundColor Cyan

$releaseScripts = @(
    ".\scripts\quality\run_post_v21_package9e_farm_scoped_onboarding_homologation.ps1",
    ".\scripts\quality\run_post_v21_package9e_release_preflight.ps1",
    ".\scripts\quality\stage_post_v21_package9e_release.ps1",
    ".\scripts\quality\check_post_v21_package9e_staged_release.ps1",
    ".\scripts\quality\check_post_v21_package9e_farm_scoped_onboarding_deployed.ps1"
)
foreach ($script in $releaseScripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script), [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        throw "Sintaxe PowerShell invalida em $script : $($errors[0].Message)"
    }
}
Write-Host "[OK] Sintaxe PowerShell dos scripts 9E validada." -ForegroundColor Green

python ".\tools\atlas_post_v21_package9e_farm_scoped_onboarding_gate.py"
if ($LASTEXITCODE -ne 0) { throw "Gate estrutural 9E reprovado." }

@'
from pathlib import Path
for name in [
    Path('backend/app/saas_growth_models.py'),
    Path('backend/app/routers/saas_growth.py'),
    Path('backend/alembic/versions/20260824_0046_onboarding_progress_farm_scope.py'),
]:
    source = name.read_text(encoding='utf-8-sig')
    compile(source, str(name), 'exec')
print('[OK] Sintaxe Python validada sem gerar cache.')
'@ | python -
if ($LASTEXITCODE -ne 0) { throw "Sintaxe Python 9E reprovada." }

flutter test ".\test\features\consultancy_client\post_v21_package9c_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Regressao 9C reprovada." }
flutter test ".\test\features\consultancy_client\post_v21_package9d_verified_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Regressao 9D reprovada." }
flutter test ".\test\features\consultancy_client\post_v21_package9e_farm_scoped_onboarding_contract_test.dart"
if ($LASTEXITCODE -ne 0) { throw "Contrato Flutter 9E reprovado." }

git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check encontrou inconsistencias." }

Write-Host "ATLAS POS-V21 PACOTE 9E: GATES APROVADOS" -ForegroundColor Green
Write-Host "Migration: 0045 -> 0046" -ForegroundColor Green
Write-Host "Alembic producao: automatico no Render" -ForegroundColor Green
